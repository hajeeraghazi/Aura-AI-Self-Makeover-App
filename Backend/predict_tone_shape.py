# ============================================================
# predict_tone_shape.py — FINAL (UPDATED CONFIDENCE LOGIC)
# ============================================================

import os
import io
import cv2
import json
import torch
import hashlib
import tempfile
import traceback
import logging
import numpy as np
from PIL import Image, ImageOps
import mediapipe as mp

# ============================================================
# LOGGING
# ============================================================
logger = logging.getLogger("aura")
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())

# ============================================================
# DEVICE
# ============================================================
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ============================================================
# MODEL CONFIG
# ============================================================
FACE_SHAPE_MODEL_PATH = "models/face_shape_model.pth"

# ✅ CORRECT ImageFolder order
FACE_LABELS = ["Diamond", "Heart", "Oval", "Round", "Square"]

# 🔥 UPDATED THRESHOLD (was 0.45)
CONFIDENCE_THRESHOLD = 0.35

# ============================================================
# LOAD FACE SHAPE MODEL
# ============================================================
_face_model = None
_transform = None

def init_face_shape_model():
    global _face_model, _transform

    if _face_model is not None:
        return

    logger.info("Loading face shape model...")

    model = torch.load(FACE_SHAPE_MODEL_PATH, map_location=DEVICE)
    model.eval().to(DEVICE)

    out_features = model.classifier[-1].out_features
    if out_features != len(FACE_LABELS):
        raise RuntimeError("Face shape class count mismatch")

    _face_model = model

    import torchvision.transforms as transforms
    _transform = transforms.Compose([
        transforms.Resize((380, 380)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225],
        ),
    ])

    logger.info("✔ Face shape model loaded successfully")

# ============================================================
# IMAGE UTILITIES
# ============================================================
def load_image_bytes_to_bgr(img_bytes: bytes):
    pil = Image.open(io.BytesIO(img_bytes))
    pil = ImageOps.exif_transpose(pil).convert("RGB")
    return cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)

def resize_for_mediapipe(img, max_dim=1024):
    h, w = img.shape[:2]
    if max(h, w) <= max_dim:
        return img
    s = max_dim / max(h, w)
    return cv2.resize(img, (int(w*s), int(h*s)))

# ============================================================
# MEDIAPIPE FACE MESH
# ============================================================
mp_face_mesh = mp.solutions.face_mesh
FaceMesh = mp_face_mesh.FaceMesh

def crop_face_from_landmarks(bgr, lm):
    h, w = bgr.shape[:2]
    xs = [int(p.x * w) for p in lm.landmark]
    ys = [int(p.y * h) for p in lm.landmark]

    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)

    size = int(max(xmax - xmin, ymax - ymin) * 0.6)
    cx, cy = (xmin + xmax) // 2, (ymin + ymax) // 2

    x0, x1 = max(0, cx - size), min(w, cx + size)
    y0, y1 = max(0, cy - size), min(h, cy + size)

    crop = bgr[y0:y1, x0:x1]
    return crop if crop.size else None

# ============================================================
# FACE SHAPE CLASSIFICATION
# ============================================================
def classify_face_shape(crop_bgr):
    if crop_bgr is None:
        return {"shape": "Unknown", "confidence": 0.0}

    init_face_shape_model()

    rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
    pil = Image.fromarray(rgb)
    img_t = _transform(pil).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        logits = _face_model(img_t)
        probs = torch.softmax(logits, dim=1)[0].cpu().numpy()

    logger.info("Face shape probs: %s",
                dict(zip(FACE_LABELS, probs.round(3))))

    idx = int(np.argmax(probs))
    conf = float(probs[idx])

    if conf < CONFIDENCE_THRESHOLD:
        return {"shape": "Unknown", "confidence": conf}

    return {
        "shape": FACE_LABELS[idx],
        "confidence": conf
    }

# ============================================================
# SKIN TONE (STONE) — SAFE VERSION
# ============================================================
try:
    import stone
    STONE_AVAILABLE = True
except:
    STONE_AVAILABLE = False

SKIN_CACHE = {}

def hex_to_color_name(hex_color):
    if not hex_color:
        return "Unknown"
    hex_color = hex_color.lstrip("#")
    r, g, b = [int(hex_color[i:i+2], 16) for i in (0,2,4)]
    avg = (r + g + b) / 3

    if avg > 220: return "Porcelain"
    if avg > 200: return "Fair"
    if avg > 180: return "Light"
    if avg > 160: return "Medium"
    if avg > 130: return "Tan"
    if avg > 100: return "Brown"
    return "Deep Brown"

def classify_skin_tone(img_bgr):
    if not STONE_AVAILABLE:
        return {"bucket": "Unknown", "confidence": 0.0}

    try:
        md5 = hashlib.md5(img_bgr.tobytes()).hexdigest()
        if md5 in SKIN_CACHE:
            return SKIN_CACHE[md5]

        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
            cv2.imwrite(tmp.name, img_bgr)
            path = tmp.name

        result = stone.process(path)
        os.remove(path)

        if isinstance(result, list) and result:
            rec = result[0]
        elif isinstance(result, dict):
            rec = result
        else:
            return {"bucket": "Unknown", "confidence": 0.0}

        faces = rec.get("faces", [])
        if not faces:
            return {"bucket": "Unknown", "confidence": 0.0}

        f = faces[0]
        hex_val = f.get("skin_tone")
        conf = f.get("accuracy", 0) / 100.0

        out = {
            "bucket": hex_to_color_name(hex_val),
            "hex": hex_val,
            "trained_label": f.get("tone_label", "unknown"),
            "confidence": conf,
            "method": "stone"
        }

        SKIN_CACHE[md5] = out
        return out

    except Exception:
        logger.exception("Skin tone classification failed")
        return {"bucket": "Unknown", "confidence": 0.0}

# ============================================================
# MAIN PIPELINE CLASS
# ============================================================
class SkinFaceClassifierAPI:
    def __init__(self):
        self.fm = FaceMesh(static_image_mode=True, max_num_faces=1, refine_landmarks=True)
        init_face_shape_model()

    def classify_image(self, img_bgr):
        try:
            img = resize_for_mediapipe(img_bgr)
            rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

            res = self.fm.process(rgb)
            if not res.multi_face_landmarks:
                return {"success": False, "error": "no_face_detected"}

            lm = res.multi_face_landmarks[0]
            crop = crop_face_from_landmarks(img, lm)

            return {
                "success": True,
                "face_shape": classify_face_shape(crop),
                "skin_tone": classify_skin_tone(img),
                "landmarks_detected": len(lm.landmark)
            }

        except Exception:
            return {
                "success": False,
                "error": "internal_error",
                "trace": traceback.format_exc()
            }
