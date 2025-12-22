# **AURA: AI Self-Makeover App**

AURA is an AI-powered, cross-platform mobile application designed to provide personalized makeup guidance and beauty recommendations. Built using **Flutter** for the frontend and **Python (FastAPI)** for the backend, the application performs facial analysis, virtual makeup simulation, and AI-driven recommendations based on user facial features.

---

## 🚀 **Key Features**

* Upload an image or capture a selfie for analysis
* Automatic **face detection and landmark extraction**
* **Skin tone classification** and **face shape detection**
* Virtual makeup simulation (lipstick, blush, eye makeup overlays)
* Step-by-step **AI-generated makeup guide**
* Personalized **beauty and product recommendations**
* Modular Flutter UI with REST-based backend integration

---

## 🗂 **Project Structure**

```
Aura-AI-Self-Makeover-App/
│
├── AURA_App/        # Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   ├── models/
│   │   └── utils/
│   └── pubspec.yaml
│
├── backend/                      # Python backend (FastAPI)
│   ├── api/
│   │   ├── makeup_guide_api.py
│   │   ├── classify_face.py
│   │   └── routes.py
│   ├── models/
│   ├── utils/
│   ├── requirements.txt
│   └── main.py
│
├── assets/                       # Images and static assets
├── README.md
└── .gitignore
```

---

## 🛠 **Technologies Used**

* **Frontend:** Flutter (Dart)
* **Backend:** Python, FastAPI
* **ASGI Server:** Uvicorn
* **AI / ML Libraries:** TensorFlow, Keras
* **Computer Vision:** OpenCV, MediaPipe, Dlib
* **Data Processing:** NumPy, Pandas
* **Version Control:** Git & GitHub
* **Development Tools:** VS Code, Postman

---

## ⚙️ **Installation & Setup**

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/hajeeraghazi/Aura-AI-Self-Makeover-App.git
cd Aura-AI-Self-Makeover-App
```

### 2️⃣ Backend Setup

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### 3️⃣ Frontend Setup

```bash
cd flutter_application_1
flutter pub get
flutter run
```

---

## 🎯 **System Workflow**

1. User uploads or captures an image
2. Backend detects face and extracts landmarks
3. Skin tone and face shape are classified using ML models
4. Virtual makeup overlays are applied
5. AI generates a step-by-step makeup guide
6. Personalized recommendations are displayed in the app

---

## 📱 **Usage Instructions**

1. Launch the AURA application
2. Upload a selfie or take a photo
4. View detected facial attributes
5. View Recommendations based on detected facial attributes and user input
6. Virtual Try-On lipstick
7. Select a makeup style
8. Preview virtual makeup and follow the guide

---

## 🤝 **Contributing**

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Submit a pull request

---

## ⚠️ **Disclaimer**

This application provides AI-based beauty and makeup recommendations for educational and demonstration purposes only. Results may vary based on lighting conditions, camera quality, and facial orientation.



