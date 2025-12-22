# ============================================================
# classification.py — FINAL FASTAPI ROUTER
# ============================================================

import traceback
import logging
from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

from predict_tone_shape import (
    SkinFaceClassifierAPI,
    load_image_bytes_to_bgr,
    classify_skin_tone
)

router = APIRouter()
logger = logging.getLogger("uvicorn.error")

_classifier = None
def get_classifier():
    global _classifier
    if _classifier is None:
        _classifier = SkinFaceClassifierAPI()
    return _classifier

# ============================================================
# /face_scan
# ============================================================
@router.post("/face_scan")
async def face_scan(image: UploadFile = File(...)):
    try:
        if not image.content_type.startswith("image/"):
            raise HTTPException(400, "Not an image")

        img = load_image_bytes_to_bgr(await image.read())
        clf = get_classifier()
        res = clf.classify_image(img)

        if not res["success"]:
            return {"success": False, "faces": []}

        return {
            "success": True,
            "faces": [
                {"face_shape": res["face_shape"]["shape"].capitalize()}
            ]
        }

    except Exception:
        traceback.print_exc()
        raise HTTPException(500, "Internal server error")

# ============================================================
# /skin_tone
# ============================================================
@router.post("/skin_tone")
async def skin_tone(image: UploadFile = File(...)):
    try:
        if not image.content_type.startswith("image/"):
            raise HTTPException(400, "Not an image")

        img = load_image_bytes_to_bgr(await image.read())
        tone = classify_skin_tone(img)

        return {
            "skin_tone": tone["bucket"],
            "debug": tone
        }

    except Exception:
        traceback.print_exc()
        raise HTTPException(500, "Internal server error")

# ============================================================
# /classify
# ============================================================
@router.post("/classify")
async def classify(image: UploadFile = File(...)):
    try:
        if not image.content_type.startswith("image/"):
            raise HTTPException(400, "Not an image")

        img = load_image_bytes_to_bgr(await image.read())
        clf = get_classifier()
        res = clf.classify_image(img)

        if res.get("face_shape"):
            res["face_shape"]["shape"] = res["face_shape"]["shape"].capitalize()

        return JSONResponse(res)

    except Exception:
        traceback.print_exc()
        raise HTTPException(500, "Internal server error")
