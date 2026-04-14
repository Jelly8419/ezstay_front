import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 이메일 및 휴대폰 인증 서비스
class VerificationService {
  /// 이메일 인증 코드 발송
  ///
  /// [email] 인증 코드를 받을 이메일 주소
  /// Returns: 성공 시 true, 실패 시 예외 발생
  static Future<bool> sendEmailVerification(String email) async {

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


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // success 필드 체크 (백엔드 응답 형식에 맞춤)
        if (data['success'] == true) {
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
      AppLogger.e('❌ [VERIFICATION] 인증 코드 발송 에러: $e');
      throw VerificationException('인증 코드 발송 중 오류가 발생했습니다');
    }
  }

  /// 이메일 인증 코드 확인
  ///
  /// [email] 이메일 주소
  /// [code] 인증 코드 (6자리)
  /// Returns: 성공 시 true, 실패 시 예외 발생
  static Future<bool> verifyEmailCode(String email, String code) async {

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


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // success 필드 체크 (백엔드 응답 형식에 맞춤)
        if (data['success'] == true) {
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
      AppLogger.e('❌ [VERIFICATION] 인증 코드 확인 에러: $e');
      throw VerificationException('인증 코드 확인 중 오류가 발생했습니다');
    }
  }

  /// 비밀번호 재설정용 이메일 인증 코드 발송
  ///
  /// [email] 인증 코드를 받을 이메일 주소
  /// type: "password_reset"으로 발송
  static Future<bool> sendPasswordResetVerification(String email) async {

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authSendVerificationCodeUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'type': 'password_reset',
        }),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
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
      AppLogger.e('❌ [VERIFICATION] 비밀번호 재설정 인증 코드 발송 에러: $e');
      throw VerificationException('인증 코드 발송 중 오류가 발생했습니다');
    }
  }

  /// 비밀번호 재설정
  ///
  /// [email] 이메일 주소
  /// [newPassword] 새 비밀번호
  /// 이메일 인증 완료 후 호출 (10분 유효)
  static Future<bool> resetPassword(String email, String newPassword) async {

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authResetPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          final message = data['message'] ?? '비밀번호 재설정에 실패했습니다';
          throw VerificationException(message);
        }
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? '비밀번호 재설정에 실패했습니다';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      AppLogger.e('❌ [VERIFICATION] 비밀번호 재설정 에러: $e');
      throw VerificationException('비밀번호 재설정 중 오류가 발생했습니다');
    }
  }

  /// 이메일 인증 코드 재발송
  ///
  /// [email] 인증 코드를 재발송할 이메일 주소
  /// Returns: 성공 시 true, 실패 시 예외 발생
  static Future<bool> resendEmailVerification(String email) async {

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


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // success 필드 체크 (백엔드 응답 형식에 맞춤)
        if (data['success'] == true) {
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
      AppLogger.e('❌ [VERIFICATION] 인증 코드 재발송 에러: $e');
      throw VerificationException('인증 코드 재발송 중 오류가 발생했습니다');
    }
  }

  /// 아이디 찾기 (KMC DI로 이메일 조회)
  ///
  /// [di] KMC 본인인증 후 수신한 DI 값
  /// Returns: 가입된 이메일 주소
  /// Throws: [VerificationException] 일치하는 계정 없음(code 4420) 또는 서버 오류
  static Future<String> findId({required String di}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authFindIdUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'di': di}),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final email = data['data']?['email'] as String?;
        if (email == null || email.isEmpty) {
          throw VerificationException('계정 정보를 불러올 수 없습니다');
        }
        return email;
      } else {
        final message = data['message'] ?? '본인인증 정보와 일치하는 계정이 없습니다.';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      AppLogger.e('❌ [VERIFICATION] 아이디 찾기 에러: $e');
      throw VerificationException('아이디 찾기 중 오류가 발생했습니다');
    }
  }

  /// 비밀번호 찾기 1단계: 이메일 존재 확인 (소셜 계정 차단)
  ///
  /// [email] 사용자가 입력한 이메일
  /// Returns: 성공 시 true (일반 계정 확인됨)
  /// Throws: [VerificationException] 소셜 계정(code 4422) 또는 미존재 계정
  static Future<void> checkEmailForPasswordReset({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authFindPasswordCheckEmailUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return;
      } else {
        final message = data['message'] ?? '이메일 확인에 실패했습니다';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      AppLogger.e('❌ [VERIFICATION] 이메일 확인 에러: $e');
      throw VerificationException('이메일 확인 중 오류가 발생했습니다');
    }
  }

  /// 비밀번호 찾기 2단계: KMC DI + 이메일로 비밀번호 재설정
  ///
  /// [email] 사용자가 입력한 이메일
  /// [di] KMC 본인인증 후 수신한 DI 값
  /// [newPassword] 새 비밀번호
  /// Throws: [VerificationException] email+DI 불일치(code 4421) 또는 서버 오류
  static Future<void> resetPasswordWithKmc({
    required String email,
    required String di,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authFindPasswordResetUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'di': di,
          'newPassword': newPassword,
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return;
      } else {
        final message = data['message'] ?? '비밀번호 재설정에 실패했습니다';
        throw VerificationException(message);
      }
    } on SocketException {
      throw VerificationException('네트워크 연결을 확인해주세요');
    } on http.ClientException {
      throw VerificationException('서버에 연결할 수 없습니다');
    } catch (e) {
      if (e is VerificationException) rethrow;
      AppLogger.e('❌ [VERIFICATION] 비밀번호 재설정 에러: $e');
      throw VerificationException('비밀번호 재설정 중 오류가 발생했습니다');
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
