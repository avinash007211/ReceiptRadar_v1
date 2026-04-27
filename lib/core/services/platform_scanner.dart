// Platform capability check — tells UI whether camera/OCR scanning works.
// Mobile → true (real camera + ML Kit)
// Web    → false (show manual-entry form instead)

export 'platform_scanner_stub.dart'
    if (dart.library.io) 'platform_scanner_mobile.dart'
    if (dart.library.js_interop) 'platform_scanner_web.dart';
