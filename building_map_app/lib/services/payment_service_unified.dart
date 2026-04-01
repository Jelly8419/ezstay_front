import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

import 'payment_service.dart';
import 'rental_order_service.dart';
import 'payment_service_web.dart'
    if (dart.library.io) 'payment_service_stub.dart';

/// 통합 결제 서비스
///
/// 웹과 모바일 플랫폼에 따라 적절한 결제 방식을 자동으로 선택합니다.
/// - 웹: PayTag JavaScript SDK 사용 (Tag.requestPay 콜백 방식)
/// - 모바일: WebView 사용
class PaymentServiceUnified {
  final PaymentService _apiService = PaymentService();
  final RentalOrderService _rentalOrderService = RentalOrderService();
  PaymentServiceWeb? _webService;

  /// 생성자 - 웹 환경에서 자동으로 SDK 초기화
  PaymentServiceUnified() {
    if (kIsWeb) {
      try {
        _webService = PaymentServiceWeb();
      } catch (e) {
        AppLogger.w('⚠️ [PaymentServiceUnified] 웹 SDK 초기화 실패: $e');
        _webService = null;
      }
    }
  }

  /// 결제 정보 조회 (공통 API)
  Future<Map<String, dynamic>> getPaymentInfo(int contractId) async {
    return await _apiService.getPaymentInfo(contractId);
  }

  /// 결제 요청 (플랫폼별 분기)
  ///
  /// 웹: PayTag SDK로 결제 → 콜백으로 즉시 결과 수신 → 백엔드 승인까지 처리
  /// 모바일: WebView로 결제창 표시 (반환값으로 결과 전달)
  Future<Map<String, dynamic>?> requestPayment({
    required int contractId,
    required Map<String, dynamic> paymentInfo,
  }) async {
    if (kIsWeb) {
      return await _requestPaymentWeb(
        contractId: contractId,
        paymentInfo: paymentInfo,
      );
    } else {
      return await _requestPaymentMobile(
        contractId: contractId,
        paymentInfo: paymentInfo,
      );
    }
  }

