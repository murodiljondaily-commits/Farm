import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Only Android is configured');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeT0p-djoyo72qFeoOuRVmDdybxSK-Wgc',
    appId: '1:3764155961:android:081ac42d9c3fe3f9feffe8',
    messagingSenderId: '3764155961',
    projectId: 'appag-499817-71026',
    storageBucket: 'appag-499817-71026.firebasestorage.app',
  );
}
