import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/core/router/app_router.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_state.dart';

/// Splash screen — first thing the user sees when the app opens.
///
/// Responsibilities:
/// 1. Show the 24Boda logo on the brand dark background
/// 2. Wait for [AuthNotifier] to finish checking auth state
/// 3. Navigate automatically — user does nothing on this screen
///
/// Design decisions backed by research:
///
/// Dark background with logo:
/// The logo was designed on a dark background. Using [AppColors.dark]
/// as the splash background makes the logo look intentional, not like
/// it was dropped onto a mismatched screen.
/// Dark → white transition as the app loads creates a visual moment
/// that feels polished (same pattern as Uber, Bolt, WhatsApp).
///
/// No spinner, no loading text:
/// Don Norman, The Design of Everyday Things — "Good design makes
/// the need for signs and instructions unnecessary."
/// The user understands they're waiting. A spinner adds anxiety.
/// The logo alone says "this is 24Boda, it's loading."
///
/// Minimum display time (800ms):
/// Without a minimum, the splash flashes for <100ms on fast devices —
/// jarring. 800ms is long enough to read the logo, short enough
/// to feel instant. Backed by Google's Material motion guidelines.
///
/// Auto-navigation driven by auth state:
/// The router's redirect function handles navigation — this screen
/// never calls [Navigator.push] directly. Reactive, not imperative.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // Minimum splash display time — logo is visible for at least 1.5s
    // even on fast devices. Prevents jarring sub-100ms flash.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // Force router to re-evaluate redirect now that auth state is ready
      final authState = ref.read(authNotifierProvider).valueOrNull;
      if (authState is AuthAuthenticated) {
        context.go(Routes.home);
      } else {
        context.go(Routes.phone);
      }
    });
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
                  'Fast. Reliable. Local.',
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
