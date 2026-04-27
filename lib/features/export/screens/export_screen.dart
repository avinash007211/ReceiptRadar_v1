import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/csv_exporter.dart';
import '../../../core/services/receipt_store.dart';
import '../../receipt/models/receipt.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});
  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  String _format = 'simple'; // 'simple' or 'datev'
  bool _exporting = false;

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _to = picked);
  }

  List<Receipt> _filter(List<Receipt> all) {
    return all.where((r) {
      final inRange = !r.date.isBefore(_from) &&
          !r.date.isAfter(_to.add(const Duration(days: 1)));
      return inRange;
    }).toList();
  }

  Future<void> _export(List<Receipt> filtered) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipts in this date range')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final csv = _format == 'datev'
          ? CsvExporter.toDatevCsv(filtered)
          : CsvExporter.toSimpleCsv(filtered);

      final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fname = _format == 'datev'
          ? 'receipt_radar_DATEV_$ts.csv'
          : 'receipt_radar_$ts.csv';

      // Build XFile from in-memory bytes — works on Android, iOS, AND web.
      // No path_provider needed (which doesn't exist on web).
      // On web, share_plus will fall back to a browser download.
      final bytes = utf8.encode(csv);
      final xfile = XFile.fromData(
        bytes,
        mimeType: 'text/csv',
        name: fname,
      );

      await Share.shareXFiles(
        [xfile],
        fileNameOverrides: [fname],
        subject: 'Receipts ${DateFormat.yMMMd().format(_from)} – '
            '${DateFormat.yMMMd().format(_to)}',
        text: CsvExporter.summary(filtered),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncReceipts = ref.watch(receiptsProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Export Receipts', style: AppTextStyles.h4),
      ),
      body: asyncReceipts.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (receipts) {
          final filtered = _filter(receipts);
          final total = filtered.fold<double>(0, (s, r) => s + r.totalAmount);
          final vat = filtered.fold<double>(0, (s, r) => s + r.vatAmount);
          final fmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              Text('Date range', style: AppTextStyles.labelSmall),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'From',
                      date: dateFmt.format(_from),
                      onTap: _pickFrom,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      label: 'To',
                      date: dateFmt.format(_to),
                      onTap: _pickTo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Format', style: AppTextStyles.labelSmall),
              const SizedBox(height: 6),
              _FormatCard(
                title: 'Simple CSV',
                subtitle:
                    'Readable spreadsheet with all fields. Works with Excel, Numbers, Google Sheets.',
                selected: _format == 'simple',
                onTap: () => setState(() => _format = 'simple'),
              ),
              const SizedBox(height: 10),
              _FormatCard(
                title: 'DATEV CSV',
                subtitle:
                    'Industry format for German Steuerberater. Imports directly into DATEV.',
                isPro: true,
                selected: _format == 'datev',
                onTap: () => setState(() => _format = 'datev'),
              ),
              const SizedBox(height: 24),

              // Preview
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.darkCardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIEW',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${filtered.length} receipts',
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _kv('Total', fmt.format(total)),
                    const SizedBox(height: 6),
                    _kv('VAT', fmt.format(vat)),
                    const SizedBox(height: 6),
                    _kv('Net',
                        fmt.format((total - vat).clamp(0, double.infinity))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: asyncReceipts.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (receipts) {
              final filtered = _filter(receipts);
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_exporting || filtered.isEmpty)
                      ? null
                      : () => _export(filtered),
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.ios_share_rounded, size: 20),
                  label: Text(
                    _exporting ? 'Exporting...' : 'Export & Share',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    disabledBackgroundColor: AppColors.border,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k,
            style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        Text(v,
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    date,
                    style: AppTextStyles.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool isPro;
  final VoidCallback onTap;

  const _FormatCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    this.isPro = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: 2,
                ),
                color: selected ? AppColors.accent : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTextStyles.labelLarge),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
