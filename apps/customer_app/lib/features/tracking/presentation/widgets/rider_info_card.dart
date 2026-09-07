import 'package:flutter/material.dart';
import 'package:core_models/core_models.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

/// Bottom card showing rider details during active delivery.
///
/// Contains:
/// - Rider name and vehicle plate
/// - Star rating
/// - Phone call button (calls the rider directly)
///
/// Design decisions:
///
/// Card anchored to the bottom of the screen:
/// Thumb zone research (Hoober) — bottom 40% of screen is where
/// the thumb naturally rests. The call button must be reachable
/// with one hand since the user may be holding a phone while
/// waiting for their package. Bottom positioning = zero stretch.
///
/// Call button prominent and orange:
/// Von Restorff effect — the one colored element stands out.
/// Calling the rider is the highest-value action when something
/// goes wrong (rider can't find the location, etc.)
///
/// Rider rating shown:
/// Social proof (Cialdini) — seeing the rider has a 4.8 rating
/// reduces anxiety during the wait. "Someone good is coming."
class RiderInfoCard extends StatelessWidget {
  const RiderInfoCard({super.key, required this.rider, required this.shipment});

  final UserProfile rider;
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppSpacing.fullRadius,
              ),
            ),
          ),

          // ── Rider row ──────────────────────────────────────────────────
          Row(
            children: [
              // Avatar
              Container(
                width: AppSpacing.avatarMd,
                height: AppSpacing.avatarMd,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rider.name.isNotEmpty ? rider.name[0].toUpperCase() : '?',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Name + vehicle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.name.isNotEmpty ? rider.name : 'Your rider',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.two_wheeler_rounded,
                          size: AppSpacing.iconMd,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('Boda Boda', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),

              // Call button
              GestureDetector(
                onTap: () {
                  // TODO: launch phone call with url_launcher
                  // url_launcher: tel:${rider.phone}
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: AppColors.background,
                    size: AppSpacing.iconMd,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Delivery summary ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.location_on_rounded,
                  label: 'Delivering to',
                  value: shipment.dropoff.address,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.payments_outlined,
                  label: 'Delivery fee',
                  value: CurrencyFormatter.format(shipment.price.effectiveFee),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.iconMd, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall),
              Text(
                value,
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
}
