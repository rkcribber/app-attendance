# Haaziri - Personal Attendance Tracker 📚

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10.4+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.10.4+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Web-green" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

**Haaziri** (हाज़िरी - Hindi for "Attendance") is a personal attendance tracking application designed for students to maintain their own attendance records with photo proof and GPS location data. This app helps students dispute incorrect attendance markings by professors by providing verifiable evidence of their presence in class.

---

## 🎯 Purpose

Have you ever been marked absent even though you were present in class? Or a professor forgot to mark attendance for a cancelled class? **Haaziri** solves this problem by:

- 📸 **Photo Proof** - Take photos as evidence of your presence in class
- 🌍 **GPS Location** - Automatically captures your location when taking photos
- 📅 **Date-wise Records** - Maintain attendance for each day separately
- 📊 **Statistics** - View overall and subject-wise attendance percentages
- 📄 **PDF Reports** - Generate shareable PDF reports with all evidence

---

## ✨ Features

### 📋 Core Features

| Feature | Description |
|---------|-------------|
| **Daily Attendance Tracking** | Track attendance for multiple subjects each day |
| **Attendance Status** | Mark each class as Present, Absent, Cancelled, or Bunk |
| **Photo Proof** | Capture photos from camera or select from gallery as evidence |
| **GPS Location Tagging** | Automatic GPS coordinates and address capture with each photo |
| **Date Selection** | Navigate between dates to view/edit past attendance |
| **Subject Management** | Add, edit, or delete subjects dynamically |
| **Persistent Storage** | All data persists across app restarts |

### 👤 Profile Section

- **Personal Information**: Name, Contact Number, Email, Admission Number
- **College Selection**: Choose from predefined colleges (LSR, KNC, JIIT, SRCC)
- **Profile Picture**: Upload and display your profile photo
- **Input Validation**: 
  - Contact: Must be exactly 10 digits
  - Email: Must end with `.com`, `.edu`, `.gov.edu`, or `.gov.in`

### 🎨 Theme Customization

Choose from **11 beautiful color themes**:
- Deep Purple, Blue, Teal, Green, Orange
- Red, Pink, Indigo, Cyan, Amber
- **Dark Theme** for low-light environments

Themes can be previewed in real-time before saving!

### 📊 Attendance Statistics

#### Daily Summary
- Real-time count of Present, Absent, Cancelled, Bunk, and Pending classes
- Visual indicators with color-coded circles

#### Overall Attendance Calculator
- Select custom date range
- Calculate:
  - Overall attendance percentage
  - Per-subject attendance breakdown
  - Progress bars with color coding (Green ≥75%, Orange ≥50%, Red <50%)
  - Detailed stats: Present, Absent, Bunk, Cancelled counts

### 📄 PDF Report Generation

#### Daily Attendance Report
- Header with date and generation timestamp
- Summary statistics
- Per-subject details including:
  - Subject name and status
  - Photo proof (embedded in PDF)
  - GPS coordinates with Google Maps link
  - Address (if available)
  - Timestamp of capture

#### Overall Attendance Report
- Date range summary
- Student profile information
- Overall attendance percentage
- Subject-wise table with all statistics
- Export and share via iOS/Android share sheet

---

## 📱 Screenshots

| Home Screen | Profile | Subject Management |
|:-----------:|:-------:|:------------------:|
| Date picker, summary, subjects | Edit profile, theme colors | Add/Edit/Delete subjects |

| Photo Capture | PDF Report | Attendance Calculator |
|:-------------:|:----------:|:--------------------:|
| Camera/Gallery with GPS | Detailed PDF with proof | Date range statistics |

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10.4+
- **Language**: Dart
- **State Management**: StatefulWidget with setState
- **Storage**: SharedPreferences (for persistence)

### Dependencies

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8        # iOS-style icons
  image_picker: ^1.0.7           # Camera & gallery access
  intl: ^0.19.0                  # Date formatting
  pdf: ^3.10.8                   # PDF generation
  path_provider: ^2.1.2          # File system paths
  share_plus: ^7.2.2             # Share functionality
  permission_handler: ^11.3.0    # Permission management
  open_file: ^3.5.10             # Open files externally
  geolocator: ^12.0.0            # GPS location
  geocoding: ^3.0.0              # Reverse geocoding
  shared_preferences: ^2.2.2     # Persistent storage
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.4 or higher
- Dart SDK 3.10.4 or higher
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rkcribber/app-attendance.git
   cd app-attendance
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   
   For iOS Simulator:
   ```bash
   flutter run -d ios
   ```
   
   For Android Emulator:
   ```bash
   flutter run -d android
   ```
   
   For macOS:
   ```bash
   flutter run -d macos
   ```

