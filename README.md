[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/inoLPW_E)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=20099722&assignment_repo_type=AssignmentRepo)
# CBSee Project - Computer Vision Object Recognition App

CBSee is a mobile application that uses computer vision and machine learning to recognize and identify objects in real-time using the device's camera. The project consists of a Flutter frontend and a Django REST API backend with PyTorch-based ML inference.

## Project Structure

```
CBSee-Project/
├── cbsee_backend/          # Django REST API Backend
│   ├── api/               # Main API app
│   │   ├── models.py      # Database models
│   │   ├── views.py       # API endpoints
│   │   ├── ml_inference.py # PyTorch ML inference
│   │   └── urls.py        # API URL routing
│   ├── backend/           # Django project settings
│   ├── models/            # ML model files
│   │   ├── mobile_model.pth
│   │   └── classes.txt
│   └── firebase/          # Firebase configuration
├── cbsee_frontend/        # Flutter Mobile App
│   ├── lib/
│   │   ├── screens/       # App screens
│   │   ├── services/      # API services
│   │   └── widgets/       # Custom widgets
│   └── assets/
│       └── models/        # Model files (duplicate for mobile)
└── README.md              # This file
```

## Prerequisites

### Backend Requirements
- **Python 3.8+** (tested with Python 3.12)
- **Django 5.0.6**
- **PyTorch** (CPU version recommended)
- **Firebase Admin SDK**

### Frontend Requirements
- **Flutter SDK 3.7.2+**
- **Dart SDK 3.7.2+**
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Firebase CLI** (optional, for deployment)

### System Requirements
- **Windows 10/11** (current setup)
- **Android device or emulator** for testing
- **At least 4GB RAM** (8GB+ recommended for ML inference)
- **Sufficient disk space** (2GB+ for dependencies and models)

---

## Backend Setup and Running Instructions

### 1. Environment Setup

1. **Navigate to backend directory:**
   ```bash
   cd CBSee-Project/cbsee_backend
   ```

2. **Create and activate virtual environment:**
   ```bash
   # Create virtual environment
   python -m venv venv

   # Activate virtual environment
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate
   ```

3. **Install Python dependencies:**
   ```bash
   pip install django==5.0.6
   pip install djangorestframework
   pip install django-cors-headers
   pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
   pip install Pillow
   pip install firebase-admin
   pip install python-dotenv
   ```

   **Alternative: Create requirements.txt and install:**
   ```bash
   # Create requirements.txt file with:
   echo "django==5.0.6
   djangorestframework
   django-cors-headers
   torch
   torchvision
   Pillow
   firebase-admin
   python-dotenv" > requirements.txt

   # Install from requirements
   pip install -r requirements.txt
   ```

### 2. Firebase Configuration

1. **Ensure Firebase service account key is present:**
   - File should be at: `CBSee-Project/cbsee_backend/firebase/cbsee-backend.json`
   - This file contains your Firebase service account credentials

2. **Verify Firebase configuration in settings.py:**
   - The Firebase config is already set up in `backend/settings.py`
   - Project ID: `cbsee-1f435`
   - Make sure the service account has the necessary permissions

### 3. Database Setup

1. **Run database migrations:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

2. **Create superuser (optional):**
   ```bash
   python manage.py createsuperuser
   ```

### 4. Model Files Setup

1. **Ensure model files are present:**
   - `models/mobile_model.pth` - Trained PyTorch model
   - `models/classes.txt` - Class labels (20 object classes)

2. **Verify model loading:**
   The ML inference will automatically load the model when the server starts.

### 5. Running the Backend Server

1. **Start the Django development server:**
   ```bash
   python manage.py runserver
   ```

2. **Server will be available at:**
   - **Main API:** `http://127.0.0.1:8000/api/v1/`
   - **Admin Panel:** `http://127.0.0.1:8000/admin/`
   - **API Endpoints:**
     - `GET /api/v1/` - Health check
     - `POST /api/v1/auth/signup/` - User registration
     - `POST /api/v1/classify/` - Image classification

3. **Test the API:**
   ```bash
   # Test health endpoint
   curl http://127.0.0.1:8000/api/v1/

   # Test image classification (with an image file)
   curl -X POST -F "image=@test_image.jpg" http://127.0.0.1:8000/api/v1/classify/
   ```

### 6. Backend Troubleshooting

**Common Issues:**

1. **Model loading errors:**
   - Ensure `mobile_model.pth` exists in `models/` directory
   - Check file permissions
   - Verify PyTorch installation

2. **Firebase authentication errors:**
   - Verify `cbsee-backend.json` file exists and is valid
   - Check Firebase project configuration
   - Ensure service account has proper permissions

3. **CORS errors:**
   - CORS is configured to allow all origins in development
   - For production, update `CORS_ALLOWED_ORIGINS` in settings.py

4. **Dependencies issues:**
   - Ensure all packages are installed in the virtual environment
   - Use `pip list` to verify installed packages
   - Consider using `pip freeze > requirements.txt` to save exact versions

---

## Frontend Setup and Running Instructions

### 1. Flutter Environment Setup

1. **Install Flutter SDK:**
   - Download from: https://flutter.dev/docs/get-started/install/windows
   - Add Flutter to your PATH environment variable
   - Verify installation: `flutter doctor`

2. **Install Android Studio:**
   - Download and install Android Studio
   - Install Android SDK (API level 33+ recommended)
   - Configure Android emulator or connect physical device

3. **Enable Swift Package Manager (for iOS, if needed):**
   ```bash
   flutter config --enable-swift-package-manager
   ```

### 2. Project Setup

