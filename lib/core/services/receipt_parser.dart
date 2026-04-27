import '../../features/receipt/models/receipt.dart';

/// Parses raw OCR text from a receipt image into structured fields.
/// Handles German + English receipt formats with common patterns.
///
/// This is pure Dart — no Flutter dependencies — so it's fully unit-testable.
class ReceiptParser {
  /// Main entry point. Takes raw OCR text and returns a best-effort Receipt.
  /// Fields that can't be detected get sensible defaults the user can edit.
  static Receipt parse(String ocrText) {
    final lines = ocrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _extractMerchant(lines);
    final date     = _extractDate(ocrText) ?? DateTime.now();
    final total    = _extractTotal(ocrText) ?? 0.0;
    final vatInfo  = _extractVat(ocrText, total);
    final category = _guessCategory(ocrText);

    return Receipt(
      merchant: merchant,
      date: date,
      totalAmount: total,
      vatAmount: vatInfo.vatAmount,
      vatRate: vatInfo.vatRate,
      categoryId: category,
      rawOcrText: ocrText,
    );
  }

  // ─── Merchant extraction ─────────────────────────────
  /// Usually the merchant name is on lines 1-3 of the receipt.
  /// We pick the first line that looks like a name (not numbers, not an address).
  static String _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Unknown';

