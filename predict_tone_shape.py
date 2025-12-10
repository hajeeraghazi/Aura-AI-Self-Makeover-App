# predict_tone_shape.py
# AURA — Face Shape + Skin Tone Classifier
# Uses:
#   - EfficientNetB4 + CNN FULL .pth MODEL
#   - skin-tone-classifier (STONE)
#   - MediaPipe FaceMesh for alignment
#   - HEX → Human skin colour name conversion

import os
import io
import cv2
import numpy as np
import traceback
import logging
from typing import Optional, Dict, Any
import hashlib
import tempfile
import json

from PIL import Image, ImageOps
import mediapipe as mp


# ============================================================
# TORCH + EFFICIENTNET
# ============================================================
try:
    import torch
    from efficientnet_pytorch import EfficientNet
    TORCH_AVAILABLE = True
except Exception:
    TORCH_AVAILABLE = False


# ============================================================
# SKIN TONE (STONE)
# ============================================================
try:
    import stone
    STONE_AVAILABLE = True
except:
    STONE_AVAILABLE = False


logger = logging.getLogger("aura")
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


# ============================================================
# MODEL PATHS
# ============================================================
FACE_SHAPE_MODEL_PATH = "models/face_shape_model.pth"
FACE_LABELS = ["Oval", "Round", "Square", "Heart", "Diamond"]

DEVICE = (
    torch.device("cuda")
    if TORCH_AVAILABLE and torch.cuda.is_available()
    else torch.device("cpu") if TORCH_AVAILABLE else None
)


# ============================================================
# COLOR NAME FROM HEX
# ============================================================
def hex_to_color_name(hex_color: str) -> str:
    """Convert hex skin tone to human-friendly skin shade names."""

    if not hex_color or not isinstance(hex_color, str):
        return "Unknown"

    hex_color = hex_color.lstrip("#")

    try:
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
    except:
        return "Unknown"

    avg = (r + g + b) / 3

    if avg > 220:
        return "Porcelain (Very Fair)"
    elif avg > 200:
        return "Fair Beige"
    elif avg > 180:
        return "Warm Beige"
    elif avg > 160:
        return "Tan"
    elif avg > 130:
        return "Caramel"
    elif avg > 100:
        return "Brown"
    else:
        return "Deep Brown"


# ============================================================
# GLOBAL MODEL STORAGE
# ============================================================
_face_model = None
_transform = None


# ============================================================
# LOAD EfficientNetB4 (FULL MODEL)
# ============================================================
def init_face_shape_model():
    """Load full EfficientNetB4 face shape model (.pth)."""
    global _face_model, _transform

    if not TORCH_AVAILABLE:
        logger.error("Torch unavailable — cannot load face model.")
        return

    if _face_model is not None:
        return

    logger.info("Loading FULL EfficientNetB4 face shape model (.pth)...")

    try:
        model = torch.load(FACE_SHAPE_MODEL_PATH, map_location=DEVICE)
    except Exception:
        logger.exception("❌ Failed loading EfficientNet face model.")
        return

    model.to(DEVICE)
    model.eval()
    _face_model = model

    # preprocessing
    import torchvision.transforms as transforms
    _transform = transforms.Compose([
        transforms.Resize((380, 380)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225],
        ),
    ])

    logger.info("✔ EfficientNet face shape model loaded.")


# ============================================================
# RUN FACE SHAPE MODEL
# ============================================================
def run_effnet_face_shape(crop_bgr: np.ndarray):
    """Run EfficientNetB4 classification on cropped face."""
    try:
        if _face_model is None:
            init_face_shape_model()

        if crop_bgr is None:
            return None

        rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
        pil = Image.fromarray(rgb)

        img_t = _transform(pil).unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            logits = _face_model(img_t)
            probs = torch.softmax(logits, dim=1)[0].cpu().numpy()

        idx = int(np.argmax(probs))

        return {
            "shape": FACE_LABELS[idx].lower(),
            "trained_label": FACE_LABELS[idx],
            "confidence": float(probs[idx]),
            "method": "efficientnet"
        }

    except Exception:
        logger.exception("EfficientNet inference failed")
        return None


# ============================================================
# IMAGE UTILITIES
# ============================================================
MAX_MEDIAPIPE_DIM = 1024

def load_image_bytes_to_bgr(img_bytes: bytes):
    """Load + correct EXIF rotation → BGR numpy array."""
    try:
        pil = Image.open(io.BytesIO(img_bytes))
        pil = ImageOps.exif_transpose(pil)
        arr = np.array(pil.convert("RGB"))
        return cv2.cvtColor(arr, cv2.COLOR_RGB2BGR)
    except:
        logger.exception("Failed to decode image")
        return None


def resize_for_mediapipe(img, max_dim=MAX_MEDIAPIPE_DIM):
    """Resize large images."""
    h, w = img.shape[:2]
    if max(h, w) <= max_dim:
        return img
    scale = max_dim / max(h, w)
    return cv2.resize(img, (int(w * scale), int(h * scale)))


