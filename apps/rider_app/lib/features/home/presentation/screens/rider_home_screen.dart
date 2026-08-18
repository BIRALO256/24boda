import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:rider_app/features/home/presentation/providers/online_status_provider.dart';
import 'package:rider_app/features/home/presentation/widgets/online_toggle_button.dart';
import 'package:rider_app/features/home/presentation/widgets/rider_map_view.dart';

/// Rider home screen — the operational hub of the rider app.
///
/// Architecture — pure orchestrator:
/// This screen contains no business logic. It composes widgets,
/// listens to state, and coordinates providers.
/// Every visual element lives in its own file.
///
/// Layout — Stack:
/// Map fills 100% of the screen. Everything else floats on top.
/// Same pattern as the customer app — the map IS the content.
///
/// Status bar at the top:
/// Shows online/offline status clearly so the rider always knows
/// whether they are receiving jobs. Green = online, dark = offline.
/// Visibility of system status (Nielsen heuristic #1).
///
/// Online toggle at the bottom centre:
/// Thumb zone (Hoober) — most reachable position with one hand.
/// Large pill button — easy to tap even while handling the bike.
///
/// Earnings summary card (when online):
/// Shows today's earnings at a glance. Riders are motivated by
/// visible progress — showing earnings in real time increases
/// the time they stay online (operant conditioning, B.F. Skinner).
class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider);
    final user = ref.watch(currentUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── Layer 1: Full-screen map ─────────────────────────────────
            const Positioned.fill(
              child: RiderMapView(),
            ),

            // ── Layer 2: Top status bar ──────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      // Status pill
                      _StatusPill(isOnline: isOnline),

                      const Spacer(),

                      // Rider avatar + name
                      _RiderAvatar(
                        name: user?.name ?? '',
                        onTap: () {
                          // TODO: open rider profile/drawer in Step 5
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Layer 3: Bottom panel ────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Earnings card — only when online
                      if (isOnline) ...[
                        _EarningsCard(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Online/offline toggle — always visible
                      const Center(child: OnlineToggleButton()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

/// Status pill shown at top-left of the map.
/// Redundant coding — color + text + icon communicate state.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success : AppColors.dark,
        borderRadius: AppSpacing.chipRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.background
                  : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rider avatar button — top right, opens profile.
class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'R',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's earnings card — shown only when online.
/// Visible progress motivates riders to stay online longer.
class _EarningsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: AppColors.success,
            size: AppSpacing.iconLg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s earnings',
                style: AppTypography.labelSmall,
              ),
              Text(
                'UGX 0', // updated in earnings feature
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '0 trips',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
