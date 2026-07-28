import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

/// Minimal floating top bar — menu button only.
///
/// Design decision (less is more):
/// The home screen has one job: let the user start a delivery.
/// The greeting, avatar, and notifications are secondary — they
/// live in the sidebar drawer, not competing for attention here.
///
/// Bolt's home screen uses exactly this pattern — single menu icon,
/// full map, zero distraction. The primary action (where to deliver)
/// is in the bottom sheet where the thumb naturally rests.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
        ),
        child: _MenuButton(onTap: onMenuTap),
      ),
    );
  }
}

/// Frosted-glass circle menu button.
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.menu_rounded,
          size: AppSpacing.iconLg,
          color: AppColors.dark,
        ),
      ),
    );
  }
}
