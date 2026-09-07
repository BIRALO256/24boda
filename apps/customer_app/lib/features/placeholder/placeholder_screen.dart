import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

/// Temporary placeholder screen.
///
/// This screen exists only to confirm:
/// 1. The app boots without errors
/// 2. AppTheme is applied correctly (orange primary color, DM Sans font)
/// 3. ProviderScope and go_router are wired correctly
///
/// Replaced entirely in Step 6 (auth feature) when the real
/// splash → phone OTP → home flow is built.
///
/// How to verify the theme is working when you run the app:
/// - App bar should be white with dark text (not purple)
/// - "Open the app" button should be orange
/// - Font should look clean and geometric (DM Sans)
/// - Background should be pure white
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App icon placeholder
            Container(
              width: AppSpacing.avatarXl,
              height: AppSpacing.avatarXl,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconHuge,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // App name
            Text(
              appName,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Status message
            Text(
              'Theme and routing are wired correctly.\nAuth feature coming in Step 6.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Primary button — verifies AppTheme button styling
            ElevatedButton(onPressed: () {}, child: const Text('App is ready')),

            const SizedBox(height: AppSpacing.md),

            // Outlined button — verifies outlined button styling
            OutlinedButton(
              onPressed: () {},
              child: const Text('Step 6: Auth coming next'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Color swatches — quick visual check of the palette
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColorSwatch(color: AppColors.primary, label: 'Primary'),
                const SizedBox(width: AppSpacing.sm),
                _ColorSwatch(color: AppColors.dark, label: 'Dark'),
                const SizedBox(width: AppSpacing.sm),
                _ColorSwatch(color: AppColors.success, label: 'Success'),
                const SizedBox(width: AppSpacing.sm),
                _ColorSwatch(color: AppColors.error, label: 'Error'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small color swatch widget for visual theme verification.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppSpacing.cardRadius,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
