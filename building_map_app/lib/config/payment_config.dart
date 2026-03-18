import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// PayTag PG 결제 설정
///
/// 웹: JavaScript SDK 사용 (dart:js 바인딩)
/// 모바일: WebView 기반 구현
///
/// 환경변수 우선순위:
/// 1. --dart-define (빌드 시 주입, Flutter 웹 프로덕션 빌드용)
/// 2. dotenv.env (런타임 .env 파일, 로컬 개발용)
/// 3. 기본값 (폴백)
class PaymentConfig {
  /// 기본 테스트 shopcode
  static const String _defaultTestShopcode = '1901110002';

  /// PayTag Shopcode
  ///
  /// 우선순위: --dart-define > .env > 기본 테스트 값
  static String get shopcode {
    // 1순위: --dart-define으로 주입된 값 (빌드 시 고정)
    const dartDefineValue = String.fromEnvironment('PAYTAG_SHOPCODE');
    if (dartDefineValue.isNotEmpty) {
      debugPrint('✅ [PaymentConfig] PAYTAG_SHOPCODE from --dart-define');
      return dartDefineValue;
    }

    // 2순위: .env 파일의 값 (런타임)
    final dotenvValue = dotenv.env['PAYTAG_SHOPCODE'];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      debugPrint('✅ [PaymentConfig] PAYTAG_SHOPCODE from .env');
      return dotenvValue;
    }

    // 3순위: 기본 테스트 값
    debugPrint('⚠️ [PaymentConfig] PAYTAG_SHOPCODE 없음 → 기본 테스트 값 사용');
    return _defaultTestShopcode;
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

  /// PayTag 웹훅 URL (가상계좌 입금 확인용)
  ///
  /// 외부에서 접근 가능한 URL이어야 함 (localhost 불가)
  /// 설정 안 되어 있으면 빈 문자열 반환 → SDK에 webhook_url 파라미터 생략
  static String get webhookUrl {
    const dartDefineValue = String.fromEnvironment('PAYTAG_WEBHOOK_URL');
    if (dartDefineValue.isNotEmpty) return dartDefineValue;

    final dotenvValue = dotenv.env['PAYTAG_WEBHOOK_URL'];
    if (dotenvValue != null && dotenvValue.isNotEmpty) return dotenvValue;

    return '';
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
    return !isProduction;
  }
}
