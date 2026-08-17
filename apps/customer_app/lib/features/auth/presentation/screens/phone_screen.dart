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
    // Controller stores digits only e.g. "700123456"
    // Prepend "0" to form the local Uganda format "0700123456"
    // that PhoneValidator expects
    final raw = _phoneController.text.trim();
    final localFormat = raw.isNotEmpty ? '0$raw' : '';
    final isValid = PhoneValidator.isValid(localFormat);
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  /// Returns the full E.164 phone number from the controller value.
  String get _fullPhone {
    final raw = _phoneController.text.trim();
    return '+256$raw';
  }

  Future<void> _onSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    _phoneFocusNode.unfocus();

    await ref.read(authNotifierProvider.notifier).sendOtp(_fullPhone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Show snackbar on error — non-blocking, dismissable
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is AuthOtpSent) {
          context.goToOtp(
            verificationId: state.verificationId,
            phoneNumber: state.phoneNumber,
          );
        }
        if (state is AuthWrongRoleRider) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                'Wrong app',
                style: AppTypography.headlineSmall,
              ),
              content: Text(
                'This number is registered as a rider. '
                'Please use the 24Boda Rider app instead.',
                style: AppTypography.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          ref.read(authNotifierProvider.notifier).resetError();
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
      // false = scaffold doesn't resize when keyboard appears.
      // The SingleChildScrollView handles keyboard avoidance instead.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Phone icon — represents SMS verification clearly
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smartphone_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Headline — short question, conversational, one line
                  Text(
                    'Your phone number?',
                    style: AppTypography.displayMedium,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    'We\'ll text you a code.',
                    style: AppTypography.bodyMedium,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Phone input
                  BodaPhoneField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    autofocus: true,
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) return 'Please enter your phone number';
                      if (!PhoneValidator.isValid('0$raw')) {
                        return 'Enter a valid Uganda number (e.g. 700 123 456)';
                      }
                      return null;
                    },
                    onSubmitted: (_) => _isValid ? _onSendCode() : null,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // CTA
                  BodaButton(
                    label: 'Send Code',
                    onPressed: _isValid ? _onSendCode : null,
                    isLoading: isLoading,
                  ),

                  const Spacer(),

                  // Legal
                  Text(
                    'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                    style: AppTypography.labelSmall,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
