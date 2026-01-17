import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// 토스페이먼츠 결제 설정
///
/// 웹: JavaScript SDK 사용 (dart:js 바인딩)
/// 모바일: WebView 기반 구현
class PaymentConfig {
  /// 토스 클라이언트 키 (테스트 환경)
  static String get clientKey => dotenv.env['TOSS_CLIENT_KEY']!;

  /// 백엔드 API Base URL
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  /// 프로덕션 환경 여부
  static bool get isProduction => dotenv.env['IS_PRODUCTION'] == 'true';

  /// Mock 모드 사용 여부
  ///
  /// - 로컬/테스트 환경 (IS_PRODUCTION=false): Mock 모드 활성화
  /// - 프로덕션 환경 (IS_PRODUCTION=true): 실제 결제 모드
  static bool get useMockMode {
    // PAYMENT_MOCK_MODE가 명시적으로 설정된 경우 우선 적용
    final explicitMode = dotenv.env['PAYMENT_MOCK_MODE'];
    if (explicitMode != null) {
      return explicitMode == 'true';
    }

    // 명시적 설정 없으면 프로덕션 여부로 자동 결정
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
