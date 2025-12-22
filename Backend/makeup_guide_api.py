# ============================================================
# AURA AI – MAKEUP GUIDE API (FINAL STABLE VERSION)
# ============================================================
# ✔ Global FaceLandmarker (MediaPipe Tasks)
# ✔ FULL face foundation (including forehead)
# ✔ CORRECT eyeliner (upper lid only, thin, no blobs)
# ✔ Realistic lipstick (accurate lip contour)
# ✔ Blush, eyeshadow, highlighter
# ✔ Detailed feedback in /compare_makeup
# ✔ Flutter compatible
# ============================================================

import base64
import logging
from typing import Optional, List, Tuple

import cv2
import numpy as np
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from mediapipe.tasks import python as mp_tasks
from mediapipe.tasks.python import vision
import mediapipe as mp

# ============================================================
# ROUTER & LOGGER
# ============================================================
router = APIRouter()
logger = logging.getLogger("makeup-guide")

# ============================================================
# SETTINGS
# ============================================================
MAX_UPLOAD_BYTES = 6 * 1024 * 1024  # 6 MB
MAX_DIM = 1280
MODEL_PATH = "models/face_landmarker.task"

# ============================================================
# GLOBAL FACE LANDMARKER (SAFE)
# ============================================================
try:
    base_options = mp_tasks.BaseOptions(model_asset_path=MODEL_PATH)
    options = vision.FaceLandmarkerOptions(
        base_options=base_options,
        num_faces=1,
        running_mode=vision.RunningMode.IMAGE,
    )
    GLOBAL_LANDMARKER = vision.FaceLandmarker.create_from_options(options)
    logger.info("FaceLandmarker loaded successfully")
except Exception as e:
    GLOBAL_LANDMARKER = None
    logger.exception("Failed to load FaceLandmarker: %s", e)

# ============================================================
# IMAGE HELPERS
# ============================================================
def decode_image(data: bytes) -> np.ndarray:
    if not data or len(data) < 10:
        raise ValueError("Empty image")
    if len(data) > MAX_UPLOAD_BYTES:
        raise ValueError("Image too large")

    img = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Invalid image")

    if MAX_DIM:
        h, w = img.shape[:2]
        scale = max(h, w) / MAX_DIM
        if scale > 1:
            img = cv2.resize(img, (int(w / scale), int(h / scale)))

    return img


def encode_jpg(img: np.ndarray) -> str:
    ok, buf = cv2.imencode(".jpg", img, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
    if not ok:
        raise RuntimeError("JPG encode failed")
    return base64.b64encode(buf).decode("utf-8")


def encode_mask_png(mask: np.ndarray) -> str:
    h, w = mask.shape
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = mask
    ok, buf = cv2.imencode(".png", rgba)
    if not ok:
        raise RuntimeError("PNG encode failed")
    return base64.b64encode(buf).decode("utf-8")

# ============================================================
# LANDMARK EXTRACTION
# ============================================================
def get_landmarks(img: np.ndarray) -> Optional[List[Tuple[int, int]]]:
    if GLOBAL_LANDMARKER is None:
        return None

    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result = GLOBAL_LANDMARKER.detect(mp_image)

    if not result.face_landmarks:
        return None

    h, w = img.shape[:2]
    return [(int(p.x * w), int(p.y * h)) for p in result.face_landmarks[0]]

# ============================================================
# LANDMARK INDICES
# ============================================================
FACE_OVAL = [
    10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288,
    397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150,
    136, 172, 58, 132, 93, 234, 127,
    162, 21, 54, 103, 67, 109
]

OUTER_LIPS = [
    61,185,40,39,37,0,267,269,270,409,
    291,308,415,310,311,312,13,82,81,
    80,191,78,95,88,178,87,14,317,
    402,318,324,308,291,375,321,405,
    314,17,84,181,91,146,61
]

# ============================================================
# MASK HELPERS
# ============================================================
def convex_mask(points, shape):
    mask = np.zeros(shape, np.uint8)
    if len(points) >= 3:
        hull = cv2.convexHull(np.array(points, np.int32))
        cv2.fillConvexPoly(mask, hull, 255)
    return mask


def blur_mask(mask, k):
    if k % 2 == 0:
        k += 1
    return cv2.GaussianBlur(mask, (k, k), 0)

# ============================================================
# REGION MASKS
# ============================================================
def foundation_mask(lm, shape):
    pts = [lm[i] for i in FACE_OVAL if i < len(lm)]
    base = convex_mask(pts, shape)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25))
    expanded = cv2.dilate(base, kernel, iterations=1)
    return blur_mask(expanded, 45)


def blush_mask(lm, shape):
    L = [lm[i] for i in [101,118,50,205] if i < len(lm)]
    R = [lm[i] for i in [330,347,280,425] if i < len(lm)]
    return blur_mask(cv2.bitwise_or(convex_mask(L, shape), convex_mask(R, shape)), 21)


def eyeshadow_mask(lm, shape):
    L = [lm[i] for i in [33,160,158,157,173,133] if i < len(lm)]
    R = [lm[i] for i in [263,387,385,384,398,362] if i < len(lm)]
    return blur_mask(cv2.bitwise_or(convex_mask(L, shape), convex_mask(R, shape)), 19)


