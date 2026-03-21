/// 모바일용 Stub 파일
///
/// 웹 전용 PaymentServiceWeb을 모바일에서 import할 때 사용하는 더미 클래스입니다.
/// conditional import로 인해 실제로 사용되지는 않습니다.

/// PayTag SDK 결제 응답 (stub)
class PayTagResponse {
  final bool proceed;
  final String resultcode;
  final String errmsg;
  final String? recvPayparam;
  final String? payType;
  final String? payerName;
  final String? payerHp;
  final String? payerEmail;
  final String? tranInst;

  PayTagResponse({
    required this.proceed,
    required this.resultcode,
    required this.errmsg,
    this.recvPayparam,
    this.payType,
    this.payerName,
    this.payerHp,
    this.payerEmail,
    this.tranInst,
  });

  bool get isSuccess => proceed && resultcode == '0000';
}

class PaymentServiceWeb {
  PaymentServiceWeb() {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<PayTagResponse> requestPayment({
    required String orderId,
    required int amount,
    required String orderName,
    required String payType,
    String installment = '00',
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<PayTagResponse> requestPaymentWithContractId({
    required int contractId,
    required String orderId,
    required int amount,
    required String orderName,
    required String payType,
    String installment = '00',
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<PayTagResponse> requestRentalPayment({
    required int rentalOrderId,
    required String orderId,
    required int amount,
    required String orderName,
    required String payType,
    String installment = '00',
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }
}
