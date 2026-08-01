import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/shipment/domain/usecases/watch_shipment.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_notifier.dart';
import 'package:core_models/core_models.dart';

/// Screen 4 — Searching for a rider.
///
/// Shown after the shipment is created in Firestore.
/// Listens to the shipment document in real time.
/// Navigates automatically when a rider accepts.
///
/// UX decisions:
/// - Animated pulsing circle — communicates "actively searching"
///   without a progress bar that implies a known end time
/// - Cancel button available — respects user autonomy
/// - Clear status text — user always knows what's happening
/// - Estimated time shown — anchors expectation, reduces anxiety
class SearchingRiderScreen extends ConsumerWidget {
  const SearchingRiderScreen({
    super.key,
    required this.shipmentId,
  });

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real-time stream of the shipment document
    final shipmentAsync = ref.watch(shipmentStreamProvider(shipmentId));

    // React to status changes
    ref.listen(shipmentStreamProvider(shipmentId), (_, next) {
      next.whenData((shipment) {
        if (shipment.status == ShipmentStatus.accepted ||
            shipment.status.isActive) {
          // TODO: navigate to tracking screen in next step
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider found! Tracking screen coming next.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (shipment.status == ShipmentStatus.cancelled) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No riders found nearby. Please try again.'),
            ),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Animated search indicator ────────────────────────────────
              const _PulsingRiderSearch(),

              const SizedBox(height: AppSpacing.xl),

              // ── Status text ──────────────────────────────────────────────
              Text(
                'Looking for a rider',
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'We\'re finding the nearest available rider.\nThis usually takes under 3 minutes.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Shipment info ────────────────────────────────────────────
              shipmentAsync.when(
                data: (shipment) => _ShipmentSummaryCard(shipment: shipment),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Spacer(),

              // ── Cancel button ────────────────────────────────────────────
              BodaButton(
                label: 'Cancel',
                variant: BodaButtonVariant.outlined,
                onPressed: () async {
                  ref.read(shipmentCreationProvider.notifier).reset();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

/// Pulsing animation — communicates active searching without implying
/// a known completion time (which a linear progress bar would suggest).
class _PulsingRiderSearch extends StatefulWidget {
  const _PulsingRiderSearch();

  @override
  State<_PulsingRiderSearch> createState() => _PulsingRiderSearchState();
}

class _PulsingRiderSearchState extends State<_PulsingRiderSearch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            // Centre icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: AppColors.background,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentSummaryCard extends StatelessWidget {
  const _ShipmentSummaryCard({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
            size: AppSpacing.iconLg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivering to', style: AppTypography.labelSmall),
                Text(
                  shipment.dropoff.address,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
