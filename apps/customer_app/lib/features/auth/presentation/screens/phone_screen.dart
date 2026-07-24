import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/core/router/app_router.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_state.dart';

/// Phone number entry screen — the first user interaction in the auth flow.
///
/// Design decisions backed by research:
///
/// Layout — logo top, form middle, legal bottom:
/// F-pattern reading (Nielsen Norman Group) — users scan top-left first.
/// Logo at top confirms identity. Form in the vertical center gets
/// immediate attention. Legal text at bottom is visible but not intrusive.
///
/// Auto-focus on load:
/// The keyboard opens automatically when this screen appears.
/// Fitts's Law — reduce steps to the primary action.
/// The user's intent on this screen is 100% clear: enter a number.
/// Making them tap the field first is unnecessary friction.
///
/// Real-time validation:
/// The "Send Code" button enables only when the number is valid.
/// Error prevention (Nielsen heuristic #5) — block submission of
/// invalid input before it happens. Never show an error for something
/// the user is still typing (only validate on unfocus or submit).
///
/// Uganda context:
/// The Uganda flag + +256 prefix removes all ambiguity about
/// which country's format to use. Recognition over recall (Norman).
/// Users in Uganda do not need to think about country codes.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final isValid = PhoneValidator.isValid(_phoneController.text.trim());
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  Future<void> _onSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    _phoneFocusNode.unfocus();

    await ref.read(authNotifierProvider.notifier).sendOtp(
          _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Show snackbar on error — non-blocking, dismissable
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is AuthOtpSent) {
          // Navigate to OTP screen
          context.goToOtp(
            verificationId: state.verificationId,
            phoneNumber: state.phoneNumber,
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).resetError();
                },
              ),
            ),
          );
        }
      });
    });

    final isLoading = authState.valueOrNull is AuthOtpSending;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  AppSpacing.lg * 2,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),

                    // Logo — confirms app identity before asking for personal info
                    Center(
                      child: Image.asset(
                        'packages/theme/assets/images/logo.png',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Headline
                    Text(
                      'Enter your phone number',
                      style: AppTypography.headlineLarge,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Subheadline — sets expectation for next step
                    Text(
                      'We\'ll send you a verification code to confirm your number.',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Phone input field
                    BodaPhoneField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      autofocus: true,
                      validator: PhoneValidator.errorMessage,
                      onSubmitted: (_) => _isValid ? _onSendCode() : null,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Primary CTA
                    BodaButton(
                      label: 'Send Code',
                      onPressed: _isValid ? _onSendCode : null,
                      isLoading: isLoading,
                      icon: Icons.arrow_forward_rounded,
                    ),

                    const Spacer(),

                    // Legal text — required but not in the way
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy. Standard SMS rates may apply.',
                      style: AppTypography.labelSmall,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
