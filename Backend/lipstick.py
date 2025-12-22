import base64
import json
import cv2
import numpy as np
import mediapipe as mp   # pyright: ignore
FaceMesh = mp.solutions.face_mesh.FaceMesh

from fastapi import APIRouter, File, Form, UploadFile, HTTPException
import logging

router = APIRouter()
logger = logging.getLogger("aura")


@router.post("/apply_makeup")
async def apply_makeup(image: UploadFile = File(...), req: str = Form(...)):
    """
    Apply virtual lipstick using mediapipe lip landmarks.
    Expects:
        - image: uploaded file
        - req: JSON string:
            {
                "makeup": {
                    "lips": [R, G, B],
                    "intensity": 0.7
                }
            }
    """
    try:
        # ---------------------------------------------------
        # Parse JSON input
        # ---------------------------------------------------
        try:
            data = json.loads(req)
        except Exception:
            raise HTTPException(status_code=422, detail="Invalid JSON in req")

        makeup = data.get("makeup", {})

        # Get lipstick color (R,G,B)
        lips_color = makeup.get("lips", [200, 0, 0])
        if not isinstance(lips_color, list) or len(lips_color) != 3:
            lips_color = [200, 0, 0]

        # Lipstick transparency 0–1
        alpha = float(makeup.get("intensity", 0.7))

        # ---------------------------------------------------
        # Decode image uploaded by user
        # ---------------------------------------------------
        img_bytes = await image.read()
        arr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image")

        h, w = img.shape[:2]
        rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # ---------------------------------------------------
        # Detect facial landmarks
        # ---------------------------------------------------
        with FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True
        ) as fm:
            res = fm.process(rgb_img)

            if not res.multi_face_landmarks:
                return {"makeup_image_base64": None}

            lm = res.multi_face_landmarks[0]

            # Lip pts from MediaPipe standard
            lips_idx = [
                61,185,40,39,37,0,267,269,270,409,291,308,415,310,
                311,312,13,82,81,80,191,78,95,88,178,87,14,317,
                402,318,324,308,291,375,321,405,314,17,84,181,
                91,146,61
            ]
            pts = [(int(lm.landmark[i].x * w), int(lm.landmark[i].y * h))
                   for i in lips_idx]

            # ---------------------------------------------------
            # Create lip mask
            # ---------------------------------------------------
            mask = np.zeros((h, w), dtype=np.uint8)
            cv2.fillPoly(mask, [np.array(pts, dtype=np.int32)], 255)
            mask = cv2.GaussianBlur(mask, (9, 9), 0)

            # Normalize & apply intensity
            mask_f = (mask.astype(float) / 255.0) * alpha

            # Lip overlay (convert RGB → BGR)
            overlay = np.full_like(img, lips_color[::-1])

            # Final blending
            img = (
                overlay * mask_f[..., None]
                + img * (1 - mask_f[..., None])
            ).astype(np.uint8)

        # ---------------------------------------------------
        # Encode final output image
        # ---------------------------------------------------
        _, buf = cv2.imencode(".jpg", img)
        final_b64 = base64.b64encode(buf).decode()

        return {"makeup_image_base64": final_b64}

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("apply_makeup failed")
        raise HTTPException(status_code=500, detail=str(e))
