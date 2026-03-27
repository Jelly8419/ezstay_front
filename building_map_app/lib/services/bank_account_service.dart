import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/bank_account.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../core/exceptions.dart';

/// 계좌 정보 관리 서비스 (호스트 전용)
/// Backend API: /api/host/account
class BankAccountService {
  final ApiClient _apiClient = ApiClient();

  /// 계좌 정보 조회
  /// GET /api/host/account
  ///
  /// 반환:
  /// - BankAccount: 계좌 정보 객체
  /// - null: 계좌 미등록 (404 에러)
  ///
  /// 예외:
  /// - Exception: 서버 에러 또는 네트워크 에러
  Future<BankAccount?> getBankAccount() async {
    try {

      // 액세스 토큰 가져오기
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw const UnauthorizedException('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/account');
      final response = await _apiClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      // response가 null이면 네트워크 에러
      if (response == null) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final accountData = data['data']['account'] as Map<String, dynamic>;
          final bankAccount = BankAccount.fromJson(accountData);

          return bankAccount;
        } else {
          AppLogger.w('⚠️ [BankAccountService] 응답 형식 오류: $data');
          throw Exception('계좌 정보를 불러올 수 없습니다.');
        }
      } else if (response.statusCode == 404) {
        // 계좌 미등록 (정상 케이스)
        return null;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? '계좌 정보 조회 실패';
        AppLogger.e('❌ [BankAccountService] 에러: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('❌ [BankAccountService] 예외 발생: $e');
      rethrow;
    }
  }

  /// 계좌 등록 여부 확인
  /// GET /api/host/account
  ///
  /// 반환:
  /// - true: 계좌 등록됨
  /// - false: 계좌 미등록
  Future<bool> hasBankAccount() async {
    try {
      final account = await getBankAccount();
      return account != null;
    } catch (e) {
      AppLogger.e('❌ [BankAccountService] 계좌 등록 여부 확인 실패: $e');
      return false;
    }
  }

  /// 정산계좌 등록/수정
  /// POST /api/account
  Future<BankAccount> saveSettlementAccount({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
  }) async {
    final accessToken = await TokenService.getValidAccessToken();
    if (accessToken == null) {
      throw const UnauthorizedException('로그인이 필요합니다.');
    }


    final response = await _apiClient.post(
      Uri.parse(ApiConfig.hostSettlementAccountUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'bank_code': bankCode,
        'account_num': accountNum,
        'account_holder_name': accountHolderName,
      }),
    );

    if (response == null) {
      throw Exception('네트워크 연결을 확인해주세요.');
    }


    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data']?['account'] != null) {
        final account = BankAccount.fromJson(
          data['data']['account'] as Map<String, dynamic>,
        );
        return account;
      }
      throw Exception('응답 형식이 올바르지 않습니다.');
    } else if (response.statusCode == 401) {
      throw const UnauthorizedException();
    } else {
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? '정산계좌 저장 실패');
    }
  }

  /// 예금주 확인
  /// POST /api/account/refund/verify (게스트와 동일 엔드포인트)
  Future<Map<String, dynamic>> verifyAccount({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
  }) async {
    final accessToken = await TokenService.getValidAccessToken();
    if (accessToken == null) {
      throw const UnauthorizedException('로그인이 필요합니다.');
    }


    final response = await _apiClient.post(
      Uri.parse(ApiConfig.hostSettlementAccountVerifyUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'bank_code': bankCode,
        'account_num': accountNum,
        'account_holder_name': accountHolderName,
      }),
    );

    if (response == null) {
      throw Exception('네트워크 연결을 확인해주세요.');
    }


    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        final verified = data['data']['verified'] as bool? ?? false;
        final actualName = data['data']['accountHolderName'] as String?;
        return {
          'verified': verified,
          'accountHolderName': actualName ?? accountHolderName,
        };
      }
      throw Exception('응답 형식이 올바르지 않습니다.');
    } else if (response.statusCode == 401) {
      throw const UnauthorizedException();
    } else {
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? '예금주 확인 실패');
    }
  }
}
