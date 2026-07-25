import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';

/// Floating top bar on the home screen.
///
/// Design decisions backed by research:
///
/// Floating (not a standard AppBar):
/// The bar floats over the map with a semi-transparent background.
/// This keeps the map visible at all times — the map IS the content,
/// not a background decoration. (Nielsen Norman: don't hide the content
/// that users came to see.)
///
/// Semi-transparent blur background:
/// Creates depth — the bar feels layered above the map rather than
/// pasted on top. Same pattern used by Google Maps, Uber, Bolt.
///
/// Left: hamburger menu. Right: notifications + avatar:
/// F-pattern reading — users scan left first. The menu (less used)
/// is on the left. The avatar and notifications (frequently tapped)
/// are on the right where the thumb naturally rests.
///
/// Shows user's name when available:
/// Personalisation increases engagement. "Hi, Jovic" vs "Hi there"
/// creates a human connection. Backed by BJ Fogg's persuasive
/// technology research — personal relevance increases action.
class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = _extractFirstName(user?.name ?? '');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Menu button — frosted glass circle
            _TopBarButton(
              icon: Icons.menu_rounded,
              onTap: () {
                // TODO: open side drawer in future step
              },
            ),

            const SizedBox(width: AppSpacing.sm),

            // Greeting — personalised when name is available
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstName.isNotEmpty ? 'Hi, $firstName 👋' : 'Hi there 👋',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.dark,
                    ),
                  ),
                  Text(
                    'Where to today?',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Notifications button
            _TopBarButton(
              icon: Icons.notifications_outlined,
              onTap: () {
                // TODO: notifications screen in future step
              },
            ),

            const SizedBox(width: AppSpacing.sm),

            // Avatar — shows first letter of name or person icon
            _AvatarButton(
              initial: firstName.isNotEmpty ? firstName[0].toUpperCase() : null,
              onTap: () {
                // TODO: profile screen in future step
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Extracts the first word from a full name.
  /// "Jovic Biralo" → "Jovic"
  /// "" → ""
  String _extractFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(' ').first;
  }
}

/// A frosted-glass circle button used in the top bar.
/// Reusable for menu, notifications, and any future top bar action.
class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: AppSpacing.iconMd,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

/// Avatar button — shows the user's initial or a default person icon.
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.onTap,
    this.initial,
  });

  final VoidCallback onTap;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: initial != null ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: initial != null
              ? Text(
                  initial!,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Icon(
                  Icons.person_outline_rounded,
                  size: AppSpacing.iconMd,
                  color: AppColors.textSecondary,
                ),
        ),
      ),
    );
  }
}
