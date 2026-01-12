import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 이메일 및 휴대폰 인증 서비스
class VerificationService {
  /// 이메일 인증 코드 발송
  ///
  /// [email] 인증 코드를 받을 이메일 주소
  /// Returns: 성공 시 true, 실패 시 예외 발생
  static Future<bool> sendEmailVerification(String email) async {
    debugPrint('📧 [VERIFICATION] 이메일 인증 코드 발송 시작: $email');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authSendVerificationCodeUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'type': 'signup',
        }),
      ).timeout(ApiConfig.timeout);

      debugPrint('📡 [VERIFICATION] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [VERIFICATION] 응답 내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // success 필드 체크 (백엔드 응답 형식에 맞춤)
        if (data['success'] == true) {
          debugPrint('✅ [VERIFICATION] 인증 코드 발송 성공');
          return true;
        } else {
          final message = data['message'] ?? '인증 코드 발송에 실패했습니다';
          throw VerificationException(message);
        }
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? '인증 코드 발송에 실패했습니다';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      debugPrint('❌ [VERIFICATION] 인증 코드 발송 에러: $e');
      throw VerificationException('인증 코드 발송 중 오류가 발생했습니다');
    }
  }

  /// 이메일 인증 코드 확인
  ///
  /// [email] 이메일 주소
  /// [code] 인증 코드 (6자리)
  /// Returns: 성공 시 true, 실패 시 예외 발생
  static Future<bool> verifyEmailCode(String email, String code) async {
    debugPrint('🔍 [VERIFICATION] 이메일 인증 코드 확인: $email, code: $code');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authVerifyEmailUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
        }),
      ).timeout(ApiConfig.timeout);

      debugPrint('📡 [VERIFICATION] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [VERIFICATION] 응답 내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // success 필드 체크 (백엔드 응답 형식에 맞춤)
        if (data['success'] == true) {
          debugPrint('✅ [VERIFICATION] 이메일 인증 성공');
          return true;
        } else {
          final message = data['message'] ?? '인증 코드가 일치하지 않습니다';
          throw VerificationException(message);
        }
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? '인증 코드 확인에 실패했습니다';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      debugPrint('❌ [VERIFICATION] 인증 코드 확인 에러: $e');
      throw VerificationException('인증 코드 확인 중 오류가 발생했습니다');
    }
  }

  /// 이메일 인증 코드 재발송
  ///
  /// [email] 인증 코드를 재발송할 이메일 주소
  /// Returns: 성공 시 true, 실패 시 예외 발생
  static Future<bool> resendEmailVerification(String email) async {
    debugPrint('🔄 [VERIFICATION] 이메일 인증 코드 재발송: $email');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authResendVerificationCodeUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      ).timeout(ApiConfig.timeout);

      debugPrint('📡 [VERIFICATION] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [VERIFICATION] 응답 내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // success 필드 체크 (백엔드 응답 형식에 맞춤)
        if (data['success'] == true) {
          debugPrint('✅ [VERIFICATION] 인증 코드 재발송 성공');
          return true;
        } else {
          final message = data['message'] ?? '인증 코드 재발송에 실패했습니다';
          throw VerificationException(message);
        }
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? '인증 코드 재발송에 실패했습니다';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      debugPrint('❌ [VERIFICATION] 인증 코드 재발송 에러: $e');
      throw VerificationException('인증 코드 재발송 중 오류가 발생했습니다');
    }
  }
}

/// 인증 예외 클래스
class VerificationException implements Exception {
  final String message;

  VerificationException(this.message);

  @override
  String toString() => message;
}
