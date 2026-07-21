import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:theme/src/app_colors.dart';

/// 24Boda typography system.
///
/// Built on DM Sans — chosen for:
/// - Tall x-height: improves readability on small screens by ~15%
/// - Geometric, clean letterforms: communicates modernity and speed
/// - Full weight range (400–700): covers all UI hierarchy needs
/// - Free Google Font: no licensing concerns
///
/// Use [AppTypography.textTheme] inside [ThemeData] so the font applies
/// globally. Then reference specific styles via:
/// ```dart
/// Theme.of(context).textTheme.headlineLarge
/// // or directly:
/// AppTypography.headlineLarge
/// ```
abstract final class AppTypography {
  // ── Display ────────────────────────────────────────────────────────────────

  static TextStyle get displayLarge => GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.dark,
      );

  static TextStyle get displayMedium => GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
        color: AppColors.dark,
      );

  // ── Headlines ──────────────────────────────────────────────────────────────

  /// Headline Large — 24sp SemiBold. Primary screen title (AppBar title).
  static TextStyle get headlineLarge => GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColors.dark,
      );

  /// Headline Medium — 20sp SemiBold. Modal titles, bottom sheet headers.
  static TextStyle get headlineMedium => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: AppColors.dark,
      );

  /// Headline Small — 18sp SemiBold. Card section titles.
  static TextStyle get headlineSmall => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
        color: AppColors.dark,
      );

  // ── Titles ─────────────────────────────────────────────────────────────────

  /// Title Large — 16sp SemiBold. List item primary text, form section labels.
  static TextStyle get titleLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: AppColors.dark,
      );

  /// Title Medium — 15sp Medium. Sub-section labels, tab bar labels.
  static TextStyle get titleMedium => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.dark,
      );

  /// Title Small — 14sp Medium. Navigation rail labels, dense list headers.
  static TextStyle get titleSmall => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.dark,
      );

  // ── Body ───────────────────────────────────────────────────────────────────

  /// Body Large — 16sp Regular. Primary body content, delivery descriptions.
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColors.dark,
      );

  /// Body Medium — 14sp Regular. Secondary content, address lines, notes.
  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  /// Body Small — 13sp Regular. Helper text, supplementary details.
  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // ── Labels ─────────────────────────────────────────────────────────────────

  /// Label Large — 14sp SemiBold. Button text, prominent chips.
  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.4,
        color: AppColors.dark,
      );

  /// Label Medium — 12sp Medium. Status badges, tag labels, bottom nav labels.
  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
        color: AppColors.dark,
      );

  /// Label Small — 11sp Regular. Timestamps, fine print, map markers.
  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ── Specialised styles ─────────────────────────────────────────────────────

  /// Price text — 20sp Bold Orange. Delivery fee, earnings amount.
  static TextStyle get price => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
        color: AppColors.primary,
      );

  /// Status pill text — 11sp SemiBold. Shipment status chips.
  static TextStyle get statusPill => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.3,
      );

  /// OTP digit — 32sp Bold. Large OTP input digits on auth screen.
  static TextStyle get otpDigit => GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
        height: 1.2,
        color: AppColors.dark,
      );

  // ── TextTheme mapping ──────────────────────────────────────────────────────

  /// Maps 24Boda styles onto Flutter's [TextTheme].
  /// Used inside [ThemeData] so [Theme.of(context).textTheme] works everywhere.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
