@JS()
library;

import 'dart:async';
import 'dart:js_util';
import 'package:js/js.dart';
import 'package:flutter/foundation.dart';
import '../config/payment_config.dart';

@JS('window.open')
external dynamic _windowOpen(String url, String target, String features);

/// 팝업 차단 예외
class PopupBlockedException implements Exception {
  final String message = '팝업이 차단되어 결제창을 열 수 없습니다.\n브라우저 설정에서 팝업 차단을 해제해주세요.';
  @override
  String toString() => message;
}

/// PayTag SDK Tag.requestPay 바인딩
@JS('Tag.requestPay')
external void _tagRequestPay(dynamic params, dynamic callback);

/// PayTag SDK 초기화 확인 (Tag.init이 index.html에서 호출됨)
@JS('Tag')
external dynamic get _tagGlobal;

/// PayTag SDK 결제 응답
///
/// Tag.requestPay 콜백으로 전달되는 응답 객체
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

  /// JS 객체에서 PayTagResponse로 변환
  factory PayTagResponse.fromJs(dynamic jsObj) {
    return PayTagResponse(
      proceed: getProperty(jsObj, 'proceed') ?? false,
      resultcode: getProperty(jsObj, 'resultcode')?.toString() ?? '',
      errmsg: getProperty(jsObj, 'errmsg')?.toString() ?? '알 수 없는 오류',
      recvPayparam: getProperty(jsObj, 'recv_payparam')?.toString(),
      payType: getProperty(jsObj, 'pay_type')?.toString(),
      payerName: getProperty(jsObj, 'payer_name')?.toString(),
      payerHp: getProperty(jsObj, 'payer_hp')?.toString(),
      payerEmail: getProperty(jsObj, 'payer_email')?.toString(),
      tranInst: getProperty(jsObj, 'tran_inst')?.toString(),
    );
  }

  bool get isSuccess => proceed && resultcode == '0000';
}

/// 웹 전용 PayTag 결제 서비스
///
/// PayTag JavaScript SDK를 사용하여 웹 브라우저에서 결제를 처리합니다.
/// Toss와 달리 URL 리다이렉트 방식이 아닌 JS 콜백 방식으로 결과를 수신합니다.
///
/// 사용 예시:
/// ```dart
/// final paymentService = PaymentServiceWeb();
/// final response = await paymentService.requestPayment(
///   orderId: 'ORDER_12345',
///   amount: 10000,
///   orderName: 'EZStay 계약금 결제',
/// );
/// if (response.isSuccess) {
///   // recvPayparam으로 백엔드 승인 요청
/// }
/// ```
class PaymentServiceWeb {
  bool _isInitialized = false;

  PaymentServiceWeb() {
    _checkSDK();
  }

