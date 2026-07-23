import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:customer_app/features/placeholder/placeholder_screen.dart';

/// Route name constants.
///
/// Always use these constants instead of raw strings.
/// Same principle as [FirestoreCollections] — typos fail silently
/// with raw strings, fail loudly at compile time with constants.
abstract final class Routes {
  /// Temporary placeholder — replaced by splash/auth routes in Step 6.
  static const String home = '/';
}

/// The customer app's router.
///
/// Provided via Riverpod so any widget can access it with:
/// ```dart
/// final router = ref.watch(routerProvider);
/// ```
///
/// Why go_router over Navigator 2.0 directly?
/// - Declarative URL-based routing — every screen has a URL
/// - Deep link support out of the box
/// - Redirect logic for auth guards is clean and centralised
/// - Industry standard for Flutter production apps
///
/// Auth guard will be added in Step 6 (auth feature).
/// For now the router simply boots to the placeholder screen.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true, // Remove in production
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const PlaceholderScreen(
          appName: '24Boda Customer',
        ),
      ),
    ],
  );
});
