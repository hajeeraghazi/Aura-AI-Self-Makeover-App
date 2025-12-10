# Aura-AI Self-Makeover App

Aura-AI is a cross-platform mobile application built using **Flutter + Python** that helps users experiment with virtual makeup, perform facial analysis, explore tutorials, and receive AI-driven beauty recommendations.

---

## 🚀 Features

- Upload or capture a selfie for AI analysis.
- Automatic **face landmark detection**, **skin-tone classification**, and **face-shape detection**.
- Try different virtual makeup looks (lip, eye, blush overlays).
- Step-by-step **makeup tutorial guide** for each look.
- Personalized **product recommendations** based on detected features.
- Smooth Flutter UI with modular backend integration.

---

## 🗂 Project Structure

```

Aura-AI-Self-Makeover-App/
│
├── lib/                     # Flutter app source
│   ├── main.dart
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   ├── models/
│   └── utils/
│
├── backend/ or python/      # Python ML/AI Logic (depends on repo structure)
│   ├── classification.py
│   ├── predict_tone_shape.py
│   ├── lipstick.py
│   ├── makeup_guide_api.py
│   └── requirements.txt
│
├── assets/
├── build.gradle / pubspec.yaml
└── README.md

````

---

## 🛠 Installation & Setup

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/hajeeraghazi/Aura-AI-Self-Makeover-App.git
cd Aura-AI-Self-Makeover-App
````

### 2️⃣ Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 3️⃣ Install Flutter Dependencies

```bash
flutter pub get
flutter run
```

### 4️⃣ Permissions

On first launch the app may request:

* Camera access
* Storage access

---

## 🎯 How It Works (AI Pipeline)

* **Face Detection & Landmarking:** FaceLandmarker model processes key facial features.
* **Skin Tone & Face Shape Classification:** Python ML models (`classification.py`, `predict_tone_shape.py`).
* **Makeup Rendering:** Color overlays & blending using OpenCV/Python scripts (e.g., `lipstick.py`).
* **Makeup Guide:** Structured tutorial steps derived from JSON/model files.
* **Recommendations:** Generated using predefined styles and user facial attributes.

---

## 📱 Usage

1. Open the app.
2. Take a selfie or upload one.
3. Aura-AI analyzes your face and shows:

   * Skin tone
   * Face shape
   * Recommended looks
4. Choose a makeup style to preview.
5. Follow step-by-step guidance and check product suggestions.

---

## 🤝 Contributing

Contributions are welcome!

Steps:

1. Fork the repository
2. Create a new feature branch
3. Commit your changes
4. Make a pull request

Please follow coding conventions and test thoroughly.

---

## ⚠️ Disclaimer

This app provides *approximate* AI-based makeup predictions.
Real-world results may vary based on lighting, camera quality, and angles.


