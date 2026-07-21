import 'package:flutter/material.dart';

/// 24Boda brand color system.
///
/// All colors in the app are sourced from this class exclusively.
/// Never hardcode a color value anywhere in the codebase.
///
/// Palette decisions:
/// - [primary]    Orange  — communicates speed, energy, action (core brand promise)
/// - [dark]       Charcoal — authority, reliability, primary text
/// - [background] White   — breathing room, map visibility, clarity
/// - [surface]    Light Grey — cards, inputs, separation without heavy borders
/// - Status colors use universal signals humans already know (green=good, red=bad)
abstract final class AppColors {
  // ── Primary brand ──────────────────────────────────────────────────────────

  /// The 24Boda orange. Used for primary buttons, FABs, active states,
  /// progress indicators, and any element that demands immediate attention.
  static const Color primary = Color(0xFFFF6B00);

  /// Lighter orange for hover states, backgrounds behind orange text,
  /// and subtle highlights.
  static const Color primaryLight = Color(0xFFFF8C33);

  /// Deeper orange for pressed states and active tab indicators.
  static const Color primaryDark = Color(0xFFCC5500);

  /// Very light orange tint — used for chip backgrounds, tag fills,
  /// and selected row highlights.
  static const Color primarySurface = Color(0xFFFFF0E6);

  // ── Dark / text ────────────────────────────────────────────────────────────

  /// Deep charcoal — primary text, navigation bar, app bar background.
  /// Slightly blue-tinted to feel authoritative without harshness.
  static const Color dark = Color(0xFF1A1A2E);

  /// Mid grey — secondary text, subtitles, helper text.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Light grey — disabled text, placeholders.
  static const Color textDisabled = Color(0xFFB0B7C3);

  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Pure white — main screen background, map base, modal backgrounds.
  static const Color background = Color(0xFFFFFFFF);

  /// Light grey — card surfaces, input field fills, bottom sheets.
  static const Color surface = Color(0xFFF5F5F5);

  /// Slightly darker surface — used for dividers and subtle separators.
  static const Color divider = Color(0xFFE5E7EB);

  // ── Status colors ──────────────────────────────────────────────────────────
  // These are system feedback colors, not brand colors.
  // They leverage universal human color associations.

  /// Success green — delivery completed, payment confirmed, OTP verified.
  static const Color success = Color(0xFF00C853);

  /// Light success background — success banners, confirmed state chips.
  static const Color successSurface = Color(0xFFE6FFF0);

  /// Warning amber — searching for rider, pending payment, unread notification.
  static const Color warning = Color(0xFFFFB300);

  /// Light warning background — warning banners, pending state chips.
  static const Color warningSurface = Color(0xFFFFF8E1);

  /// Error red — delivery failed, payment failed, form validation errors.
  static const Color error = Color(0xFFD32F2F);

  /// Light error background — error banners, cancelled state chips.
  static const Color errorSurface = Color(0xFFFFEBEE);

  /// Info blue — in transit status, informational tooltips, tracking updates.
  static const Color info = Color(0xFF1565C0);

  /// Light info background — info banners, in-transit chips.
  static const Color infoSurface = Color(0xFFE3F2FD);

  // ── Utility ────────────────────────────────────────────────────────────────

  /// Fully transparent — used for removing backgrounds cleanly.
  static const Color transparent = Colors.transparent;

  /// White with 80% opacity — used for overlays on map and image content.
  static const Color overlayLight = Color(0xCCFFFFFF);

  /// Dark with 60% opacity — used for modal scrim / bottom sheet backdrop.
  static const Color overlayDark = Color(0x991A1A2E);
}
