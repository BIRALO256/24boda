import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_models/core_models.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/features/jobs/presentation/providers/job_request_provider.dart';

/// Job request modal — slides up when a new delivery job is available.
///
/// Design decisions backed by research:
///
/// Bottom sheet (not full screen):
/// The map stays visible behind the modal. The rider can see
/// where the pickup is relative to their position before deciding.
/// Spatial context reduces decision anxiety (Norman).
///
/// 30-second countdown timer:
/// Bolt uses 15s, Uber uses 15-20s, SafeBoda uses 30s.
/// We use 30s because Uganda's network latency can be higher —
/// giving the rider time to read and decide without network pressure.
/// The Zeigarnik effect: a visible countdown creates urgency
/// that drives action without feeling forced.
///
/// Accept large (full width), Decline small (outlined):
/// Fitts's Law — primary action gets largest touch target.
/// Accepting is the rider's job. Declining should be deliberate
/// and slightly harder to tap — not a thumb-slip away from the
/// Accept button.
///
/// Show earnings prominently:
/// The rider's primary motivation is money. Showing "You'll earn
/// UGX 4,400" before they decide converts more acceptances than
/// showing the fee the customer pays.
///
/// Auto-decline on timer expiry:
/// Industry standard. Keeps the platform responsive for customers.
/// A job that nobody accepts within 30s is re-broadcast to other
/// nearby riders.
class JobRequestModal extends ConsumerStatefulWidget {
  const JobRequestModal({
    super.key,
    required this.shipment,
  });

  final Shipment shipment;

  @override
  ConsumerState<JobRequestModal> createState() => _JobRequestModalState();
}

class _JobRequestModalState extends ConsumerState<JobRequestModal> {
  static const int _timerSeconds = 30;
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _timerSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          // Auto-decline when timer expires
          ref.read(jobRequestProvider.notifier).declineJob();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobRequestProvider);
    final isAccepting = jobState is JobRequestAccepting;
    final price = widget.shipment.price;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.bottomSheetRadius,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppSpacing.fullRadius,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Header row: title + countdown ───────────────────────────
          Row(
            children: [
              Text(
                'New delivery request',
                style: AppTypography.headlineSmall,
              ),
              const Spacer(),
              // Countdown timer — orange when urgent (< 10s)
              _CountdownBadge(remainingSeconds: _remainingSeconds),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Route card ───────────────────────────────────────────────
          _RouteCard(shipment: widget.shipment),

          const SizedBox(height: AppSpacing.md),

          // ── Earnings highlight ───────────────────────────────────────
          // Show what the RIDER earns, not the customer fee.
          // Their motivation is earnings, not the customer's cost.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You\'ll earn', style: AppTypography.labelSmall),
                    Text(
                      CurrencyFormatter.format(
                        price.estimatedFee * 0.80,
                      ),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Distance', style: AppTypography.labelSmall),
                    Text(
                      DistanceFormatter.format(widget.shipment.distanceKm),
                      style: AppTypography.titleLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Accept button (large, green, full width) ─────────────────
          BodaButton(
            label: 'Accept',
            onPressed: isAccepting
                ? null
                : () => ref
                    .read(jobRequestProvider.notifier)
                    .acceptJob(widget.shipment.id),
            isLoading: isAccepting,
            icon: Icons.check_rounded,
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Decline button (small, outlined, less prominent) ─────────
          BodaButton(
            label: 'Decline',
            onPressed: isAccepting
                ? null
                : () =>
                    ref.read(jobRequestProvider.notifier).declineJob(),
            variant: BodaButtonVariant.outlined,
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

/// Countdown badge — turns orange when < 10 seconds remain.
/// Color change signals increasing urgency without being alarming.
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.remainingSeconds});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.warningSurface : AppColors.surface,
        borderRadius: AppSpacing.chipRadius,
        border: Border.all(
          color: isUrgent ? AppColors.warning : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: AppSpacing.iconMd,
            color: isUrgent ? AppColors.warning : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            DateFormatter.countdown(
              Duration(seconds: remainingSeconds),
            ),
            style: AppTypography.labelLarge.copyWith(
              color: isUrgent ? AppColors.warning : AppColors.dark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Route card showing pickup → dropoff with package size.
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.shipment});

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
      child: Column(
        children: [
          // Pickup
          _RouteRow(
            icon: Icons.my_location_rounded,
            color: AppColors.primary,
            label: 'Pick up from',
            address: shipment.pickup.address,
          ),
          // Connector line
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.smMd),
            child: Container(
              height: 20,
              width: 1.5,
              color: AppColors.divider,
            ),
          ),
          // Dropoff
          _RouteRow(
            icon: Icons.location_on_rounded,
            color: AppColors.dark,
            label: 'Deliver to',
            address: shipment.dropoff.address,
          ),

          if (shipment.packageSize != null) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: AppSpacing.iconMd,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${shipment.packageSize![0].toUpperCase()}${shipment.packageSize!.substring(1)} package',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                Text(
                  DistanceFormatter.formatDuration(
                    shipment.estimatedDurationMinutes,
                  ),
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: AppSpacing.iconMd),
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
