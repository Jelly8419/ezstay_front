import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// 토스페이먼츠 결제 설정
///
/// 웹: JavaScript SDK 사용 (dart:js 바인딩)
/// 모바일: WebView 기반 구현
///
/// 환경변수 우선순위:
/// 1. --dart-define (빌드 시 주입, Flutter 웹 프로덕션 빌드용)
/// 2. dotenv.env (런타임 .env 파일, 로컬 개발용)
/// 3. 기본값 (폴백)
class PaymentConfig {
  /// 기본 테스트 클라이언트 키
  static const String _defaultTestKey = 'test_ck_PBal2vxj81voBvwla6xG35RQgOAN';

  /// 토스 클라이언트 키
  ///
  /// 우선순위: --dart-define > .env > 기본 테스트 키
  static String get clientKey {
    // 1순위: --dart-define으로 주입된 값 (빌드 시 고정)
    const dartDefineKey = String.fromEnvironment('TOSS_CLIENT_KEY');
    if (dartDefineKey.isNotEmpty) {
      debugPrint('✅ [PaymentConfig] TOSS_CLIENT_KEY from --dart-define');
      return dartDefineKey;
    }

    // 2순위: .env 파일의 값 (런타임)
    final dotenvKey = dotenv.env['TOSS_CLIENT_KEY'];
    if (dotenvKey != null && dotenvKey.isNotEmpty) {
      debugPrint('✅ [PaymentConfig] TOSS_CLIENT_KEY from .env');
      return dotenvKey;
    }

    // 3순위: 기본 테스트 키
    debugPrint('⚠️ [PaymentConfig] TOSS_CLIENT_KEY 없음 → 기본 테스트 키 사용');
    return _defaultTestKey;
  }

  /// 백엔드 API Base URL
  ///
  /// 우선순위: --dart-define > .env > localhost
  static String get baseUrl {
    // 1순위: --dart-define
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }

    // 2순위: .env
    final dotenvUrl = dotenv.env['API_BASE_URL'];
    if (dotenvUrl != null && dotenvUrl.isNotEmpty) {
      return dotenvUrl;
    }

    // 3순위: 기본값
    debugPrint('⚠️ [PaymentConfig] API_BASE_URL 없음 → localhost 사용');
    return 'http://localhost:8080';
  }

  /// 프로덕션 환경 여부
  ///
  /// 우선순위: --dart-define > .env > false
  static bool get isProduction {
    // 1순위: --dart-define
    const dartDefineValue = String.fromEnvironment('IS_PRODUCTION');
    if (dartDefineValue.isNotEmpty) {
      return dartDefineValue.toLowerCase() == 'true';
    }

    // 2순위: .env
    final dotenvValue = dotenv.env['IS_PRODUCTION'];
    if (dotenvValue != null) {
      return dotenvValue.toLowerCase() == 'true';
    }

    // 3순위: 기본값 (개발 모드)
    return false;
  }

  /// Mock 모드 사용 여부
  ///
  /// - 로컬/테스트 환경 (IS_PRODUCTION=false): Mock 모드 활성화
  /// - 프로덕션 환경 (IS_PRODUCTION=true): 실제 결제 모드
  static bool get useMockMode {
    // 1순위: --dart-define으로 명시적 설정
    const dartDefineMode = String.fromEnvironment('PAYMENT_MOCK_MODE');
    if (dartDefineMode.isNotEmpty) {
      return dartDefineMode.toLowerCase() == 'true';
    }

    // 2순위: .env 파일에서 명시적 설정
    final dotenvMode = dotenv.env['PAYMENT_MOCK_MODE'];
    if (dotenvMode != null) {
      return dotenvMode.toLowerCase() == 'true';
    }

    // 3순위: 프로덕션 여부로 자동 결정
    // 프로덕션 → Mock 모드 비활성화 (실제 결제)
    // 로컬/테스트 → Mock 모드 활성화
    return !isProduction;
  }

  /// 결제 성공 시 리다이렉트 URL
  static String get successUrl {
    if (kIsWeb) {
      // 웹: 현재 도메인의 /payment/success로 리다이렉트
      return '${Uri.base.origin}/payment/success';
    } else {
      // 모바일: 백엔드 URL 사용
      return '$baseUrl/payment/success';
    }
  }

  /// 결제 실패 시 리다이렉트 URL
  static String get failUrl {
    if (kIsWeb) {
      // 웹: 현재 도메인의 /payment/fail로 리다이렉트
      return '${Uri.base.origin}/payment/fail';
    } else {
      // 모바일: 백엔드 URL 사용
      return '$baseUrl/payment/fail';
    }
  }
}