  /// 웹 결제 요청 (PayTag SDK)
  ///
  /// PayTag SDK의 Tag.requestPay를 호출하고 콜백으로 결과를 수신합니다.
  /// 성공 시 자동으로 백엔드 승인 API를 호출합니다.
  Future<Map<String, dynamic>?> _requestPaymentWeb({
    required int contractId,
    required Map<String, dynamic> paymentInfo,
  }) async {
    if (_webService == null) {
      throw Exception('웹 결제 서비스가 초기화되지 않았습니다.');
    }

    final orderId = paymentInfo['orderId'] as String;
    final actualAmount = paymentInfo['amount'] as int;
    final pgAmount = paymentInfo['pgAmount'] as int?;
    final orderName = paymentInfo['orderName'] as String;
    final customerName = paymentInfo['customerName'] as String?;
    final customerEmail = paymentInfo['customerEmail'] as String?;
    final customerPhone = paymentInfo['customerPhone'] as String?;
    final payType = paymentInfo['payType'] as String? ?? 'BC';

    // PG SDK 호출 금액: 백엔드에서 pgAmount를 내려주면 해당 값 사용, 없으면 실제 금액
    final sdkAmount = pgAmount ?? actualAmount;


    try {
      // PayTag SDK 호출 → 콜백으로 즉시 결과 수신
      // 테스트 환경에서는 100원으로 SDK 결제, 백엔드에는 실제 금액 전달
      final response = await _webService!.requestPaymentWithContractId(
        contractId: contractId,
        orderId: orderId,
        amount: sdkAmount,
        orderName: orderName,
        payType: payType,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

      if (response.isSuccess && response.recvPayparam != null) {
        // 결제 인증 성공 → 백엔드 승인 API 호출 (실제 금액으로 전달)
        final confirmResult = await _apiService.confirmPayment(
          contractId: contractId,
          recvPayparam: response.recvPayparam!,
          orderId: orderId,
          amount: actualAmount,
          payType: response.payType,
        );
        return confirmResult;
      } else {
        // 결제 실패 또는 사용자 취소
        throw Exception(response.errmsg);
      }
    } catch (e) {
      AppLogger.e('❌ [PaymentServiceUnified] 웹 결제 실패: $e');
      rethrow;
    }
  }

  /// 모바일 결제 요청 (WebView)
  Future<Map<String, dynamic>?> _requestPaymentMobile({
    required int contractId,
    required Map<String, dynamic> paymentInfo,
  }) async {

    // TODO: 모바일 WebView 구현
    throw UnimplementedError('모바일 결제는 PaymentWebView 위젯을 직접 사용하세요.');
  }

  /// 결제 승인 (직접 호출용)
  ///
  /// 모바일 WebView에서 결제 결과를 받은 후 직접 승인할 때 사용합니다.
  Future<Map<String, dynamic>> confirmPayment({
    required int contractId,
    required String recvPayparam,
    required String orderId,
    required int amount,
    String? payType,
  }) async {
    return await _apiService.confirmPayment(
      contractId: contractId,
      recvPayparam: recvPayparam,
      orderId: orderId,
      amount: amount,
      payType: payType,
    );
  }

  /// Mock 결제 승인 (테스트용)
  Future<Map<String, dynamic>> confirmPaymentMock({
    required int contractId,
    required String orderId,
    required int amount,
    bool simulateFailure = false,
  }) async {
    return await _apiService.confirmPaymentMock(
      contractId: contractId,
      orderId: orderId,
      amount: amount,
      simulateFailure: simulateFailure,
    );
  }

  /// 렌탈 추가 결제 요청 (웹 전용)
  ///
  /// PayTag SDK를 호출하여 렌탈 아이템 추가 결제를 진행합니다.
  /// 성공 시 백엔드 승인까지 자동 처리합니다.
  Future<Map<String, dynamic>?> requestRentalPayment({
    required int rentalOrderId,
    required Map<String, dynamic> paymentInfo,
    required String payType,
  }) async {
    if (!kIsWeb) {
      throw Exception('렌탈 추가 결제는 현재 웹에서만 지원됩니다.');
    }

    if (_webService == null) {
      throw Exception('웹 결제 서비스가 초기화되지 않았습니다.');
    }

    final orderId = paymentInfo['orderId'] as String;
    final actualAmount = (paymentInfo['amount'] as num).toInt();
    final pgAmount = paymentInfo['pgAmount'] == null ? null : (paymentInfo['pgAmount'] as num).toInt();
    final orderName = paymentInfo['orderName'] as String? ?? '렌탈 아이템 추가';
    final customerName = paymentInfo['customerName'] as String?;
    final customerEmail = paymentInfo['customerEmail'] as String?;
    final customerPhone = paymentInfo['customerPhone'] as String?;

    // PG SDK 호출 금액: pgAmount가 있으면 사용, 없으면 실제 금액
    final sdkAmount = pgAmount ?? actualAmount;

    try {
      final response = await _webService!.requestRentalPayment(
        rentalOrderId: rentalOrderId,
        orderId: orderId,
        amount: sdkAmount,
        orderName: orderName,
        payType: payType,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

      if (response.isSuccess && response.recvPayparam != null) {
        // SDK 인증 성공 → 백엔드 승인 API 호출 (실제 금액으로 전달)
        final confirmResult = await _rentalOrderService.confirmPayment(
          rentalOrderId: rentalOrderId,
          recvPayparam: response.recvPayparam!,
          orderId: orderId,
          amount: actualAmount,
          payType: response.payType,
        );
        return confirmResult;
      } else {
        throw Exception(response.errmsg);
      }
    } catch (e) {
      AppLogger.e('❌ [PaymentServiceUnified] 렌탈 결제 요청 실패: $e');
      rethrow;
    }
  }
}
