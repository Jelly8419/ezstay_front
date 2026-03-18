import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// 결제 서비스
///
/// PayTag PG 결제 관련 API 통신을 담당합니다.
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
  /// PayTag SDK 콜백 결과를 백엔드에 전달하여 결제 승인을 요청합니다.
  Future<Map<String, dynamic>> confirmPayment({
    required int contractId,
    required String recvPayparam,
    required String orderId,
    required int amount,
    String? payType,
  }) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 [PaymentService] 결제 승인 요청');
    debugPrint('  - contractId: $contractId');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');
    debugPrint('  - payType: $payType');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/confirm-payment'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recvPayparam': recvPayparam,
          'payType': payType ?? 'CARD',
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

  /// 호스트 위약금 결제 정보 조회
  ///
  /// 호스트 귀책 취소 시 호스트가 결제해야 할 위약금 정보를 조회합니다.
  /// 호스트 부담금 = (임대료 × 위약률) + 게스트 서비스 수수료
  Future<Map<String, dynamic>> getHostPenaltyPaymentInfo(int contractId) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 [PaymentService] 호스트 위약금 결제 정보 요청: contractId=$contractId');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/contracts/$contractId/host-penalty-info'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [PaymentService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ [PaymentService] 호스트 위약금 정보 조회 성공');
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('계약을 찾을 수 없습니다.');
      } else if (response.statusCode == 403) {
        throw Exception('권한이 없습니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '위약금 정보 조회 실패');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버 오류가 발생했습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// 호스트 위약금 결제 승인
  ///
  /// 호스트 귀책 취소 확정을 위한 위약금 결제를 승인합니다.
  /// 결제 완료 후: 게스트 PG 전액 환불 + 게스트 보전 지급이 처리됩니다.
  Future<Map<String, dynamic>> confirmHostPenaltyPayment({
    required int contractId,
    required String recvPayparam,
    required String orderId,
    required int amount,
    String? payType,
  }) async {
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 [PaymentService] 호스트 위약금 결제 승인 요청');
    debugPrint('  - contractId: $contractId');
    debugPrint('  - amount: $amount');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/confirm-host-penalty'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recvPayparam': recvPayparam,
          'payType': payType ?? 'CARD',
          'orderId': orderId,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 [PaymentService] 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ [PaymentService] 호스트 위약금 결제 승인 성공');
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '잘못된 결제 정보입니다.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '위약금 결제 승인 실패');
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
