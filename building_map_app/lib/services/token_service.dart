import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../config/api_config.dart';

/// 토큰 관리 서비스
class TokenService {
  static const _storage = FlutterSecureStorage();

  /// Access Token 저장
  static Future<void> saveAccessToken(String token) async {
    if (!ApiConfig.isProduction) {
      debugPrint('💾 [TOKEN] Access Token 저장 중...');
      debugPrint('💾 [TOKEN] Token 길이: ${token.length}');
    }
    await _storage.write(key: 'access_token', value: token);
    if (!ApiConfig.isProduction) {
      debugPrint('✅ [TOKEN] Access Token 저장 완료');
    }
  }

  /// Refresh Token 저장
  static Future<void> saveRefreshToken(String token) async {
    if (!ApiConfig.isProduction) {
      debugPrint('💾 [TOKEN] Refresh Token 저장 중...');
    }
    await _storage.write(key: 'refresh_token', value: token);
    if (!ApiConfig.isProduction) {
      debugPrint('✅ [TOKEN] Refresh Token 저장 완료');
    }
  }

  /// 토큰 저장 (Access + Refresh)
  static Future<void> saveTokens(String accessToken, String? refreshToken) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Access Token 불러오기
  static Future<String?> getAccessToken() async {
    final token = await _storage.read(key: 'access_token');

    // 토큰이 있으면 만료 여부 확인
    if (token != null && isTokenExpired(token)) {
      if (!ApiConfig.isProduction) {
        debugPrint('⚠️ [TOKEN] Access Token이 만료되었습니다');
      }
      return null;
    }

    return token;
  }

  /// Refresh Token 불러오기
  static Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: 'refresh_token');

    // 토큰이 있으면 만료 여부 확인
    if (token != null && isTokenExpired(token)) {
      if (!ApiConfig.isProduction) {
        debugPrint('⚠️ [TOKEN] Refresh Token이 만료되었습니다');
      }
      return null;
    }

    return token;
  }

  /// 토큰 삭제
  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    if (!ApiConfig.isProduction) {
      debugPrint('🗑️ [TOKEN] 토큰 삭제 완료');
    }
  }

  /// JWT 토큰 만료 여부 확인
  static bool isTokenExpired(String token) {
    try {
      // JWT가 유효한 형식인지 확인
      if (!_isValidJwtFormat(token)) {
        if (!ApiConfig.isProduction) {
          debugPrint('❌ [TOKEN] 유효하지 않은 JWT 형식');
        }
        return true;
      }

      // JWT 디코딩
      final payload = Jwt.parseJwt(token);

      // exp (만료 시간) 확인
      if (payload['exp'] == null) {
        if (!ApiConfig.isProduction) {
          debugPrint('⚠️ [TOKEN] JWT에 exp 필드가 없습니다');
        }
        return false; // exp가 없으면 만료되지 않은 것으로 간주
      }

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        payload['exp'] * 1000,
      );

      final isExpired = DateTime.now().isAfter(expiryDate);

      if (!ApiConfig.isProduction) {
        debugPrint('🔍 [TOKEN] 만료 시간: $expiryDate');
        debugPrint('🔍 [TOKEN] 현재 시간: ${DateTime.now()}');
        debugPrint('🔍 [TOKEN] 만료 여부: $isExpired');
      }

      return isExpired;
    } catch (e) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [TOKEN] JWT 파싱 에러: $e');
      }
      return true; // 파싱 실패 시 만료된 것으로 간주
    }
  }

  /// JWT 토큰 형식 검증
  static bool _isValidJwtFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3 &&
           parts.every((part) => part.isNotEmpty) &&
           token.length > 10;
  }

  /// JWT 토큰에서 사용자 ID 추출
  static String? getUserIdFromToken(String token) {
    try {
      if (!_isValidJwtFormat(token)) return null;

      final payload = Jwt.parseJwt(token);
      return payload['sub']?.toString() ?? payload['userId']?.toString();
    } catch (e) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [TOKEN] 사용자 ID 추출 실패: $e');
      }
      return null;
    }
  }

  /// JWT 토큰에서 이메일 추출
  static String? getEmailFromToken(String token) {
    try {
      if (!_isValidJwtFormat(token)) return null;

      final payload = Jwt.parseJwt(token);
      return payload['email']?.toString();
    } catch (e) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [TOKEN] 이메일 추출 실패: $e');
      }
      return null;
    }
  }

  /// 토큰이 곧 만료되는지 확인 (5분 이내)
  static bool isTokenExpiringSoon(String token, {Duration buffer = const Duration(minutes: 5)}) {
    try {
      if (!_isValidJwtFormat(token)) return true;

      final payload = Jwt.parseJwt(token);

      if (payload['exp'] == null) return false;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        payload['exp'] * 1000,
      );

      final bufferTime = DateTime.now().add(buffer);

      return bufferTime.isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }
}