# ============================================================
# MEDIAPIPE FACE CROP
# ============================================================
mp_face_mesh = mp.solutions.face_mesh
FaceMesh = mp_face_mesh.FaceMesh


def get_rotation_angle(lm, w, h):
    try:
        le = lm.landmark[33]
        re = lm.landmark[263]
        dx = (re.x - le.x) * w
        dy = (re.y - le.y) * h
        return np.degrees(np.arctan2(dy, dx))
    except:
        return 0


def crop_face_from_landmarks(bgr, lm, margin=0.45):
    """Aligned face crop."""
    try:
        h, w = bgr.shape[:2]
        xs, ys = [], []

        for p in lm.landmark:
            xs.append(int(p.x * w))
            ys.append(int(p.y * h))

        xmin, xmax = min(xs), max(xs)
        ymin, ymax = min(ys), max(ys)

        bw = xmax - xmin
        bh = ymax - ymin
        size = max(bw, bh)

        cx = xmin + bw // 2
        cy = ymin + bh // 2
        half = int(size * (0.5 + margin))

        angle = get_rotation_angle(lm, w, h)
        mat = cv2.getRotationMatrix2D((cx, cy), angle, 1.0)
        rot = cv2.warpAffine(bgr, mat, (w, h), borderMode=cv2.BORDER_REPLICATE)

        x0 = max(0, cx - half)
        x1 = min(w, cx + half)
        y0 = max(0, cy - half)
        y1 = min(h, cy + half)

        crop = rot[y0:y1, x0:x1]
        return crop if crop.size else None

    except:
        return None


# ============================================================
# SKIN TONE VIA STONE
# ============================================================
SKIN_CACHE = {}

def classify_skin_tone_stone(img_bgr):
    """STONE model for skin tone → human color name."""
    if not STONE_AVAILABLE:
        return {"bucket": "unknown", "method": "stone_unavailable"}

    try:
        md5 = hashlib.md5(img_bgr.tobytes()).hexdigest()
        if md5 in SKIN_CACHE:
            return SKIN_CACHE[md5]

        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
            cv2.imwrite(tmp.name, img_bgr)
            path = tmp.name

        result = stone.process(path)
        os.remove(path)

        rec = result[0] if isinstance(result, list) and result else result
        faces = rec.get("faces", [])

        if not faces:
            return {"bucket": "unknown", "method": "stone"}

        f = faces[0]
        tone_label = f.get("tone_label", "unknown")
        hex_val = f.get("skin_tone")
        acc = f.get("accuracy", 0) / 100.0

        friendly = hex_to_color_name(hex_val)

        out = {
            "bucket": friendly,            # FINAL NAME
            "trained_label": tone_label,   # original classifier label
            "hex": hex_val,
            "friendly_color": friendly,
            "confidence": acc,
            "method": "stone",
        }

        SKIN_CACHE[md5] = out
        return out

    except:
        return {"bucket": "unknown", "method": "stone_error"}


# ============================================================
# MAIN API CLASS
# ============================================================
class SkinFaceClassifierAPI:
    def __init__(self):
        self.fm = FaceMesh(static_image_mode=True, max_num_faces=1, refine_landmarks=True)
        init_face_shape_model()

    def classify_image(self, img_bgr):
        try:
            if img_bgr is None:
                return {"success": False, "error": "invalid_image"}

            safe = resize_for_mediapipe(img_bgr)
            rgb = cv2.cvtColor(safe, cv2.COLOR_BGR2RGB)

            res = self.fm.process(rgb)
            if not res.multi_face_landmarks:
                return {"success": False, "error": "no_face_detected"}

            lm = res.multi_face_landmarks[0]

            # FACE CROP
            crop = crop_face_from_landmarks(safe, lm, margin=0.12)

            # SKIN TONE
            skin = classify_skin_tone_stone(safe)

            # FACE SHAPE
            face = run_effnet_face_shape(crop)
            if face is None:
                face = {
                    "shape": "unknown",
                    "trained_label": "Unknown",
                    "confidence": 0.0,
                    "method": "efficientnet_failed",
                }

            face["shape"] = face["shape"].capitalize()

            return {
                "success": True,
                "skin_tone": skin,
                "face_shape": face,
                "landmarks_detected": len(lm.landmark),
            }

        except Exception:
            return {
                "success": False,
                "error": "internal_error",
                "trace": traceback.format_exc(),
            }


# ============================================================
# CLI TEST
# ============================================================
if __name__ == "__main__":
    import sys
    init_face_shape_model()

    if len(sys.argv) < 2:
        print("Usage: python predict_tone_shape.py <image>")
        exit()

    img_path = sys.argv[1]

    with open(img_path, "rb") as f:
        data = f.read()

    img = load_image_bytes_to_bgr(data)
    api = SkinFaceClassifierAPI()
    out = api.classify_image(img)
    print(json.dumps(out, indent=2))
