import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// 결제 서비스
///
/// 토스페이먼츠 결제 관련 API 통신을 담당합니다.
class PaymentService {
  final String baseUrl = PaymentConfig.baseUrl;
  final AuthService _authService = AuthService();

  /// 결제 정보 조회
  ///
  /// 백엔드에서 결제에 필요한 정보(orderId, amount, orderName 등)를 가져옵니다.
  Future<Map<String, dynamic>> getPaymentInfo(int contractId) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 [PaymentService] 결제 정보 요청: contractId=$contractId');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/contracts/$contractId/payment-info'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [PaymentService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ [PaymentService] 결제 정보 조회 성공');
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('계약을 찾을 수 없습니다.');
      } else if (response.statusCode == 403) {
        throw Exception('결제 권한이 없습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '결제 정보 조회 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 결제 승인 (실제 결제)
  ///
  /// 토스페이먼츠 결제 성공 후 백엔드에 결제 승인을 요청합니다.
  Future<Map<String, dynamic>> confirmPayment({
    required int contractId,
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 [PaymentService] 결제 승인 요청');
    debugPrint('  - contractId: $contractId');
    debugPrint('  - paymentKey: $paymentKey');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/confirm-payment'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 [PaymentService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ [PaymentService] 결제 승인 성공');
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '잘못된 결제 정보입니다.');
      } else if (response.statusCode == 409) {
        throw Exception('이미 결제된 계약입니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '결제 승인 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// Mock 결제 승인 (테스트용)
  ///
  /// 실제 결제 없이 백엔드에서 결제 완료 처리합니다.
  Future<Map<String, dynamic>> confirmPaymentMock({
    required int contractId,
    required String orderId,
    required int amount,
    bool simulateFailure = false,
  }) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('🎭 [PaymentService] Mock 결제 승인 요청');
    debugPrint('  - contractId: $contractId');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');
    debugPrint('  - simulateFailure: $simulateFailure');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/confirm-payment-mock'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderId': orderId,
          'amount': amount,
          'simulateFailure': simulateFailure,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [PaymentService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ [PaymentService] Mock 결제 승인 성공');
        return data['data'] as Map<String, dynamic>;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Mock 결제 실패');
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
