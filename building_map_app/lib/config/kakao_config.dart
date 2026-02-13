import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';

/// 카카오 API 설정
class KakaoConfig {
  /// 카카오 REST API 키
  /// 우선순위: 1) 컴파일 타임 상수 (--dart-define), 2) .env 파일, 3) fallback (로컬 개발용)
  static String get restApiKey {
    const compileTimeKey = String.fromEnvironment('KAKAO_REST_API_KEY');
    if (compileTimeKey.isNotEmpty) return compileTimeKey;

    // dotenv 초기화 확인 후 접근 (안전성 추가)
    try {
      final envKey = dotenv.env['KAKAO_REST_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) return envKey;
    } catch (e) {
      // dotenv 초기화 전에 접근 시 fallback으로 처리
    }

    // fallback: 로컬 개발용 (배포 시에는 사용되지 않음)
    return '32ea67da1f7c3d55fd573c285a5fc0f2'; // test 키로 변경
  }

  /// 카카오 JavaScript API 키 (지도용)
  /// 우선순위: 1) 컴파일 타임 상수 (--dart-define), 2) .env 파일
  static String get javascriptKey {
    const compileTimeKey = String.fromEnvironment('KAKAO_JAVASCRIPT_KEY');
    if (compileTimeKey.isNotEmpty) return compileTimeKey;

    // dotenv 초기화 확인 후 접근 (안전성 추가)
    try {
      final envKey = dotenv.env['KAKAO_JAVASCRIPT_KEY'];
      if (envKey != null && envKey.isNotEmpty) return envKey;
    } catch (e) {
      // dotenv 초기화 전에 접근 시 fallback으로 처리
    }

    // fallback: 로컬 개발용
    return '8fa88a5c7a3edac4ee6d8dd52af14f60'; // test 키로 변경
  }

  /// 리다이렉트 URL
  static String get redirectUrl => '${ApiConfig.baseUrl}/api/auth/kakao';

  /// 웹용 리다이렉트 URL (Flutter Web)
  static String get webRedirectUrl => '${ApiConfig.baseUrl}/api/auth/kakao';

  /// 카카오 앱 스킴 (네이티브 앱용)
  static String get nativeAppKey => 'kakao$restApiKey';

  /// 카카오 OAuth 인증 URL
  static String get authUrl =>
      'https://kauth.kakao.com/oauth/authorize'
      '?response_type=code'
      '&client_id=$restApiKey'
      '&redirect_uri=$redirectUrl';

  /// 카카오 토큰 발급 URL
  static const String tokenUrl = 'https://kauth.kakao.com/oauth/token';

  /// 카카오 사용자 정보 API URL
  static const String userInfoUrl = 'https://kapi.kakao.com/v2/user/me';

  /// API 키 유효성 검사
  static bool isApiKeyValid() {
    return restApiKey.isNotEmpty && restApiKey != 'YOUR_KAKAO_REST_API_KEY';
  }
}