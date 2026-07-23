import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/core/router/app_router.dart';

/// The root widget of the 24Boda Customer App.
///
/// Responsibilities:
/// - Reads the [routerProvider] to get the configured [GoRouter]
/// - Applies [AppTheme.light] as the app-wide theme
/// - Wires [MaterialApp.router] so go_router controls navigation
///
/// Why [ConsumerWidget] and not [StatelessWidget]?
/// We need to read [routerProvider] from Riverpod.
/// [ConsumerWidget] gives us access to [WidgetRef] via the [build] method.
///
/// Why is the theme applied here and not in [main]?
/// Theme belongs to the app widget, not the bootstrap.
/// [main] only knows about Riverpod and Flutter engine setup —
/// it has no business knowing what color the buttons are.
class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // App identity
      title: '24Boda',
      debugShowCheckedModeBanner: false,

      // 24Boda design system — all colors, fonts, component styles
      theme: AppTheme.light,

      // go_router wires navigation declaratively
      routerConfig: router,
    );
  }
}
