# EchoLock Password Manager

A secure, cross-platform password manager built with Flutter, featuring end-to-end encryption, multi-device synchronization, and comprehensive password security analysis.

## 🔐 Features

### **Password Management**
- **Secure Vault**: Store passwords, secure notes, and credit card information
- **Password Generator**: Create strong, customizable passwords
- **Password Health Dashboard**: Monitor password security with real-time analysis
- **Breach Detection**: Check passwords against HaveIBeenPwned database using k-anonymity
- **Duplicate Detection**: Identify reused passwords across accounts
- **Strength Analysis**: Evaluate password complexity and security

### **Security & Privacy**
- **End-to-End Encryption**: AES-256-GCM encryption with PBKDF2 key derivation
- **Zero-Knowledge Architecture**: Server never sees your unencrypted data
- **Biometric Authentication**: Secure app access with fingerprint/face recognition
- **Password Fingerprints**: Privacy-preserving duplicate detection using SHA-256 hashes
- **Offline-First Design**: Full functionality without internet connection

### **Synchronization**
- **Multi-Device Sync**: Seamlessly access your vault across all devices
- **Firebase Integration**: Encrypted cloud backup and synchronization
- **Conflict Resolution**: Robust handling of concurrent edits
- **Incremental Updates**: Efficient sync with granular change tracking

## 📱 Screenshots

