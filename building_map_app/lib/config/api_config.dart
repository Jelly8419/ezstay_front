import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 키와 설정을 관리하는 클래스
class ApiConfig {
  /// 백엔드 API 베이스 URL
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
  }

  /// API 타임아웃 시간 (초)
  static int get timeoutSeconds {
    final timeout = dotenv.env['API_TIMEOUT_SECONDS'];
    return timeout != null ? int.tryParse(timeout) ?? 10 : 10;
  }

  /// API 타임아웃 Duration
  static Duration get timeout {
    return Duration(seconds: timeoutSeconds);
  }

  /// 개발/프로덕션 환경 구분
  static bool get isProduction {
    final envValue = dotenv.env['IS_PRODUCTION'] ?? 'false';
    return envValue.toLowerCase() == 'true';
  }

  /// 인증 API 엔드포인트
  static String get authLoginUrl => '$baseUrl/api/auth/login';
  static String get authRegisterUrl => '$baseUrl/api/auth/register';
  static String get authLogoutUrl => '$baseUrl/api/auth/logout';
  static String get authKakaoUrl => '$baseUrl/auth/kakao';
  static String get authKakaoWebUrl => '$baseUrl/api/auth/kakao';
  static String get authProfileUrl => '$baseUrl/api/auth/profile';
  static String get authRefreshUrl => '$baseUrl/api/auth/refresh';

  /// 방 관리 API 엔드포인트
  static String get roomsBaseUrl => '$baseUrl/api/host/rooms';
  static String roomUrl(int roomId) => '$roomsBaseUrl/$roomId';
  static String roomPricingUrl(int roomId) => '$roomsBaseUrl/$roomId/pricing';
  static String roomPhotosUrl(int roomId) => '$roomsBaseUrl/$roomId/photos';
  static String roomAmenitiesUrl(int roomId) => '$roomsBaseUrl/$roomId/amenities';
  static String roomFreeServicesUrl(int roomId) => '$roomsBaseUrl/$roomId/free-services';
  static String roomCleaningToolUrl(int roomId) => '$roomsBaseUrl/$roomId/cleaning-tool-image';
  static String roomDescriptionUrl(int roomId) => '$roomsBaseUrl/$roomId/description';
  static String roomSubmitReviewUrl(int roomId) => '$roomsBaseUrl/$roomId/submit-review';
  static String roomPhotosReorderUrl(int roomId) => '$roomsBaseUrl/$roomId/photos/reorder';
  static String roomPhotoDeleteUrl(int roomId, int photoId) => '$roomsBaseUrl/$roomId/photos/$photoId';

  //게스트 방 조회 API 엔드포인트
  static String getRoomById(int roomId) => '$baseUrl/api/rooms/$roomId';

  /// API 설정 유효성 검사
  static bool isConfigValid() {
    return baseUrl.isNotEmpty &&
           baseUrl != 'YOUR_API_BASE_URL_HERE';
  }
}
