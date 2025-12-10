from pydantic import BaseModel
from typing import List, Dict, Any, Optional


# ============================================================
# FACE ANALYSIS OUTPUT (/api/classify)
# ============================================================

class SkinToneModel(BaseModel):
    bucket: str                      # e.g., "caramel_brown"
    trained_label: Optional[str] = None
    hex: Optional[str] = None        # "#c49a6a"
    color_name: Optional[str] = None # "Caramel Brown"
    confidence: float
    method: str                      # "stone", "heuristic"


class FaceShapeModel(BaseModel):
    shape: str                       # "Oval", "Heart", etc.
    trained_label: Optional[str] = None
    confidence: float
    method: str                      # "efficientnet", "heuristic"


class FaceAnalysisResponse(BaseModel):
    success: bool
    skin_tone: SkinToneModel
    face_shape: FaceShapeModel
    landmarks_detected: int


# ============================================================
# MAKEUP + FASHION RECOMMENDATION MODELS
# ============================================================

class OutfitItem(BaseModel):
    item: str
    color: str
    link: Optional[str] = ""         # backend doesn't return link yet


class FashionRecommendations(BaseModel):
    colorPalette: List[str]
    recommendedColor: str
    outfits: List[OutfitItem]
    bag: str
    shoes: str


class MakeupRecommendations(BaseModel):
    foundation: str
    lipstick: str
    blush: str
    hairstyle: str
    accessories: List[str]


class RecommendationRequest(BaseModel):
    face_shape: str
    skin_tone: str
    gender: str
    event: str
    body_type: str


class RecommendationsResponse(BaseModel):
    makeup: MakeupRecommendations
    fashion: FashionRecommendations
    summary: str


# ============================================================
# LOOK FEEDBACK (GAN + CNN evaluation)
# ============================================================

class FeedbackResponse(BaseModel):
    symmetry_score: float
    blending_score: float
    suggestions: List[str]
