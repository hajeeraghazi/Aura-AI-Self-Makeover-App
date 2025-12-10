# makeup_guide_api.py — STABLE WITH BETTER LOGGING (UPDATED + FEEDBACK)
# ============================================================
# - Global FaceLandmarker (fast, safer error handling)
# - More accurate regions (blush, eyeshadow, eyeliner, lipstick, highlighter)
# - Feedback from /compare_makeup (score + tips)
# - Works with Flutter endpoints:
#     /api/makeup_guide/health
#     /api/makeup_guide/analyze_face
#     /api/makeup_guide/get_makeup_guide
#     /api/makeup_guide/compare_makeup
# ============================================================

import base64
import logging
from typing import Optional, List, Tuple

import cv2
import numpy as np
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from mediapipe.tasks import python as mp_tasks
from mediapipe.tasks.python import vision
import mediapipe as mp  # for mp.Image and mp.ImageFormat

router = APIRouter()
logger = logging.getLogger("makeup-guide")

# ============================================================
# SETTINGS
# ============================================================
MAX_UPLOAD_BYTES = 6 * 1024 * 1024  # 6 MB
MAX_DIM = 1280
MODEL_PATH = "models/face_landmarker.task"  # make sure this file exists


# ============================================================
# GLOBAL LANDMARKER (fast, explicit running mode)
# ============================================================
try:
    base_options = mp_tasks.BaseOptions(model_asset_path=MODEL_PATH)
    landmarker_options = vision.FaceLandmarkerOptions(
        base_options=base_options,
        num_faces=1,
        running_mode=vision.RunningMode.IMAGE,
        output_face_blendshapes=False,
        output_facial_transformation_matrixes=False,
    )
    GLOBAL_LANDMARKER = vision.FaceLandmarker.create_from_options(
        landmarker_options
    )
    logger.info("FaceLandmarker loaded successfully from %s", MODEL_PATH)
except Exception as e:
    GLOBAL_LANDMARKER = None
    logger.exception("Failed to load FaceLandmarker model from %s: %s", MODEL_PATH, e)


# ============================================================
# IMAGE HELPERS
# ============================================================
def decode_image(file_bytes: bytes) -> np.ndarray:
    """Decode bytes → BGR image, resize for speed."""
    if not file_bytes or len(file_bytes) < 10:
        raise ValueError("Empty image or too few bytes")
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise ValueError("Image too large")

    arr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Could not decode image (cv2.imdecode returned None)")

    # Optional: normalize orientation (simple, EXIF-safe-ish)
    try:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    except Exception as e:
        logger.warning("decode_image: orientation normalization failed: %s", e)

    if MAX_DIM:
        h, w = img.shape[:2]
        scale = max(h, w) / float(MAX_DIM)
        if scale > 1.0:
            img = cv2.resize(img, (int(w / scale), int(h / scale)))
    return img


