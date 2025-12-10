"""
AURA AI – FULL MAKEUP + FASHION ENGINE (UPDATED)

✔ Uses new human-friendly skin tones:
   - Porcelain (Very Fair)
   - Fair Beige
   - Warm Beige
   - Tan
   - Caramel
   - Brown
   - Deep Brown

✔ Outfits returned as individual items (T-shirt, Jeans, etc.)
✔ Each item includes a link placeholder
"""

import random
from typing import Dict, Any
from pydantic import BaseModel


class RecommendationRequest(BaseModel):
    face_shape: str
    skin_tone: str
    gender: str
    event: str
    body_type: str


# ============================================================
# TONE NORMALIZATION
# ============================================================

# New tone keys we will use internally
NEW_TONES = [
    "porcelain",
    "fair beige",
    "warm beige",
    "tan",
    "caramel",
    "brown",
    "deep brown",
]

# Map legacy / alternative labels → new tone keys
LEGACY_TONE_MAP = {
    "porcelain (very fair)": "porcelain",
    "porcelain": "porcelain",
    "very_fair": "porcelain",
    "very fair": "porcelain",
    "fair": "fair beige",
    "light": "fair beige",
    "fair beige": "fair beige",
    "warm beige": "warm beige",
    "medium": "warm beige",
    "mid-light": "warm beige",
    "wheatish": "warm beige",
    "tan": "tan",
    "mid-dark": "caramel",
    "caramel": "caramel",
    "honey": "caramel",
    "brown": "brown",
    "dark": "brown",
    "deep brown": "deep brown",
    "deep": "deep brown",
}


def normalize_tone(raw: str) -> str:
    """Normalize any skin_tone string into our internal keys."""
    if not raw:
        return "warm beige"

    val = raw.strip().lower()

    # remove parentheses content for cases like "porcelain (very fair)"
    if "(" in val and ")" in val:
        val = val.split("(")[0].strip()

    # direct match to legacy map
    if val in LEGACY_TONE_MAP:
        return LEGACY_TONE_MAP[val]

    # if already exactly one of the new tones
    if val in NEW_TONES:
        return val

    # small fuzzy-ish fallbacks
    if "porcelain" in val:
        return "porcelain"
    if "fair" in val:
        return "fair beige"
    if "warm" in val or "beige" in val:
        return "warm beige"
    if "tan" in val:
        return "tan"
    if "caramel" in val or "honey" in val:
        return "caramel"
    if "deep" in val:
        return "deep brown"
    if "dark" in val or "brown" in val:
        return "brown"

    # default
    return "warm beige"


# ============================================================
# CONSTANT TABLES
# ============================================================

CLOTHING_COLORS = {
    "porcelain": ["Pastel Blue", "Rose Pink", "Lavender", "Soft Mint"],
    "fair beige": ["Peach", "Coral", "Sky Blue", "Soft Pink"],
    "warm beige": ["Mustard", "Olive", "Teal", "Maroon"],
    "tan": ["Emerald Green", "Rust", "Chocolate Brown", "Black"],
    "caramel": ["Gold", "Wine", "Cobalt Blue", "Copper"],
    "brown": ["Burgundy", "Burnt Orange", "Forest Green"],
    "deep brown": ["Plum", "Ruby Red", "Mahogany", "Black"],
}

# Individual clothing items per event & gender
EVENT_CLOTHING = {
    "female": {
        "casual": [
            "T-shirt", "Jeans",
            "Crop Top", "High Waist Jeans",
            "Kurti", "Leggings",
            "Oversized Tee", "Joggers",
        ],
        "formal": [
            "Blazer", "Formal Shirt", "Trousers",
            "Pencil Skirt", "Blouse",
        ],
        "party": [
            "Sequin Dress", "A-line Dress", "Bodycon Dress", "Gown",
        ],
        "wedding": [
            "Saree", "Lehenga", "Anarkali", "Designer Kurta",
        ],
    },
    "male": {
        "casual": [
            "T-shirt", "Jeans",
            "Casual Shirt", "Chinos",
            "Hoodie", "Denim Pants",
            "Oversized Tee", "Joggers",
        ],
        "formal": [
            "Blazer", "Formal Shirt", "Trousers",
            "3-Piece Suit",
        ],
        "party": [
            "Party Blazer", "Printed Shirt", "Trousers", "Designer Shirt",
        ],
        "wedding": [
            "Sherwani", "Kurta Pajama", "Nehru Jacket",
        ],
    },
}

