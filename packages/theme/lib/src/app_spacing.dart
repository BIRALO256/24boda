import 'package:flutter/material.dart';

/// 24Boda spacing system.
///
/// Built on a base-4 grid. Every spacing value is a multiple of 4.
/// This creates visual rhythm and consistency across all screens.
///
/// Why base-4?
/// - Most mobile screens are divisible by 4 in their layout grids
/// - Matches Material Design's baseline 4dp grid
/// - Makes designs feel ordered without requiring a designer every time
///
/// Usage:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.md),  // 16
/// )
/// SizedBox(height: AppSpacing.sm)             // 8
/// ```
abstract final class AppSpacing {
  // ── Base values ────────────────────────────────────────────────────────────

  /// 4dp — micro gaps between tightly related elements (icon + label).
  static const double xs = 4;

  /// 8dp — small gaps between related elements (icon + text in a row).
  static const double sm = 8;

  /// 12dp — comfortable inner padding for compact components (chips, badges).
  static const double smMd = 12;

  /// 16dp — standard padding. The most used value in the app.
  /// Card inner padding, screen horizontal margins, list item padding.
  static const double md = 16;

  /// 20dp — slightly generous spacing, form field vertical padding.
  static const double mdLg = 20;

  /// 24dp — section spacing, between card and next element.
  static const double lg = 24;

  /// 32dp — generous section separation, modal header padding.
  static const double xl = 32;

  /// 40dp — large visual breathing room, onboarding screen padding.
  static const double xxl = 40;

  /// 48dp — hero section spacing, bottom of onboarding screens.
  static const double xxxl = 48;

  /// 64dp — maximum structural spacing, splash screen logo positioning.
  static const double huge = 64;

  // ── Screen margins ─────────────────────────────────────────────────────────

  /// Standard horizontal screen margin — 16dp on both sides.
  /// Every screen's content should sit within this margin.
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: md,
  );

  /// Standard screen padding — 16dp horizontal, 24dp vertical.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  /// Bottom sheet inner padding — accounts for safe area at bottom.
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(
    md,
    lg,
    md,
    md,
  );

  // ── Border radius ──────────────────────────────────────────────────────────

  /// 4dp — very subtle rounding, used on input field borders.
  static const double radiusXs = 4;

  /// 8dp — standard card corner radius.
  static const double radiusSm = 8;

  /// 12dp — prominent card radius, modal sheets.
  static const double radiusMd = 12;

  /// 16dp — large card radius, bottom sheet top corners.
  static const double radiusLg = 16;

  /// 24dp — pill-shaped chips and tags.
  static const double radiusXl = 24;

  /// 999dp — fully rounded (circle pills, avatar badges, FAB).
  static const double radiusFull = 999;

  // ── Border radius objects (pre-composed for convenience) ──────────────────

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(radiusXl),
  );

  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(radiusSm),
  );

  static const BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusLg),
    topRight: Radius.circular(radiusLg),
  );

  static const BorderRadius fullRadius = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ── Icon sizes ─────────────────────────────────────────────────────────────

  /// 16dp — small inline icons (within body text, labels).
  static const double iconSm = 16;

  /// 20dp — standard UI icons (list items, form field trailing).
  static const double iconMd = 20;

  /// 24dp — prominent icons (app bar actions, bottom nav).
  static const double iconLg = 24;

  /// 32dp — large feature icons (empty state illustrations, step indicators).
  static const double iconXl = 32;

  /// 48dp — hero icons (splash screen, onboarding illustrations).
  static const double iconHuge = 48;

  // ── Avatar / image sizes ───────────────────────────────────────────────────

  /// 32dp — compact avatar (chat, list item).
  static const double avatarSm = 32;

  /// 48dp — standard avatar (profile, rider card).
  static const double avatarMd = 48;

  /// 64dp — large avatar (profile screen header).
  static const double avatarLg = 64;

  /// 96dp — hero avatar (rider profile modal).
  static const double avatarXl = 96;

  // ── Button heights ─────────────────────────────────────────────────────────

  /// 48dp — standard button height. Meets WCAG minimum 44dp touch target.
  static const double buttonHeight = 48;

  /// 40dp — compact button for inline use (filters, secondary actions).
  static const double buttonHeightSm = 40;

  /// 56dp — large CTA button (primary screen action, booking confirmation).
  static const double buttonHeightLg = 56;
}
