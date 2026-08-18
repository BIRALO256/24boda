import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:rider_app/features/home/presentation/providers/online_status_provider.dart';

/// The most important button in the rider app.
///
/// Toggles the rider between online (receiving jobs) and offline.
///
/// Design decisions backed by research:
///
/// Large, prominent, centered at the bottom:
/// Thumb zone research (Hoober) — the bottom center of the screen
/// is the most reachable position with one hand. This button is
/// tapped multiple times per day — it must require zero effort to reach.
///
/// Two distinct states with color + text + icon:
/// Redundant coding (Norman) — never rely on color alone.
/// Online = green + "You're Online" + check icon.
/// Offline = grey + "Go Online" + power icon.
/// A colorblind rider can still tell the state from text and icon.
///
/// Loading state during transition:
/// The Firestore write takes ~200-500ms. During that time the button
/// shows a spinner so the rider knows their tap registered.
/// Without this feedback, users tap multiple times thinking
/// it didn't work. (Nielsen: visibility of system status)
///
/// Why not a Switch widget?
/// Switches communicate binary state but feel passive.
/// A button feels like a deliberate action — going online is
/// a commitment to accept work. The button's weight matches
/// the intention behind the action.
class OnlineToggleButton extends ConsumerStatefulWidget {
  const OnlineToggleButton({super.key});

  @override
  ConsumerState<OnlineToggleButton> createState() =>
      _OnlineToggleButtonState();
}

class _OnlineToggleButtonState extends ConsumerState<OnlineToggleButton> {
  bool _isLoading = false;

  Future<void> _onTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    await ref.read(onlineStatusProvider.notifier).toggle();

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(onlineStatusProvider);

    return GestureDetector(
      onTap: _isLoading ? null : _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.success : AppColors.dark,
          borderRadius: AppSpacing.fullRadius,
          boxShadow: [
            BoxShadow(
              color: (isOnline ? AppColors.success : AppColors.dark)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: AppSpacing.iconMd,
                height: AppSpacing.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            else
              Icon(
                isOnline
                    ? Icons.check_circle_rounded
                    : Icons.power_settings_new_rounded,
                color: AppColors.background,
                size: AppSpacing.iconMd,
              ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _isLoading
                  ? 'Please wait...'
                  : isOnline
                      ? 'You\'re Online'
                      : 'Go Online',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
