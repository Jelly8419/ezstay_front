// Firebase 플랫폼별 옵션 정의
// 웹: 실제 설정은 index.html의 env_config.js → window.firebaseConfig 에서 관리됨
//     여기 값은 로컬 개발 fallback 용도
// Android/iOS: google-services.json / GoogleService-Info.plist 추가 시 교체 필요
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  // --dart-define=ENVIRONMENT=production 으로 환경 분기
  static const _env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');
  static bool get _isProduction => _env == 'production';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _isProduction ? webProduction : web;
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

  // 운영 환경 (ezstay-prod)
  static const FirebaseOptions webProduction = FirebaseOptions(
    apiKey: 'AlzaSyC37Xu7zGwC9wwTIHURk1OXLo92JoS5zmw',
    appId: '1:943255185973:web:d0c8951d279e415fd55c3c',
    messagingSenderId: '943255185973',
    projectId: 'ezstay-prod',
    authDomain: 'ezstay-prod.firebaseapp.com',
    storageBucket: 'ezstay-prod.firebasestorage.app',
    measurementId: 'G-HLOJJSF99W',
  );

  // 로컬/테스트 환경 (ezstay-864bc)
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
