// Entry point for the Scanner screen. Routes to platform-specific impl.
// Mobile → real camera + ML Kit OCR
// Web    → manual entry form (ML Kit not available on web)
//
// All router code imports from this file. It never sees the platform detail.

export 'scanner_screen_stub.dart'
    if (dart.library.io) 'scanner_screen_mobile.dart'
    if (dart.library.js_interop) 'scanner_screen_web.dart';
