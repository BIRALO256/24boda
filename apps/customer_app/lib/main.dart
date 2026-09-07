import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');
  if (kIsWeb && recaptchaSiteKey.isEmpty) {
    throw StateError(
      'RECAPTCHA_V3_SITE_KEY is required for Firebase App Check on web.',
    );
  }
  await FirebaseAppCheck.instance.activate(
    webProvider: kIsWeb ? ReCaptchaV3Provider(recaptchaSiteKey) : null,
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );

  runApp(const ProviderScope(child: CustomerApp()));
}
