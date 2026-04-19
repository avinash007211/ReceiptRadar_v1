import 'package:flutter/material.dart';

/// Receipt Radar — Design System Colors
/// Deep teal accent, warm cream background, dark charcoal text.
/// Feels like a premium finance tool, not a toy.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────
  static const Color accent      = Color(0xFF0E7C66); // deep teal
  static const Color accentLight = Color(0xFFE8F4F0); // teal tint
  static const Color accentDark  = Color(0xFF075E4D); // pressed
  static const Color goldAccent  = Color(0xFFCC9B3E); // premium/pro gold

  // ── Backgrounds ────────────────────────────────────
  static const Color bgPrimary   = Color(0xFFF5F2EC); // warm cream
  static const Color bgSecondary = Color(0xFFFFFFFF); // card
  static const Color bgTertiary  = Color(0xFFEDE9E1); // subtle
  static const Color bgDark      = Color(0xFF15201F); // dark cards/scanner

  // ── Text ───────────────────────────────────────────
  static const Color textPrimary     = Color(0xFF15201F);
  static const Color textSecondary   = Color(0xFF4F5958);
  static const Color textMuted       = Color(0xFF8A918F);
  static const Color textOnDark      = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xB3FFFFFF);

  // ── Semantic ───────────────────────────────────────
  static const Color success = Color(0xFF0E7C66);
  static const Color warning = Color(0xFFCC9B3E);
  static const Color error   = Color(0xFFCC4040);
  static const Color info    = Color(0xFF2563EB);

  // ── Borders ────────────────────────────────────────
  static const Color border      = Color(0xFFE0DBD1);
  static const Color borderLight = Color(0xFFEBE7DC);

  // ── Gradients ──────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E7C66), Color(0xFF075E4D), Color(0xFF0D1817)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15201F), Color(0xFF1E2B2A)],
  );

  static const LinearGradient scannerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1212), Color(0xFF15201F)],
  );
}
