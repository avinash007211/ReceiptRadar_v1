import 'package:uuid/uuid.dart';

/// Represents a single receipt scanned and parsed by the app.
/// Stored locally as JSON in SharedPreferences for the MVP.
class Receipt {
  final String id;
  final String merchant;
  final DateTime date;
  final double totalAmount;
  final double vatAmount;
  final double vatRate; // 0, 7, or 19
  final String currency;
  final String categoryId;
  final String? notes;
  final String? imagePath; // local path to receipt image
  final String? rawOcrText; // full OCR output (for reference)
  final DateTime createdAt;

  Receipt({
    String? id,
    required this.merchant,
    required this.date,
    required this.totalAmount,
    this.vatAmount = 0.0,
    this.vatRate = 19.0,
    this.currency = 'EUR',
    this.categoryId = 'other',
    this.notes,
    this.imagePath,
    this.rawOcrText,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get netAmount => totalAmount - vatAmount;

  Receipt copyWith({
    String? merchant,
    DateTime? date,
    double? totalAmount,
    double? vatAmount,
    double? vatRate,
    String? currency,
    String? categoryId,
    String? notes,
    String? imagePath,
    String? rawOcrText,
  }) {
    return Receipt(
      id: id,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      vatAmount: vatAmount ?? this.vatAmount,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'date': date.toIso8601String(),
        'totalAmount': totalAmount,
        'vatAmount': vatAmount,
        'vatRate': vatRate,
        'currency': currency,
        'categoryId': categoryId,
        'notes': notes,
        'imagePath': imagePath,
        'rawOcrText': rawOcrText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        merchant: json['merchant'] as String,
        date: DateTime.parse(json['date'] as String),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 19.0,
        currency: json['currency'] as String? ?? 'EUR',
        categoryId: json['categoryId'] as String? ?? 'other',
        notes: json['notes'] as String?,
        imagePath: json['imagePath'] as String?,
        rawOcrText: json['rawOcrText'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
