# classification.py — FINAL VERSION for AURA Backend
# Works with EfficientNet Face Shape Model + STONE Skin Tone classifier
# Uses EXIF-correct loader and unified pipeline from predict_tone_shape.py

import cv2
import numpy as np
import traceback
import logging

from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

from predict_tone_shape import SkinFaceClassifierAPI, load_image_bytes_to_bgr

router = APIRouter()

# ======================================================
# Singleton classifier — our main engine
# ======================================================
_classifier = None

def get_classifier():
    global _classifier
    if _classifier is None:
        _classifier = SkinFaceClassifierAPI()
    return _classifier

logger = logging.getLogger("uvicorn.error")


# ======================================================
# /face_scan — FACE SHAPE ONLY
# ======================================================
@router.post("/face_scan")
async def face_scan(image: UploadFile = File(...)):
    """
    Returns only face shape using EfficientNet + MediaPipe.
    {
        "success": true,
        "faces": [{ "face_shape": "Oval" }]
    }
    """
    try:
        data = await image.read()
        img = load_image_bytes_to_bgr(data)

        if img is None:
            raise HTTPException(400, "Invalid or unreadable image")

        clf = get_classifier()
        result = clf.classify_image(img)

        if not result.get("success"):
            return JSONResponse({
                "success": False,
                "faces": [],
                "error": result.get("error", "unknown")
            })

        # Always return capitalized shape
        shape = result["face_shape"]["shape"].capitalize()

        return JSONResponse({
            "success": True,
            "faces": [
                {"face_shape": shape}
            ]
        })

    except Exception as e:
        logger.error(f"/face_scan error: {e}")
        traceback.print_exc()
        raise HTTPException(500, "Internal server error")


# ======================================================
# /skin_tone — SKIN TONE ONLY
# ======================================================
@router.post("/skin_tone")
async def skin_tone(image: UploadFile = File(...)):
    """
    Returns only skin tone using STONE model.
    {
        "skin_tone": "Caramel",
        "debug": {...full stone output...}
    }
    """
    try:
        data = await image.read()
        img = load_image_bytes_to_bgr(data)

        if img is None:
            raise HTTPException(400, "Invalid or unreadable image")

        clf = get_classifier()
        result = clf.classify_image(img)

        if not result.get("success"):
            return JSONResponse({
                "skin_tone": "unknown",
                "error": result.get("error", "unknown")
            })

        tone_bucket = result["skin_tone"]["bucket"]  # Already normalized (Fair, Caramel, Deep Brown, etc.)

        return JSONResponse({
            "skin_tone": tone_bucket,
            "debug": result["skin_tone"]
        })

    except Exception as e:
        logger.error(f"/skin_tone error: {e}")
        traceback.print_exc()
        raise HTTPException(500, "Internal server error")


# ======================================================
# /classify — FACE SHAPE + SKIN TONE TOGETHER
# ======================================================
@router.post("/classify")
async def classify(file: UploadFile = File(...)):
    """
    Combined output for Flutter:
    {
        "success": true,
        "skin_tone": {...},
        "face_shape": {...},
        "landmarks_detected": 478
    }
    """
    try:
        data = await file.read()
        img = load_image_bytes_to_bgr(data)

        if img is None:
            raise HTTPException(400, "Invalid or unreadable image")

        clf = get_classifier()
        result = clf.classify_image(img)

        # Clean + standardize JSON output
        if result.get("face_shape"):
            result["face_shape"]["shape"] = result["face_shape"]["shape"].capitalize()

        return JSONResponse(result)

    except Exception as e:
        logger.error(f"/classify error: {e}")
        traceback.print_exc()
        raise HTTPException(500, "Internal server error")
