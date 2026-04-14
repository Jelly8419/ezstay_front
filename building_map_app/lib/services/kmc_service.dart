import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

/// KMC 본인인증 서비스
///
/// KMC(한국모바일인증) API와 통신하여 휴대폰 본인인증을 처리합니다.
/// - 인증 요청 데이터 생성 (암호화된 trCert)
/// - 인증 결과 검증 (apiToken + certNum → 실명/전화번호/생년월일)
class KmcService {
  /// 인증 요청 데이터 생성
  ///
  /// 백엔드에 POST /api/auth/kmc/request 호출하여
  /// KMC 인증창에 전달할 암호화된 데이터를 받습니다.
  ///
  /// Returns: [KmcRequestResult] 암호화된 인증 요청 데이터
  static Future<KmcRequestResult> requestVerification() async {

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // 로그인 상태면 토큰 추가 (회원가입 시에는 토큰 없이 호출)
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.post(
        Uri.parse(ApiConfig.kmcRequestUrl),
        headers: headers,
      ).timeout(ApiConfig.timeout);


      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final result = KmcRequestResult.fromJson(data['data']);
        return result;
      } else {
        final code = data['code']?.toString() ?? '';
        final message = data['message'] ?? '인증 요청 생성에 실패했습니다.';
        throw KmcException(code: code, message: message);
      }
    } on SocketException {
      throw KmcException(code: 'NETWORK', message: '네트워크 연결을 확인해주세요.');
    } on http.ClientException {
      throw KmcException(code: 'NETWORK', message: '서버에 연결할 수 없습니다.');
    } catch (e) {
      if (e is KmcException) rethrow;
      AppLogger.e('❌ [KMC] 인증 요청 에러: $e');
      throw KmcException(code: 'UNKNOWN', message: '인증 요청 중 오류가 발생했습니다.');
    }
  }

  /// 인증 결과 검증
  ///
  /// KMC 인증 완료 후 받은 apiToken과 certNum으로
  /// 백엔드에 POST /api/auth/kmc/verify 호출하여 결과를 검증합니다.
  ///
  /// [apiToken] KMC 인증 완료 후 수신한 API 토큰
  /// [certNum] KMC 인증 완료 후 수신한 인증 번호
  /// [purpose] 인증 목적: 'register'(기본), 'find_id', 'find_password'
  ///
  /// Returns: [KmcVerifyResult] 검증된 사용자 정보
  static Future<KmcVerifyResult> verifyResult({
    required String apiToken,
    required String certNum,
    String? purpose,
  }) async {

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // 로그인 상태면 토큰 추가 (회원가입 시에는 토큰 없이 호출)
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final body = <String, String>{
        'apiToken': apiToken,
        'certNum': certNum,
      };
      if (purpose != null) body['purpose'] = purpose;

      final response = await http.post(
        Uri.parse(ApiConfig.kmcVerifyUrl),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 20)); // KMC 서버 연동이므로 타임아웃 여유있게


      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final result = KmcVerifyResult.fromJson(data['data']);
        return result;
      } else {
        final code = data['code']?.toString() ?? '';
        final message = data['message'] ?? '인증 결과 검증에 실패했습니다.';
        throw KmcException(code: code, message: message);
      }
    } on SocketException {
      throw KmcException(code: 'NETWORK', message: '네트워크 연결을 확인해주세요.');
    } on http.ClientException {
      throw KmcException(code: 'NETWORK', message: '서버에 연결할 수 없습니다.');
    } catch (e) {
      if (e is KmcException) rethrow;
      AppLogger.e('❌ [KMC] 인증 검증 에러: $e');
      throw KmcException(code: 'UNKNOWN', message: '인증 결과 검증 중 오류가 발생했습니다.');
    }
  }

  /// KMC 에러 코드별 사용자 메시지
  static String getErrorMessage(String code) {
    switch (code) {
      case '4401':
        return '인증 요청 생성에 실패했습니다. 잠시 후 다시 시도해주세요.';
      case '4402':
        return '인증 결과를 처리할 수 없습니다. 다시 시도해주세요.';
      case '4403':
        return '인증 시간이 만료되었습니다. 다시 인증해주세요.';
      case '4404':
        return '인증 정보를 찾을 수 없습니다.';
      case '4405':
        return '본인인증에 실패했습니다.';
      case '4406':
        return '인증 데이터 위변조가 감지되었습니다.';
      case '4407':
        return '인증 서버 연동 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case '4408':
        return '인증 시스템이 준비 중입니다. 잠시 후 다시 시도해주세요.';
      case '4410':
        return '이미 다른 계정에서 본인인증이 완료된 정보입니다.';
      default:
        return '본인인증 중 오류가 발생했습니다.';
    }
  }
}

/// KMC 인증 요청 결과 데이터
class KmcRequestResult {
  final String trCert;
  final String cpId;
  final String trUrl;
  final String certNum;
  final String reqDate;
  final String certMet;
  final String plusInfo;

  const KmcRequestResult({
    required this.trCert,
    required this.cpId,
    required this.trUrl,
    required this.certNum,
    required this.reqDate,
    required this.certMet,
    required this.plusInfo,
  });

  factory KmcRequestResult.fromJson(Map<String, dynamic> json) {
    return KmcRequestResult(
      trCert: json['trCert'] ?? '',
      cpId: json['cpId'] ?? '',
      trUrl: json['trUrl'] ?? '',
      certNum: json['certNum'] ?? '',
      reqDate: json['reqDate'] ?? '',
      certMet: json['certMet'] ?? 'T',
      plusInfo: json['plusInfo'] ?? '',
    );
  }
}

/// KMC 인증 검증 결과 데이터
class KmcVerifyResult {
  final bool verified;
  final String name;
  final String phoneNumber;
  final String birth;
  final String gender;
  final String di;

  const KmcVerifyResult({
    required this.verified,
    required this.name,
    required this.phoneNumber,
    required this.birth,
    required this.gender,
    required this.di,
  });

  factory KmcVerifyResult.fromJson(Map<String, dynamic> json) {
    return KmcVerifyResult(
      verified: json['verified'] ?? false,
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      birth: json['birth'] ?? '',
      gender: json['gender'] ?? '',
      di: json['di'] ?? '',
    );
  }

  /// 생년월일을 DateTime으로 변환
  DateTime? get birthDate {
    if (birth.length != 8) return null;
    try {
      return DateTime(
        int.parse(birth.substring(0, 4)),
        int.parse(birth.substring(4, 6)),
        int.parse(birth.substring(6, 8)),
      );
    } catch (_) {
      return null;
    }
  }
}

/// KMC 인증 예외
class KmcException implements Exception {
  final String code;
  final String message;

  KmcException({required this.code, required this.message});

  @override
  String toString() => message;
}