    for (var i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i];
      // Skip if it's mostly digits (like a tax ID or phone number)
      final digits = line.replaceAll(RegExp(r'\D'), '').length;
      if (digits > line.length / 2) continue;
      // Skip if it looks like a street address
      if (RegExp(r'str(\.|aße)|straße|\d+\s*\w+', caseSensitive: false)
          .hasMatch(line) &&
          line.length < 30) {
        continue;
      }
      // Skip super short lines
      if (line.length < 3) continue;
      // Clean up
      return _titleCase(line.substring(0, line.length.clamp(0, 40)));
    }
    return _titleCase(lines.first);
  }

  // ─── Date extraction ─────────────────────────────────
  /// Tries common German + English date formats.
  static DateTime? _extractDate(String text) {
    // DD.MM.YYYY or DD.MM.YY  (German most common)
    final dePattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})');
    final deMatch = dePattern.firstMatch(text);
    if (deMatch != null) {
      final d = int.tryParse(deMatch.group(1)!);
      final m = int.tryParse(deMatch.group(2)!);
      var y = int.tryParse(deMatch.group(3)!);
      if (d != null && m != null && y != null) {
        if (y < 100) y += 2000;
        try {
          final dt = DateTime(y, m, d);
          if (dt.year >= 2020 && dt.year <= DateTime.now().year + 1) {
            return dt;
          }
        } catch (_) {}
      }
    }

    // YYYY-MM-DD
    final isoPattern = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
    final isoMatch = isoPattern.firstMatch(text);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      final d = int.tryParse(isoMatch.group(3)!);
      if (y != null && m != null && d != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }

    // DD/MM/YYYY or MM/DD/YYYY (ambiguous - assume DD/MM for EU)
    final slashPattern = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})');
    final slashMatch = slashPattern.firstMatch(text);
    if (slashMatch != null) {
      final d = int.tryParse(slashMatch.group(1)!);
      final m = int.tryParse(slashMatch.group(2)!);
      var y = int.tryParse(slashMatch.group(3)!);
      if (d != null && m != null && y != null) {
        if (y < 100) y += 2000;
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }
    return null;
  }

  // ─── Total extraction ────────────────────────────────
  /// Looks for the largest number prefixed by "Summe", "Total", "Gesamt", "EUR", "€".
  /// Falls back to the largest currency amount on the receipt.
  static double? _extractTotal(String text) {
    final lines = text.split('\n');

    // Strong signal keywords (in priority order — gesamt/total should win over summe
    // because receipts with tips/service charges put the actual total in "Gesamt")
    final keywords = [
      'gesamtbetrag', 'endbetrag', 'zu zahlen', 'gesamt', 'total',
      'amount due', 'summe', 'betrag',
    ];

    for (final keyword in keywords) {
      for (final line in lines) {
        if (line.toLowerCase().contains(keyword)) {
          final amount = _parseAmount(line);
          if (amount != null) return amount;
        }
      }
    }

    // Fallback: largest amount on receipt
    final amountPattern = RegExp(r'(\d+[,.]\d{2})(?!\d)');
    final matches = amountPattern.allMatches(text);
    double? max;
    for (final match in matches) {
      final parsed = _normalizeNumber(match.group(1)!);
      if (parsed != null) {
        if (max == null || parsed > max) max = parsed;
      }
    }
    return max;
    // ignore: avoid_print
  }

  // ─── VAT extraction ──────────────────────────────────
  /// Returns detected VAT amount + VAT rate.
  /// Defaults to 19% (German standard rate) and calculates if no explicit VAT found.
  static ({double vatAmount, double vatRate}) _extractVat(
      String text, double total) {
    // Try to find explicit VAT line: "MwSt 19%  5,12"
    final patterns = [
      RegExp(r'mwst\.?\s*(\d{1,2})\s*%?\s*[^0-9]{0,5}(\d+[,.]\d{2})',
          caseSensitive: false),
      RegExp(r'ust\.?\s*(\d{1,2})\s*%?\s*[^0-9]{0,5}(\d+[,.]\d{2})',
          caseSensitive: false),
      RegExp(r'vat\s*(\d{1,2})\s*%?\s*[^0-9]{0,5}(\d+[,.]\d{2})',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final rate = double.tryParse(match.group(1)!);
        final amount = _normalizeNumber(match.group(2)!);
        if (rate != null && amount != null && amount < total) {
          return (vatAmount: amount, vatRate: rate);
        }
      }
    }

    // Detect rate without amount (e.g. "inkl. 19% MwSt")
    double rate = 19.0;
    if (RegExp(r'7\s*%').hasMatch(text) && !RegExp(r'19\s*%').hasMatch(text)) {
      rate = 7.0;
    } else if (RegExp(r'19\s*%').hasMatch(text)) {
      rate = 19.0;
    }

    // Calculate VAT backwards from total: vat = total × rate / (100 + rate)
    final calculated = total * rate / (100.0 + rate);
    return (vatAmount: double.parse(calculated.toStringAsFixed(2)),
        vatRate: rate);
  }

  // ─── Category guessing ───────────────────────────────
  /// Heuristic category detection based on merchant keywords.
  /// This is fast, free, and works offline. Users can override it.
  static String _guessCategory(String text) {
    final lower = text.toLowerCase();

    // Fuel stations
    if (_containsAny(lower, ['shell', 'aral', 'esso', 'total', 'jet',
        'tankstelle', 'bp ', 'hem ', 'agip', 'orlen', 'avia'])) {
      return 'fuel';
    }
    // Restaurants / food
    if (_containsAny(lower, ['restaurant', 'café', 'cafe', 'bistro',
        'pizzeria', 'gaststätte', 'bar ', 'bäckerei', 'metzgerei',
        'imbiss', 'trinkgeld', 'mcdonald', 'burger', 'kfc',
        'mwst 7'])) {
      return 'meals_business';
    }
    // Travel
    if (_containsAny(lower, ['hotel', 'pension', 'db ag', 'deutsche bahn',
        'flixbus', 'lufthansa', 'ryanair', 'airbnb', 'booking.com',
        'bahnhof', 'ticket', 'flughafen'])) {
      return 'travel';
    }
    // Software / subscriptions
    if (_containsAny(lower, ['adobe', 'microsoft', 'office 365', 'google',
        'apple', 'dropbox', 'github', 'notion', 'slack', 'zoom',
        'subscription', 'abonnement'])) {
      return 'software';
    }
    // Office supplies
    if (_containsAny(lower, ['staples', 'mcpaper', 'müller', 'dm ',
        'rossmann', 'papier', 'druckerpatrone', 'bürobedarf'])) {
      return 'office_supplies';
    }
    // Hardware
    if (_containsAny(lower, ['media markt', 'saturn', 'mediamarkt',
        'cyberport', 'notebooksbilliger', 'conrad', 'reichelt', 'alternate'])) {
      return 'hardware';
    }
    // Phone / Internet
    if (_containsAny(lower, ['telekom', 'vodafone', 'o2 ', 'o2germany',
        '1&1', 'congstar', 'aldi talk'])) {
      return 'phone_internet';
    }
    return 'other';
  }

  // ─── Helpers ─────────────────────────────────────────
  static bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    return false;
  }

  static String _titleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      if (w.length <= 2) return w.toUpperCase(); // AG, e.V., etc.
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ').trim();
  }

  /// Finds the first currency amount in a line (e.g. "Summe: 15,99 €" → 15.99)
  static double? _parseAmount(String line) {
    final pattern = RegExp(r'(\d+[,.]\d{2})');
    final matches = pattern.allMatches(line);
    double? max;
    for (final m in matches) {
      final value = _normalizeNumber(m.group(1)!);
      if (value != null && (max == null || value > max)) max = value;
    }
    return max;
  }

  /// Converts "12,34" or "12.34" to 12.34
  static double? _normalizeNumber(String s) {
    // If it has both . and , — last one is decimal (common locale quirk)
    if (s.contains(',') && s.contains('.')) {
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }
}
