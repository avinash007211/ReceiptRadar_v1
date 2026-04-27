// Cross-platform receipt image display.
// Mobile → Image.file(File(path))
// Web    → empty (web has no file system; image is null on web anyway)

export 'receipt_image_stub.dart'
    if (dart.library.io) 'receipt_image_mobile.dart'
    if (dart.library.js_interop) 'receipt_image_web.dart';