![WhatsApp Image 2025-10-21 at 14 00 40_df94f043](https://github.com/user-attachments/assets/3500173b-20b8-4158-a8a4-378c60ba9380)
![WhatsApp Image 2025-10-21 at 14 00 40_827d81db](https://github.com/user-attachments/assets/4be9a926-c78e-42f8-8ee8-70e7cb585e89)
![WhatsApp Image 2025-10-21 at 14 00 40_11e5b1be](https://github.com/user-attachments/assets/569e2ae4-aec8-4d13-aca0-ecc0d4a3a89f)
![WhatsApp Image 2025-10-21 at 14 00 41_60967c27](https://github.com/user-attachments/assets/ba402229-db1e-4078-82ad-810f53ce5e4a)
![WhatsApp Image 2025-10-21 at 14 00 41_54a09ed1](https://github.com/user-attachments/assets/10cc711a-40d9-4f71-97e4-c094f6aacdae)
![WhatsApp Image 2025-10-21 at 14 00 41_32f5f8ab](https://github.com/user-attachments/assets/9683eb34-66fd-4379-a96d-ff612c598a53)
![WhatsApp Image 2025-10-21 at 14 00 41_4a5a7b55](https://github.com/user-attachments/assets/72519a68-a391-46fd-9c1a-e970f249eb5e)
![WhatsApp Image 2025-10-21 at 14 00 41_4df275ff](https://github.com/user-attachments/assets/23ac481e-e829-4cb8-807a-2c20695842f2)
![WhatsApp Image 2025-10-21 at 14 00 42_d6ccb58e](https://github.com/user-attachments/assets/a3cb4834-124e-432e-a224-dca3fa13f06d)
![WhatsApp Image 2025-10-21 at 14 00 42_a811e5e8](https://github.com/user-attachments/assets/3302bfcf-c8dd-4894-a197-e351faea5f12)
![WhatsApp Image 2025-10-21 at 14 00 42_03aecc3a](https://github.com/user-attachments/assets/192c2bba-9d15-4521-955c-26a7d35051e3)
![WhatsApp Image 2025-10-21 at 14 00 41_9e695d09](https://github.com/user-attachments/assets/184e1411-5a46-4a0b-8a90-c2348fa64cfb)
![WhatsApp Image 2025-10-21 at 14 00 41_1b11ae32](https://github.com/user-attachments/assets/d6a2c7b8-96db-4d59-995e-3c0155629acc)


## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=2.17.0)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/alexap120/password_manager.git
   cd password_manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firestore Database
   - Enable Authentication (Email/Password)
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

### **Data Layer**
- **Local Storage**: Hive database for offline-first functionality
- **Cloud Storage**: Firebase Firestore for encrypted synchronization
- **Models**: Structured data classes for LoginItem, NoteItem, CardItem

### **Security Layer**
- **Encryption Service**: AES-256-GCM implementation for data protection
- **Authentication**: Firebase Auth with biometric integration
- **Password Analysis**: Breach checking and strength evaluation

### **Synchronization Layer**
- **Sync Service**: Bi-directional synchronization between local and cloud
- **Status Tracking**: Granular sync state management

## 🔒 Security Implementation

### **Encryption Details**
```dart
// Master key derivation
final key = await deriveKeyPBKDF2(password, salt, iterations: 100000);

// Data encryption
final encrypted = await encryptAesGcm(key, plaintext);
// Returns: { ciphertext, nonce, tag }

// Secure password checking (k-anonymity)
final hashPrefix = sha1Hash.substring(0, 5);  // Only 5 chars sent to API
final hashSuffix = sha1Hash.substring(5);     // Kept locally
```

### **Privacy Protection**
- **Password Fingerprints**: SHA-256 hashes for duplicate detection without exposing plaintext
- **k-Anonymity**: HaveIBeenPwned integration sends only hash prefixes
- **Zero-Knowledge**: Firebase stores only encrypted blobs, cannot decrypt user data

### **Authentication Flow**
1. User enters master password
2. PBKDF2 key derivation (100,000+ iterations)
3. Key verification against stored hash
4. Biometric authentication (optional)
5. Vault unlock and data decryption

## 📊 Password Health Analysis

The app provides comprehensive password security analysis:

- **Breach Detection**: Real-time checking against known data breaches
- **Strength Evaluation**: Analysis of length, complexity, and character variety
- **Duplicate Identification**: Detection of reused passwords using fingerprints
- **Visual Dashboard**: Color-coded security metrics and actionable insights

## 🛠️ Technology Stack

### **Frontend**
- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language
- **Material Design**: UI components and design system

### **Backend & Services**
- **Firebase Firestore**: Cloud database
- **Firebase Auth**: Authentication service
- **HaveIBeenPwned API**: Password breach database

### **Security & Storage**
- **Hive**: Local NoSQL database
- **crypto**: Cryptographic operations
- **local_auth**: Biometric authentication

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  crypto: ^3.0.3
  local_auth: ^2.1.6
  http: ^1.1.0
```

## 🔧 Configuration

### **Environment Setup**
Create a `.env` file (not included in repository):
```env
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id_here
```

### **Security Configuration**
- Update PBKDF2 iterations in `encryption_service.dart`
- Configure biometric authentication in `auth_service.dart`
- Set up custom password strength rules in `password_strength_util.dart`

## 📱 Platform Support

- ✅ **Android**: Minimum SDK 21 (Android 5.0+)
- ✅ **iOS**: iOS 12.0+

## ⚠️ Security Considerations

### **Before Making Public**

1. **Remove Sensitive Data**
   ```bash
   # Check for exposed secrets
   git log --patch | grep -E "(api|key|password|secret|token)"
   
   # Clean up git history if needed
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch config/secrets.dart' \
   --prune-empty --tag-name-filter cat -- --all
   ```

2. **Environment Variables**
   - Move all API keys to environment variables
   - Add `.env` and `*.config` to `.gitignore`
   - Document required environment variables in README

3. **Firebase Security Rules**
   ```javascript
   // Firestore security rules example
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null 
           && request.auth.uid == userId;
       }
     }
   }
   ```

4. **Code Review Checklist**
   - [ ] No hardcoded API keys or secrets
   - [ ] No debug/testing credentials
   - [ ] Proper error handling without exposing internals
   - [ ] Input validation and sanitization
   - [ ] Secure Firebase rules configured

---

**⚠️ Disclaimer**: This is a personal project for educational purposes only.
