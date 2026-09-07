import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

/// Reusable step indicator for the shipment creation flow.
///
/// Shows "2/3  Details" — compact, no noise, one focal point.
/// Used on every screen in the 3-step booking flow for uniformity.
///
/// Why a shared widget and not duplicated per screen?
/// Nielsen heuristic #4: consistency and standards.
/// The same component must look and behave identically across
/// all screens. Duplicating it means two things to maintain —
/// they will inevitably drift apart over time. One widget = one truth.
class ShipmentStepIndicator extends StatelessWidget {
  const ShipmentStepIndicator({super.key, required this.currentStep});

  final int currentStep;
  static const int totalSteps = 3;

  String get _stepLabel => switch (currentStep) {
    1 => 'Address',
    2 => 'Details',
    _ => 'Price',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Fraction — only the current number is orange, slash and total muted
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$currentStep',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: '/$totalSteps',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Step name — dark, not orange
        Text(
          _stepLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
