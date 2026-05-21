# Flutter Scanner (Fintech OCR)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg?logo=dart)](https://dart.dev)
[![Architecture: Clean](https://img.shields.io/badge/Architecture-Clean-green.svg)](https://pub.dev/packages/flutter_bloc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-grade OCR application designed for the Fintech sector. This project demonstrates advanced on-device text recognition for credit/debit cards and bank passbooks, utilizing a heuristic-based parsing engine for high accuracy in real-world conditions.

---

## 🚀 Key Features

### 💳 Smart Card Scanner
- **Heuristic Scoring Engine**: Contextual detection of expiry dates (proximity to 'Valid Thru', 'Exp', etc.).
- **Luhn Validation**: Manual implementation of the Luhn algorithm for card checksum verification.
- **Normalization**: Automatic correction of common OCR misreads (e.g., `O` to `0`, `I` to `1`).
- **Real-time Feedback**: Interactive UI for immediate field correction and validation.

### 🏦 Passbook Scanner
- **IFSC Extraction**: Specialized logic for Indian Financial System Codes with auto-standardization of the 5th character.
- **Account Number Scoring**: Keywords-based confidence scoring to differentiate account numbers from transaction amounts.

### 🛡️ Secure & Private
- **100% On-Device**: Zero data leaves the device. Uses Google ML Kit for local processing.
- **Privacy First**: Designed for fintech compliance with clear "Trust Indicators" in the UI.

---

## 🛠 Tech Stack & Architecture

- **State Management**: [Cubit (Flutter Bloc)](https://pub.dev/packages/flutter_bloc) for predictable, testable business logic.
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it) for service decoupling.
- **OCR Engine**: [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition).
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing.
- **Architecture**: Feature-first Clean Architecture.

### Directory Structure
```text
lib/
 ├── core/          # Shared utilities (Regex, Luhn, Text Normalization)
 ├── features/      # Domain-specific logic (Card, Passbook)
 ├── shared/        # Reusable UI components
 └── app/           # DI, Theme, and Routing configuration
```

---

## 🛠 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/codebyforam/flutter-scanner.git
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run Tests**
   ```bash
   flutter test
   ```

4. **Run Application**
   ```bash
   flutter run
   ```



## 👤 Author
**codeByForam**
- GitHub: [@codeByForam](https://github.com/codeByForam)

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
