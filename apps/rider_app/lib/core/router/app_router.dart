import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rider_app/features/placeholder/placeholder_screen.dart';

/// Route name constants for the rider app.
abstract final class Routes {
  /// Temporary placeholder — replaced by splash/auth routes in Step 6.
  static const String home = '/';
}

/// The rider app's router.
///
/// Mirrors the customer app's router structure exactly.
/// Auth guard and real routes added in Step 6.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true, // Remove in production
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const PlaceholderScreen(
          appName: '24Boda Rider',
        ),
      ),
    ],
  );
});
