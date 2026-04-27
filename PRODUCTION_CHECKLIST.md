# 🚀 Receipt Radar — Production-Readiness, Security & Launch Guide

> **Realistic goal:** Reduce attack surface, protect user data (GDPR matters in Germany), and ship a launch-ready app to Netlify + Google Play. No app is "unhackable" — what we can do is follow defense-in-depth best practices.

---

## 📑 Table of Contents

1. [Repository hygiene & secret leak audit](#1-repository-hygiene--secret-leak-audit)
2. [App security hardening](#2-app-security-hardening)
3. [Production build configuration](#3-production-build-configuration)
4. [Legal & compliance (Germany / EU / GDPR)](#4-legal--compliance-germany--eu--gdpr)
5. [Quality gates before launch](#5-quality-gates-before-launch)
6. [Web deployment — Netlify](#6-web-deployment--netlify)
7. [Android deployment — Google Play Store](#7-android-deployment--google-play-store)
8. [Post-launch monitoring](#8-post-launch-monitoring)

---

## 1. Repository hygiene & secret leak audit

### 1.1 Replace `.gitignore` with a proper Flutter `.gitignore`

Your current `.gitignore` is missing critical entries. Replace it with this (based on the official Flutter template):

```gitignore
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.build/
.buildlog/
.history
.svn/
.swiftpm/
migrate_working_dir/

# IntelliJ / Android Studio
*.iml
*.ipr
*.iws
.idea/

# VS Code
.vscode/

# Flutter / Dart / Pub-related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/

# Symbolication-related
app.*.symbols

# Obfuscation-related
app.*.map.json

# Android-related
**/android/**/gradle-wrapper.jar
.gradle/
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks
*.keystore

# iOS/XCode-related
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/*sync/
**/ios/**/.sconsign.dblite
**/ios/**/.tags*
**/ios/**/.vagrant/
**/ios/**/DerivedData/
**/ios/**/Icon?
**/ios/**/Pods/
**/ios/**/.symbols/
**/ios/**/profile
**/ios/**/xcuserdata
**/ios/.generated/
**/ios/Flutter/.last_build_id
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/Flutter/flutter_export_environment.sh
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*

# Web-related
lib/generated_plugin_registrant.dart

# Environment / secrets
.env
.env.local
.env.*.local
*.pem
secrets.json
```

### 1.2 Audit existing git history for accidentally committed secrets

Before going private, run this **on your local machine** to scan all history:

```bash
# Quick check — anything that looks like a key or token in any commit?
git log -p --all | grep -iE "(api[_-]?key|secret|password|token|keystore|BEGIN PRIVATE|BEGIN RSA)"

# Better: use a real scanner
# Install gitleaks: https://github.com/gitleaks/gitleaks
gitleaks detect --source . --verbose
```

If anything sensitive is found in history, **rotating the secret is mandatory**. Just deleting the file in a new commit doesn't help — old commits still contain it.

### 1.3 Going private is good, but not magical

When you flip the repo to private:
- New visitors can no longer see code — good ✅
- Existing forks remain visible if anyone forked it — check at `https://github.com/avinash007211/ReceiptRadar_v1/network/members`
- Public mirrors (archive.org, etc.) are out of your control
- **Therefore:** assume anything ever pushed publicly is permanently public. Rotate any credential that was ever in the repo.

---

## 2. App security hardening

### 2.1 Encrypt local receipt storage

Your app currently uses `SharedPreferences` for receipt data. That's plaintext on disk — anyone with root access (or a forensic image of a stolen phone) can read everything.

**Option A — minimal change (recommended):** swap to `flutter_secure_storage`. It uses Android Keystore + iOS Keychain.

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^9.2.2
```

Replace your storage layer:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReceiptStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveReceipts(List<Map<String, dynamic>> receipts) async {
    await _storage.write(key: 'receipts', value: jsonEncode(receipts));
  }

  static Future<List<Map<String, dynamic>>> loadReceipts() async {
    final raw = await _storage.read(key: 'receipts');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }
}
```

> ⚠️ **Web limitation:** `flutter_secure_storage` on web uses `localStorage` with a generated key — not actually secure on web. For web, treat the receipt list as cleartext; users should be warned.

### 2.2 Block screenshots & recents thumbnails (Android)

Add `FLAG_SECURE` so receipts don't leak to the recents screen, screen recordings, or screenshots.

Add to `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
    }
}
```

### 2.3 Audit Android permissions

Open `android/app/src/main/AndroidManifest.xml`. You should only see permissions you actually use:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

Remove anything else (no INTERNET if you don't make API calls, no STORAGE permissions unless you need them — modern Android uses scoped storage).

### 2.4 Add Network Security Config (defense in depth)

Even if you don't make API calls today, lock the door. Create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

Reference it in `AndroidManifest.xml` inside `<application>`:

```xml
android:networkSecurityConfig="@xml/network_security_config"
android:usesCleartextTraffic="false"
```

### 2.5 Web — add security headers

Create `web/_headers` (Netlify reads this automatically):

```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: blob:; connect-src 'self'; frame-ancestors 'none';
```

> Note: Flutter Web's default config may need `'unsafe-inline'` for styles and `'wasm-unsafe-eval'` for scripts. Test in Chrome DevTools → Console for CSP violations and tighten gradually.

### 2.6 Dependency vulnerability check

Run regularly:

```bash
flutter pub outdated
flutter pub upgrade --major-versions  # only after testing
dart pub deps                          # see your full tree
```

For deeper scanning, set up GitHub's free **Dependabot** (Settings → Code security → enable Dependabot alerts). It'll auto-PR security fixes for your dependencies.

### 2.7 Threat model in plain English

Realistic threats for your app, and what mitigates each:

| Threat | Mitigation |
|---|---|
| Lost/stolen phone, attacker reads receipts | `flutter_secure_storage` (§2.1) + device PIN/biometric |
| User screenshots a receipt by accident in a public app store demo | `FLAG_SECURE` (§2.2) |
| Malicious app on same device tries to read your data | Android sandbox (built-in) + secure storage |
| Reverse engineering to bypass the paywall | Code obfuscation (§3.2). Honest take: any client-side paywall is bypassable. Treat it as a speed bump, not a vault. Real subscription enforcement requires server-side validation (Play Billing receipts). |
| Man-in-the-middle on a future API | TLS pinning + network security config (§2.4) |
| Supply chain attack via a Flutter package | Dependabot (§2.6), pinned versions in `pubspec.lock` |

---

## 3. Production build configuration

### 3.1 Bump Android target SDK to 35

Google Play requires **API 35 (Android 15) or higher** for new apps and updates as of August 31, 2025. In `android/app/build.gradle` (or `build.gradle.kts`):

```gradle
android {
    compileSdkVersion 35
    defaultConfig {
        minSdkVersion 21      // covers ~99% of devices
        targetSdkVersion 35
    }
}
```

### 3.2 Configure release signing

Generate your release keystore **on your local machine — never commit it**:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (already in your `.gitignore` per §1.1):

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Wire it into `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

> 🔐 **Back up the keystore** (encrypted external drive + password manager). If you lose it, you can never publish updates to the same Play Store listing again. This is the most expensive mistake you can make.

### 3.3 Build with obfuscation

```bash
# Android App Bundle (what Play Store wants)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info

# Web
flutter build web --release \
  --wasm  # optional: WebAssembly renderer, faster
```

Keep `build/debug-info/` (the symbols) safe. You need it to decode crash stack traces.

### 3.4 Add ProGuard rules for ML Kit

Create `android/app/proguard-rules.pro`:

```
# ML Kit text recognition
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
```

---

## 4. Legal & compliance (Germany / EU / GDPR)

You're selling to German freelancers — DSGVO/GDPR is non-negotiable.

### 4.1 Required documents (host on a public URL — Netlify works)

- **Datenschutzerklärung (Privacy Policy)** — Required for Play Store listing. Must declare: what data is collected, where it's stored, that it's local-only, retention, user rights (Auskunft, Löschung).
- **AGB (Terms of Service)** — Required because you have a paywall.
- **Impressum** — Mandatory in Germany under §5 TMG for any commercial offering. Include your legal name and address.

Generators: [e-recht24.de](https://www.e-recht24.de) is the standard for German legal templates.

### 4.2 Data Safety form (Play Console)

When you submit, Play Store asks you to declare data practices. With your current architecture:
- Data collected: **None transmitted** (everything local)
- Data shared: **None**
- Data encrypted in transit: **N/A**
- User can request deletion: **Yes (uninstall app)**

This is a strong selling point — say so on your store listing.

### 4.3 Play Billing (when you implement the paywall properly)

Your current paywall UI is just UI — there's no actual purchase enforcement. Before launch, integrate `in_app_purchase` (Google Play Billing). Validate purchases server-side if possible, but for a solo app a local check with server-side receipt validation via a simple Cloud Function is enough.

---

## 5. Quality gates before launch

- [ ] `flutter analyze` — zero errors, zero warnings
- [ ] `flutter test` — at least smoke tests for core flows (currently 0 tests; add a few)
- [ ] Manual test on a real Android device (not just emulator) — back button, rotation, low memory
- [ ] Manual test on Chrome, Safari, Firefox
- [ ] Test with German receipts from at least 5 different merchants
- [ ] Test CSV export → open in LibreOffice Calc → confirm DATEV format imports correctly
- [ ] Accessibility: try with TalkBack on Android, verify text scaling at 200%
- [ ] Internationalization sanity check — German is your target market, but the UI strings should be ready for i18n via `flutter_localizations` even if you only ship one locale

---

## 6. Web deployment — Netlify

### 6.1 Build the web bundle

```bash
flutter build web --release
```

Output goes to `build/web/`.

### 6.2 First-time Netlify setup (free tier is plenty)

**Option A — Drag & drop (fastest, one-off):**

1. Go to [app.netlify.com](https://app.netlify.com), sign up.
2. Click "Add new site" → "Deploy manually".
3. Drag the entire `build/web/` folder onto the page.
4. You get a URL like `https://something-random.netlify.app`. Done.

**Option B — Git-connected continuous deploy (recommended):**

1. Create `netlify.toml` in the repo root:

```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.24.0"  # match your local version

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

2. In Netlify: "Add new site" → "Import from Git" → connect your GitHub → pick the repo.
3. Netlify auto-installs Flutter and builds on every push to `main`.

> ⚠️ Netlify's default build image doesn't have Flutter. You'll need a custom build script. Easier path: run `flutter build web` locally, commit `build/web/` to a separate `gh-pages` branch, OR use **GitHub Actions + Netlify CLI** to build and deploy. For first launch, use Option A.

### 6.3 Custom domain (optional, ~€10/year)

1. Buy a domain (Namecheap, INWX, Strato).
2. In Netlify → Site settings → Domain management → Add custom domain.
3. Point your DNS A/CNAME records as Netlify instructs.
4. Free Let's Encrypt SSL is auto-provisioned.

### 6.4 Verify your security headers worked

After deploy, run:
```bash
curl -I https://yoursite.netlify.app
```

You should see `Strict-Transport-Security`, `X-Frame-Options: DENY`, etc. Or use [securityheaders.com](https://securityheaders.com) — aim for grade A.

---

## 7. Android deployment — Google Play Store

### 7.1 One-time setup (~30 min, €25)

1. Create a Google Play Developer account: [play.google.com/console](https://play.google.com/console). One-time fee €25 (~$25).
2. Verify identity (passport/ID upload). For Germany, takes a few days.
3. Set up a payment profile if you'll charge for the app.

### 7.2 Prepare store listing assets

| Asset | Size | Notes |
|---|---|---|
| App icon | 512×512 PNG | You already have this |
| Feature graphic | 1024×500 JPG/PNG | Banner for the listing |
| Screenshots | 2–8 per device type | Phone min 320px, max 3840px |
| Short description | 80 chars | Punchy hook |
| Full description | 4000 chars | Use German for the German market |
| Privacy policy URL | — | Hosted on your Netlify site |

### 7.3 Build the AAB (Android App Bundle)

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 7.4 Submission flow

1. Play Console → "Create app" → fill in name, language (German + English), free/paid.
2. Set up app:
   - **App access** — declare if any features need login (yours: no)
   - **Ads** — none
   - **Content rating** — fill questionnaire (yours = "Everyone")
   - **Target audience** — Adults
   - **Data safety** — see §4.2
   - **Privacy policy URL** — your Netlify URL
3. **Internal testing track first** (recommended):
   - Releases → Internal testing → Create new release
   - Upload your `.aab`
   - Add yourself + 2-3 trusted testers by email
   - Get the opt-in link, install, test on a real device
4. Once happy → promote to **Closed testing** (10–20 friends/colleagues, German freelancers ideally) for 14 days
5. Then → **Production** release. First review takes 1–7 days.

### 7.5 Post-launch must-haves

- Set up **Play Console crash reporting** (built-in, free)
- Watch the first 50 installs closely — most ANRs and crashes show up early
- Respond to every review in the first month, especially negatives — Play's algorithm rewards engaged developers

---

## 8. Post-launch monitoring

- **Crash reporting:** Play Console (Android) is enough to start. Add Sentry later if you want unified Android+Web crash tracking. Sentry has a free tier (5k events/month).
- **Analytics:** Optional. If you add it, prefer **Plausible** or **Umami** (cookieless, GDPR-friendly, no consent banner needed) over Google Analytics.
- **Uptime for the web app:** [uptimerobot.com](https://uptimerobot.com) — free, alerts you if Netlify goes down.
- **Dependency updates:** Dependabot weekly. Review and merge promptly.
- **Yearly:** Bump target SDK before the August deadline each year, or your app stops being installable on new phones.

---

## 📌 Quick action list — this week

```text
□ Replace .gitignore (§1.1)
□ Run gitleaks on history (§1.2)
□ Migrate to flutter_secure_storage (§2.1)
□ Add FLAG_SECURE (§2.2)
□ Add web/_headers file (§2.5)
□ Generate keystore + back it up to two places (§3.2)
□ Set up Dependabot in GitHub Settings
□ Write Datenschutzerklärung + Impressum + AGB
□ Make repo private (after § 1.2 audit passes)
□ Build web → drag-drop to Netlify → share the link
□ Build AAB → start Play Console internal testing
```

---

*This checklist is a starting point, not a guarantee. For an app handling tax data in the EU, consider a one-time review by a German-licensed lawyer for the AGB/Datenschutz, especially before you take the first paid customer.*