### Build for Release

**iOS**
```bash
flutter build ios --release
```

**Android APK**
```bash
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

---

## 📂 Project Structure

```
attendance_management/
├── lib/
│   └── main.dart              # Main application code (all-in-one)
├── android/                   # Android-specific configuration
├── ios/                       # iOS-specific configuration
├── macos/                     # macOS-specific configuration
├── linux/                     # Linux-specific configuration
├── windows/                   # Windows-specific configuration
├── web/                       # Web-specific configuration
├── test/
│   └── widget_test.dart       # Widget tests
├── pubspec.yaml               # Dependencies & configuration
├── analysis_options.yaml      # Linter rules
└── README.md                  # This file
```

---

## 🔒 Permissions Required

### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to take attendance photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires photo library access to select attendance photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires location access to tag your attendance with GPS coordinates</string>
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 📖 Usage Guide

### 1. Setting Up Profile
1. Tap the **profile icon** (top-left corner)
2. Add your photo, name, contact, email, college, and admission number
3. Select a theme color
4. Tap **Save Profile**

### 2. Managing Subjects
1. Tap the **book icon** (top-right corner)
2. Edit existing subject names or delete them
3. Add new subjects using the "Add New Subject" button
4. Subject names persist across app restarts

### 3. Recording Attendance
1. Select the date using the date picker
2. For each subject:
   - Tap the camera icon to take a photo or select from gallery
   - Select attendance status: Present, Absent, Cancelled, or Bunk
3. GPS location is automatically captured with each photo

### 4. Saving Daily Record
1. Scroll to the bottom
2. Tap **Save Record as PDF**
3. Choose to **Open PDF** or **Share/Save** to Files

### 5. Calculating Overall Attendance
1. Scroll to the bottom
2. Tap **Calculate Overall Attendance**
3. Select start and end dates
4. Tap **Calculate Attendance**
5. View statistics and optionally save as PDF

---

## 🎨 Data Models

### AttendanceStatus (Enum)
```dart
enum AttendanceStatus { none, present, absent, cancelled, bunk }
```

### LocationData
```dart
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
}
```

### SubjectAttendance
```dart
class SubjectAttendance {
  final String subjectName;
  AttendanceStatus status;
  String? photoPath;
  LocationData? location;
}
```

---

## 🔧 Configuration

### Supported Colleges
The app comes with predefined colleges:
- LSR (Lady Shri Ram College)
- KNC (Kirori Mal College)
- JIIT (Jaypee Institute of Information Technology)
- SRCC (Shri Ram College of Commerce)

To add more colleges, modify the `collegeOptions` list in `main.dart`:
```dart
static const List<String> collegeOptions = ['LSR', 'KNC', 'JIIT', 'SRCC', 'YourCollege'];
```

### Default Subjects
Default subjects can be modified in the `subjectNames` list:
```dart
List<String> subjectNames = [
  'Subject 1',
  'Subject 2',
  'Subject 3',
  'Subject 4',
  'Subject 5',
];
```

---

## 🐛 Known Issues & Troubleshooting

### PDF Font Issues
If you see font-related warnings in the console:
```
Helvetica-Bold has no Unicode support
Unable to find a font to draw "✓"
```
**Solution**: The PDF uses default fonts. Special characters are replaced with text equivalents in the PDF.

### App Closes When Disconnected from Mac
If running via Xcode Runner, the app may close when USB is disconnected.
**Solution**: Install the app properly via TestFlight or build a release IPA.

### Location Permission Denied
If GPS doesn't work:
1. Go to Settings > Privacy > Location Services
2. Enable location for "Haaziri"

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Anmol Mishra**
- GitHub: [@rkcribber](https://github.com/rkcribber)
- Email: anmol.j2020@gmail.com

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All the package authors for their wonderful contributions
- The student community for inspiring this project

---

## 📈 Future Enhancements

- [ ] Cloud sync for backup
- [ ] Multiple semester support
- [ ] Export to Excel/CSV
- [ ] Widgets for iOS/Android home screen
- [ ] Apple Watch / Wear OS companion apps
- [ ] Notifications for low attendance warnings
- [ ] Dark mode improvements
- [ ] Biometric lock for privacy

---

<p align="center">
  Made with ❤️ using Flutter
</p>

<p align="center">
  <b>Haaziri</b> - Never let wrong attendance affect your grades again! 🎓
</p>

