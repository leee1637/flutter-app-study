import 'package:firebase_core/firebase_core.dart';
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCtnzPAkdRLfkyRq_XUexwvAdaDqeaWCYs',
    appId: '1:673632393241:web:7474351281bfcf6511b288',
    messagingSenderId: '673632393241',
    projectId: 'dz11-1c536',
    authDomain: 'dz11-1c536.firebaseapp.com',
    storageBucket: 'dz11-1c536.firebasestorage.app',
    measurementId: 'G-99J7YTNLWY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFJvAaEuf1avRX3tUdU1fJs0_fpdrP6ZA',
    appId: '1:673632393241:android:46ec78fd4f76de6411b288',
    messagingSenderId: '673632393241',
    projectId: 'dz11-1c536',
    storageBucket: 'dz11-1c536.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCtnzPAkdRLfkyRq_XUexwvAdaDqeaWCYs',
    appId: '1:673632393241:web:1d42b03ac0a60f5a11b288',
    messagingSenderId: '673632393241',
    projectId: 'dz11-1c536',
    authDomain: 'dz11-1c536.firebaseapp.com',
    storageBucket: 'dz11-1c536.firebasestorage.app',
    measurementId: 'G-9DP37PP0GX',
  );
}
