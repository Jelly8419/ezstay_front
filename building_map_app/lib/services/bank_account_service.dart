import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/bank_account.dart';
import 'api_client.dart';
import 'token_service.dart';

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
      debugPrint('🏦 [BankAccountService] 계좌 정보 조회 시작');

      // 액세스 토큰 가져오기
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
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

      debugPrint('🏦 [BankAccountService] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final accountData = data['data']['account'] as Map<String, dynamic>;
          final bankAccount = BankAccount.fromJson(accountData);

          debugPrint('✅ [BankAccountService] 계좌 정보 조회 성공: ${bankAccount.bankName}');
          return bankAccount;
        } else {
          debugPrint('⚠️ [BankAccountService] 응답 형식 오류: $data');
          throw Exception('계좌 정보를 불러올 수 없습니다.');
        }
      } else if (response.statusCode == 404) {
        // 계좌 미등록 (정상 케이스)
        debugPrint('ℹ️ [BankAccountService] 계좌 미등록 (404)');
        return null;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? '계좌 정보 조회 실패';
        debugPrint('❌ [BankAccountService] 에러: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [BankAccountService] 예외 발생: $e');
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
      debugPrint('❌ [BankAccountService] 계좌 등록 여부 확인 실패: $e');
      return false;
    }
  }
}
