import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Bootstrap entry point for the 24Boda Customer App.
///
/// Order of operations matters here:
/// 1. [WidgetsFlutterBinding.ensureInitialized] — Flutter engine ready
/// 2. [Firebase.initializeApp] — Firebase ready before any widget builds
/// 3. [runApp] with [ProviderScope] — app starts with DI container
///
/// Why Firebase init here and not inside a widget?
/// Firebase must be initialised before ANY Firebase SDK call.
/// If it were inside a widget, there's a race condition where
/// Riverpod providers could try to use Firebase before it's ready.
/// Initialising in main() guarantees Firebase is always ready first.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: CustomerApp(),
    ),
  );
}
