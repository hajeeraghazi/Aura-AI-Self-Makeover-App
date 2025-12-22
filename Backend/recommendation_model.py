"""
AURA AI – FULL MAKEUP + FASHION ENGINE
FINAL VERSION – VTU READY ✔
Rule-based, Personalized, Explainable
"""

import random
from typing import Dict, Any, List
from pydantic import BaseModel


# ============================================================
# REQUEST MODEL
# ============================================================

class RecommendationRequest(BaseModel):
    face_shape: str
    skin_tone: str
    gender: str
    event: str
    body_type: str   # average | slim | muscular | heavy


# ============================================================
# SKIN TONE NORMALIZATION
# ============================================================

LEGACY_TONE_MAP = {
    "very fair": "porcelain",
    "fair": "fair beige",
    "light": "fair beige",
    "wheatish": "warm beige",
    "medium": "warm beige",
    "olive": "warm beige",
    "tan": "tan",
    "caramel": "caramel",
    "brown": "brown",
    "dark": "brown",
    "deep": "deep brown",
}

def normalize_tone(raw: str) -> str:
    if not raw:
        return "warm beige"
    raw = raw.lower()
    for k, v in LEGACY_TONE_MAP.items():
        if k in raw:
            return v
    return "warm beige"


# ============================================================
# MAKEUP DATABASE
# ============================================================

FOUNDATION_PRODUCTS = {
    "porcelain": ["Maybelline Fit Me 110", "MAC NC10"],
    "fair beige": ["Maybelline 115 Ivory", "MAC NC15"],
    "warm beige": ["Maybelline 220 Natural Beige", "MAC NC35"],
    "tan": ["MAC NC42", "Maybelline 310 Sun Beige"],
    "caramel": ["Fenty 310 Honey", "MAC NC44"],
    "brown": ["Maybelline 355 Coconut", "MAC NW45"],
    "deep brown": ["Fenty 480", "MAC NW50"],
}

LIPSTICK_PRODUCTS = {
    "porcelain": ["Soft Pink Nude", "Peach Nude"],
    "fair beige": ["Nude Peach", "Warm Pink"],
    "warm beige": ["Terracotta", "Warm Berry"],
    "tan": ["Brick Red", "Rust Nude"],
    "caramel": ["Copper Brown", "Wine Red"],
    "brown": ["Burgundy", "Deep Plum"],
    "deep brown": ["Dark Berry", "Espresso Brown"],
}

BLUSH_PRODUCTS = {
    "porcelain": ["Soft Peach", "Baby Pink"],
    "fair beige": ["Rosy Pink"],
    "warm beige": ["Warm Rose"],
    "tan": ["Coral"],
    "caramel": ["Terracotta"],
    "brown": ["Brick Brown"],
    "deep brown": ["Berry"],
}


# ============================================================
# HAIR COLOR BY SKIN TONE  ✅ (FIX)
# ============================================================

HAIR_COLOR_BY_TONE = {
    "porcelain": ["Natural Black", "Dark Brown"],
    "fair beige": ["Chocolate Brown", "Ash Brown"],
    "warm beige": ["Chestnut Brown", "Soft Caramel"],
    "tan": ["Warm Brown", "Auburn"],
    "caramel": ["Golden Brown", "Honey Highlights"],
    "brown": ["Espresso Brown"],
    "deep brown": ["Natural Black"],
}


# ============================================================
# FACE SHAPE → HAIRSTYLE
# ============================================================

HAIRSTYLE_BY_FACE = {
    "oval": ["Loose Waves", "Sleek Bun", "High Ponytail"],
    "round": ["Long Layers", "Side Part", "Voluminous Bun"],
    "square": ["Soft Waves", "Side Swept Hair"],
    "heart": ["Low Bun", "Soft Curls"],
}


# ============================================================
# BODY TYPE → FIT
# ============================================================

BODY_TYPE_FIT = {
    "slim": ["Tailored Fit", "Layered Outfits"],
    "average": ["Classic Fit", "Balanced Silhouettes"],
    "muscular": ["Structured Fit", "Relaxed Fit"],
    "heavy": ["Straight Cut", "Flowy Fabrics"],
}

#ACCESSORY RULE TABLES
#Face Shape → Accessory Shape
ACCESSORIES_BY_FACE = {
    "round": ["Long Drop Earrings", "Vertical Pendants"],
    "oval": ["Stud Earrings", "Hoop Earrings"],
    "square": ["Round Hoops", "Curved Necklaces"],
    "heart": ["Teardrop Earrings", "Chokers"],
}

# Skin Tone → Metal / Color
ACCESSORIES_BY_TONE = {
    "porcelain": ["Silver Jewelry", "Pearl Accessories"],
    "fair beige": ["Rose Gold Jewelry", "Pearls"],
    "warm beige": ["Gold Jewelry", "Bronze Accessories"],
    "tan": ["Antique Gold", "Beaded Jewelry"],
    "caramel": ["Gold Jewelry", "Copper Accessories"],
    "brown": ["Oxidized Silver", "Gold Jewelry"],
    "deep brown": ["Bold Gold", "Black Metal Accessories"],
}

