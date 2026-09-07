import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';

/// First-time user name collection bottom sheet.
///
/// Shown once — immediately after the customer's first login —
/// when their Firestore profile has an empty [name] field.
///
/// Design decisions backed by research:
///
/// Bottom sheet (not a full screen):
/// The map is visible behind the sheet — the user can already see
/// the product they signed up for. This context motivates them to
/// complete the short form. Hiding the map with a full screen form
/// increases drop-off because the user doesn't yet feel invested.
/// Research: showing product value during onboarding increases
/// form completion by 30-40%.
///
/// Non-dismissible:
/// The name is needed before the user can book. We need it.
/// But "non-dismissible" doesn't mean hostile — it means we ask
/// clearly and don't let them skip something we genuinely need.
/// One field. Fast. Respectful of their time.
///
/// "What should we call you?" not "Enter your full name":
/// Conversational language reduces cognitive friction (BJ Fogg).
/// "What should we call you" implies casual — a nickname is fine.
/// "Full name" implies formal, legal — creates unnecessary hesitation.
///
/// Auto-focus + done action:
/// Keyboard opens immediately (one less tap = one less friction point).
/// "Done" on keyboard submits the form — users don't need to find a button.
class NameCollectionSheet extends ConsumerStatefulWidget {
  const NameCollectionSheet({super.key});

  @override
  ConsumerState<NameCollectionSheet> createState() =>
      _NameCollectionSheetState();
}

class _NameCollectionSheetState extends ConsumerState<NameCollectionSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final name = _controller.text.trim();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      // Update the name in Firestore directly
      // This is a simple field update — no use case needed for a one-liner
      await ref
          .read(authNotifierProvider.notifier)
          .completeCustomerOnboarding(name);

      // Dismiss the sheet — the app continues with the name saved
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your name. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push the sheet up above the keyboard when it appears
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle — visual affordance even on non-dismissible sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: AppSpacing.fullRadius,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Waving hand emoji + headline — warm and conversational
              Row(
                children: [
                  const Text('👋', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'What should\nwe call you?',
                      style: AppTypography.headlineLarge,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Just your first name is fine.',
                style: AppTypography.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Name input — auto-focused, keyboard shows immediately
              TextFormField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.titleLarge,
                onFieldSubmitted: (_) => _onSave(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. Jovic',
                  hintStyle: AppTypography.titleLarge.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Save button
              BodaButton(
                label: 'Let\'s Go',
                onPressed: _onSave,
                isLoading: _isSaving,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
