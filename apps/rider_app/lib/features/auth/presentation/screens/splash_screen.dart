import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/theme.dart';

import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _initSplash();
  }

  Future<void> _initSplash() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 800)),
      _waitForAuthResolved(),
    ]);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is AuthAuthenticated) {
      context.go(Routes.home);
    } else {
      context.go(Routes.phone);
    }
  }

  Future<void> _waitForAuthResolved() async {
    const timeout = Duration(seconds: 8);
    const checkInterval = Duration(milliseconds: 150);
    var elapsed = Duration.zero;

    while (elapsed < timeout) {
      // Wait until the AsyncNotifier build() completes (not loading anymore)
      // AND the resulting state is not AuthInitial
      final asyncValue = ref.read(authNotifierProvider);

      // Still loading — build() hasn't completed yet
      if (asyncValue.isLoading) {
        await Future.delayed(checkInterval);
        elapsed += checkInterval;
        continue;
      }

      // build() completed — check the resulting state
      final authState = asyncValue.valueOrNull;
      if (authState != null && authState is! AuthInitial) return;

      await Future.delayed(checkInterval);
      elapsed += checkInterval;
    }
    // Timeout — navigate anyway
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'packages/theme/assets/images/logo.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Rider App',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.background.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
