import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppConstants {
  AppConstants._();

  static const String appName    = 'Receipt Radar';
  static const String appTagline = 'Scan. Categorize. Export. Done.';

  // Free tier limit
  static const int freeReceiptsPerMonth = 10;

  // Storage keys
  static const String receiptsKey    = 'rr_receipts_v1';
  static const String settingsKey    = 'rr_settings_v1';
  static const String onboardedKey   = 'rr_onboarded_v1';
  static const String proStatusKey   = 'rr_pro_v1';

  // German/EU tax categories with DATEV SKR03 account numbers
  static const List<TaxCategory> taxCategories = [
    TaxCategory(
      id: 'office_supplies',
      nameEn: 'Office Supplies',
      nameDe: 'Büromaterial',
      datevAccount: '4930',
      emoji: '📎',
      color: Color(0xFF2563EB),
    ),
    TaxCategory(
      id: 'meals_business',
      nameEn: 'Business Meals',
      nameDe: 'Bewirtungskosten',
      datevAccount: '4650',
      emoji: '🍽️',
      color: Color(0xFFCC9B3E),
    ),
    TaxCategory(
      id: 'travel',
      nameEn: 'Travel Expenses',
      nameDe: 'Reisekosten',
      datevAccount: '4660',
      emoji: '✈️',
      color: Color(0xFF7C3AED),
    ),
    TaxCategory(
      id: 'fuel',
      nameEn: 'Fuel & Vehicle',
      nameDe: 'Kraftstoff / Kfz',
      datevAccount: '4530',
      emoji: '⛽',
      color: Color(0xFFDC2626),
    ),
    TaxCategory(
      id: 'software',
      nameEn: 'Software & Subscriptions',
      nameDe: 'Software / Abos',
      datevAccount: '4940',
      emoji: '💻',
      color: Color(0xFF0E7C66),
    ),
    TaxCategory(
      id: 'hardware',
      nameEn: 'Hardware & Equipment',
      nameDe: 'Geräte / Technik',
      datevAccount: '0490',
      emoji: '🖥️',
      color: Color(0xFF059669),
    ),
    TaxCategory(
      id: 'phone_internet',
      nameEn: 'Phone & Internet',
      nameDe: 'Telefon / Internet',
      datevAccount: '4920',
      emoji: '📱',
      color: Color(0xFF0891B2),
    ),
    TaxCategory(
      id: 'education',
      nameEn: 'Training & Education',
      nameDe: 'Fortbildung',
      datevAccount: '4945',
      emoji: '📚',
      color: Color(0xFFD97706),
    ),
    TaxCategory(
      id: 'marketing',
      nameEn: 'Marketing & Ads',
      nameDe: 'Werbung',
      datevAccount: '4610',
      emoji: '📣',
      color: Color(0xFFEC4899),
    ),
    TaxCategory(
      id: 'other',
      nameEn: 'Other',
      nameDe: 'Sonstiges',
      datevAccount: '4980',
      emoji: '📄',
      color: AppColors.textMuted,
    ),
  ];

  static TaxCategory categoryById(String id) {
    return taxCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => taxCategories.last, // 'other'
    );
  }

  // Common German VAT rates
  static const List<double> vatRates = [0.0, 7.0, 19.0];
}

class TaxCategory {
  final String id;
  final String nameEn;
  final String nameDe;
  final String datevAccount;
  final String emoji;
  final Color color;

  const TaxCategory({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.datevAccount,
    required this.emoji,
    required this.color,
  });
}
