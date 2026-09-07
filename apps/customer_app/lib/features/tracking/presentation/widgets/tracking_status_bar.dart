import 'package:flutter/material.dart';
import 'package:core_models/core_models.dart';
import 'package:theme/theme.dart';

/// Status bar shown at the top of the tracking screen.
///
/// Shows the current delivery status as a human-readable label
/// with a matching icon and color.
///
/// Design decision — top of screen, not bottom:
/// Status is informational — the user reads it, doesn't tap it.
/// Bottom of screen is reserved for action buttons (call rider).
/// Informational content belongs at the top where eyes go first
/// when looking for context. (F-pattern reading, Nielsen Norman)
class TrackingStatusBar extends StatelessWidget {
  const TrackingStatusBar({super.key, required this.status});

  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppSpacing.chipRadius,
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.iconColor, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.label,
            style: AppTypography.labelMedium.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(ShipmentStatus status) {
    return switch (status) {
      ShipmentStatus.accepted || ShipmentStatus.enRoutePickup => _StatusConfig(
        icon: Icons.two_wheeler_rounded,
        iconColor: AppColors.primary,
        textColor: AppColors.primary,
        backgroundColor: AppColors.primarySurface,
        borderColor: AppColors.primary,
      ),
      ShipmentStatus.pickedUp => _StatusConfig(
        icon: Icons.inventory_2_rounded,
        iconColor: AppColors.info,
        textColor: AppColors.info,
        backgroundColor: AppColors.infoSurface,
        borderColor: AppColors.info,
      ),
      ShipmentStatus.inTransit => _StatusConfig(
        icon: Icons.local_shipping_rounded,
        iconColor: AppColors.info,
        textColor: AppColors.info,
        backgroundColor: AppColors.infoSurface,
        borderColor: AppColors.info,
      ),
      ShipmentStatus.delivered => _StatusConfig(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        textColor: AppColors.success,
        backgroundColor: AppColors.successSurface,
        borderColor: AppColors.success,
      ),
      _ => _StatusConfig(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        borderColor: AppColors.divider,
      ),
    };
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
}
