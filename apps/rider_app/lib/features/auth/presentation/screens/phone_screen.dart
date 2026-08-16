import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_state.dart';

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
    final raw = _phoneController.text.trim();
    final localFormat = raw.isNotEmpty ? '0$raw' : '';
    final isValid = PhoneValidator.isValid(localFormat);
    if (isValid != _isValid) setState(() => _isValid = isValid);
  }

  String get _fullPhone => '+256${_phoneController.text.trim()}';

  Future<void> _onSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    _phoneFocusNode.unfocus();
    await ref.read(authNotifierProvider.notifier).sendOtp(_fullPhone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.valueOrNull is AuthOtpSending;

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is AuthOtpSent) {
          context.goToOtp(
            verificationId: state.verificationId,
            phoneNumber: state.phoneNumber,
          );
        }
        if (state is AuthWrongRole) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This number is registered as a customer. '
                'Please use the 24Boda customer app.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
          ref.read(authNotifierProvider.notifier).resetError();
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          ref.read(authNotifierProvider.notifier).resetError();
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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

                  // Rider icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Rider login',
                    style: AppTypography.displayMedium,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Your phone number?',
                    style: AppTypography.bodyMedium,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  BodaPhoneField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    autofocus: true,
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!PhoneValidator.isValid('0$raw')) {
                        return 'Enter a valid Uganda number';
                      }
                      return null;
                    },
                    onSubmitted: (_) => _isValid ? _onSendCode() : null,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  BodaButton(
                    label: 'Send Code',
                    onPressed: _isValid ? _onSendCode : null,
                    isLoading: isLoading,
                  ),

                  const Spacer(),

                  Text(
                    'Only registered 24Boda riders can access this app.',
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
