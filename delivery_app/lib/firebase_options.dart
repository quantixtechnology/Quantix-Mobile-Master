// GENERATED FILE — do not edit manually.
// Run: flutterfire configure --project=<your-firebase-project-id>
// This file is git-ignored. Each tenant gets its own google-services.json
// and a regenerated firebase_options.dart before building.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for $defaultTargetPlatform');
    }
  }

  // ── Replace these values after running: flutterfire configure ────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
    iosBundleId: 'com.quantix.delivery',
  );
}
