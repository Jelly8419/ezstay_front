import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/bank_account.dart';
import 'auth_service.dart';

/// 게스트 환급 계좌 관리 서비스
/// Backend API: /api/account/refund
class RefundAccountService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  /// 환급 계좌 조회
  /// GET /api/account/refund
  ///
  /// 반환:
  /// - BankAccount: 계좌 정보 객체
  /// - null: 계좌 미등록 (404)
  Future<BankAccount?> getRefundAccount() async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🏦 [RefundAccountService] 환급 계좌 조회 시작');

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.refundAccountUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

      debugPrint('📥 [RefundAccountService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data']?['account'] != null) {
          final account = BankAccount.fromJson(
            data['data']['account'] as Map<String, dynamic>,
          );
          debugPrint('✅ [RefundAccountService] 환급 계좌 조회 성공: ${account.bankName}');
          return account;
        }
        return null;
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ [RefundAccountService] 환급 계좌 미등록 (404)');
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '환급 계좌 조회 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 환급 계좌 저장/수정
  /// POST /api/account/refund
  ///
  /// 신규 등록 시 201, 수정 시 200 반환
  Future<BankAccount> saveRefundAccount({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🏦 [RefundAccountService] 환급 계좌 저장 시작');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refundAccountUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bank_code': bankCode,
          'account_num': accountNum,
          'account_holder_name': accountHolderName,
        }),
      ).timeout(ApiConfig.timeout);

      debugPrint('📥 [RefundAccountService] 응답: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data']?['account'] != null) {
          final account = BankAccount.fromJson(
            data['data']['account'] as Map<String, dynamic>,
          );
          debugPrint('✅ [RefundAccountService] 환급 계좌 저장 성공');
          return account;
        }
        throw Exception('응답 형식이 올바르지 않습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '환급 계좌 저장 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 예금주 확인
  /// POST /api/account/refund/verify
  ///
  /// 반환: {verified: bool, accountHolderName: String}
  Future<Map<String, dynamic>> verifyAccount({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🏦 [RefundAccountService] 예금주 확인 시작');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refundAccountVerifyUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bank_code': bankCode,
          'account_num': accountNum,
          'account_holder_name': accountHolderName,
        }),
      ).timeout(ApiConfig.timeout);

      debugPrint('📥 [RefundAccountService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final verified = data['data']['verified'] as bool? ?? false;
          final actualName = data['data']['accountHolderName'] as String?;
          debugPrint('✅ [RefundAccountService] 예금주 확인: verified=$verified, name=$actualName');
          return {
            'verified': verified,
            'accountHolderName': actualName ?? accountHolderName,
          };
        }
        throw Exception('응답 형식이 올바르지 않습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '예금주 확인 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 환급 계좌 삭제
  /// DELETE /api/account/refund
  Future<void> deleteRefundAccount() async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🏦 [RefundAccountService] 환급 계좌 삭제 시작');

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.refundAccountUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

      debugPrint('📥 [RefundAccountService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [RefundAccountService] 환급 계좌 삭제 성공');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '환급 계좌 삭제 실패');
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
