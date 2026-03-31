import '../services/payment_service.dart';
import '../services/payment_service_unified.dart';
import '../services/rental_order_service.dart';

/// 게스트 결제 처리 서비스
/// - 계약 결제 (웹/모바일) 및 추가 옵션 결제 비즈니스 로직 담당
/// - UI 상태 변경은 콜백으로 위임
class GuestPaymentService {
  final PaymentServiceUnified _paymentService;
  final PaymentService _legacyPaymentService;
  final RentalOrderService _rentalOrderService;

  GuestPaymentService({
    PaymentServiceUnified? paymentService,
    PaymentService? legacyPaymentService,
    RentalOrderService? rentalOrderService,
  })  : _paymentService = paymentService ?? PaymentServiceUnified(),
        _legacyPaymentService = legacyPaymentService ?? PaymentService(),
        _rentalOrderService = rentalOrderService ?? RentalOrderService();

  /// 계약 결제 정보 조회
  Future<Map<String, dynamic>> getPaymentInfo(int contractId) async {
    return await _paymentService.getPaymentInfo(contractId);
  }

  /// 웹 결제 요청 (PayTag SDK)
  Future<Map<String, dynamic>?> requestWebPayment({
    required int contractId,
    required Map<String, dynamic> paymentInfo,
    required String payType,
  }) async {
    final enrichedPaymentInfo = Map<String, dynamic>.from(paymentInfo)
      ..['payType'] = payType;

    return await _paymentService.requestPayment(
      contractId: contractId,
      paymentInfo: enrichedPaymentInfo,
    );
  }

  /// 모바일 결제 승인 처리
  Future<void> confirmMobilePayment({
    required int contractId,
    required String recvPayparam,
    required String orderId,
    required int amount,
    String? payType,
  }) async {
    await _paymentService.confirmPayment(
      contractId: contractId,
      recvPayparam: recvPayparam,
      orderId: orderId,
      amount: amount,
      payType: payType,
    );
  }

  /// Mock 결제 처리 (개발/테스트 환경)
  Future<void> processMockPayment(int contractId) async {
    final paymentInfo = await _legacyPaymentService.getPaymentInfo(contractId);
    await _legacyPaymentService.confirmPaymentMock(
      contractId: contractId,
      orderId: paymentInfo['orderId'] as String,
      amount: paymentInfo['amount'] as int,
    );
  }

  /// 추가 옵션 주문 생성 + 결제 정보 조회
  /// 반환: {rentalOrderId, paymentInfo} 또는 빈 옵션 시 null
  Future<AdditionalOptionPaymentData?> prepareAdditionalOptionPayment({
    required int contractId,
    required Map<int, int> selectedOptions,
  }) async {
    if (selectedOptions.isEmpty) return null;

    final items = <RentalOrderItem>[];
    for (final entry in selectedOptions.entries) {
      if (entry.value > 0) {
        items.add(RentalOrderItem(itemId: entry.key, quantity: entry.value));
      }
    }

    if (items.isEmpty) return null;

    final orderResponse = await _rentalOrderService.createRentalOrder(
      contractId: contractId,
      items: items,
    );

    final paymentInfo = await _rentalOrderService.getPaymentInfo(
      orderResponse.rentalOrderId,
    );

    return AdditionalOptionPaymentData(
      rentalOrderId: orderResponse.rentalOrderId,
      paymentInfo: paymentInfo,
    );
  }

  /// 추가 옵션 웹 결제 요청 (PayTag SDK)
  Future<void> requestAdditionalOptionWebPayment({
    required int rentalOrderId,
    required Map<String, dynamic> paymentInfo,
    required String payType,
  }) async {
    await _paymentService.requestRentalPayment(
      rentalOrderId: rentalOrderId,
      orderId: paymentInfo['orderId'] as String,
      amount: paymentInfo['amount'] as int,
      orderName: paymentInfo['orderName'] as String,
      payType: payType,
      customerName: paymentInfo['customerName'] as String?,
      customerEmail: paymentInfo['customerEmail'] as String?,
      customerPhone: paymentInfo['customerPhone'] as String?,
    );
  }
}

/// 추가 옵션 결제 준비 데이터
class AdditionalOptionPaymentData {
  final int rentalOrderId;
  final Map<String, dynamic> paymentInfo;

  const AdditionalOptionPaymentData({
    required this.rentalOrderId,
    required this.paymentInfo,
  });

  int get amount => paymentInfo['amount'] as int;
}
