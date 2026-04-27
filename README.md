# 🧾 Receipt Radar

**Smart receipt scanning & DATEV export for German freelancers.**

Receipt Radar helps Freelancer and Kleinunternehmer in Germany digitize receipts, auto-categorize expenses for German tax, and export DATEV-compatible CSV files — ready to hand to your Steuerberater.

Same codebase runs on **Android** (camera scan with OCR) and **Web** (manual entry).

---

## Features

- **Camera Scan (Android)** — Point, shoot, and Receipt Radar extracts merchant name, total, date, and tax amounts using ML Kit OCR. Tested with REWE, Shell, restaurants, hotels, MediaMarkt, and more.
- **Manual Entry (Web)** — Clean form-based input when camera isn't available. Button label adapts automatically ("Add Receipt" on web, "Scan Receipt" on mobile).
- **German Tax Auto-Categorization** — Receipts are mapped to 10 tax-relevant categories with DATEV SKR03 account numbers (e.g., Büromaterial, Bewirtung, Reisekosten).
- **Edit & Review** — Tap any receipt to correct OCR results or change the category before export.
- **Receipt List with Filtering** — Browse all receipts, filter by category.
- **CSV Export** — Select a date range and export in two formats:
  - **Simple CSV** — Human-readable spreadsheet
  - **DATEV CSV** — Import-ready for your Steuerberater's DATEV software
- **100% Local & GDPR-Friendly** — All data stays on your device. No Firebase, no cloud sync, no account required.
- **Paywall UI** — Free tier (10 receipts/month), €4.99/mo, €39/yr, €99 lifetime.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.4+ (Dart) |
| State Management | Riverpod 3.x (`flutter_riverpod`) |
| Navigation | GoRouter |
| OCR | Google ML Kit Text Recognition |
| Camera | `camera` + `image_picker` |
| Local Storage | SharedPreferences |
| Export | `csv` + `share_plus` |
| Styling | Google Fonts, Flutter Animate |

**No backend. No Firebase. No servers.**

---

## Project Structure

```
lib/
├── main.dart                  # App entry point & router
├── models/
│   └── receipt.dart           # Receipt data model
├── providers/
│   └── receipt_provider.dart  # Riverpod state management
├── screens/
│   ├── home_screen.dart       # Receipt list + filters
│   ├── scanner_screen.dart    # Platform-conditional import hub
│   ├── scanner_screen_mobile.dart  # Camera + OCR (Android)
│   ├── scanner_screen_web.dart     # Manual entry form (Web)
│   ├── scanner_screen_stub.dart    # Fallback stub
│   ├── review_screen.dart     # Edit scanned receipt
│   ├── receipt_detail_screen.dart
│   └── export_screen.dart     # Date-range CSV export
├── widgets/
│   ├── receipt_image.dart     # Platform-conditional image display
│   └── ...
└── utils/
    ├── categories.dart        # German tax categories + SKR03 codes
    ├── platform_scanner.dart  # Platform detection helpers
    └── ...
```

### Cross-Platform Pattern

ML Kit doesn't support web, so the app uses Dart conditional imports to route to the correct implementation at compile time:

```dart
export 'scanner_screen_stub.dart'
    if (dart.library.io) 'scanner_screen_mobile.dart'
    if (dart.library.js_interop) 'scanner_screen_web.dart';
```

This same pattern is applied to `platform_scanner.dart` and `receipt_image.dart`.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.4.0
- Android Studio (for Android builds) or Chrome (for web)
- An Android device/emulator with a camera (for OCR features)

### Setup

```bash
# Clone the repo
git clone https://github.com/avinash007211/ReceiptRadar_v1.git
cd ReceiptRadar_v1

# Install dependencies
flutter pub get

# Run on Android emulator
flutter run

# Run on Chrome
flutter run -d chrome
```

> See [`SETUP_GUIDE.md`](SETUP_GUIDE.md) for detailed setup instructions.

---

## Export Formats

### Simple CSV
```
Date,Merchant,Amount,Tax,Category,Notes
2025-03-15,REWE,47.82,7.64,Lebensmittel,Weekly groceries
```

### DATEV CSV
Generates a file formatted for direct import into DATEV accounting software, including SKR03 account numbers, tax keys, and proper German date formatting — exactly what your Steuerberater expects.

---

## Roadmap

- [x] Android MVP with camera scan + OCR
- [x] Web support with manual entry
- [x] DATEV CSV export
- [x] Custom app icon & PWA support
- [ ] Deploy web version to Netlify
- [ ] Publish to Google Play Store
- [ ] iOS build via Codemagic (cloud Mac)
- [ ] Multi-receipt batch scanning
- [ ] Steuerberater B2B portal

---

## License

This project is proprietary. All rights reserved.

---

## Author

**Avinash Kumar Jha**

Built in Germany, for German freelancers. 🇩🇪
