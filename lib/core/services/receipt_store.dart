import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../../features/receipt/models/receipt.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Async provider that loads receipts from encrypted storage on app start.
/// UI widgets use ref.watch(receiptsProvider) to get a reactive list.
class ReceiptStore extends AsyncNotifier<List<Receipt>> {
  @override
  Future<List<Receipt>> build() async {
    return _load();
  }

  Future<List<Receipt>> _load() async {
    final raw = await _storage.read(key: AppConstants.receiptsKey);
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
    await _storage.write(key: AppConstants.receiptsKey, value: raw);
  }

  // ── Public API ─────────────────────────────────────

  Future<void> add(Receipt receipt) async {
    final current = state.value ?? <Receipt>[];
    final updated = <Receipt>[receipt, ...current];
    await _save(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final current = state.value ?? <Receipt>[];
    final updated = current
        .map((r) => r.id == receipt.id ? receipt : r)
        .toList();
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
    await _storage.delete(key: AppConstants.receiptsKey);
    state = const AsyncValue.data(<Receipt>[]);
  }

  int countThisMonth() {
    final now = DateTime.now();
    final receipts = state.value ?? <Receipt>[];
    return receipts
        .where(
          (r) => r.createdAt.year == now.year && r.createdAt.month == now.month,
        )
        .length;
  }
}

final receiptsProvider = AsyncNotifierProvider<ReceiptStore, List<Receipt>>(
  ReceiptStore.new,
);

// ── Pro status ────────────────────────────────────────
class ProStatus extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<void> init() async {
    final value = await _storage.read(key: AppConstants.proStatusKey);
    state = value == 'true';
  }

  Future<void> setPro(bool isPro) async {
    await _storage.write(
      key: AppConstants.proStatusKey,
      value: isPro.toString(),
    );
    state = isPro;
  }
}

final proStatusProvider = NotifierProvider<ProStatus, bool>(ProStatus.new);
