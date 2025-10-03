import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 키와 설정을 관리하는 클래스
class ApiConfig {
  /// Google Maps API 키 (.env 파일에서 로드)
  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  /// 개발/프로덕션 환경 구분
  static bool get isProduction {
    final envValue = dotenv.env['IS_PRODUCTION'] ?? 'false';
    return envValue.toLowerCase() == 'true';
  }

  /// API 키 유효성 검사
  static bool isApiKeyValid() {
    final key = googleMapsApiKey;
    return key.isNotEmpty &&
           key != 'YOUR_API_KEY_HERE' &&
           key != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  }
}
