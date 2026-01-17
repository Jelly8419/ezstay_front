/// 모바일용 Stub 파일
///
/// 웹 전용 PaymentServiceWeb을 모바일에서 import할 때 사용하는 더미 클래스입니다.
/// conditional import로 인해 실제로 사용되지는 않습니다.
class PaymentServiceWeb {
  PaymentServiceWeb() {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<void> requestCardPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
    String? customerMobilePhone,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<void> requestTossPayPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
    String? customerMobilePhone,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<void> requestTransferPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
    String? customerMobilePhone,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }

  Future<void> requestVirtualAccountPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
    String? customerMobilePhone,
  }) {
    throw UnsupportedError('PaymentServiceWeb은 웹에서만 사용 가능합니다.');
  }
}
