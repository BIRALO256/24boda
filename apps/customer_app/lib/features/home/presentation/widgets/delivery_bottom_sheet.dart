import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/home/presentation/providers/location_provider.dart';

/// The draggable bottom sheet on the home screen.
///
/// Design decisions backed by research:
///
/// Draggable sheet (not a fixed panel):
/// DraggableScrollableSheet allows the user to expand for more options
/// or collapse to see more of the map. This follows the progressive
/// disclosure principle — show the minimum needed, let the user ask for more.
///
/// Three snap points: 0.12 (collapsed), 0.45 (default), 0.85 (expanded):
/// - 0.12: collapsed — just the drag handle visible, max map visibility
/// - 0.45: default — pickup address + "Where to deliver?" CTA visible
/// - 0.85: expanded — recent deliveries visible, keyboard-ready for input
///
/// Why 0.45 as the default (not 0.3 or 0.6)?
/// Thumb zone research (Steven Hoober) — at 0.45 height, the primary
/// action button sits at exactly the right-thumb sweet spot on a
/// standard 6-inch phone. Users tap it without adjusting their grip.
///
/// "Where to deliver?" as the single primary action:
/// Miller's Law — 7±2 items max in working memory. One CTA = zero
/// cognitive load. The user knows exactly what to do.
///
/// Pickup auto-filled from GPS:
/// Don't Make Me Think (Krug) — pre-fill what you know.
/// Showing the current address reduces friction to zero for the first field.
/// User only needs to fill in the destination.
class DeliveryBottomSheet extends ConsumerWidget {
  const DeliveryBottomSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider).valueOrNull;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.bottomSheetRadius,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A1A1A2E),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          // The handle is an affordance signal (Norman) — it communicates
          // "this panel can be dragged". Without it users don't discover
          // the expand/collapse functionality.
          const _DragHandle(),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),

                // ── Pickup location ────────────────────────────────────────
                _SectionLabel(label: 'Deliver from'),
                const SizedBox(height: AppSpacing.sm),

                _PickupLocationTile(locationState: locationState),

                const SizedBox(height: AppSpacing.md),

                // ── Primary CTA — where to deliver ────────────────────────
                _WhereToDeliverButton(
                  onTap: () {
                    // TODO: navigate to address search screen in Step 8
                    // (shipment creation feature)
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Recent deliveries ──────────────────────────────────────
                // Recognition over recall (Norman) — showing past destinations
                // means users don't have to remember or retype addresses.
                // Only visible when sheet is expanded.
                _SectionLabel(label: 'Recent deliveries'),
                const SizedBox(height: AppSpacing.sm),

                const _RecentDeliveriesPlaceholder(),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey drag handle at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: AppSpacing.fullRadius,
          ),
        ),
      ),
    );
  }
}

/// Small section label.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Shows the current GPS-detected pickup address.
/// Tappable — lets the user change the pickup location.
class _PickupLocationTile extends StatelessWidget {
  const _PickupLocationTile({required this.locationState});

  final dynamic locationState;

  @override
  Widget build(BuildContext context) {
    final address = locationState is LocationLoaded
        ? (locationState as LocationLoaded).location.address
        : null;

    return GestureDetector(
      onTap: () {
        // TODO: navigate to pickup address search in Step 8
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.inputRadius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Orange pin icon — matches the brand and indicates "from here"
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: locationState is LocationLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Getting your location...',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address ?? 'Your current location',
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (address != null)
                          Text(
                            'Tap to change pickup',
                            style: AppTypography.labelSmall,
                          ),
                      ],
                    ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: AppSpacing.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}

/// The primary "Where to deliver?" CTA button.
///
/// Styled as a search field — communicates "tap and type your destination."
/// Orange background on the icon differentiates it from the pickup tile above.
class _WhereToDeliverButton extends StatelessWidget {
  const _WhereToDeliverButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppSpacing.inputRadius,
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.background,
                size: AppSpacing.iconMd,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Text(
                'Where to deliver?',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: AppSpacing.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for recent deliveries list.
/// Replaced with real data when shipment history is built in Step 9.
class _RecentDeliveriesPlaceholder extends StatelessWidget {
  const _RecentDeliveriesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlaceholderTile(
          icon: Icons.access_time_rounded,
          label: 'Owino Market',
          sublabel: 'Kampala, Uganda',
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlaceholderTile(
          icon: Icons.access_time_rounded,
          label: 'Kampala Road',
          sublabel: 'Kampala, Uganda',
        ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppSpacing.iconMd, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.titleSmall),
              Text(sublabel, style: AppTypography.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}
