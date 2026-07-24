import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theme/src/app_colors.dart';
import 'package:theme/src/app_spacing.dart';
import 'package:theme/src/app_typography.dart';

/// The 24Boda standard text input field.
///
/// Wraps Flutter's [TextFormField] with 24Boda styling pre-applied.
/// Used for phone number input, name input, address input, and notes.
///
/// Design decisions:
/// - Label floats above the field on focus — Material Design pattern
///   users already know. Recognition over recall (Norman).
/// - Error message appears inline below the field — immediate feedback.
///   Nielsen heuristic #9: help users recognize, diagnose, recover from errors.
/// - Prefix icon anchors the field's purpose visually before the user reads.
/// - inputFormatters built-in — prevents invalid input at the source
///   rather than catching errors on submit.
///
/// Usage:
/// ```dart
/// BodaTextField(
///   controller: _phoneController,
///   label: 'Phone Number',
///   hint: '0700 123 456',
///   keyboardType: TextInputType.phone,
///   prefixIcon: Icons.phone_outlined,
///   validator: PhoneValidator.errorMessage,
/// )
/// ```
class BodaTextField extends StatelessWidget {
  const BodaTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final bool obscureText;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: AppTypography.bodyLarge,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '', // hide the maxLength counter
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: AppSpacing.iconMd)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// A specialised phone number input field.
///
/// Pre-configured with:
/// - Phone keyboard type
/// - Uganda flag prefix
/// - +256 country code display
/// - Numeric input formatter
/// - Auto-focus (phone screen opens keyboard immediately)
///
/// This is a concrete reusable widget for the phone screen —
/// not a generic field. It encapsulates all phone-input behaviour
/// so the phone screen stays clean and declarative.
class BodaPhoneField extends StatelessWidget {
  const BodaPhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      style: AppTypography.bodyLarge,
      // Only allow digits, spaces, and + for manual E.164 entry
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s+]')),
        LengthLimitingTextInputFormatter(15),
      ],
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '0700 123 456',
        // Uganda flag + country code prefix
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.smMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🇺🇬',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '+256',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 1,
                height: 20,
                color: AppColors.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
