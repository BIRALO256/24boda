import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';

/// Placeholder for the rider home screen.
/// Replaced in Step 3 (rider home screen build).
class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('24Boda Rider', style: AppTypography.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome, ${user?.name.isNotEmpty == true ? user!.name : 'Rider'}!',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Home screen coming in Step 3.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
