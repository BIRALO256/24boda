import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

/// Temporary placeholder screen for the rider app.
///
/// Same purpose as the customer app placeholder —
/// confirms boot, theme, and routing are wired correctly.
/// Replaced in Step 6 when real auth flow is built.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.appName,
  });

  final String appName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
      ),
      body: Padding(
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
                Icons.two_wheeler_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconHuge,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              appName,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Theme and routing are wired correctly.\nAuth feature coming in Step 6.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            ElevatedButton(
              onPressed: () {},
              child: const Text('App is ready'),
            ),

            const SizedBox(height: AppSpacing.md),

            OutlinedButton(
              onPressed: () {},
              child: const Text('Step 6: Auth coming next'),
            ),

            const SizedBox(height: AppSpacing.xl),

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

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
  });

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
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