# Event → Styling Level
ACCESSORIES_BY_EVENT = {
    "casual": ["Minimal Accessories"],
    "formal": ["Elegant Jewelry"],
    "party": ["Statement Accessories"],
    "wedding": ["Traditional Jewelry"],
}


# ============================================================
# SKIN TONE → COLOR PALETTE
# ============================================================

CLOTHING_COLORS = {
    "porcelain": ["Pastel Blue", "Lavender", "Rose Pink"],
    "fair beige": ["Peach", "Sky Blue", "Blush Pink"],
    "warm beige": ["Mustard", "Olive", "Teal"],
    "tan": ["Emerald Green", "Rust", "Navy Blue"],
    "caramel": ["Wine", "Gold", "Deep Teal"],
    "brown": ["Burgundy", "Forest Green", "Royal Blue"],
    "deep brown": ["Plum", "Black", "Metallic Gold"],
}


# ============================================================
# EVENT & GENDER → CLOTHING
# ============================================================

EVENT_CLOTHING = {
    "female": {
        "casual": ["T-shirt", "Jeans", "Kurti"],
        "formal": ["Blazer", "Trousers", "Midi Dress"],
        "party": ["Bodycon Dress", "Satin Skirt"],
        "wedding": ["Saree", "Lehenga", "Anarkali"],
    },
    "male": {
        "casual": ["T-shirt", "Jeans"],
        "formal": ["Blazer", "Trousers"],
        "party": ["Printed Shirt"],
        "wedding": ["Sherwani", "Kurta Pyjama"],
    },
}

BAG_MAP = {
    "casual": ["Crossbody Bag"],
    "formal": ["Structured Handbag"],
    "party": ["Clutch"],
    "wedding": ["Potli Bag"],
}

SHOE_MAP = {
    "female": {
        "casual": ["Sneakers"],
        "formal": ["Block Heels"],
        "party": ["Stilettos"],
        "wedding": ["Juttis"],
    },
    "male": {
        "casual": ["Sneakers"],
        "formal": ["Oxford Shoes"],
        "party": ["Designer Shoes"],
        "wedding": ["Mojaris"],
    },
}


# ============================================================
# DYNAMIC SUMMARY
# ============================================================

def generate_summary(req: RecommendationRequest, tone: str) -> str:
    return (
        f"For the {tone} skin tone and {req.face_shape.lower()} face shape, "
        f"the AI suggests suitable makeup shades and hairstyles. "
        f"Based on the {req.body_type.lower()} body type and {req.event.lower()} event, "
        f"it recommends well-fitted outfits, accessories, and footwear for a complete look."
    )

# ACCESSORY GENERATION FUNCTION
def generate_accessories(face: str, tone: str, event: str) -> List[str]:
    face_items = ACCESSORIES_BY_FACE.get(face, ["Stud Earrings"])
    tone_items = ACCESSORIES_BY_TONE.get(tone, ["Gold Jewelry"])
    event_items = ACCESSORIES_BY_EVENT.get(event, ["Minimal Accessories"])

    # Combine intelligently
    return list({
        random.choice(face_items),
        random.choice(tone_items),
        random.choice(event_items),
    })



# ============================================================
# MAIN RECOMMENDATION ENGINE (MODEL SAFE)
# ============================================================

def make_recommendation(req: RecommendationRequest) -> Dict[str, Any]:

    tone = normalize_tone(req.skin_tone)
    face = req.face_shape.lower()
    gender = req.gender.lower()
    event = req.event.lower()
    body = req.body_type.lower()

    # ---------------- MAKEUP ----------------
    makeup = {
        "foundation": random.choice(FOUNDATION_PRODUCTS[tone]),
        "lipstick": random.choice(LIPSTICK_PRODUCTS[tone]),
        "blush": random.choice(BLUSH_PRODUCTS[tone]),
        "hairstyles": HAIRSTYLE_BY_FACE.get(face, HAIRSTYLE_BY_FACE[face]),
        "hairColors": HAIR_COLOR_BY_TONE[tone],  
        "accessories": generate_accessories(face, tone, event),
    }

    # ---------------- FASHION ----------------
    palette = CLOTHING_COLORS[tone]
    body_fit = BODY_TYPE_FIT.get(body, ["Classic Fit"])
    clothing_items = EVENT_CLOTHING[gender][event]

    outfits: List[Dict[str, str]] = []
    for item in clothing_items:
        color = random.choice(palette)
        outfits.append({
            "item": item,
            "color": color,
            "link": f"https://www.google.com/search?q={item.replace(' ','+')}+{color.replace(' ','+')}"
        })

    fashion = {
        "colorPalette": palette,
        "recommendedColor": palette[0],
        "outfits": outfits,
        "bag": random.choice(BAG_MAP[event]),
        "shoes": random.choice(SHOE_MAP[gender][event]),
    }

    return {
        "makeup": makeup,
        "fashion": fashion,
        "summary": generate_summary(req, tone),
    }
