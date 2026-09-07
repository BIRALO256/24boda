import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';

/// Side drawer for the customer home screen.
///
/// Contains everything that doesn't belong on the primary map view:
/// - User profile (name + phone)
/// - My Deliveries (history)
/// - Payment methods
/// - Settings
/// - Sign out
///
/// Why a drawer and not a bottom nav bar?
/// Bottom nav bars work for apps with 3-5 equally important sections.
/// 24Boda has ONE primary action (book delivery) — everything else
/// is secondary. A drawer keeps secondary actions accessible without
/// giving them equal visual weight to the primary action.
/// Same pattern used by Bolt and SafeBoda.
class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.displayName ?? '';
    final phone = user?.phoneE164 ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Drawer(
      backgroundColor: AppColors.background,
      width: MediaQuery.of(context).size.width * 0.80,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── User profile header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: AppSpacing.avatarLg,
                    height: AppSpacing.avatarLg,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Name + phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Welcome',
                          style: AppTypography.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(phone, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            const SizedBox(height: AppSpacing.sm),

            // ── Navigation items ─────────────────────────────────────────
            _DrawerItem(
              icon: Icons.delivery_dining_rounded,
              label: 'My Deliveries',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: navigate to history screen
              },
            ),

            _DrawerItem(
              icon: Icons.payment_rounded,
              label: 'Payment',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: navigate to payment screen
              },
            ),

            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: navigate to settings screen
              },
            ),

            _DrawerItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: navigate to support screen
              },
            ),

            const Spacer(),

            const Divider(height: 1),

            // ── Sign out ─────────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// A single drawer navigation item.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.dark;

    return ListTile(
      leading: Icon(icon, color: itemColor, size: AppSpacing.iconLg),
      title: Text(
        label,
        style: AppTypography.titleSmall.copyWith(color: itemColor),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
