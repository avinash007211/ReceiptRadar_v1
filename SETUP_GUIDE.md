# Receipt Radar — Setup Guide

## TL;DR

You already have Flutter installed from the DeskFit project. So:

```powershell
cd receipt_radar
flutter pub get
flutter run
```

The app should launch on your emulator. That's it.

---

## Prerequisites (already done from DeskFit)

- ✅ Flutter SDK at `C:\flutter`
- ✅ Android Studio with SDK + emulator
- ✅ Java 21
- ✅ VS Code with Flutter extension

## Fresh install (if new computer)

1. Flutter SDK → https://docs.flutter.dev/get-started/install/windows
2. Android Studio → https://developer.android.com/studio
3. VS Code + Flutter extension
4. Run `flutter doctor --android-licenses` and accept all

---

## What's in this project

```
receipt_radar/
├── lib/
│   ├── main.dart                   ← Entry point
│   ├── core/
│   │   ├── theme/                  ← Colors, typography, theme
│   │   ├── router/                 ← GoRouter navigation
│   │   ├── constants/              ← German tax categories, DATEV accounts
│   │   └── services/
│   │       ├── receipt_parser.dart ← OCR text → structured fields
│   │       ├── receipt_store.dart  ← SharedPreferences storage
│   │       └── csv_exporter.dart   ← DATEV CSV export
│   ├── features/
│   │   ├── onboarding/             ← Splash screen
│   │   ├── home/                   ← Dashboard with stats
│   │   ├── scanner/                ← Camera + ML Kit OCR
│   │   ├── receipt/                ← Review, list, detail screens
│   │   ├── export/                 ← CSV export with date range
│   │   ├── paywall/                ← Subscription screen
│   │   └── settings/               ← Settings & data management
│   └── shared/                     ← Shared widgets
├── android/                        ← Android build config
├── assets/                         ← Images & animations
└── pubspec.yaml                    ← Dependencies
```

---

## Core features working in MVP

**Scan receipts**

- Camera preview with corner guides
- ML Kit on-device OCR (works offline, free, no API key)
- Gallery fallback if camera fails
- Auto-extracts: merchant, date, total, VAT amount, VAT rate

**Smart categorization**

- 10 German tax categories with DATEV SKR03 account numbers
- Heuristic auto-categorization based on merchant keywords
  - Shell/Aral → Fuel (account 4530)
  - Restaurant → Bewirtungskosten (account 4650)
  - Hotel/DB → Reisekosten (account 4660)
  - MediaMarkt → Hardware (account 0490)
  - ...etc

**Review & edit**

- Edit any parsed field before saving
- Date picker, VAT rate selector (0%/7%/19%)
- Category picker with horizontal scroll
- Notes field for Bewirtungsanlass, client name, etc.

**Export**

- Simple CSV (Excel/Numbers/Sheets compatible)
- DATEV CSV (direct import into German accounting software)
- Date range picker
- Share via native share sheet (email, Drive, WhatsApp)

**Data management**

- All data stored locally on device (GDPR friendly)
- No Firebase, no servers, no account needed
- Clear all data from settings

---

## Key technical decisions

| Decision                     | Reason                                        |
| ---------------------------- | --------------------------------------------- |
| No Firebase                  | Avoids the `google-services.json` setup pain  |
| SharedPreferences (not Hive) | Simpler, battle-tested, no init issues        |
| ML Kit (not cloud OCR)       | Free, fast, works offline, no API keys        |
| Flutter 3.4+ & Riverpod 3.x  | Latest stable; no deprecated APIs             |
| AGP 8.9.1 + Gradle 8.11.1    | Known-working combo with Java 21              |
| minSdk 24                    | ML Kit requires this; 90%+ of Android devices |

---

## If something fails

### Build error?

```powershell
flutter clean
flutter pub get
flutter run
```

### Camera crash on emulator?

Android emulators have quirky cameras. Test on a **real device** via USB:

1. Enable Developer Options on your phone (tap Build Number 7 times)
2. Enable USB Debugging
3. Plug in via USB
4. `flutter run` should detect your phone

Or use "Pick from Gallery" in the scanner to test OCR with any existing photo.

### ML Kit model download issue?

First OCR runs downloads the ~15MB language model. Needs internet on first run only. After that it works offline.

---

## What to build next

Quick wins for v1.1:

1. **iOS Podfile** (I can generate it — just ask)
2. **RevenueCat subscriptions** (the paywall UI is ready, just needs wiring)
3. **GPT-4o enhancement** — cloud fallback when on-device OCR fails on weird receipts
4. **Multi-page receipts** — bookings, rental agreements
5. **Auto-sync to Google Drive / iCloud** — 10-year legal archive

Ask me any of these and I'll generate the code.

---

## App Store submission

When you're ready to publish:

1. **Google Play** — build `.aab`, upload to Play Console, 3-7 day review
2. **Apple App Store** — needs Mac or Codemagic cloud builder ($29/mo)
3. **Pricing suggestion** — Free (10/mo) → €4.99/mo → €39/yr → €99 lifetime

Expected revenue based on research:

- Month 3: ~€250 MRR (50 paying users)
- Month 6: ~€1,500 MRR (300 paying users)
- Year 1: ~€6,500 MRR (1,200 users + 5 Steuerberater B2B deals)
- Year 2: ~€20,000 MRR with solid German TikTok/LinkedIn presence
