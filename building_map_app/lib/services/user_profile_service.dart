import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

/// 사용자 프로필 서비스
class UserProfileService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  /// 사용자 프로필 조회
  ///
  /// GET /api/user/profile
  ///
  /// 응답:
  /// ```json
  /// {
  ///   "data": {
  ///     "name": "홍길동",
  ///     "email": "guest@example.com",
  ///     "phoneNumber": "010-1234-5678",
  ///     "createdAt": "2025-01-01"
  ///   }
  /// }
  /// ```
  Future<UserProfile?> getUserProfile() async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📋 [UserProfileService] 프로필 조회 시작');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [UserProfileService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ [UserProfileService] 프로필 조회 성공');
        return UserProfile.fromJson(data['data'] as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '프로필 조회 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 비밀번호 변경
  ///
  /// PATCH /api/user/password
  ///
  /// 요청:
  /// ```json
  /// {
  ///   "currentPassword": "OldPass123!",
  ///   "newPassword": "NewPass456!"
  /// }
  /// ```
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🔐 [UserProfileService] 비밀번호 변경 시작');

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/user/password'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [UserProfileService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [UserProfileService] 비밀번호 변경 성공');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다.');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '비밀번호 형식이 올바르지 않습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '비밀번호 변경 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 연락처 변경
  ///
  /// PATCH /api/user/phone
  ///
  /// 요청:
  /// ```json
  /// {
  ///   "phoneNumber": "010-9876-5432"
  /// }
  /// ```
  Future<void> changePhoneNumber({
    required String phoneNumber,
  }) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📱 [UserProfileService] 연락처 변경 시작');

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/user/phone'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [UserProfileService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [UserProfileService] 연락처 변경 성공');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다.');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '연락처 변경 실패');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '연락처 변경 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 회원 탈퇴
  ///
  /// DELETE /api/user/account
  Future<void> withdrawUser() async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🚪 [UserProfileService] 회원 탈퇴 시작');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/user/account'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [UserProfileService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [UserProfileService] 회원 탈퇴 성공');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다.');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '회원 탈퇴 실패');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '회원 탈퇴 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }
}
