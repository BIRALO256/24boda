import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theme/src/app_colors.dart';
import 'package:theme/src/app_spacing.dart';
import 'package:theme/src/app_typography.dart';

/// 24Boda app theme.
///
/// Exposes a single [AppTheme.light] getter that returns the fully configured
/// [ThemeData] for the app. Both [customer_app] and [rider_app] use this.
///
/// Usage in your app's root widget:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   ...
/// )
/// ```
///
/// Every component theme below is explicitly configured so there are
/// zero surprises from Flutter's defaults bleeding through.
abstract final class AppTheme {
  /// The 24Boda light theme.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // ── Color scheme ──────────────────────────────────────────────────────
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        // Primary — orange
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDark,
        // Secondary — charcoal (used for nav bar, headers)
        secondary: AppColors.dark,
        onSecondary: AppColors.background,
        secondaryContainer: AppColors.surface,
        onSecondaryContainer: AppColors.dark,
        // Tertiary — info blue (used for tracking, in-transit states)
        tertiary: AppColors.info,
        onTertiary: AppColors.background,
        tertiaryContainer: AppColors.infoSurface,
        onTertiaryContainer: AppColors.info,
        // Error
        error: AppColors.error,
        onError: AppColors.background,
        errorContainer: AppColors.errorSurface,
        onErrorContainer: AppColors.error,
        // Surface & background
        surface: AppColors.background,
        onSurface: AppColors.dark,
        surfaceContainerHighest: AppColors.surface,
        onSurfaceVariant: AppColors.textSecondary,
        // Outline
        outline: AppColors.divider,
        outlineVariant: AppColors.surface,
        // Shadow & scrim
        shadow: AppColors.dark,
        scrim: AppColors.overlayDark,
        // Inverse (used for snackbars)
        inverseSurface: AppColors.dark,
        onInverseSurface: AppColors.background,
        inversePrimary: AppColors.primaryLight,
      ),

      // ── Text theme ────────────────────────────────────────────────────────
      textTheme: AppTypography.textTheme,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(
          color: AppColors.dark,
          size: AppSpacing.iconLg,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // ── Bottom navigation bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.labelMedium,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Navigation bar (Material 3) ───────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primarySurface,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            );
          }
          return AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          );
        }),
        elevation: 8,
        shadowColor: AppColors.divider,
      ),

      // ── Elevated button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smMd,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          elevation: 0,
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.background,
          ),
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smMd,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Input decoration (text fields) ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        errorStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
          side: BorderSide(color: AppColors.divider),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySurface,
        disabledColor: AppColors.surface,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.chipRadius,
          side: BorderSide(color: AppColors.divider),
        ),
        side: const BorderSide(color: AppColors.divider),
        elevation: 0,
      ),

      // ── Floating action button ────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.fullRadius,
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── List tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minVerticalPadding: AppSpacing.smMd,
        titleTextStyle: AppTypography.titleLarge,
        subtitleTextStyle: AppTypography.bodyMedium,
        iconColor: AppColors.textSecondary,
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        modalElevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.divider,
        dragHandleSize: Size(40, 4),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
      ),

      // ── Snack bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.dark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.background,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
        elevation: 4,
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySurface,
        circularTrackColor: AppColors.primarySurface,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.background;
          }
          return AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.divider;
        }),
      ),

      // ── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── Splash / highlight ────────────────────────────────────────────────
      splashColor: AppColors.primarySurface,
      highlightColor: AppColors.primarySurface,
    );
  }
}