LIPSTICK_BY_TONE = {
    "porcelain": ["Soft Pink", "Rose Nude", "Peach Pink"],
    "fair beige": ["Warm Pink", "Nude Peach", "Mauve Nude"],
    "warm beige": ["Rosewood Nude", "Terracotta", "Warm Berry"],
    "tan": ["Burnt Orange", "Brick Red", "Cinnamon Brown"],
    "caramel": ["Warm Brown Nude", "Copper Brown", "Wine Red"],
    "brown": ["Chocolate Brown", "Burgundy", "Deep Plum"],
    "deep brown": ["Maroon", "Dark Berry", "Espresso Brown"],
}

FOUNDATION_MAP = {
    "porcelain": ["Maybelline 110 Porcelain", "MAC NC10"],
    "fair beige": ["Maybelline 115 Ivory", "MAC NC15"],
    "warm beige": ["Maybelline 220 Natural Beige", "MAC NC35"],
    "tan": ["Maybelline 310 Sun Beige", "MAC NC42"],
    "caramel": ["Fenty 310 Honey", "MAC NC44"],
    "brown": ["Maybelline 355 Coconut", "MAC NW45"],
    "deep brown": ["MAC NW50", "Fenty 480"],
}

BLUSH_MAP = {
    "porcelain": "Soft Peach Blush",
    "fair beige": "Rosy Pink Blush",
    "warm beige": "Warm Rose Blush",
    "tan": "Coral Blush",
    "caramel": "Terracotta Blush",
    "brown": "Brick Brown Blush",
    "deep brown": "Berry Blush",
}

ACCESSORIES_MAP = {
    "oval": ["Hoop Earrings", "Delicate Necklace"],
    "round": ["Dangling Earrings", "Statement Rings"],
    "square": ["Bold Sunglasses", "Chunky Bracelets"],
    "heart": ["Stud Earrings", "Layered Chains"],
    "diamond": ["Teardrop Earrings", "Minimalist Pendant"],
}

HAIRSTYLE_MAP = {
    "oval": ["Soft Waves", "Low Ponytail", "Layered Cut", "Curtain Bangs"],
    "round": ["Long Layers", "High Ponytail", "Side-Swept Bangs", "Volumized Crown"],
    "square": ["Soft Curls", "Side Part Waves", "Textured Bob", "Feathered Layers"],
    "heart": ["Chin-Length Bob", "Side Fringe", "Soft Waves Down", "Layered Lob"],
    "diamond": ["Middle Part Straight Hair", "Layered Medium Cut", "Low Bun with Strands", "Hollywood Waves"],
}

BAG_MAP = {
    "casual": ["Crossbody Bag", "Mini Backpack", "Tote Bag"],
    "formal": ["Structured Handbag", "Leather Shoulder Bag", "Clutch"],
    "party": ["Shimmer Clutch", "Metallic Sling Bag", "Crystal Clutch"],
    "wedding": ["Potli Bag", "Embroidered Clutch", "Zari Sling Bag"],
}

