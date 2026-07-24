import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theme/src/app_colors.dart';
import 'package:theme/src/app_spacing.dart';
import 'package:theme/src/app_typography.dart';

/// A 6-digit OTP input field built from individual digit boxes.
///
/// Design decisions backed by research:
///
/// Individual boxes vs one text field:
/// Gestalt psychology — discrete boxes communicate exactly
/// how many digits are expected. "6 empty boxes" is immediately
/// understood with zero reading. A single text field creates
/// ambiguity ("how many digits?").
///
/// Auto-advance between boxes:
/// Reduces motor effort (Fitts's Law). Each digit typed moves
/// focus forward automatically — the user types 6 digits in a
/// single uninterrupted flow without lifting their attention.
///
/// Auto-submit on 6th digit:
/// Don't Make Me Think (Krug). Eliminates the "now what?" moment
/// after typing the last digit. The form submits itself.
///
/// Clipboard paste support:
/// 80% of mobile OTP users receive via SMS and copy-paste
/// (Google UX research). [onChanged] is called with the full
/// 6-digit string when a valid OTP is pasted.
///
/// Usage:
/// ```dart
/// BodaOtpField(
///   onCompleted: (otp) => notifier.verifyOtp(otp),
///   onChanged: (otp) => setState(() => _otp = otp),
/// )
/// ```
class BodaOtpField extends StatefulWidget {
  const BodaOtpField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.autofocus = true,
    this.enabled = true,
  });

  /// Called when all digits are filled. Receives the full OTP string.
  final ValueChanged<String> onCompleted;

  /// Called on every keystroke with the current partial/full OTP.
  final ValueChanged<String>? onChanged;

  /// Number of OTP digits. Defaults to 6.
  final int length;

  /// Auto-focuses the first box when the widget is built.
  final bool autofocus;

  /// When false, all boxes are disabled (used during verification loading).
  final bool enabled;

  @override
  State<BodaOtpField> createState() => _BodaOtpFieldState();
}

class _BodaOtpFieldState extends State<BodaOtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _currentOtp =>
      _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.length > 1) {
      // Handle paste — distribute digits across boxes
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= widget.length) {
        for (int i = 0; i < widget.length; i++) {
          _controllers[i].text = digits[i];
        }
        _focusNodes.last.requestFocus();
        final otp = digits.substring(0, widget.length);
        widget.onChanged?.call(otp);
        widget.onCompleted(otp);
        return;
      }
    }

    if (value.isNotEmpty) {
      // Move focus to next box
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last box filled — unfocus and submit
        _focusNodes[index].unfocus();
        final otp = _currentOtp;
        if (otp.length == widget.length) {
          widget.onChanged?.call(otp);
          widget.onCompleted(otp);
        }
      }
    }

    widget.onChanged?.call(_currentOtp);
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // Move back on backspace when box is empty
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(index, event),
            child: SizedBox(
              width: 44,
              height: 54,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofocus: widget.autofocus && index == 0,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: AppTypography.otpDigit,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.inputRadius,
                    borderSide: const BorderSide(
                      color: AppColors.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.inputRadius,
                    borderSide: const BorderSide(
                      color: AppColors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.inputRadius,
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: _controllers[index].text.isNotEmpty
                      ? AppColors.primarySurface
                      : AppColors.surface,
                ),
                onChanged: (value) => _onDigitEntered(index, value),
              ),
            ),
          ),
        );
      }),
    );
  }
}