def encode_jpg(img: np.ndarray) -> str:
    ok, buf = cv2.imencode(".jpg", img, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
    if not ok:
        raise RuntimeError("JPG encode failed")
    return base64.b64encode(buf.tobytes()).decode("utf-8")


def encode_mask_png(mask: np.ndarray) -> str:
    """Encode single-channel mask as RGBA PNG (transparent outside)."""
    h, w = mask.shape
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[:, :, 3] = mask
    rgba[:, :, 0:3] = 255

    ok, buf = cv2.imencode(".png", rgba)
    if not ok:
        raise RuntimeError("PNG encode failed")
    return base64.b64encode(buf.tobytes()).decode("utf-8")


# ============================================================
# LANDMARKS (MediaPipe Tasks API)
# ============================================================
def get_landmarks(img: np.ndarray) -> Optional[List[Tuple[int, int]]]:
    """
    Uses global FaceLandmarker instance.
    Returns list of (x, y) pixels for 478 landmarks or None.
    Any internal MediaPipe error is logged and returns None.
    """
    if GLOBAL_LANDMARKER is None:
        logger.error("get_landmarks: GLOBAL_LANDMARKER is not initialized")
        return None

    try:
        # BGR → RGB
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    except Exception as e:
        logger.exception("get_landmarks: cvtColor failed: %s", e)
        return None

    try:
        mp_image = mp.Image(
            image_format=mp.ImageFormat.SRGB,
            data=rgb,
        )
        result = GLOBAL_LANDMARKER.detect(mp_image)
    except Exception as e:
        logger.exception("get_landmarks: FaceLandmarker.detect failed: %s", e)
        return None

    if not result.face_landmarks:
        return None

    h, w = img.shape[:2]
    pts = [(int(lm.x * w), int(lm.y * h)) for lm in result.face_landmarks[0]]
    return pts


# ============================================================
# INDICES FOR REGIONS
# (still here for reference; some masks use custom subsets)
# ============================================================
FACE = [
    10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379,
    378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127,
    162, 21, 54, 103, 67, 109
]

LEFT_CHEEK = [50, 101, 118, 199, 200, 201]
RIGHT_CHEEK = [280, 330, 347, 346, 345, 444]

LEFT_EYE = [33, 7, 163, 144, 145, 153, 154, 155, 133]
RIGHT_EYE = [362, 382, 381, 380, 374, 373, 390, 249, 263]

OUTER_LIPS = [61, 185, 40, 39, 37, 267, 269, 270, 409, 291, 375, 321, 405, 314]
INNER_LIPS = [78, 191, 80, 81, 82, 13, 312, 311, 310, 415, 308, 324, 318, 402]


# ============================================================
# MASK HELPERS
# ============================================================
def convex_mask(points, shape):
    mask = np.zeros(shape, np.uint8)
    if len(points) >= 3:
        hull = cv2.convexHull(np.array(points, np.int32))
        cv2.fillConvexPoly(mask, hull, 255)
    return mask


def blur_mask(mask, k=25):
    if k % 2 == 0:
        k += 1
    return cv2.GaussianBlur(mask, (k, k), 0)


# ---- More accurate masks per region ----

def foundation_mask(lm, shape):
    h, w = shape
    pts = [lm[i] for i in FACE if i < len(lm)]
    return blur_mask(convex_mask(pts, (h, w)), 35)


def blush_mask(lm, shape):
    """
    Blush only on the apples of cheeks – tighter region.
    """
    h, w = shape
    left_pts = [lm[i] for i in [101, 118, 50, 205] if i < len(lm)]
    right_pts = [lm[i] for i in [330, 347, 280, 425] if i < len(lm)]

    L = convex_mask(left_pts, (h, w))
    R = convex_mask(right_pts, (h, w))

    return blur_mask(cv2.bitwise_or(L, R), 20)


def eyeshadow_mask(lm, shape):
    """
    Eyeshadow mainly along upper eyelid.
    """
    h, w = shape
    left_pts = [lm[i] for i in [33, 160, 158, 159, 157, 173, 133] if i < len(lm)]
    right_pts = [lm[i] for i in [263, 387, 385, 386, 384, 398, 362] if i < len(lm)]

    L = convex_mask(left_pts, (h, w))
    R = convex_mask(right_pts, (h, w))

    return blur_mask(cv2.bitwise_or(L, R), 15)


def eyeliner_mask(lm, shape):
    """
    Eyeliner very close to lash line – thinner region than eyeshadow.
    """
    h, w = shape
    left_pts = [lm[i] for i in [33, 133, 159, 145] if i < len(lm)]
    right_pts = [lm[i] for i in [263, 362, 386, 374] if i < len(lm)]

    L = convex_mask(left_pts, (h, w))
    R = convex_mask(right_pts, (h, w))

    return blur_mask(cv2.bitwise_or(L, R), 7)


def lipstick_mask(lm, shape):
    """
    Lipstick closely following outer lip contour, small blur.
    """
    h, w = shape
    pts = [lm[i] for i in OUTER_LIPS if i < len(lm)]
    base = convex_mask(pts, (h, w))
    return blur_mask(base, 7)


def highlighter_mask(lm, shape):
    """
    Highlighter on upper cheekbones – small soft area.
    """
    h, w = shape
    left_pts = [lm[i] for i in [101, 118, 50] if i < len(lm)]
    right_pts = [lm[i] for i in [330, 347, 280] if i < len(lm)]

    L = convex_mask(left_pts, (h, w))
    R = convex_mask(right_pts, (h, w))

    return blur_mask(cv2.bitwise_or(L, R), 12)


def makeup_region_mask(kind: str, lm, shape):
    """Return soft mask for each makeup kind."""
    h, w = shape

    if kind == "foundation":
        return foundation_mask(lm, (h, w))

    if kind == "blush":
        return blush_mask(lm, (h, w))

    if kind == "eyeshadow":
        return eyeshadow_mask(lm, (h, w))

    if kind == "eyeliner":
        return eyeliner_mask(lm, (h, w))

    if kind == "lipstick":
        return lipstick_mask(lm, (h, w))

    if kind == "highlighter":
        return highlighter_mask(lm, (h, w))

    # Fallback: no mask
    return np.zeros((h, w), np.uint8)


# ============================================================
# BLENDING
# ============================================================
DEFAULT_COLORS = {
    "foundation": (230, 200, 170),
    "blush": (255, 130, 180),
    "eyeshadow": (180, 80, 255),
    "eyeliner": (40, 40, 40),
    "lipstick": (180, 40, 120),
    "highlighter": (255, 240, 210),
}

OPACITY = {
    "foundation": 0.30,
    "blush": 0.40,
    "eyeshadow": 0.45,
    "eyeliner": 0.80,
    "lipstick": 0.70,
    "highlighter": 0.35,
}


def blend(img, mask, color, opacity):
    """Alpha-blend solid color into img using soft mask."""
    mask_f = (mask.astype(np.float32) / 255.0) * float(opacity)
    mask3 = np.stack([mask_f] * 3, axis=-1)
    color3 = np.array(color, dtype=np.float32)

    out = img.astype(np.float32) * (1.0 - mask3) + color3 * mask3
    return np.clip(out, 0, 255).astype(np.uint8)


# ============================================================
# FEEDBACK (for compare_makeup)
# ============================================================
def get_feedback(before: np.ndarray, after: np.ndarray) -> dict:
    """
    Simple heuristic feedback based on how different the
    'after' image is from the 'before' image.
    """
    diff = cv2.absdiff(before, after)
    gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)

    mean_change = float(np.mean(gray))  # 0–255

    # Map mean_change (approx 0–80 in practice) to 10–100
    norm = min(max(mean_change / 50.0, 0.0), 1.0)  # 0–1
    score = int(10 + norm * 90)  # 10–100

    tips: List[str] = []

    if score < 40:
        tips.append("Try applying a bit more product so the effect is clearer.")
        tips.append("Make sure lighting is even and your face is fully visible.")
    elif score < 60:
        tips.append("Good start! Work on blending for a smoother finish.")
    elif score < 80:
        tips.append("Nice application. You can refine symmetry for an even better look.")
    else:
        tips.append("Great job! Your makeup looks even and well-blended.")

    overall: str
    if score >= 85:
        overall = "Excellent finish — very polished look!"
    elif score >= 65:
        overall = "Good look — just a few small tweaks needed."
    else:
        overall = "Keep practicing blending and placement to enhance the result."

    return {
        "score": score,
        "overall": overall,
        "tips": tips,
    }


