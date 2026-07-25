import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_state.dart';

/// OTP verification screen.
///
/// The user arrives here after [PhoneScreen] successfully sends the SMS.
/// They enter 6 digits and are automatically signed in.
///
/// Design decisions backed by research:
///
/// Masked phone number display:
/// Confirmation feedback (Norman, The Design of Everyday Things).
/// "+256 7** *** 326" tells the user exactly where the code was sent
/// without exposing the full number to shoulder-surfing.
///
/// 60-second countdown timer + resend:
/// Zeigarnik effect — a visible countdown creates productive tension.
/// Users wait for a timer they can see. Without it they either
/// give up or spam "resend". The timer anchors their patience.
/// Resend is only available after the timer expires — prevents
/// Firebase quota exhaustion from impatient taps.
///
/// Auto-submit on 6th digit:
/// Don't Make Me Think — after 6 digits there is exactly one
/// logical next step. The app takes it automatically.
///
/// Error recovery — "Try Again" goes back to phone screen:
/// Nielsen heuristic #9: help users recover from errors.
/// If verification fails, the user needs to re-enter their
/// number and request a fresh code — not retry the same expired code.
///
/// Disabled OTP field during verification:
/// Prevents the user from editing digits while the network call
/// is in flight — prevents state corruption.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  /// Received from [PhoneScreen] via [AuthOtpSent] state.
  final String verificationId;

  /// Displayed masked so user knows which number received the code.
  final String phoneNumber;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  // Countdown timer state
  static const int _timerSeconds = 60;
  late int _remainingSeconds;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = _timerSeconds;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _onOtpCompleted(String otp) async {
    await ref.read(authNotifierProvider.notifier).verifyOtp(
          verificationId: widget.verificationId,
          otpCode: otp,
        );
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    _startTimer();
    await ref.read(authNotifierProvider.notifier).sendOtp(widget.phoneNumber);
  }

  /// Masks the phone number for display: "+256700123456" → "+256 7** *** 456"
  String _maskedPhone(String phone) {
    try {
      final e164 = PhoneValidator.toE164(phone);
      if (e164.length < 8) return phone;
      final start = e164.substring(0, 6);   // +256 7
      final end = e164.substring(e164.length - 3); // 456
      return '$start** *** $end';
    } catch (_) {
      return phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isVerifying = authState.valueOrNull is AuthVerifying;

    // Listen for errors
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              action: SnackBarAction(
                label: 'Try Again',
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).resetError();
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Back to phone screen — let user correct their number
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isVerifying
              ? null // Disable back during verification
              : () {
                  ref.read(authNotifierProvider.notifier).resetError();
                  Navigator.of(context).pop();
                },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icon — visual anchor for the screen
              Container(
                width: AppSpacing.avatarLg,
                height: AppSpacing.avatarLg,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  color: AppColors.primary,
                  size: AppSpacing.iconXl,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Headline
              Text(
                'Enter verification code',
                style: AppTypography.headlineLarge,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Masked phone confirmation
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyMedium,
                  children: [
                    const TextSpan(text: 'Code sent to '),
                    TextSpan(
                      text: _maskedPhone(widget.phoneNumber),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // OTP boxes — centred, prominent
              BodaOtpField(
                onCompleted: _onOtpCompleted,
                enabled: !isVerifying,
                autofocus: true,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Loading indicator during verification
              if (isVerifying) ...[
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Verifying...',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Countdown timer + resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend) ...[
                    const Icon(
                      Icons.timer_outlined,
                      size: AppSpacing.iconMd,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Resend code in ${DateFormatter.countdown(
                        Duration(seconds: _remainingSeconds),
                      )}',
                      style: AppTypography.bodyMedium,
                    ),
                  ] else ...[
                    Text(
                      'Didn\'t receive the code? ',
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: _onResend,
                      child: Text(
                        'Resend',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
