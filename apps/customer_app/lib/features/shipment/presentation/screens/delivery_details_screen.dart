import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_notifier.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_state.dart';
import 'package:customer_app/features/shipment/presentation/screens/price_estimate_screen.dart';

/// Screen 2 of the shipment creation flow.
///
/// The user selects the package size and optionally adds a description
/// and a note to the rider.
///
/// UX decisions backed by research:
///
/// Card-based size picker (not a dropdown):
/// Baymard Institute: dropdowns for 4 options have 40% higher error rate
/// than visual card selectors. All 4 options visible at once = zero
/// extra taps, zero "did I select the right thing?" anxiety.
///
/// Selected card gets orange border + checkmark:
/// Clear affordance (Norman). The selection state is unambiguous.
/// Users never wonder "did my tap register?"
///
/// Optional fields collapsed behind "Add more details" toggle:
/// Progressive disclosure — most users don't need these fields.
/// Showing them by default adds visual noise and increases form
/// abandonment. Power users who need them can expand.
///
/// "Get Price" button disabled until size is selected:
/// Nielsen heuristic #5: error prevention. Block invalid submission
/// before it happens. Don't show an error after the fact.
///
/// Single screen, no sub-navigation:
/// All details collected in one scroll — no page-flipping between
/// "size" and "description" sub-steps. Reduces friction.
class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  const DeliveryDetailsScreen({super.key});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState
    extends ConsumerState<DeliveryDetailsScreen> {
  PackageSize? _selectedSize;
  bool _showOptionalFields = false;
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selectedSize == null) return;

    ref.read(shipmentCreationProvider.notifier).onDetailsEntered(
          packageSize: _selectedSize!,
          packageDescription: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          customerNote: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PriceEstimateScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentCreationProvider);

    // If state regressed (user went back), pop this screen
    if (state is! ShipmentCreationAddressPicked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && state is ShipmentCreationIdle) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Package details',
          style: AppTypography.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Step indicator ───────────────────────────────────
                    _StepIndicator(currentStep: 2),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Section label ────────────────────────────────────
                    Text(
                      'What are you sending?',
                      style: AppTypography.headlineSmall,
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Select the size that best describes your package.',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Package size picker ──────────────────────────────
                    // 2x2 grid of size cards — all options visible at once
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 1.4,
                      children: PackageSize.values
                          .map((size) => _SizeCard(
                                size: size,
                                isSelected: _selectedSize == size,
                                onTap: () => setState(
                                  () => _selectedSize = size,
                                ),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Optional fields toggle ───────────────────────────
                    GestureDetector(
                      onTap: () => setState(
                        () => _showOptionalFields = !_showOptionalFields,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showOptionalFields
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppColors.primary,
                            size: AppSpacing.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _showOptionalFields
                                ? 'Hide extra details'
                                : 'Add more details (optional)',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Optional fields ──────────────────────────────────
                    if (_showOptionalFields) ...[
                      const SizedBox(height: AppSpacing.lg),

                      // Package description
                      BodaTextField(
                        controller: _descriptionController,
                        label: 'What\'s in the package?',
                        hint: 'e.g. Laptop, documents, food',
                        prefixIcon: Icons.inventory_2_outlined,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Note to rider
                      BodaTextField(
                        controller: _noteController,
                        label: 'Note to rider',
                        hint: 'e.g. Call me when you arrive',
                        prefixIcon: Icons.note_outlined,
                        textInputAction: TextInputAction.done,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom CTA ────────────────────────────────────────
            // Positioned outside the scroll area so it's always visible.
            // Nielsen heuristic: primary action should always be accessible.
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: BodaButton(
                label: 'Get Price',
                onPressed: _selectedSize != null ? _onContinue : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

/// Step progress indicator — shows the user where they are in the flow.
///
/// Why show steps?
/// Nielsen heuristic #1: visibility of system status.
/// Users who can see their progress are 30% less likely to abandon
/// a multi-step form (Baymard Institute).
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;
  static const int totalSteps = 3; // address → details → price

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < totalSteps - 1 ? AppSpacing.xs : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: AppSpacing.fullRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  switch (stepNumber) {
                    1 => 'Address',
                    2 => 'Details',
                    _ => 'Price',
                  },
                  style: AppTypography.labelSmall.copyWith(
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textDisabled,
                    fontWeight: isCurrent
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

/// A tappable package size card.
///
/// Design:
/// - Unselected: light grey background, grey border
/// - Selected: light orange background, orange border, checkmark
///
/// The checkmark + color change together provide two distinct signals
/// of selection — redundant coding (Norman) — ensuring users with
/// color vision deficiency can also see the selection clearly.
class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final PackageSize size;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (size) {
        PackageSize.small => Icons.mail_outline_rounded,
        PackageSize.medium => Icons.inventory_2_outlined,
        PackageSize.large => Icons.luggage_rounded,
        PackageSize.fragile => Icons.broken_image_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.smMd),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row — icon + checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: AppSpacing.iconLg,
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: AppSpacing.iconMd,
                  ),
              ],
            ),

            // Label + description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  size.label,
                  style: AppTypography.titleSmall.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.dark,
                  ),
                ),
                Text(
                  size.description,
                  style: AppTypography.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
