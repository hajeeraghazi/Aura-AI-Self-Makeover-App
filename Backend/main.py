# main.py — AURA Backend (EfficientNet + STONE version)
"""
Unified backend for:
 - EfficientNet face shape classification (.pth)
 - Skin-tone-classifier (STONE)
 - EXIF-safe image loader + MediaPipe alignment
 - Fashion + Makeup Recommendations using new tone system
"""

import datetime
import logging
from typing import Optional

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# ------------ Internal Models & Engines ------------ #
from classification import router as classify_router
from makeup_guide_api import router as makeup_guide_router
from lipstick import router as lipstick_router

from predict_tone_shape import SkinFaceClassifierAPI, load_image_bytes_to_bgr
from recommendation_model import make_recommendation
from models import (
    RecommendationRequest,
    RecommendationsResponse,
)


# ============================================================
# FASTAPI SETUP
# ============================================================
app = FastAPI(title="AURA AI Backend", version="3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # allow all for mobile app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers for other modules
app.include_router(makeup_guide_router, prefix="/api/makeup_guide", tags=["makeup_guide"])
app.include_router(lipstick_router, prefix="/api/lipstick", tags=["lipstick"])
app.include_router(classify_router, prefix="/api/face", tags=["classification"])


# ============================================================
# LOGGING CONFIG
# ============================================================
LOGFILE = "aura_errors.log"
logging.basicConfig(
    filename=LOGFILE,
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("aura")
logger.addHandler(logging.StreamHandler())  # also to console


# ============================================================
# CLASSIFIER SINGLETON
# ============================================================
_classifier: Optional[SkinFaceClassifierAPI] = None


def get_classifier(force_reload=False) -> SkinFaceClassifierAPI:
    global _classifier

    if _classifier is not None and not force_reload:
        return _classifier

    try:
        logger.info("Loading SkinFaceClassifierAPI…")
        _classifier = SkinFaceClassifierAPI()
        logger.info("Classifier loaded successfully.")
        return _classifier
    except Exception as e:
        logger.exception("Failed to load classifier")
        raise HTTPException(500, f"Classifier initialization failed: {e}")


# ============================================================
# BASIC ENDPOINTS
# ============================================================
@app.get("/")
async def root():
    return {
        "status": "running",
        "version": "3.0",
        "timestamp": datetime.datetime.now().isoformat()
    }


@app.get("/health")
async def health():
    return {"status": "ok"}


# ============================================================
# CLASSIFICATION — SKIN TONE + FACE SHAPE
# ============================================================
@app.post("/api/classify")
async def classify_api(file: UploadFile = File(...)):
    """
    Returns Skin Tone + Face Shape:
    {
        "success": true,
        "skin_tone": {...},
        "face_shape": {...},
        "landmarks_detected": 478
    }
    """
    clf = get_classifier()

    img_bytes = await file.read()
    img = load_image_bytes_to_bgr(img_bytes)

    if img is None:
        raise HTTPException(400, "Invalid image")

    try:
        result = clf.classify_image(img)

        # Format face shape title case
        if isinstance(result.get("face_shape"), dict):
            result["face_shape"]["shape"] = (
                result["face_shape"]["shape"].capitalize()
            )

        return JSONResponse(result)

    except Exception as e:
        logger.exception("Error during classification")
        raise HTTPException(500, f"Classification error: {e}")


# ============================================================
# SKIN TONE ONLY (Legacy/Fallback)
# ============================================================
@app.post("/api/skin_tone")
async def skin_tone_api(file: UploadFile = File(...)):
    clf = get_classifier()

    img_bytes = await file.read()
    img = load_image_bytes_to_bgr(img_bytes)

    if img is None:
        raise HTTPException(400, "Invalid image")

    try:
        result = clf.classify_image(img)

        if not result.get("success"):
            return {"skin_tone": "unknown", "error": result.get("error")}

        return {
            "skin_tone": result["skin_tone"]["bucket"],
            "debug": result["skin_tone"]
        }

    except Exception as e:
        logger.exception("Skin tone endpoint failed")
        raise HTTPException(500, str(e))


# ============================================================
# MODEL RELOAD
# ============================================================
@app.post("/api/reload-models")
async def reload_models():
    global _classifier
    _classifier = None

    try:
        get_classifier(force_reload=True)
        return {"success": True}
    except Exception as e:
        logger.exception("Reload failed")
        raise HTTPException(500, f"Reload error: {e}")


# ============================================================
# MAKEUP + FASHION RECOMMENDATIONS
# ============================================================
@app.post("/api/makeup_recommendation", response_model=RecommendationsResponse)
async def makeup_recommendation(req: RecommendationRequest):
    """
    Returns:
    {
        "makeup": {...},
        "fashion": {...},
        "summary": "..."
    }
    """
    try:
        result = make_recommendation(req)

        return RecommendationsResponse(
            makeup=result["makeup"],
            fashion=result["fashion"],
            summary=result["summary"]
        )

    except Exception as e:
        logger.exception("Recommendation engine failed")
        raise HTTPException(500, f"Recommendation error: {e}")


# ============================================================
# SERVER STARTER
# ============================================================
if __name__ == "__main__":
    import uvicorn
    logger.info("Starting backend server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
