import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html show window;
import '../config/api_config.dart';

/// 토큰 관리 서비스
class TokenService {
  static const _storage = FlutterSecureStorage();

  /// 웹에서는 localStorage, 네이티브에서는 secure storage 사용
  /// 웹에서는 flutter_secure_storage와 호환되도록 'flutter.' 접두사 추가
  static String _getWebKey(String key) {
    return 'flutter.$key';
  }

  static Future<void> _writeSecure(String key, String value) async {
    if (kIsWeb) {
      final webKey = _getWebKey(key);
      html.window.localStorage[webKey] = value;
      if (!ApiConfig.isProduction) {
        debugPrint('💾 [WEB] localStorage에 저장: $webKey');
      }
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static Future<String?> _readSecure(String key) async {
    if (kIsWeb) {
      final webKey = _getWebKey(key);
      final value = html.window.localStorage[webKey];
      if (!ApiConfig.isProduction) {
        debugPrint('🔍 [WEB] localStorage에서 조회: $webKey - ${value != null ? "있음" : "없음"}');
      }
      return value;
    } else {
      return await _storage.read(key: key);
    }
  }

  static Future<void> _deleteSecure(String key) async {
    if (kIsWeb) {
      final webKey = _getWebKey(key);
      html.window.localStorage.remove(webKey);
      if (!ApiConfig.isProduction) {
        debugPrint('🗑️ [WEB] localStorage에서 삭제: $webKey');
      }
    } else {
      await _storage.delete(key: key);
    }
  }

  /// Access Token 저장
  static Future<void> saveAccessToken(String token) async {
    if (!ApiConfig.isProduction) {
      debugPrint('💾 [TOKEN] Access Token 저장 중...');
      debugPrint('💾 [TOKEN] Token 길이: ${token.length}');
      debugPrint('💾 [TOKEN] Token 앞 20자: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    }
    await _writeSecure('access_token', token);

    // 저장 직후 바로 읽어서 확인
    final saved = await _readSecure('access_token');
    if (!ApiConfig.isProduction) {
      debugPrint('✅ [TOKEN] Access Token 저장 완료');
      debugPrint('🔍 [TOKEN] 저장 검증: ${saved != null ? "성공 (${saved.length}자)" : "실패"}');
    }
  }

  /// Refresh Token 저장
  static Future<void> saveRefreshToken(String token) async {
    if (!ApiConfig.isProduction) {
      debugPrint('💾 [TOKEN] Refresh Token 저장 중...');
    }
    await _writeSecure('refresh_token', token);
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
  static Future<String?> getAccessToken({bool skipExpiryCheck = false}) async {
    if (!ApiConfig.isProduction) {
      debugPrint('🔍 [TOKEN] Access Token 조회 시도...');
    }

    final token = await _readSecure('access_token');

    if (!ApiConfig.isProduction) {
      debugPrint('🔍 [TOKEN] Access Token 조회 결과: ${token != null ? "있음 (${token.length}자)" : "없음 ⚠️"}');
      if (token != null) {
        debugPrint('🔍 [TOKEN] Token 앞 20자: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
    }

    if (token == null) return null;

    // 개발 환경에서 만료 체크 스킵 옵션
    if (skipExpiryCheck && !ApiConfig.isProduction) {
      debugPrint('⚠️ [DEV] 토큰 만료 체크를 건너뜁니다');
      return token;
    }

    // 토큰 만료 여부 확인
    if (isTokenExpired(token)) {
      if (!ApiConfig.isProduction) {
        debugPrint('⚠️ [TOKEN] Access Token이 만료되었습니다');
        debugPrint('💡 [TOKEN] 다시 로그인하거나 개발 중이라면 skipExpiryCheck: true를 사용하세요');
      }
      return null;
    }

    return token;
  }

  /// Refresh Token 불러오기
  static Future<String?> getRefreshToken() async {
    final token = await _readSecure('refresh_token');

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
    await _deleteSecure('access_token');
    await _deleteSecure('refresh_token');
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

  /// 토큰 자동 갱신
  /// Access Token이 만료되었거나 곧 만료될 경우 Refresh Token으로 새 토큰 발급
  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _readSecure('refresh_token');

      if (refreshToken == null) {
        if (!ApiConfig.isProduction) {
          debugPrint('❌ [TOKEN] Refresh Token이 없습니다');
        }
        return null;
      }

      // Refresh Token도 만료되었는지 확인
      if (isTokenExpired(refreshToken)) {
        if (!ApiConfig.isProduction) {
          debugPrint('❌ [TOKEN] Refresh Token도 만료되었습니다. 다시 로그인이 필요합니다.');
        }
        await clearTokens();
        return null;
      }

      if (!ApiConfig.isProduction) {
        debugPrint('🔄 [TOKEN] Access Token 갱신 시도 중...');
      }

      // 백엔드 API 호출 (백엔드는 req.body.refreshToken에서 읽음)
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 두 가지 응답 구조 모두 처리:
        // 1) { accessToken, refreshToken } (직접)
        // 2) { success, data: { accessToken, refreshToken } } (래핑)
        final String? newAccessToken = data['accessToken'] as String? ??
            (data['data'] is Map ? data['data']['accessToken'] as String? : null);
        final String? newRefreshToken = data['refreshToken'] as String? ??
            (data['data'] is Map ? data['data']['refreshToken'] as String? : null);

        if (newAccessToken != null) {
          await saveAccessToken(newAccessToken);

          // 새로운 Refresh Token도 제공되면 저장
          if (newRefreshToken != null) {
            await saveRefreshToken(newRefreshToken);
          }

          if (!ApiConfig.isProduction) {
            debugPrint('✅ [TOKEN] Access Token 갱신 완료');
          }

          return newAccessToken;
        }
      } else if (response.statusCode == 401) {
        // Refresh Token도 유효하지 않음 - 재로그인 필요
        if (!ApiConfig.isProduction) {
          debugPrint('❌ [TOKEN] Refresh Token이 유효하지 않습니다. 재로그인이 필요합니다.');
        }
        await clearTokens();
        return null;
      } else {
        if (!ApiConfig.isProduction) {
          debugPrint('❌ [TOKEN] 토큰 갱신 실패: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [TOKEN] 토큰 갱신 중 에러: $e');
      }
      return null;
    }

    return null;
  }

  /// 유효한 Access Token 가져오기 (자동 갱신 포함)
  /// 만료되었거나 곧 만료될 경우 자동으로 갱신 시도
  static Future<String?> getValidAccessToken({bool autoRefresh = true}) async {
    String? token = await _readSecure('access_token');

    if (token == null) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [TOKEN] Access Token이 없습니다');
      }
      return null;
    }

    // 토큰이 만료되었는지 확인
    if (isTokenExpired(token)) {
      if (!ApiConfig.isProduction) {
        debugPrint('⚠️ [TOKEN] Access Token이 만료되었습니다');
      }

      // 자동 갱신 활성화 시 갱신 시도
      if (autoRefresh) {
        token = await refreshAccessToken();
      } else {
        return null;
      }
    }
    // 토큰이 곧 만료되는지 확인 (5분 이내)
    else if (autoRefresh && isTokenExpiringSoon(token)) {
      if (!ApiConfig.isProduction) {
        debugPrint('⚠️ [TOKEN] Access Token이 곧 만료됩니다. 갱신 시도 중...');
      }

      // 백그라운드에서 갱신 시도 (실패해도 현재 토큰 반환)
      refreshAccessToken().then((newToken) {
        if (newToken != null && !ApiConfig.isProduction) {
          debugPrint('✅ [TOKEN] 백그라운드에서 토큰 갱신 완료');
        }
      });
    }

    return token;
  }
}
