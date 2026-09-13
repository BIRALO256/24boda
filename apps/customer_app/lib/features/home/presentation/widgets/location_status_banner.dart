import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/home/presentation/providers/location_provider.dart';

class LocationStatusBanner extends ConsumerWidget {
  const LocationStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationNotifierProvider).valueOrNull;
    return switch (state) {
      LocationLoading() => const _StatusCard(
        icon: Icons.location_searching_rounded,
        message: 'Finding your location…',
        showProgress: true,
      ),
      LocationLowAccuracy(:final accuracyMeters) => _StatusCard(
        icon: Icons.location_disabled_rounded,
        message:
            'Accuracy is about ${accuracyMeters.round()} m. Check the pin before booking.',
        actionLabel: 'Try again',
        onAction: () =>
            ref.read(locationNotifierProvider.notifier).fetchCurrentLocation(),
      ),
      LocationError(:final reason, :final message, :final actionLabel) =>
        _StatusCard(
          icon: Icons.location_off_rounded,
          message: message,
          actionLabel: actionLabel,
          onAction: () =>
              ref.read(locationNotifierProvider.notifier).recover(reason),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (showProgress)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppTypography.bodySmall)),
            if (actionLabel != null) ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
