import 'dart:html' as html;
import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

/// 웹 전용 localStorage 기반 저장소
/// flutter_secure_storage의 대체재로 사용 (웹에서 더 안정적)
class WebStorageService {
  /// Access Token 저장
  static Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage['access_token'] = token;
    }
  }

  /// Refresh Token 저장
  static Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage['refresh_token'] = token;
    }
  }

  /// Access Token 가져오기
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final token = html.window.localStorage['access_token'];
      return token;
    }
    return null;
  }

  /// Refresh Token 가져오기
  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final token = html.window.localStorage['refresh_token'];
      return token;
    }
    return null;
  }

  /// 토큰 삭제
  static Future<void> clearTokens() async {
    if (kIsWeb) {
      html.window.localStorage.remove('access_token');
      html.window.localStorage.remove('refresh_token');
    }
  }

  /// 사용자 정보 저장
  static Future<void> saveUserInfo(Map<String, String> userInfo) async {
    if (kIsWeb) {
      userInfo.forEach((key, value) {
        html.window.localStorage['user_$key'] = value;
      });
    }
  }

  /// 사용자 정보 가져오기
  static Future<Map<String, String?>> getUserInfo() async {
    if (kIsWeb) {
      return {
        'id': html.window.localStorage['user_id'],
        'email': html.window.localStorage['user_email'],
        'name': html.window.localStorage['user_name'],
        'mode': html.window.localStorage['user_mode'],
        'provider': html.window.localStorage['user_provider'],
        'profileImageUrl': html.window.localStorage['user_profileImageUrl'],
      };
    }
    return {};
  }

  /// 사용자 정보 삭제
  static Future<void> clearUserInfo() async {
    if (kIsWeb) {
      html.window.localStorage.remove('user_id');
      html.window.localStorage.remove('user_email');
      html.window.localStorage.remove('user_name');
      html.window.localStorage.remove('user_mode');
      html.window.localStorage.remove('user_provider');
      html.window.localStorage.remove('user_profileImageUrl');
    }
  }
}
