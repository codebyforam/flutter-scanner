# Flutter Scanner (Fintech OCR)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg?logo=dart)](https://dart.dev)
[![Architecture: Clean](https://img.shields.io/badge/Architecture-Clean-green.svg)](https://pub.dev/packages/flutter_bloc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-grade OCR application designed for the Fintech sector. This project demonstrates advanced on-device text recognition for credit/debit cards and bank passbooks, utilizing a heuristic-based parsing engine for high accuracy in real-world conditions.

---

## 🚀 Features & Assignment Requirements

### 1. Card Scanner
- **Details Extracted**: Card Number, Expiry Date, Card Holder Name.
- **Privacy**: Automated **masking** of the card number (e.g., `XXXX XXXX XXXX 1234`) with a toggle to view.
- **Algorithm**: `CardParser` manually processes noisy OCR text using a scoring system.
- **Luhn Validation**: Manual implementation of the **Luhn Algorithm** (`LuhnValidator`) to verify card authenticity.

### 2. Passbook Scanner
- **Details Extracted**: Account Holder Name, Account Number, IFSC Code.
- **Algorithm**: `PassbookParser` uses keyword proximity and heuristic scoring to identify account details amidst transaction history and noisy text.
- **Normalization**: Standardizes Indian IFSC codes (ensuring the 5th character is always `0`).

---

## 🛠 Manual Parsing Algorithms

As per assignment constraints, **no external libraries** were used for parsing the extracted OCR text.

### Card Parsing Logic
1. **Candidate Identification**: Scans text for 13-19 digit sequences.
2. **Prioritization**: Ranks candidates based on Luhn validity and standard card lengths.
3. **Expiry Detection**: Searches for `MM/YY` or `MM/YYYY` patterns. Scores them higher if near keywords like "Valid Thru" or "Expiry" and lower if near "DOB".
4. **Name Extraction**: Identifies 2-3 word uppercase strings excluding card brand names and banking keywords.

### Passbook Parsing Logic
1. **IFSC Detection**: Regex-based pattern matching for standard 11-digit IFSC codes.
2. **Account Number Extraction**: Identifies numeric sequences of 9-18 digits. Uses a scoring system where proximity to "A/C" or "Account" increases confidence, while proximity to "Balance" or "Amount" decreases it.
3. **Name Extraction**: Looks for name-related keywords and extracts the following alphabetic string.

---

## 📝 Assumptions & Constraints

- **Language**: Optimized for English-language documents.
- **IFSC Format**: Assumes the standard 11-character Indian IFSC format.
- **Card Holder Name**: Extracted if printed in standard uppercase format on the card front.
- **Image Quality**: Assumes reasonable lighting and focus for on-device OCR accuracy.

### What was skipped / Trade-offs
- **Bank Logo Recognition**: While branding helps scoring, a full logo-to-bank mapping was skipped to focus on text-based parsing.
- **Non-Standard Expiry**: Very rare formats (e.g., text-based "Dec 2025") were deprioritized over numeric formats.
- **Offline ML Models**: Used Google ML Kit which is on-device but requires initial library download; fully air-gapped custom Tesseract models were skipped for better performance/size ratio.

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
