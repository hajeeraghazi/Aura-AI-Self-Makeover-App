# ============================================================
# Skin Tone Classification using STONE (FINAL)
# ============================================================

import os
import cv2
import hashlib
import tempfile
import logging

logger = logging.getLogger("aura")

# ============================================================
# TRY IMPORT STONE
# ============================================================
try:
    import stone
    STONE_AVAILABLE = True
except Exception:
    STONE_AVAILABLE = False
    logger.warning("STONE library not available")

# ============================================================
# CACHE (avoid recomputation)
# ============================================================
SKIN_CACHE = {}

# ============================================================
# HEX → HUMAN FRIENDLY NAME
# ============================================================
def hex_to_color_name(hex_color: str) -> str:
    if not hex_color:
        return "Unknown"

    hex_color = hex_color.lstrip("#")

    try:
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
    except Exception:
        return "Unknown"

    avg = (r + g + b) / 3

    if avg > 220:
        return "Porcelain (Very Fair)"
    elif avg > 200:
        return "Fair"
    elif avg > 180:
        return "Light"
    elif avg > 160:
        return "Medium"
    elif avg > 130:
        return "Tan"
    elif avg > 100:
        return "Brown"
    else:
        return "Deep Brown"

# ============================================================
# MAIN SKIN TONE CLASSIFIER
# ============================================================
def classify_skin_tone(img_bgr):
    """
    Returns:
    {
      bucket: Human-friendly tone,
      hex: "#aabbcc",
      trained_label: original STONE label,
      confidence: 0-1,
      method: "stone"
    }
    """

    if not STONE_AVAILABLE:
        return {
            "bucket": "Unknown",
            "confidence": 0.0,
            "method": "stone_unavailable"
        }

    try:
        md5 = hashlib.md5(img_bgr.tobytes()).hexdigest()
        if md5 in SKIN_CACHE:
            return SKIN_CACHE[md5]

        # Save temp image
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
            cv2.imwrite(tmp.name, img_bgr)
            path = tmp.name

        result = stone.process(path)

        # Always cleanup
        os.remove(path)

        if not result:
            return {
                "bucket": "Unknown",
                "confidence": 0.0,
                "method": "stone_no_result"
            }

        rec = result[0]
        faces = rec.get("faces", [])

        if not faces:
            return {
                "bucket": "Unknown",
                "confidence": 0.0,
                "method": "stone_no_face"
            }

        f = faces[0]
        hex_val = f.get("skin_tone")
        trained_label = f.get("tone_label", "unknown")
        confidence = f.get("accuracy", 0) / 100.0

        friendly = hex_to_color_name(hex_val)

        out = {
            "bucket": friendly,
            "hex": hex_val,
            "trained_label": trained_label,
            "confidence": confidence,
            "method": "stone"
        }

        SKIN_CACHE[md5] = out
        return out

    except Exception as e:
        logger.exception("Skin tone classification failed")
        return {
            "bucket": "Unknown",
            "confidence": 0.0,
            "method": "stone_error"
        }
