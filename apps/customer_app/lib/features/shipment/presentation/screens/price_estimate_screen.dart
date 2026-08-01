import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_notifier.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_state.dart';
import 'package:customer_app/features/shipment/presentation/screens/searching_rider_screen.dart';

/// Screen 3 — Price estimate and booking confirmation.
///
/// Shows the full breakdown before the user commits.
/// No surprises at payment — transparency builds trust.
///
/// UX decisions:
/// - Full price breakdown shown (base + distance + size + surge)
/// - "Book Delivery" is the only primary action — one decision to make
/// - Editing pickup/dropoff links back to previous screens
/// - Surge pricing shown clearly when active — honesty over hiding it
class PriceEstimateScreen extends ConsumerWidget {
  const PriceEstimateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shipmentCreationProvider);

    // Guard — only render when details are entered
    if (state is! ShipmentCreationDetailsEntered) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isSubmitting = ref.watch(shipmentCreationProvider)
        is ShipmentCreationSubmitting;

    // Navigate to searching screen when shipment is created
    ref.listen<ShipmentCreationState>(shipmentCreationProvider, (_, next) {
      if (next is ShipmentCreationSearching) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SearchingRiderScreen(
              shipmentId: next.shipment.id,
            ),
          ),
        );
      }
      if (next is ShipmentCreationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    final price = state.priceEstimate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Price estimate', style: AppTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step indicator
                    _StepIndicator(currentStep: 3),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Route summary card ───────────────────────────────
                    _RouteCard(state: state),

                    const SizedBox(height: AppSpacing.md),

                    // ── Price breakdown card ─────────────────────────────
                    _PriceBreakdownCard(state: state),

                    if (price.isSurge) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _SurgeBanner(),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // ── Sticky Book button ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total price prominent display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTypography.titleLarge),
                      Text(
                        CurrencyFormatter.format(price.estimatedFee),
                        style: AppTypography.price,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BodaButton(
                    label: 'Book Delivery',
                    onPressed: isSubmitting
                        ? null
                        : () => ref
                            .read(shipmentCreationProvider.notifier)
                            .confirmBooking(),
                    isLoading: isSubmitting,
                    icon: Icons.local_shipping_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step <= currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? AppSpacing.xs : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.divider,
                    borderRadius: AppSpacing.fullRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ['Address', 'Details', 'Price'][index],
                  style: AppTypography.labelSmall.copyWith(
                    color: step == currentStep
                        ? AppColors.primary
                        : AppColors.textDisabled,
                    fontWeight: step == currentStep
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.state});
  final ShipmentCreationDetailsEntered state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _RouteRow(
            icon: Icons.my_location_rounded,
            iconColor: AppColors.primary,
            label: 'From',
            address: state.pickup.address,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.smMd),
            child: Container(
              height: 20,
              width: 1.5,
              color: AppColors.divider,
            ),
          ),
          _RouteRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.dark,
            label: 'To',
            address: state.dropoff.address,
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(
                icon: Icons.straighten_rounded,
                label: DistanceFormatter.format(state.distanceKm),
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: DistanceFormatter.formatDuration(
                  state.estimatedDurationMinutes,
                ),
              ),
              _InfoChip(
                icon: Icons.inventory_2_outlined,
                label: state.packageSize.label,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: AppSpacing.iconMd),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall),
              Text(
                address,
                style: AppTypography.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.iconMd, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.bodyMedium),
      ],
    );
  }
}

class _PriceBreakdownCard extends StatelessWidget {
  const _PriceBreakdownCard({required this.state});
  final ShipmentCreationDetailsEntered state;

  @override
  Widget build(BuildContext context) {
    final p = state.priceEstimate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Price breakdown', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _PriceRow(label: 'Base rate', amount: p.baseRate),
          _PriceRow(label: 'Distance (${DistanceFormatter.format(state.distanceKm)})',
              amount: p.distanceCharge),
          if (p.sizeSurcharge > 0)
            _PriceRow(
              label: '${state.packageSize.label} surcharge',
              amount: p.sizeSurcharge,
            ),
          if (p.isSurge)
            _PriceRow(
              label: 'Peak hour surge (${((p.surgeMultiplier - 1) * 100).round()}%)',
              amount: p.estimatedFee - (p.estimatedFee / p.surgeMultiplier),
              isHighlight: true,
            ),
          const Divider(height: AppSpacing.lg),
          _PriceRow(
            label: 'Estimated total',
            amount: p.estimatedFee,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.isHighlight = false,
  });

  final String label;
  final double amount;
  final bool isBold;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? AppTypography.titleLarge
        : AppTypography.bodyMedium.copyWith(
            color: isHighlight ? AppColors.warning : null,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(CurrencyFormatter.formatCompact(amount), style: style),
        ],
      ),
    );
  }
}

class _SurgeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.warning, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Peak hour pricing is active. Prices return to normal after 9 AM and 8 PM.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}
