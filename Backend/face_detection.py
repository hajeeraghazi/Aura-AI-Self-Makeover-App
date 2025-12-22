import torch
import numpy as np
import cv2
import dlib
from typing import Dict, Any, List
from ultralytics import YOLO
import io
from PIL import Image
from torchvision import transforms
import base64

# Load YOLOv8 face detection model
yolo_model = YOLO("yolov8n-face-lindevs.pt")
yolo_model.conf = 0.5

# Load dlib landmark detector
predictor_path = 'models/shape_predictor_68_face_landmarks.dat'
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(predictor_path)



def bytes_to_cv2(image_bytes: bytes):
    """Convert bytes → safe OpenCV BGR uint8 image"""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)

    if img is None:
        raise ValueError("Could not decode image from bytes")

    # Fix RGBA → BGR
    if len(img.shape) == 3 and img.shape[2] == 4:
        img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)

    # Fix grayscale → BGR
    if len(img.shape) == 2:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)

    # Fix dtype
    if img.dtype != np.uint8:
        img = cv2.convertScaleAbs(img)

    return img

def cv2_to_base64(img: np.ndarray) -> str:
    """Convert cv2 image → base64 string for JSON response"""
    _, buffer = cv2.imencode(".jpg", img)
    return base64.b64encode(buffer).decode("utf-8")

def detect_faces_and_landmarks(image_bytes: bytes) -> Dict[str, Any]:
    img = bytes_to_cv2(image_bytes)  # BGR image from bytes
    results = yolo_model(img)

    faces_data = []

    for result in results:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())

            # Crop face
            face_img = img[y1:y2, x1:x2]
            if face_img is None or face_img.size == 0:
                continue

            # ✅ Ensure 8-bit grayscale for predictor
            gray = cv2.cvtColor(face_img, cv2.COLOR_BGR2GRAY)
            if gray.dtype != np.uint8:
                gray = cv2.convertScaleAbs(gray)

            # dlib rect on cropped face
            dlib_rect = dlib.rectangle(0, 0, gray.shape[1], gray.shape[0])

            try:
                shape = predictor(gray, dlib_rect)  # 68 landmarks
            except RuntimeError as e:
                print(f"⚠️ dlib predictor failed: {e}")
                continue

            # Map landmarks back to original image coords
            landmarks = [(shape.part(i).x, shape.part(i).y) for i in range(68)]
            landmarks_in_image_coords = [(x + x1, y + y1) for (x, y) in landmarks]

            # Draw landmarks for debugging
            for (lx, ly) in landmarks_in_image_coords:
                cv2.circle(img, (lx, ly), 1, (0, 255, 0), -1)

            face_shape = classify_face_shape(landmarks_in_image_coords)

            faces_data.append({
                'bbox': [x1, y1, x2, y2],
                'landmarks': landmarks_in_image_coords,
                'face_shape': face_shape
            })

    return {
        'annotated_image': img,
        'faces': faces_data,
    }



def classify_face_shape(landmarks):
    jaw_width = np.linalg.norm(np.array(landmarks[0]) - np.array(landmarks[16]))
    face_length = np.linalg.norm(np.array(landmarks[8]) - np.array(landmarks[27]))
    forehead_width = np.linalg.norm(np.array(landmarks[17]) - np.array(landmarks[26]))

    ratio_jaw_face = face_length / jaw_width
    ratio_forehead_jaw = forehead_width / jaw_width

    if ratio_jaw_face > 1.6 and ratio_forehead_jaw > 0.9:
        return "Oval"
    elif ratio_jaw_face <= 1.4 and ratio_forehead_jaw <= 0.9:
        return "Round"
    elif ratio_jaw_face <= 1.5 and ratio_forehead_jaw > 1.0:
        return "Square"
    else:
        return "Heart"
