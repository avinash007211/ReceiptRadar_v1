import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../../features/receipt/models/receipt.dart';

/// Generates DATEV-compatible CSVs that German tax advisors can import directly.
/// DATEV is the standard accounting software in Germany — this is the killer feature.
class CsvExporter {
  /// Simple CSV export — human readable, great for review
  static String toSimpleCsv(List<Receipt> receipts) {
    final rows = <List<dynamic>>[
      // Header
      [
        'Date',
        'Merchant',
        'Category',
        'DATEV Account',
        'Net Amount',
        'VAT Rate (%)',
        'VAT Amount',
        'Total',
        'Currency',
        'Notes',
      ],
    ];

    final dateFmt = DateFormat('yyyy-MM-dd');
    for (final r in receipts) {
      final cat = AppConstants.categoryById(r.categoryId);
      rows.add([
        dateFmt.format(r.date),
        r.merchant,
        cat.nameDe,
        cat.datevAccount,
        r.netAmount.toStringAsFixed(2),
        r.vatRate.toStringAsFixed(1),
        r.vatAmount.toStringAsFixed(2),
        r.totalAmount.toStringAsFixed(2),
        r.currency,
        r.notes ?? '',
      ]);
    }

    return const ListToCsvConverter(
      fieldDelimiter: ';', // German Excel default
      textDelimiter: '"',
    ).convert(rows);
  }

  /// DATEV-format CSV — the industry standard in Germany
  /// Format: "Umsatz;Soll/Haben;Währung;Konto;Gegenkonto;Belegdatum;Belegfeld 1;Buchungstext"
  static String toDatevCsv(List<Receipt> receipts) {
    final rows = <List<dynamic>>[
      [
        'Umsatz (ohne Soll/Haben-Kz)',
        'Soll/Haben-Kennzeichen',
        'WKZ Umsatz',
        'Kurs',
        'Basis-Umsatz',
        'WKZ Basis-Umsatz',
        'Konto',
        'Gegenkonto (ohne BU-Schlüssel)',
        'BU-Schlüssel',
        'Belegdatum',
        'Belegfeld 1',
        'Belegfeld 2',
        'Skonto',
        'Buchungstext',
      ],
    ];

    final dateFmt = DateFormat('ddMM'); // DATEV uses DDMM format for dates

    for (var i = 0; i < receipts.length; i++) {
      final r = receipts[i];
      final cat = AppConstants.categoryById(r.categoryId);
      rows.add([
        r.totalAmount.toStringAsFixed(2).replaceAll('.', ','),
        'S', // Soll (debit)
        r.currency,
        '', '', '',
        cat.datevAccount,
        '1200', // Bank standard account
        _vatKey(r.vatRate),
        dateFmt.format(r.date),
        'REC-${i + 1}', // Belegfeld 1
        '',
        '',
        '${r.merchant} - ${cat.nameDe}',
      ]);
    }

    return const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
    ).convert(rows);
  }

  /// DATEV BU-Schlüssel (VAT key) — maps VAT rate to DATEV code
  static String _vatKey(double rate) {
    if (rate == 19.0) return '9';
    if (rate == 7.0) return '8';
    return '0';
  }

  /// Generates a summary string — nice for a preview or email body
  static String summary(List<Receipt> receipts) {
    if (receipts.isEmpty) return 'No receipts to export.';
    final total = receipts.fold<double>(0, (s, r) => s + r.totalAmount);
    final vat = receipts.fold<double>(0, (s, r) => s + r.vatAmount);
    final fmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    return 'Receipts: ${receipts.length}\n'
        'Total: ${fmt.format(total)}\n'
        'VAT: ${fmt.format(vat)}';
  }
}
