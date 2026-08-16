import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_state.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  final String verificationId;
  final String phoneNumber;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
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

  String _maskedPhone(String phone) {
    try {
      final e164 = PhoneValidator.toE164(phone);
      if (e164.length < 8) return phone;
      final start = e164.substring(0, 6);
      final end = e164.substring(e164.length - 3);
      return '$start** *** $end';
    } catch (_) {
      return phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isVerifying = authState.valueOrNull is AuthVerifying;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isVerifying
              ? null
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
              const SizedBox(height: AppSpacing.lg),

              Container(
                width: AppSpacing.avatarLg,
                height: AppSpacing.avatarLg,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_rounded,
                  color: AppColors.primary,
                  size: AppSpacing.iconXl,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text('Check your messages', style: AppTypography.headlineLarge),

              const SizedBox(height: AppSpacing.xs),

              RichText(
                text: TextSpan(
                  style: AppTypography.bodyMedium,
                  children: [
                    const TextSpan(text: 'We texted a code to '),
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

              const SizedBox(height: AppSpacing.xxl),

              BodaOtpField(
                onCompleted: _onOtpCompleted,
                enabled: !isVerifying,
                autofocus: true,
              ),

              const SizedBox(height: AppSpacing.lg),

              if (isVerifying) ...[
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Verifying...', style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center),
              ],

              const SizedBox(height: AppSpacing.lg),

              Center(
                child: !_canResend
                    ? Text(
                        'Resend in ${DateFormatter.countdown(
                          Duration(seconds: _remainingSeconds),
                        )}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : GestureDetector(
                        onTap: _onResend,
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodyMedium,
                            children: [
                              const TextSpan(
                                text: 'Didn\'t get it? ',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              TextSpan(
                                text: 'Resend',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