SHOE_MAP = {
    "female": {
        "casual": ["Sneakers", "Ballerina Flats", "Chunky Sandals"],
        "formal": ["Pointed Heels", "Block Heels", "Formal Loafers"],
        "party": ["Stilettos", "Metallic Heels", "Strappy Sandals"],
        "wedding": ["Juttis", "Kolhapuri Sandals", "Embroidered Mojaris"],
    },
    "male": {
        "casual": ["Sneakers", "Slip-on Shoes", "Casual Loafers"],
        "formal": ["Oxford Shoes", "Formal Loafers", "Derby Shoes"],
        "party": ["Glossy Loafers", "Designer Shoes", "Velvet Slip-ons"],
        "wedding": ["Kolhapuris", "Mojaris", "Ethnic Sandals"],
    },
}


# ============================================================
# HELPERS
# ============================================================

def recommend_hairstyle(face: str) -> str:
    face_key = face.lower()
    return random.choice(HAIRSTYLE_MAP.get(face_key, HAIRSTYLE_MAP["oval"]))


def recommend_lipstick(tone_key: str) -> str:
    return random.choice(LIPSTICK_BY_TONE.get(tone_key, LIPSTICK_BY_TONE["warm beige"]))


def get_bag_and_shoes(gender: str, event: str):
    gender_key = gender.lower()
    event_key = event.lower()

    bag = random.choice(BAG_MAP.get(event_key, BAG_MAP["casual"]))
    shoes_group = SHOE_MAP.get(gender_key, SHOE_MAP["female"])
    shoes = random.choice(shoes_group.get(event_key, shoes_group["casual"]))
    return bag, shoes


# ============================================================
# MAIN ENGINE
# ============================================================

def make_recommendation(req: RecommendationRequest) -> Dict[str, Any]:
    """
    Main engine to generate:
      - makeup: foundation, lipstick, blush, accessories, hairstyle
      - fashion: color palette, outfit items, bag, shoes
      - summary: human-readable explanation
    """

    # Normalize skin tone into our internal keys
    tone_key = normalize_tone(req.skin_tone)
    face_key = req.face_shape.lower()
    gender_key = req.gender.lower()
    event_key = req.event.lower()

    # --------------- MAKEUP ---------------
    foundation_choices = FOUNDATION_MAP.get(tone_key, FOUNDATION_MAP["warm beige"])
    foundation = random.choice(foundation_choices)

    lipstick = recommend_lipstick(tone_key)
    blush = BLUSH_MAP.get(tone_key, BLUSH_MAP["warm beige"])
    accessories = ACCESSORIES_MAP.get(face_key, ACCESSORIES_MAP["oval"])
    hairstyle = recommend_hairstyle(face_key)

    makeup = {
        "foundation": foundation,
        "lipstick": lipstick,
        "blush": blush,
        "accessories": accessories,
        "hairstyle": hairstyle,
    }

    # --------------- FASHION COLORS ---------------
    palette = CLOTHING_COLORS.get(tone_key, CLOTHING_COLORS["warm beige"])
    highlight_color = random.choice(palette)

    # --------------- OUTFITS (SEPARATE ITEMS) ---------------
    gender_clothes = EVENT_CLOTHING.get(gender_key, EVENT_CLOTHING["female"])
    outfit_items = gender_clothes.get(event_key, gender_clothes["casual"])

    outfit_list = [
        {
            "item": item,
            "color": highlight_color,
            "link": f"link://{item.replace(' ', '_').lower()}/{highlight_color.replace(' ', '_').lower()}"
        }
        for item in outfit_items
    ]

    bag, shoes = get_bag_and_shoes(gender_key, event_key)

    fashion = {
        "colorPalette": palette,
        "recommendedColor": highlight_color,
        "outfits": outfit_list,
        "bag": bag,
        "shoes": shoes,
    }

    # --------------- SUMMARY ---------------
    summary = (
        f"Skin tone: {req.skin_tone} → styled as '{tone_key}'.\n"
        f"For a {event_key} look, choose {highlight_color} pieces from the suggested outfits.\n"
        f"Bag: {bag} | Shoes: {shoes}.\n"
        f"Makeup suggestion: {foundation} with {lipstick} and {blush}."
    )

    return {
        "makeup": makeup,
        "fashion": fashion,
        "summary": summary,
    }
