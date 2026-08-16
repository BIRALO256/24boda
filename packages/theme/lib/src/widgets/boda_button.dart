import 'package:flutter/material.dart';
import 'package:theme/src/app_colors.dart';
import 'package:theme/src/app_spacing.dart';

/// The 24Boda primary action button.
///
/// Used for every primary CTA in the app:
/// - "Send Code" on phone screen
/// - "Verify" on OTP screen
/// - "Book Delivery" on shipment screen
/// - "Accept Job" on rider job screen
///
/// Design decisions backed by research:
/// - Full width by default — Fitts's Law: larger touch target = faster,
///   fewer errors. Studies show full-width buttons reduce mis-taps by 40%.
/// - 48dp minimum height — WCAG 2.1 AA minimum touch target is 44dp.
///   We use 48dp to be safe on all device sizes.
/// - Orange fill — Von Restorff effect: the one colored element on a
///   white screen is what the eye goes to first.
/// - Loading state built-in — prevents double-submission. Don't Make Me
///   Think: the button itself communicates "I received your tap."
/// - Disabled state built-in — error prevention (Nielsen heuristic #5):
///   prevent errors before they happen, don't just report them.
///
/// Usage:
/// ```dart
/// BodaButton(
///   label: 'Send Code',
///   onPressed: isValid ? () => doSomething() : null,
///   isLoading: state is AuthOtpSending,
/// )
/// ```
class BodaButton extends StatelessWidget {
  const BodaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.size = BodaButtonSize.large,
    this.variant = BodaButtonVariant.primary,
    this.icon,
  });

  /// The button label text.
  final String label;

  /// Called when the button is tapped.
  /// Pass null to disable the button.
  final VoidCallback? onPressed;

  /// When true, shows a circular progress indicator instead of the label.
  /// The button is also non-tappable while loading.
  final bool isLoading;

  /// When true (default), button stretches to fill available width.
  final bool isFullWidth;

  /// Controls button height. Defaults to [BodaButtonSize.large] (56dp).
  final BodaButtonSize size;

  /// Visual variant. Defaults to [BodaButtonVariant.primary] (filled orange).
  final BodaButtonVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      BodaButtonSize.small => AppSpacing.buttonHeightSm,
      BodaButtonSize.medium => AppSpacing.buttonHeight,
      BodaButtonSize.large => AppSpacing.buttonHeightLg,
    };

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == BodaButtonVariant.primary
                    ? AppColors.background
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      BodaButtonVariant.primary => ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            maximumSize: Size(isFullWidth ? double.infinity : double.infinity, height),
          ),
          child: child,
        ),
      BodaButtonVariant.outlined => OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            maximumSize: Size(isFullWidth ? double.infinity : double.infinity, height),
          ),
          child: child,
        ),
      BodaButtonVariant.text => TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
          ),
          child: child,
        ),
    };

    return AnimatedOpacity(
      opacity: _isDisabled && !isLoading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: button,
    );
  }
}

enum BodaButtonSize { small, medium, large }
enum BodaButtonVariant { primary, outlined, text }
