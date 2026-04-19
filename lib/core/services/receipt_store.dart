import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../../features/receipt/models/receipt.dart';

/// Async provider that loads receipts from SharedPreferences on app start.
class ReceiptStore extends AsyncNotifier<List<Receipt>> {
  late SharedPreferences _prefs;

  @override
  Future<List<Receipt>> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _load();
  }

  List<Receipt> _load() {
    final raw = _prefs.getString(AppConstants.receiptsKey);
    if (raw == null || raw.isEmpty) return <Receipt>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Receipt>[];
    }
  }

  Future<void> _save(List<Receipt> receipts) async {
    final raw = jsonEncode(receipts.map((r) => r.toJson()).toList());
    await _prefs.setString(AppConstants.receiptsKey, raw);
  }

  // ── Public API ─────────────────────────────────────

  Future<void> add(Receipt receipt) async {
    // Using .value instead of .valueOrNull for broader compatibility
    final current = state.value ?? <Receipt>[];
    final updated = <Receipt>[receipt, ...current]; // Explicitly typed list
    await _save(updated);
    state = AsyncValue.data(updated);
  }

  // RENAMED from 'update' to 'updateReceipt' to avoid Riverpod collision
  Future<void> updateReceipt(Receipt receipt) async {
    final current = state.value ?? <Receipt>[];
    final updated =
        current.map((r) => r.id == receipt.id ? receipt : r).toList();
    await _save(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> delete(String id) async {
    final current = state.value ?? <Receipt>[];
    final updated = current.where((r) => r.id != id).toList();
    await _save(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> clear() async {
    await _prefs.remove(AppConstants.receiptsKey);
    state = const AsyncValue.data(<Receipt>[]);
  }

  int countThisMonth() {
    final now = DateTime.now();
    // Use value ?? [] to safely handle loading/error states
    final receipts = state.value ?? <Receipt>[];
    return receipts
        .where((r) =>
            r.createdAt.year == now.year && r.createdAt.month == now.month)
        .length;
  }
}

final receiptsProvider =
    AsyncNotifierProvider<ReceiptStore, List<Receipt>>(ReceiptStore.new);

// ── Pro status ────────────────────────────────────────
class ProStatus extends Notifier<bool> {
  late SharedPreferences _prefs;

  @override
  bool build() {
    return false;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs.getBool(AppConstants.proStatusKey) ?? false;
  }

  Future<void> setPro(bool isPro) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setBool(AppConstants.proStatusKey, isPro);
    state = isPro;
  }
}

final proStatusProvider = NotifierProvider<ProStatus, bool>(ProStatus.new);
