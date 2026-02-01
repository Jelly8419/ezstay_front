import 'package:flutter/foundation.dart';
import 'payment_service.dart';
import 'payment_service_web.dart'
    if (dart.library.io) 'payment_service_stub.dart';

/// 통합 결제 서비스
///
/// 웹과 모바일 플랫폼에 따라 적절한 결제 방식을 자동으로 선택합니다.
/// - 웹: JavaScript SDK 사용
/// - 모바일: WebView 사용
class PaymentServiceUnified {
  final PaymentService _apiService = PaymentService();
  PaymentServiceWeb? _webService;

  /// 생성자 - 웹 환경에서 자동으로 SDK 초기화
  ///
  /// SDK 초기화 실패 시에도 앱이 계속 작동하도록 예외를 catch합니다.
  PaymentServiceUnified() {
    if (kIsWeb) {
      try {
        _webService = PaymentServiceWeb();
        debugPrint('✅ [PaymentServiceUnified] 웹 SDK 자동 초기화 완료');
      } catch (e) {
        debugPrint('⚠️ [PaymentServiceUnified] 웹 SDK 초기화 실패: $e');
        debugPrint('⚠️ [PaymentServiceUnified] 결제 기능이 비활성화됩니다. 앱은 계속 작동합니다.');
        _webService = null;
      }
    }
  }

  /// 웹 SDK 초기화 (하위 호환성을 위해 유지, 생성자에서 자동 호출됨)
  @Deprecated('생성자에서 자동으로 초기화됩니다. 이 메서드는 호출할 필요가 없습니다.')
  void initializeWebSDK() {
    if (kIsWeb && _webService == null) {
      try {
        _webService = PaymentServiceWeb();
      } catch (e) {
        debugPrint('⚠️ [PaymentServiceUnified] initializeWebSDK 실패: $e');
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
  /// 웹: JavaScript SDK로 결제창 호출 (토스 SDK가 결제수단 선택 UI 제공)
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

  /// 웹 결제 요청 (JavaScript SDK)
  ///
  /// 토스페이먼츠 SDK가 자체적으로 결제수단 선택 UI를 제공하므로
  /// 별도의 결제수단 선택 모달이 필요 없습니다.
  Future<Map<String, dynamic>?> _requestPaymentWeb({
    required int contractId,
    required Map<String, dynamic> paymentInfo,
  }) async {
    if (_webService == null) {
      throw Exception('웹 결제 서비스가 초기화되지 않았습니다. initializeWebSDK()를 호출하세요.');
    }

    final orderId = paymentInfo['orderId'] as String;
    final amount = paymentInfo['amount'] as int;
    final orderName = paymentInfo['orderName'] as String;
    final customerName = paymentInfo['customerName'] as String?;
    final customerEmail = paymentInfo['customerEmail'] as String?;

    debugPrint('🌐 [PaymentServiceUnified] 웹 결제 요청');
    debugPrint('  - contractId: $contractId');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');

    try {
      // 토스 SDK가 모든 결제수단을 표시하므로 통합 메서드 호출
      // contractId를 successUrl/failUrl에 포함시켜 callback에서 사용
      await _webService!.requestPaymentWithContractId(
        contractId: contractId,
        orderId: orderId,
        amount: amount,
        orderName: orderName,
        customerName: customerName,
        customerEmail: customerEmail,
      );

      // 웹에서는 자동 리다이렉트되므로 null 반환
      // 실제 결과는 successUrl/failUrl로 전달됨
      return null;
    } catch (e) {
      debugPrint('❌ [PaymentServiceUnified] 웹 결제 요청 실패: $e');
      rethrow;
    }
  }

  /// 모바일 결제 요청 (WebView)
  Future<Map<String, dynamic>?> _requestPaymentMobile({
    required int contractId,
    required Map<String, dynamic> paymentInfo,
  }) async {
    debugPrint('📱 [PaymentServiceUnified] 모바일 결제 요청');

    // TODO: 모바일 WebView 구현
    // 기존 PaymentWebView 위젯 사용
    throw UnimplementedError('모바일 결제는 PaymentWebView 위젯을 직접 사용하세요.');
  }

  /// 결제 승인 (실제 결제)
  Future<Map<String, dynamic>> confirmPayment({
    required int contractId,
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    return await _apiService.confirmPayment(
      contractId: contractId,
      paymentKey: paymentKey,
      orderId: orderId,
      amount: amount,
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
}
