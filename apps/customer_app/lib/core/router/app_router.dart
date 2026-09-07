import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_state.dart';
import 'package:customer_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/phone_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:customer_app/features/home/presentation/screens/home_screen.dart';

/// Route path constants.
///
/// Every route in the app is defined here as a constant.
/// Never use raw strings for navigation — a typo in a raw string
/// fails silently at runtime. A typo in a constant fails loudly
/// at compile time.
abstract final class Routes {
  /// Splash screen — shown on launch while auth state loads.
  static const String splash = '/';

  /// Phone number entry — first step of auth flow.
  static const String phone = '/phone';

  /// OTP verification — second step of auth flow.
  static const String otp = '/otp';

  /// Customer home — shown after successful authentication.
  static const String home = '/home';
}

/// Route parameter keys — used with [GoRouterState.extra].
abstract final class RouteParams {
  static const String verificationId = 'verificationId';
  static const String phoneNumber = 'phoneNumber';
}

/// The customer app's router with auth guard.
///
/// The auth guard (redirect function) is the single point of
/// access control for all routes. It runs before every navigation
/// and decides whether to allow or redirect based on [AuthState].
///
/// Auth guard logic:
/// ```
/// AuthInitial     → always show splash (auth still loading)
/// Unauthenticated → redirect to /phone (unless already there or on /otp)
/// OtpSent         → redirect to /otp (unless already there)
/// Authenticated   → redirect to /home (unless already there)
/// ```
///
/// Why put the guard in the router and not in each screen?
/// Single Responsibility — navigation logic lives in one place.
/// If you add a new authenticated screen, it's automatically
/// protected by the guard with zero additional code.
///
/// [refreshListenable] connects [AuthNotifier] to the router.
/// Every time auth state changes, go_router re-evaluates the
/// redirect function and navigates if needed.
final routerProvider = Provider<GoRouter>((ref) {
  // [GoRouterRefreshStream] is not needed here because we use
  // a [ChangeNotifier]-based listenable instead.
  // We create a simple [_AuthStateNotifier] that wraps Riverpod.
  final authNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,

    // ── Auth guard ──────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider).valueOrNull;
      final currentPath = state.uri.path;

      // Still loading — stay on splash
      if (authState == null || authState is AuthInitial) {
        return currentPath == Routes.splash ? null : Routes.splash;
      }

      // Authenticated — go to home
      if (authState is AuthAuthenticated) {
        if (currentPath == Routes.home) return null;
        return Routes.home;
      }

      // OTP sent — go to OTP screen
      if (authState is AuthOtpSent) {
        if (currentPath == Routes.otp) return null;
        return null; // OTP screen is pushed programmatically from phone screen
      }

      // Unauthenticated / error — go to phone screen
      final authScreens = [Routes.splash, Routes.phone, Routes.otp];
      if (authScreens.contains(currentPath)) return null;
      return Routes.phone;
    },

    // ── Routes ──────────────────────────────────────────────────────────
    routes: [
      // Splash — initial loading screen
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),

      // Phone number entry
      GoRoute(
        path: Routes.phone,
        pageBuilder: (context, state) =>
            const MaterialPage(child: PhoneScreen()),
      ),

      // OTP verification
      GoRoute(
        path: Routes.otp,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final verificationId =
              extra?[RouteParams.verificationId] as String? ?? '';
          final phoneNumber = extra?[RouteParams.phoneNumber] as String? ?? '';
          return MaterialPage(
            child: OtpScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          );
        },
      ),

      // Home — real home screen with Google Maps
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) =>
            const MaterialPage(child: HomeScreen()),
      ),
    ],
  );
});

/// A [ChangeNotifier] that listens to [AuthNotifier] via Riverpod
/// and notifies go_router to re-evaluate its redirect function.
///
/// Why this bridge class?
/// go_router's [refreshListenable] expects a [Listenable] (ChangeNotifier).
/// Riverpod providers are not Listenables. This bridge converts
/// Riverpod state changes into ChangeNotifier notifications.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Listen to auth state changes and notify the router
    ref.listen<AsyncValue<AuthState>>(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

/// Extension on [BuildContext] for cleaner navigation to OTP screen.
/// Usage: context.goToOtp(verificationId: id, phoneNumber: phone)
extension AuthNavigation on BuildContext {
  void goToOtp({required String verificationId, required String phoneNumber}) {
    go(
      Routes.otp,
      extra: {
        RouteParams.verificationId: verificationId,
        RouteParams.phoneNumber: phoneNumber,
      },
    );
  }
}
