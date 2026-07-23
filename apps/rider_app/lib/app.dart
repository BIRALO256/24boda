import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme/theme.dart';

import 'package:rider_app/core/router/app_router.dart';

/// The root widget of the 24Boda Rider App.
///
/// Mirrors the [CustomerApp] structure exactly.
/// Both apps share the same [AppTheme.light] from the theme package —
/// one design system, zero duplication.
class RiderApp extends ConsumerWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // App identity
      title: '24Boda Rider',
      debugShowCheckedModeBanner: false,

      // 24Boda design system — same theme as customer app
      theme: AppTheme.light,

      // go_router wires navigation declaratively
      routerConfig: router,
    );
  }
}
