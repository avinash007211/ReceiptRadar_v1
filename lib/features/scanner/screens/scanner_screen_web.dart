import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_store.dart';
import '../../receipt/models/receipt.dart';
import '../../receipt/widgets/category_picker.dart';

/// Web version of the scanner screen.
///
/// Google ML Kit doesn't support Flutter Web (it's mobile-only), so instead
/// of broken camera scanning we provide a clean manual-entry form.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _merchantCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  double _vatRate = 19.0;
  String _categoryId = 'other';
  bool _saving = false;

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _totalCtrl.dispose();
    _vatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final merchant = _merchantCtrl.text.trim();
    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a merchant name')),
      );
      return;
    }

    final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid total amount')),
      );
      return;
    }

    final vat = double.tryParse(_vatCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() => _saving = true);
    try {
      final receipt = Receipt(
        merchant: merchant,
        date: _date,
        totalAmount: total,
        vatAmount: vat,
        vatRate: _vatRate,
        categoryId: _categoryId,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await ref.read(receiptsProvider.notifier).add(receipt);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt added ✓'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      context.go(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');

    // FIX: instead of Center+ConstrainedBox+ListView (which collapses on web),
    // use a single ListView with horizontal padding that scales to width.
    // This is the simplest, most reliable layout for Flutter web.
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = screenWidth > 640
        ? (screenWidth - 640) / 2 + 24
        : 24.0;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Add Receipt', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 120),
        children: [
          // Info banner: promote mobile app for auto-scanning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_iphone,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Want auto-scanning?',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.accentDark)),
                      const SizedBox(height: 2),
                      Text(
                        'Install the mobile app to scan receipts automatically with your camera.',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentDark,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),

          _label('Merchant'),
          TextField(
            controller: _merchantCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Shell Deutschland'),
            autofocus: true,
          ),
          const SizedBox(height: 16),

          _label('Date'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(dateFmt.format(_date),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Total (€)'),
                    TextField(
                      controller: _totalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('VAT (€)'),
                    TextField(
                      controller: _vatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _label('VAT Rate'),
          Row(
            children: AppConstants.vatRates.map((rate) {
              final isSelected = rate == _vatRate;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _vatRate = rate),
                  child: Container(
                    margin: EdgeInsets.only(
                        right:
                            rate == AppConstants.vatRates.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.border,
                        width: isSelected ? 0 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text('${rate.toInt()}%',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _label('Tax Category'),
          CategoryPicker(
            selectedId: _categoryId,
            onSelect: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: 20),

          _label('Notes (optional)'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Client meeting, project name...',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(_saving ? 'Saving...' : 'Save Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.labelSmall),
      );
}
