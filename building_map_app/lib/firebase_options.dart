// Firebase 플랫폼별 옵션 정의
// 웹: 실제 설정은 index.html의 env_config.js → window.firebaseConfig 에서 관리됨
//     여기 값은 로컬 개발 fallback 용도
// Android/iOS: google-services.json / GoogleService-Info.plist 추가 시 교체 필요
// ignore_for_file: type=lint
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBDwxJU7ivdjfdMOJeA7N_buRjdJLfdKUs',
    appId: '1:922042336723:web:054fdbcc6b9b219aed1b26',
    messagingSenderId: '922042336723',
    projectId: 'ezstay-864bc',
    authDomain: 'ezstay-864bc.firebaseapp.com',
    storageBucket: 'ezstay-864bc.firebasestorage.app',
    measurementId: 'G-1QZK8YMFEV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDwxJU7ivdjfdMOJeA7N_buRjdJLfdKUs',
    appId: '1:922042336723:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '922042336723',
    projectId: 'ezstay-864bc',
    storageBucket: 'ezstay-864bc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDwxJU7ivdjfdMOJeA7N_buRjdJLfdKUs',
    appId: '1:922042336723:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '922042336723',
    projectId: 'ezstay-864bc',
    storageBucket: 'ezstay-864bc.firebasestorage.app',
    iosBundleId: 'com.example.ezstay',
  );
}