# ============================================================
# ROUTES
# ============================================================

@router.get("/health")
async def health():
    return {
        "status": "OK",
        "face_landmarker": "active" if GLOBAL_LANDMARKER is not None else "error",
    }


# -----------------------------
# ANALYZE FACE
# -----------------------------
@router.post("/analyze_face")
async def analyze_face(image: UploadFile = File(...)):
    try:
        data = await image.read()
        logger.info("analyze_face: received %d bytes", len(data))

        try:
            img = decode_image(data)
        except ValueError as ve:
            logger.warning("analyze_face: decode_image error: %s", ve)
            raise HTTPException(status_code=400, detail=str(ve))

        logger.info("analyze_face: image shape %s", img.shape)

        lm = get_landmarks(img)
        if lm is None:
            logger.warning("analyze_face: landmarks not found or detector failed")
            raise HTTPException(status_code=400, detail="No face detected")

        return {"success": True, "landmarks": len(lm)}

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("analyze_face failed: %s", e)
        raise HTTPException(status_code=500, detail="Face analysis failed")


# -----------------------------
# GET MAKEUP GUIDE
# -----------------------------
@router.post("/get_makeup_guide")
async def get_makeup_guide(
    image: UploadFile = File(...),
    makeupLooks: str = Form(...),
    lipstickColor: Optional[str] = Form(None),
    returnMaskPNG: bool = Form(True),
):
    """
    Flutter sends:
      makeupLooks = "foundation,blush,eyeshadow,eyeliner,lipstick,highlighter"
      lipstickColor = "f44336" (no #)
    """
    try:
        data = await image.read()
        logger.info("get_makeup_guide: received %d bytes", len(data))

        try:
            img = decode_image(data)
        except ValueError as ve:
            logger.warning("get_makeup_guide: decode_image error: %s", ve)
            raise HTTPException(status_code=400, detail=str(ve))

        logger.info("get_makeup_guide: image shape %s", img.shape)

        lm = get_landmarks(img)
        if not lm:
            logger.warning("get_makeup_guide: landmarks not found or detector failed")
            raise HTTPException(status_code=400, detail="No face detected")

        looks = [
            l.strip().lower()
            for l in makeupLooks.split(",")
            if l.strip()
        ]

        h, w = img.shape[:2]
        guides = []

        for step, look in enumerate(looks, 1):
            if look not in DEFAULT_COLORS:
                raise HTTPException(
                    status_code=400,
                    detail=f"Unknown makeup type '{look}'",
                )

            mask = makeup_region_mask(look, lm, (h, w))
            color = DEFAULT_COLORS[look]

            if look == "lipstick" and lipstickColor:
                hex_str = lipstickColor.lstrip("#").strip()
                if len(hex_str) == 6:
                    r = int(hex_str[0:2], 16)
                    g = int(hex_str[2:4], 16)
                    b = int(hex_str[4:6], 16)
                    color = (b, g, r)

            out = blend(img, mask, color, OPACITY.get(look, 0.4))

            item = {
                "step": step,
                "makeupType": look,
                "image": encode_jpg(out),
            }

            if returnMaskPNG:
                item["maskPNG"] = encode_mask_png(mask)

            guides.append(item)

        return {"success": True, "guides": guides}

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("get_makeup_guide failed: %s", e)
        raise HTTPException(status_code=500, detail="Makeup guide processing failed")


# -----------------------------
# COMPARE MAKEUP (with feedback)
# -----------------------------
@router.post("/compare_makeup")
async def compare_makeup(
    originalImage: UploadFile = File(...),
    afterImage: UploadFile = File(...),
):
    try:
        before_bytes = await originalImage.read()
        after_bytes = await afterImage.read()

        logger.info(
            "compare_makeup: before %d bytes, after %d bytes",
            len(before_bytes),
            len(after_bytes),
        )

        before = decode_image(before_bytes)
        after = decode_image(after_bytes)

        if before.shape != after.shape:
            after = cv2.resize(after, (before.shape[1], before.shape[0]))

        comp = np.hstack([before, after])
        feedback = get_feedback(before, after)

        return {
            "success": True,
            "comparisonImage": encode_jpg(comp),
            "feedback": feedback,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("compare_makeup failed: %s", e)
        raise HTTPException(status_code=500, detail="Comparison failed")
