import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/receipt/screens/receipt_review_screen.dart';
import '../../features/receipt/screens/receipt_list_screen.dart';
import '../../features/receipt/screens/receipt_detail_screen.dart';
import '../../features/export/screens/export_screen.dart';
import '../../features/paywall/screens/paywall_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home       = '/';
  static const String scanner    = '/scanner';
  static const String review     = '/review';
  static const String list       = '/receipts';
  static const String detail     = '/receipts/detail';
  static const String export     = '/export';
  static const String paywall    = '/paywall';
  static const String settings   = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (ctx, state) => _slide(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (ctx, state) => _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.scanner,
        pageBuilder: (ctx, state) => _slide(state, const ScannerScreen()),
      ),
      GoRoute(
        path: AppRoutes.review,
        pageBuilder: (ctx, state) {
          final receiptId = state.uri.queryParameters['id'] ?? '';
          return _slide(state, ReceiptReviewScreen(receiptId: receiptId));
        },
      ),
      GoRoute(
        path: AppRoutes.list,
        pageBuilder: (ctx, state) => _slide(state, const ReceiptListScreen()),
      ),
      GoRoute(
        path: AppRoutes.detail,
        pageBuilder: (ctx, state) {
          final receiptId = state.uri.queryParameters['id'] ?? '';
          return _slide(state, ReceiptDetailScreen(receiptId: receiptId));
        },
      ),
      GoRoute(
        path: AppRoutes.export,
        pageBuilder: (ctx, state) => _slide(state, const ExportScreen()),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        pageBuilder: (ctx, state) => _slide(state, const PaywallScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (ctx, state) => _slide(state, const SettingsScreen()),
      ),
    ],
  );
});

CustomTransitionPage _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (ctx, anim, _, c) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: c,
      ),
    );

CustomTransitionPage _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (ctx, anim, _, c) =>
          FadeTransition(opacity: anim, child: c),
    );