  /// SDK 로드 확인 (Tag.init은 index.html에서 수행)
  void _checkSDK() {
    try {
      final tag = _tagGlobal;
      if (tag != null) {
        _isInitialized = true;
        debugPrint('✅ [PaymentServiceWeb] PayTag SDK 확인 완료');
      } else {
        debugPrint('⚠️ [PaymentServiceWeb] PayTag SDK가 로드되지 않았습니다.');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('⚠️ [PaymentServiceWeb] PayTag SDK 확인 실패: $e');
      _isInitialized = false;
    }
  }

  /// SDK 초기화 확인
  void _ensureInitialized() {
    if (!_isInitialized) {
      // 재시도
      _checkSDK();
      if (!_isInitialized) {
        throw Exception('PayTag SDK가 초기화되지 않았습니다');
      }
    }
  }

  /// 팝업 차단 여부 감지
  ///
  /// window.open으로 테스트 팝업을 열어 차단 여부를 확인합니다.
  /// 차단되면 true를 반환합니다.
  bool isPopupBlocked() {
    try {
      final popup = _windowOpen('about:blank', '_blank', 'width=1,height=1');
      if (popup == null) {
        debugPrint('⚠️ [PaymentServiceWeb] 팝업이 차단되었습니다');
        return true;
      }
      // 테스트 팝업 즉시 닫기
      callMethod(popup, 'close', []);
      return false;
    } catch (e) {
      debugPrint('⚠️ [PaymentServiceWeb] 팝업 차단 감지 중 오류: $e');
      return true;
    }
  }

  /// 통합 결제 요청 (기본 - 신용카드)
  ///
  /// PayTag SDK의 Tag.requestPay를 호출하고 콜백으로 결과를 수신합니다.
  /// Toss와 달리 리다이렉트가 아닌 즉시 응답을 반환합니다.
  ///
  /// [orderId]: 주문 ID (백엔드에서 생성)
  /// [amount]: 결제 금액
  /// [orderName]: 주문명
  /// [payType]: 결제수단 코드 (기본: 'CARD')
  /// [installment]: 할부 개월 (기본: '00' 일시불)
  /// [customerName]: 구매자 이름
  /// [customerPhone]: 구매자 전화번호
  /// [customerEmail]: 구매자 이메일
  Future<PayTagResponse> requestPayment({
    required String orderId,
    required int amount,
    required String orderName,
    required String payType,
    String installment = '00',
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    _ensureInitialized();

    // 팝업 차단 여부 사전 감지
    if (isPopupBlocked()) {
      throw PopupBlockedException();
    }

    debugPrint('💳 [PaymentServiceWeb] PayTag 결제 요청');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');
    debugPrint('  - payType: $payType');
    debugPrint('  - orderName: $orderName');

    final completer = Completer<PayTagResponse>();

    try {
      // JS 객체로 파라미터 생성
      final params = newObject<dynamic>();
      setProperty(params, 'resType', '1'); // API Direct 방식 (필수)
      setProperty(params, 'reqtype', '');
      setProperty(params, 'payType', payType);
      setProperty(params, 'shop_orderno', orderId);
      setProperty(params, 'tran_amt', amount);
      setProperty(params, 'tran_inst', installment);
      setProperty(params, 'goods_name', orderName);
      setProperty(params, 'order_name', customerName ?? '');
      setProperty(params, 'order_hp', customerPhone ?? '');
      setProperty(params, 'order_email', customerEmail ?? '');

      // TODO: 오픈 후 가상계좌 추가 시 웹훅 URL 활성화
      // final webhookUrl = PaymentConfig.webhookUrl;
      // if (webhookUrl.isNotEmpty) {
      //   setProperty(params, 'webhook_url', webhookUrl);
      // }

      // PayTag SDK 콜백
      final callback = allowInterop((dynamic resp) {
        try {
          final response = PayTagResponse.fromJs(resp);
          debugPrint('📥 [PaymentServiceWeb] PayTag 응답: resultcode=${response.resultcode}');

          if (response.isSuccess) {
            debugPrint('✅ [PaymentServiceWeb] 결제 인증 성공');
            debugPrint('  - payType: ${response.payType}');
            debugPrint('  - recvPayparam: ${response.recvPayparam?.substring(0, 20)}...');
          } else {
            debugPrint('❌ [PaymentServiceWeb] 결제 실패: ${response.errmsg}');
          }

          completer.complete(response);
        } catch (e) {
          debugPrint('❌ [PaymentServiceWeb] 응답 파싱 실패: $e');
          completer.completeError(e);
        }
      });

      _tagRequestPay(params, callback);
    } catch (e) {
      debugPrint('❌ [PaymentServiceWeb] Tag.requestPay 호출 실패: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  /// 계약 결제 요청 (contractId 포함)
  ///
  /// 계약 결제에 특화된 메서드로, PayTag SDK 응답과 함께
  /// contractId를 포함한 결과를 반환합니다.
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
  }) async {
    debugPrint('💳 [PaymentServiceWeb] 계약 결제 요청 (contractId: $contractId)');

    return requestPayment(
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      payType: payType,
      installment: installment,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
  }

  /// 렌탈 추가 결제 요청
  ///
  /// 렌탈 아이템 추가 주문에 대한 결제를 요청합니다.
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
  }) async {
    debugPrint('💳 [PaymentServiceWeb] 렌탈 결제 요청 (rentalOrderId: $rentalOrderId)');

    return requestPayment(
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      payType: payType,
      installment: installment,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
  }
}