1. **Navigate to frontend directory:**
   ```bash
   cd CBSee-Project/cbsee_frontend
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup:**
   ```bash
   flutter doctor
   ```
   Ensure all required components show as installed.

### 3. Firebase Configuration

1. **Firebase project is already configured:**
   - Project ID: `cbsee-1f435`
   - Configuration files are present in the project
   - `google-services.json` for Android
   - Firebase configuration in `lib/firebase_options.dart`

2. **Verify Firebase setup:**
   - Ensure Firebase project is active
   - Check that Authentication is enabled
   - Verify Google Sign-In is configured

### 4. Device Setup

1. **For Android Device:**
   ```bash
   # Enable Developer Options on your Android device
   # Enable USB Debugging
   # Connect device via USB
   
   # Verify device connection
   flutter devices
   ```

2. **For Android Emulator:**
   ```bash
   # Start Android Studio
   # Open AVD Manager
   # Create/Start an Android Virtual Device
   
   # Verify emulator connection
   flutter devices
   ```

### 5. Running the Flutter App

1. **Check available devices:**
   ```bash
   flutter devices
   ```

2. **Run on connected device:**
   ```bash
   # Run on specific device
   flutter run -d <device-id>
   
   # Run on first available device
   flutter run
   
   # Run in debug mode (default)
   flutter run --debug
   
   # Run in release mode (for performance testing)
   flutter run --release
   ```

3. **Build APK for distribution:**
   ```bash
   # Build debug APK
   flutter build apk --debug
   
   # Build release APK
   flutter build apk --release
   ```

### 6. Frontend Troubleshooting

**Common Issues:**

1. **Device not recognized:**
   ```bash
   # Check device connection
   flutter devices
   
   # Restart ADB server
   adb kill-server
   adb start-server
   ```

2. **Build failures due to disk space:**
   - Free up disk space (at least 2GB recommended)
   - Clear Flutter cache: `flutter clean`
   - Clear Gradle cache: `cd android && ./gradlew clean`

3. **Swift Package Manager issues (iOS):**
   ```bash
   flutter config --enable-swift-package-manager
   flutter clean
   flutter pub get
   ```

4. **Dependencies issues:**
   ```bash
   # Clean and reinstall dependencies
   flutter clean
   flutter pub get
   
   # Update dependencies
   flutter pub upgrade
   ```

5. **Firebase configuration issues:**
   - Verify `google-services.json` is in `android/app/`
   - Check Firebase project settings
   - Ensure SHA-1 fingerprints are added to Firebase console

---

## Full Application Workflow

### 1. Start Backend Server
```bash
cd CBSee-Project/cbsee_backend
venv\Scripts\activate  # Windows
python manage.py runserver
```

### 2. Start Frontend App
```bash
cd CBSee-Project/cbsee_frontend
flutter run
```

### 3. Application Features
- **User Authentication:** Firebase-based signup/login
- **Object Recognition:** Real-time camera-based object detection
- **ML Classification:** 20 object classes supported
- **History Tracking:** View past recognition results
- **Settings Management:** App configuration options

### 4. Supported Object Classes
The app can recognize these 20 object types:
- apple_fruit, bag_backpack, book, chair, clock, comb
- cup_mug, key, notebook, pencil_pen, plate, radio
- shoes, soccer_ball_football, spoon, table, television
- toothbrush, towel, water_bottle

---

## Development Notes

### Backend Development
- **API Documentation:** Available at `/admin/` when running
- **Database:** SQLite (development), easily configurable for PostgreSQL/MySQL
- **ML Model:** PyTorch-based MobileNet v3 Small
- **Authentication:** Firebase Admin SDK integration

### Frontend Development
- **State Management:** Basic state management with setState
- **Navigation:** Material Design navigation
- **Camera Integration:** Real-time camera preview and capture
- **HTTP Client:** Built-in HTTP package for API communication

### Performance Considerations
- **ML Inference:** Runs on CPU (backend) for reliability
- **Image Processing:** Optimized preprocessing pipeline
- **Caching:** Model loaded once at startup for efficiency
- **Error Handling:** Comprehensive error handling and logging

---

## Production Deployment

### Backend Deployment
1. **Configure production settings:**
   - Set `DEBUG = False`
   - Configure production database
   - Set up proper CORS origins
   - Use environment variables for secrets

2. **Deploy options:**
   - **Heroku:** Easy Django deployment
   - **AWS/GCP/Azure:** Containerized deployment
   - **DigitalOcean:** VPS deployment

### Frontend Deployment
1. **Build for production:**
   ```bash
   flutter build apk --release
   flutter build appbundle --release  # For Play Store
   ```

2. **Distribution:**
   - **Google Play Store:** Upload APK/AAB
   - **App Store:** iOS build and submission
   - **Direct Distribution:** Share APK files

---

## Support and Maintenance

### Logging
- **Backend:** Django logging to console and files
- **Frontend:** Flutter debug console logging
- **ML Inference:** Detailed prediction logging

### Updates
- **Model Updates:** Replace `mobile_model.pth` and retrain if needed
- **Dependencies:** Regular updates for security patches
- **Flutter SDK:** Keep Flutter SDK updated for latest features

### Monitoring
- **Backend Health:** Monitor Django server status
- **API Performance:** Track response times and errors
- **ML Accuracy:** Monitor prediction accuracy and user feedback

---

## Contact and Support

For technical support or questions about this project, please refer to the code comments and documentation within each component.

**Key Files to Review:**
- `cbsee_backend/api/ml_inference.py` - ML model integration
- `cbsee_backend/api/views.py` - API endpoints
- `cbsee_frontend/lib/screens/scan_screen.dart` - Main camera functionality
- `cbsee_frontend/lib/services/auth_service.dart` - Authentication service