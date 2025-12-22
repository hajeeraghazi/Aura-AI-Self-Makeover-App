Install all dependies 

save this project in any folder and open command prompt.
and run below command:

pip install -r requirement.txt

once it is installed then run uvicorn server

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

http://localhost:8000/docs use this link to show API working model


Next steps:
Replace ai_inference.py placeholders with real model code:

Use YOLO or OpenCV for face/feature detection.

Load your GAN/CNN models for recommendations.

Implement feedback analysis using CNNs.

training data should be prepared
models/skin_tone_cnn.pth

Add authentication & user profile management (Firebase or JWT).

Connect this backend API with your Flutter frontend via HTTP calls.

Implement AR features natively or call AR SDKs from the frontend.