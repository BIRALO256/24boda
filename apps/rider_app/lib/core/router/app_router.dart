import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_state.dart';
import 'package:rider_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:rider_app/features/auth/presentation/screens/phone_screen.dart';
import 'package:rider_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:rider_app/features/home/presentation/screens/rider_home_screen.dart';

abstract final class Routes {
  static const String splash = '/';
  static const String phone = '/phone';
  static const String otp = '/otp';
  static const String home = '/home';
}

abstract final class RouteParams {
  static const String verificationId = 'verificationId';
  static const String phoneNumber = 'phoneNumber';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider).valueOrNull;
      final currentPath = state.uri.path;

      if (authState == null || authState is AuthInitial) {
        return currentPath == Routes.splash ? null : Routes.splash;
      }

      if (authState is AuthAuthenticated) {
        if (currentPath == Routes.home) return null;
        return Routes.home;
      }

      final authScreens = [Routes.splash, Routes.phone, Routes.otp];
      if (authScreens.contains(currentPath)) return null;
      return Routes.phone;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: Routes.phone,
        pageBuilder: (context, state) =>
            const MaterialPage(child: PhoneScreen()),
      ),
      GoRoute(
        path: Routes.otp,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final verificationId =
              extra?[RouteParams.verificationId] as String? ?? '';
          final phoneNumber =
              extra?[RouteParams.phoneNumber] as String? ?? '';
          return MaterialPage(
            child: OtpScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) =>
            const MaterialPage(child: RiderHomeScreen()),
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

extension AuthNavigation on BuildContext {
  void goToOtp({
    required String verificationId,
    required String phoneNumber,
  }) {
    go(Routes.otp, extra: {
      RouteParams.verificationId: verificationId,
      RouteParams.phoneNumber: phoneNumber,
    });
  }
}
