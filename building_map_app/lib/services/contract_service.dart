import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

/// 계약 요청 서비스
class ContractService {
  ContractService();

  /// 계약 승인 요청
  Future<Map<String, dynamic>> requestContract({
    required int roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int totalDays,
    required int totalWeeks,
    required int rentalFee,
    required int maintenanceFee,
    required int cleaningFee,
    required int rentalItemsFee,
    required int platformFee,
    required int discountAmount,
    required int subtotal,
    required int totalUsageFee,
    required int deposit,
    required int finalTotalAmount,
    Map<String, dynamic>? rentalItems,
    String? guestMessage,
    String? discountCode,
    String? discountType,
    String? paymentMethod,
    int? installmentMonths,
    required bool serviceTermsAgreed,
    required bool cancellationPolicyAgreed,
    required bool refundPolicyAgreed,
    bool? earlyCheckIn,
    bool? lateCheckOut,
    bool? petAccompanying,
    String? additionalNotes,
    required double dailyRentalFee,
    required double dailyMaintenanceFee,
    required double platformFeeRate,
    required double depositRate,
  }) async {
    // 유효한 토큰 가져오기 (자동 갱신 포함)
    final token = await TokenService.getValidAccessToken(autoRefresh: true);

    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final body = {
      // 필수 필드
      'roomId': roomId,
      'checkInDate': checkInDate.toIso8601String().split('T')[0],
      'checkOutDate': checkOutDate.toIso8601String().split('T')[0],
      'totalDays': totalDays,
      'totalWeeks': totalWeeks,

      // 금액 (백엔드에서 재검증)
      'rentalFee': rentalFee,
      'maintenanceFee': maintenanceFee,
      'cleaningFee': cleaningFee,
      'rentalItemsFee': rentalItemsFee,
      'platformFee': platformFee,
      'discountAmount': discountAmount,
      'subtotal': subtotal,
      'totalUsageFee': totalUsageFee,
      'deposit': deposit,
      'finalTotalAmount': finalTotalAmount,

      // 렌탈 아이템
      if (rentalItems != null && rentalItems.isNotEmpty) 'rentalItems': rentalItems,

      // 메시지
      if (guestMessage != null && guestMessage.isNotEmpty) 'guestMessage': guestMessage,

      // 선택 필드
      if (discountCode != null && discountCode.isNotEmpty) 'discountCode': discountCode,
      if (discountType != null && discountType.isNotEmpty) 'discountType': discountType,
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
      if (installmentMonths != null) 'installmentMonths': installmentMonths,

      // 약관 동의 (필수)
      'termsAgreed': {
        'serviceTerms': serviceTermsAgreed,
        'cancellationPolicy': cancellationPolicyAgreed,
        'refundPolicy': refundPolicyAgreed,
      },

      // 특별 요청
      if (earlyCheckIn != null || lateCheckOut != null || petAccompanying != null || (additionalNotes != null && additionalNotes.isNotEmpty))
        'specialRequests': {
          if (earlyCheckIn != null) 'earlyCheckIn': earlyCheckIn,
          if (lateCheckOut != null) 'lateCheckOut': lateCheckOut,
          if (petAccompanying != null) 'petAccompanying': petAccompanying,
          if (additionalNotes != null && additionalNotes.isNotEmpty) 'additionalNotes': additionalNotes,
        },

      // 가격 스냅샷 (분쟁 대비)
      'pricingSnapshot': {
        'dailyRentalFee': dailyRentalFee,
        'dailyMaintenanceFee': dailyMaintenanceFee,
        'platformFeeRate': platformFeeRate,
        'depositRate': depositRate,
        'snapshotTimestamp': DateTime.now().toIso8601String(),
      },
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/contracts/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? '잘못된 요청입니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 409) {
        throw Exception('이미 예약된 기간입니다.');
      } else {
        throw Exception('계약 승인 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('서버 응답 시간이 초과되었습니다. 다시 시도해주세요.');
      }
      rethrow;
    }
  }
}
