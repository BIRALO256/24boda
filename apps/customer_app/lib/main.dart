import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Bootstrap entry point for the 24Boda Customer App.
///
/// Responsibilities of main():
/// 1. Ensure Flutter engine is fully initialised before any async work
/// 2. Wrap the entire app in [ProviderScope] — required by Riverpod
/// 3. Hand off to [CustomerApp] for all UI and routing
///
/// Nothing else belongs here. Business logic, Firebase initialisation,
/// and routing all live in [CustomerApp] and its dependencies.
/// Keeping main() to ~10 lines makes it instantly readable.
void main() {
  // Required when calling any Flutter service before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is the Riverpod dependency injection container.
    // It must wrap the entire widget tree — nothing above it can
    // use Riverpod providers.
    const ProviderScope(
      child: CustomerApp(),
    ),
  );
}