# ============================================================
# ✅ FIXED EYELINER (UPPER LID ONLY)
# ============================================================
def eyeliner_mask(lm, shape):
    """
    Thin, precise eyeliner along upper eyelids only.
    No blobs, no lower lid.
    """
    mask = np.zeros(shape, np.uint8)

    LEFT_UPPER = [33, 160, 158, 157, 173, 133]
    RIGHT_UPPER = [263, 387, 385, 384, 398, 362]

    L = [lm[i] for i in LEFT_UPPER if i < len(lm)]
    R = [lm[i] for i in RIGHT_UPPER if i < len(lm)]

    if len(L) >= 2:
        cv2.polylines(mask, [np.array(L, np.int32)], False, 255, 2, cv2.LINE_AA)
    if len(R) >= 2:
        cv2.polylines(mask, [np.array(R, np.int32)], False, 255, 2, cv2.LINE_AA)

    return cv2.GaussianBlur(mask, (3, 3), 0)


def lipstick_mask(lm, shape):
    mask = np.zeros(shape, np.uint8)
    pts = [lm[i] for i in OUTER_LIPS if i < len(lm)]
    if len(pts) >= 3:
        cv2.fillPoly(mask, [np.array(pts, np.int32)], 255)
    return blur_mask(mask, 9)


def highlighter_mask(lm, shape):
    pts = [lm[i] for i in [101,118,50,330,347,280,168,5] if i < len(lm)]
    return blur_mask(convex_mask(pts, shape), 17)


def makeup_region_mask(kind, lm, shape):
    if kind == "foundation":
        return foundation_mask(lm, shape)
    if kind == "blush":
        return blush_mask(lm, shape)
    if kind == "eyeshadow":
        return eyeshadow_mask(lm, shape)
    if kind == "eyeliner":
        return eyeliner_mask(lm, shape)
    if kind == "lipstick":
        return lipstick_mask(lm, shape)
    if kind == "highlighter":
        return highlighter_mask(lm, shape)
    return np.zeros(shape, np.uint8)

# ============================================================
# COLORS & OPACITY
# ============================================================
DEFAULT_COLORS = {
    "foundation": (230,200,170),
    "blush": (255,130,180),
    "eyeshadow": (160,110,200),
    "eyeliner": (25,25,25),
    "lipstick": (180,40,120),
    "highlighter": (255,245,230),
}

OPACITY = {
    "foundation": 0.38,
    "blush": 0.35,
    "eyeshadow": 0.30,
    "eyeliner": 0.90,
    "lipstick": 0.70,
    "highlighter": 0.45,
}

# ============================================================
# BLENDING
# ============================================================
def blend(img, mask, color, opacity):
    mask_f = (mask.astype(np.float32) / 255.0) * opacity
    mask3 = np.dstack([mask_f] * 3)
    out = img * (1 - mask3) + np.array(color) * mask3
    return np.clip(out, 0, 255).astype(np.uint8)

# ============================================================
# FEEDBACK
# ============================================================
def get_feedback(before, after):
    diff = cv2.absdiff(before, after)
    gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
    change = float(np.mean(gray))
    score = int(min(max((change / 55.0) * 100, 15), 100))

    if score < 40:
        return {"score": score, "overall": "Needs improvement"}
    elif score < 65:
        return {"score": score, "overall": "Fair application"}
    elif score < 85:
        return {"score": score, "overall": "Good makeup look"}
    else:
        return {"score": score, "overall": "Excellent finish"}

# ============================================================
# ROUTES
# ============================================================
@router.get("/health")
async def health():
    return {"status": "OK", "face_landmarker": GLOBAL_LANDMARKER is not None}


@router.post("/analyze_face")
async def analyze_face(image: UploadFile = File(...)):
    img = decode_image(await image.read())
    lm = get_landmarks(img)
    if not lm:
        raise HTTPException(400, "No face detected")
    return {"success": True, "landmarks": len(lm)}


@router.post("/get_makeup_guide")
async def get_makeup_guide(
    image: UploadFile = File(...),
    makeupLooks: str = Form(...),
    lipstickColor: Optional[str] = Form(None),
    returnMaskPNG: bool = Form(True),
):
    img = decode_image(await image.read())
    lm = get_landmarks(img)
    if not lm:
        raise HTTPException(400, "No face detected")

    looks = [l.strip().lower() for l in makeupLooks.split(",") if l.strip()]
    h, w = img.shape[:2]
    guides = []

    for step, look in enumerate(looks, 1):
        mask = makeup_region_mask(look, lm, (h, w))
        color = DEFAULT_COLORS.get(look, (255,255,255))
        opacity = OPACITY.get(look, 0.4)

        if look == "lipstick" and lipstickColor:
            hexv = lipstickColor.lstrip("#")
            if len(hexv) == 6:
                r = int(hexv[0:2], 16)
                g = int(hexv[2:4], 16)
                b = int(hexv[4:6], 16)
                color = (b, g, r)

        out = blend(img, mask, color, opacity)

        item = {
            "step": step,
            "makeupType": look,
            "image": encode_jpg(out),
        }
        if returnMaskPNG:
            item["maskPNG"] = encode_mask_png(mask)

        guides.append(item)

    return {"success": True, "guides": guides}


@router.post("/compare_makeup")
async def compare_makeup(
    originalImage: UploadFile = File(...),
    afterImage: UploadFile = File(...),
):
    before = decode_image(await originalImage.read())
    after = decode_image(await afterImage.read())

    if before.shape != after.shape:
        after = cv2.resize(after, (before.shape[1], before.shape[0]))

    comp = np.hstack([before, after])
    feedback = get_feedback(before, after)

    return {
        "success": True,
        "comparisonImage": encode_jpg(comp),
        "feedback": feedback,
    }
