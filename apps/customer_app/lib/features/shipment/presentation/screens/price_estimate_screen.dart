import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_notifier.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_state.dart';
import 'package:customer_app/features/shipment/presentation/widgets/shipment_step_indicator.dart';

class PriceEstimateScreen extends ConsumerWidget {
  const PriceEstimateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shipmentCreationProvider);
    if (state is! ShipmentCreationQuoteAvailable) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final quote = state.quote;
    final price = quote.price;
    final distanceKm = quote.routeDistanceMeters / 1000;
    final durationMinutes = (quote.routeDurationSeconds / 60).ceil();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Delivery price', style: AppTypography.headlineMedium),
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
                    const ShipmentStepIndicator(currentStep: 3),
                    const SizedBox(height: AppSpacing.xl),
                    _RouteCard(
                      pickupAddress: quote.pickup.address,
                      dropoffAddress: quote.dropoff.address,
                      distanceKm: distanceKm,
                      durationMinutes: durationMinutes,
                      packageLabel: state.packageSize.label,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PriceCard(
                      subtotalUgx: price.subtotalUgx,
                      discountUgx: price.discountUgx,
                      taxUgx: price.taxUgx,
                      totalUgx: price.customerTotalUgx,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuoteValidityCard(expiresAt: quote.expiresAt),
                  ],
                ),
              ),
            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTypography.titleLarge),
                      Text(
                        CurrencyFormatter.format(
                          price.customerTotalUgx.toDouble(),
                        ),
                        style: AppTypography.price,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const BodaButton(
                    label: 'Delivery confirmation coming next',
                    onPressed: null,
                    icon: Icons.lock_clock_rounded,
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

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.packageLabel,
  });

  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int durationMinutes;
  final String packageLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppSpacing.cardRadius,
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      children: [
        _RouteRow(label: 'From', address: pickupAddress, isPickup: true),
        const Divider(height: AppSpacing.lg),
        _RouteRow(label: 'To', address: dropoffAddress, isPickup: false),
        const Divider(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _InfoChip(label: DistanceFormatter.format(distanceKm)),
            _InfoChip(label: DistanceFormatter.formatDuration(durationMinutes)),
            _InfoChip(label: packageLabel),
          ],
        ),
      ],
    ),
  );
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.label,
    required this.address,
    required this.isPickup,
  });

  final String label;
  final String address;
  final bool isPickup;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
        color: isPickup ? AppColors.primary : AppColors.dark,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall),
            Text(
              address,
              style: AppTypography.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
  );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.subtotalUgx,
    required this.discountUgx,
    required this.taxUgx,
    required this.totalUgx,
  });

  final int subtotalUgx;
  final int discountUgx;
  final int taxUgx;
  final int totalUgx;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: AppSpacing.cardRadius,
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      children: [
        _PriceRow(label: 'Delivery price', amountUgx: subtotalUgx),
        if (discountUgx > 0)
          _PriceRow(label: 'Discount', amountUgx: -discountUgx),
        if (taxUgx > 0) _PriceRow(label: 'Tax', amountUgx: taxUgx),
        const Divider(height: AppSpacing.lg),
        _PriceRow(label: 'Total', amountUgx: totalUgx, emphasized: true),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amountUgx,
    this.emphasized = false,
  });

  final String label;
  final int amountUgx;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTypography.titleLarge
        : AppTypography.bodyMedium;
    final prefix = amountUgx < 0 ? '- ' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '$prefix${CurrencyFormatter.format(amountUgx.abs().toDouble())}',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _QuoteValidityCard extends StatelessWidget {
  const _QuoteValidityCard({required this.expiresAt});
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final expiryTime = TimeOfDay.fromDateTime(
      expiresAt.toLocal(),
    ).format(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This fixed price is reserved until $expiryTime.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}
