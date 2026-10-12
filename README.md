# 📱 CollegeCantin - Student Mobile App (Dart / Flutter)

This is the standalone **Flutter / Dart** mobile application for students to order food online from college canteens and get cryptographic single-use QR tickets on their phones.

---

## 🚀 How to Run the Flutter App

### Prerequisites
- Install **Flutter SDK** (>= 3.0.0): [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- Android Studio / VS Code with Flutter extension.

### Steps:

1. **Navigate into `student_flutter_app` folder**:
   ```bash
   cd student_flutter_app
   ```

2. **Get Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Connected Android Phone / iPhone / Emulator**:
   ```bash
   flutter run
   ```

---

## 🌐 Connected Backend API
The Flutter app connects directly to the live production server at:
`https://collegecantin.vercel.app`

- **Fetch Canteens**: `GET /api/tenants`
- **Fetch Food Menu**: `GET /api/menu`
- **Submit UPI Order & Generate QR**: `POST /api/orders`
- **Check Real-Time Status**: `GET /api/orders/:id`
