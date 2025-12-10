"""
makeup_models.py  
AURA AI – Makeup GAN + Feedback CNN Loader (Safe for PyTorch 2.5+)
"""

import sys
import torch
import torch.nn as nn
import torch.serialization
from torchvision import models, transforms
from PIL import Image
import io, urllib.parse
from typing import Dict, Any

# ============================================================
# FIX: PyTorch "__main__.Generator" unpickling issue
# ============================================================
sys.modules["__main__"] = sys.modules[__name__]

# ============================================================
# MODEL DEFINITIONS (must match training-time definitions)
# ============================================================

class Generator(nn.Module):
    """Simple GAN Generator used in AURA Makeup GAN training."""
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv2d(3, 64, 4, 2, 1), nn.ReLU(True),

            nn.Conv2d(64, 128, 4, 2, 1),
            nn.BatchNorm2d(128), nn.ReLU(True),

            nn.ConvTranspose2d(128, 64, 4, 2, 1),
            nn.BatchNorm2d(64), nn.ReLU(True),

            nn.ConvTranspose2d(64, 3, 4, 2, 1),
            nn.Sigmoid()
        )

    def forward(self, x):
        return self.net(x)


# Allow safe loading of custom classes
torch.serialization.add_safe_globals([
    Generator,
    models.resnet.ResNet,
])


# ============================================================
# SAFE MODEL LOADER
# ============================================================

def load_model_safely(path: str, model_name: str):
    """Load model using PyTorch’s safe global override."""
    try:
        model = torch.load(path, map_location="cpu", weights_only=False)
        model.eval()
        print(f"[makeup_models] ✅ Loaded: {model_name}")
        return model
    except Exception as e:
        print(f"[makeup_models] ⚠️ Could not load {model_name}: {e}")
        return None


# Load your models
makeup_gan_model = load_model_safely("models/makeup_gan.pth", "makeup_gan.pth")
feedback_model = load_model_safely("models/makeup_feedback_cnn.pth", "makeup_feedback_cnn.pth")


# ============================================================
# TRANSFORMS
# ============================================================

transform_cnn = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    ),
])


# ============================================================
# HELPERS
# ============================================================

def bytes_to_pil(image_bytes: bytes):
    """Convert raw bytes → PIL image."""
    return Image.open(io.BytesIO(image_bytes)).convert("RGB")


def generate_ecommerce_link(item_name: str, platform: str = "myntra") -> str:
    """Create a dynamic product search links for e-commerce stores."""
    q = urllib.parse.quote_plus(item_name)
    if platform == "amazon":
        return f"https://www.amazon.in/s?k={q}"
    elif platform == "flipkart":
        return f"https://www.flipkart.com/search?q={q}"
    return f"https://www.myntra.com/{q}"


# ============================================================
# MAKEUP RECOMMENDATION ENGINE
# ============================================================

def recommend_makeup(face_shape: str, skin_tone: str):
    face_shape = face_shape.lower()
    skin_tone = skin_tone.lower()

    foundation_map = {
        "fair": "Light Ivory Foundation",
        "warm beige": "Warm Beige Foundation",
        "tan": "Golden Tan Foundation",
        "brown": "Cocoa Brown Foundation",
        "deep brown": "Deep Espresso Foundation",
        "medium": "Warm Beige Foundation"
    }

    lipstick_map = {
        "oval": "Soft Pink Lipstick",
        "round": "Bold Red Lipstick",
        "square": "Nude Matte Lipstick",
        "heart": "Coral Gloss Lipstick",
        "diamond": "Rosewood Lipstick"
    }

    blush_map = {
        "fair": "Peach Blush",
        "warm beige": "Coral Blush",
        "tan": "Apricot Blush",
        "brown": "Copper Blush",
        "deep brown": "Bronze Blush",
        "medium": "Rose Blush"
    }

    accessories_map = {
        "oval": ["Gold Hoop Earrings", "Delicate Necklace"],
        "round": ["Dangling Earrings", "Statement Rings"],
        "square": ["Chunky Bracelets", "Bold Sunglasses"],
        "heart": ["Stud Earrings", "Layered Chains"],
        "diamond": ["Pearl Earrings", "Elegant Choker"]
    }

    return {
        "foundation": foundation_map.get(skin_tone, "Warm Beige Foundation"),
        "lipstick": lipstick_map.get(face_shape, "Soft Pink Lipstick"),
        "blush": blush_map.get(skin_tone, "Rose Blush"),
        "accessories": accessories_map.get(face_shape, ["Classic Earrings"])
    }


# ============================================================
# FULL MAKEUP + OUTFIT RECOMMENDER
# ============================================================

def generate_makeup_recommendations(user_data: Dict[str, Any]) -> Dict[str, Any]:
    face_shape = user_data.get("face_shape", "oval")
    skin_tone = user_data.get("skin_tone", "medium")

    makeup = recommend_makeup(face_shape, skin_tone)

    # Outfit suggestions based on tone and shape
    outfits = [
        "pastel summer dress" if "fair" in skin_tone else "earth-tone beige top",
        "sleek black blazer set" if face_shape in ["square", "oval"] else "soft pastel kurti"
    ]

    outfit_data = [
        {"name": o, "link": generate_ecommerce_link(o)} for o in outfits
    ]

    makeup_data = {
        "foundation": {
            "name": makeup["foundation"],
            "link": generate_ecommerce_link(makeup["foundation"], "amazon"),
        },
        "lipstick": {
            "name": makeup["lipstick"],
            "link": generate_ecommerce_link(makeup["lipstick"], "myntra"),
        },
        "blush": {
            "name": makeup["blush"],
            "link": generate_ecommerce_link(makeup["blush"], "flipkart"),
        },
        "accessories": [
            {"name": acc, "link": generate_ecommerce_link(acc, "myntra")}
            for acc in makeup["accessories"]
        ]
    }

    return {"outfits": outfit_data, "makeup": makeup_data}


# ============================================================
# APPLY MAKEUP STYLE — GAN
# ============================================================

def apply_makeup_style(face_img_tensor):
    """Apply GAN-based makeup filter."""
    if makeup_gan_model is None:
        raise RuntimeError("GAN model not loaded.")
    with torch.no_grad():
        return makeup_gan_model(face_img_tensor)


# ============================================================
# FEEDBACK CNN — LOOK ANALYSIS
# ============================================================

def analyze_look_feedback(image_bytes: bytes) -> Dict[str, Any]:
    """Analyze final look for symmetry + blending."""
    if feedback_model is None:
        raise RuntimeError("Feedback CNN not loaded.")

    img = bytes_to_pil(image_bytes)
    tensor = transform_cnn(img).unsqueeze(0)

    with torch.no_grad():
        output = feedback_model(tensor)
        scores = torch.sigmoid(output).cpu().numpy().flatten()

    suggestions = []
    if scores[0] < 0.75:
        suggestions.append("Improve foundation blending on jawline.")
    if scores[1] < 0.65:
        suggestions.append("Add mascara for better eye definition.")

    return {
        "symmetry_score": round(float(scores[0]), 2),
        "blending_score": round(float(scores[1]), 2),
        "suggestions": suggestions or ["Look is well-balanced! Great work!"]
    }
