// File generated for Firebase project: gramin-seva-health
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCgz-Qc8enWJYgGAINIoLbxcukacLErPfo',
    appId: '1:704031253866:web:693865444bc90917c63113',
    messagingSenderId: '704031253866',
    projectId: 'gramin-seva-health',
    authDomain: 'gramin-seva-health.firebaseapp.com',
    storageBucket: 'gramin-seva-health.firebasestorage.app',
    measurementId: 'G-FCPXS9H6HR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgz-Qc8enWJYgGAINIoLbxcukacLErPfo',
    appId: '1:704031253866:web:693865444bc90917c63113',
    messagingSenderId: '704031253866',
    projectId: 'gramin-seva-health',
    authDomain: 'gramin-seva-health.firebaseapp.com',
    storageBucket: 'gramin-seva-health.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgz-Qc8enWJYgGAINIoLbxcukacLErPfo',
    appId: '1:704031253866:web:693865444bc90917c63113',
    messagingSenderId: '704031253866',
    projectId: 'gramin-seva-health',
    authDomain: 'gramin-seva-health.firebaseapp.com',
    storageBucket: 'gramin-seva-health.firebasestorage.app',
    iosBundleId: 'com.ruralcare.health',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgz-Qc8enWJYgGAINIoLbxcukacLErPfo',
    appId: '1:704031253866:web:693865444bc90917c63113',
    messagingSenderId: '704031253866',
    projectId: 'gramin-seva-health',
    authDomain: 'gramin-seva-health.firebaseapp.com',
    storageBucket: 'gramin-seva-health.firebasestorage.app',
  );
}
