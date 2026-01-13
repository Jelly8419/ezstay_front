@JS()
library payment_service_web;

import 'dart:async';
import 'package:js/js.dart';
import 'package:flutter/foundation.dart';
import '../config/payment_config.dart' as config;

/// 토스페이먼츠 V2 SDK 초기화 함수 바인딩
/// 사용법: const tossPayments = TossPayments(clientKey);
@JS('TossPayments')
external TossPaymentsJS tossPaymentsInit(String clientKey);

/// 토스페이먼츠 V2 SDK 인스턴스
@JS()
@anonymous
class TossPaymentsJS {
  /// payment() 메서드로 결제 인스턴스 생성
  external PaymentJS payment(PaymentOptionsJS config);
}

/// Payment 인스턴스 (결제 요청을 실제로 수행)
@JS()
@anonymous
class PaymentJS {
  /// 결제 요청
  external Promise requestPayment(PaymentRequest request);
}

/// Payment 설정 (customerKey)
@JS()
@anonymous
class PaymentOptionsJS {
  external String get customerKey;

  external factory PaymentOptionsJS({
    required String customerKey,
  });
}

/// 결제 요청 파라미터 (V2 API)
@JS()
@anonymous
class PaymentRequest {
  external String get method;
  external AmountJS get amount;
  external String get orderId;
  external String get orderName;
  external String get successUrl;
  external String get failUrl;
  external String? get customerName;
  external String? get customerEmail;
  external CardOptionsJS? get card;

  external factory PaymentRequest({
    required String method,
    required AmountJS amount,
    required String orderId,
    required String orderName,
    required String successUrl,
    required String failUrl,
    String? customerName,
    String? customerEmail,
    CardOptionsJS? card,
  });
}

/// 금액 정보
@JS()
@anonymous
class AmountJS {
  external String get currency;
  external int get value;

  external factory AmountJS({
    required String currency,
    required int value,
  });
}

/// 카드 결제 옵션
@JS()
@anonymous
class CardOptionsJS {
  external bool? get useEscrow;
  external String? get flowMode;
  external String? get easyPay;
  external String? get cardCompany;
  external bool? get useCardPoint;
  external bool? get useAppCardOnly;

  external factory CardOptionsJS({
    bool? useEscrow,
    String? flowMode,
    String? easyPay,
    String? cardCompany,
    bool? useCardPoint,
    bool? useAppCardOnly,
  });
}

/// Promise를 Dart Future로 변환하기 위한 헬퍼
@JS('Promise')
class Promise {
  external Promise then(Function onFulfilled, [Function? onRejected]);
}

/// 웹 전용 토스페이먼츠 결제 서비스
///
/// V2 Standard SDK를 사용하여 웹 브라우저에서 결제를 처리합니다.
///
/// 사용 예시:
/// ```dart
/// final paymentService = PaymentServiceWeb();
/// await paymentService.requestPayment(
///   orderId: 'ORDER_12345',
///   amount: 10000,
///   orderName: 'EZStay 계약금 결제',
/// );
/// ```
class PaymentServiceWeb {
  TossPaymentsJS? _tossPayments;
  PaymentJS? _payment;
  bool _isInitialized = false;

  PaymentServiceWeb() {
    _initializeSDK();
  }

  /// SDK 동기 초기화 (V2는 동기 API 사용)
  void _initializeSDK() {
    try {
      debugPrint('🔄 [PaymentServiceWeb] 토스페이먼츠 V2 SDK 초기화 중...');

      // V2 SDK는 동기 초기화
      _tossPayments = tossPaymentsInit(config.PaymentConfig.clientKey);

      // Payment 인스턴스 생성 (익명 사용자는 TossPayments.ANONYMOUS 사용)
      // 실제 고객 키가 있으면 해당 값 사용
      _payment = _tossPayments!.payment(
        PaymentOptionsJS(
          customerKey: 'ANONYMOUS', // 익명 사용자
        ),
      );

      _isInitialized = true;
      debugPrint('✅ [PaymentServiceWeb] 토스페이먼츠 V2 SDK 초기화 완료');
    } catch (e) {
      debugPrint('❌ [PaymentServiceWeb] SDK 초기화 실패: $e');
      rethrow;
    }
  }

  /// SDK 초기화 확인
  void _ensureInitialized() {
    if (!_isInitialized || _payment == null) {
      throw Exception('토스페이먼츠 SDK가 초기화되지 않았습니다');
    }
  }

  /// 카드 결제 요청 (모든 결제수단 표시)
  ///
  /// [orderId]: 주문 ID (백엔드에서 생성)
  /// [amount]: 결제 금액
  /// [orderName]: 주문명 (예: "EZStay 계약금 결제")
  /// [customerName]: 구매자 이름 (선택)
  /// [customerEmail]: 구매자 이메일 (선택)
  /// [flowMode]: 결제창 타입 ('DEFAULT' 또는 'DIRECT')
  /// [easyPay]: 간편결제 지정 ('TOSSPAY' 등, flowMode='DIRECT'일 때)
  /// [cardCompany]: 카드사 지정 (flowMode='DIRECT'일 때)
  Future<void> requestCardPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
    String? flowMode,
    String? easyPay,
    String? cardCompany,
  }) async {
    _ensureInitialized();

    debugPrint('💳 [PaymentServiceWeb] 카드 결제 요청');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');
    debugPrint('  - orderName: $orderName');

    try {
      final request = PaymentRequest(
        method: 'CARD',
        amount: AmountJS(
          currency: 'KRW',
          value: amount,
        ),
        orderId: orderId,
        orderName: orderName,
        successUrl: config.PaymentConfig.successUrl,
        failUrl: config.PaymentConfig.failUrl,
        customerName: customerName,
        customerEmail: customerEmail,
        card: CardOptionsJS(
          useEscrow: false,
          flowMode: flowMode ?? 'DEFAULT',
          easyPay: easyPay,
          cardCompany: cardCompany,
          useCardPoint: false,
          useAppCardOnly: false,
        ),
      );

      // JavaScript SDK 호출 (Promise 반환)
      final promise = _payment!.requestPayment(request);

      // Promise를 Future로 변환
      await _promiseToFuture(promise);

      debugPrint('✅ [PaymentServiceWeb] 결제 요청 성공 (리다이렉트 중...)');
    } catch (e) {
      debugPrint('❌ [PaymentServiceWeb] 결제 요청 실패: $e');
      rethrow;
    }
  }

  /// 간편결제 요청 (토스페이)
  Future<void> requestTossPayPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
  }) async {
    debugPrint('💰 [PaymentServiceWeb] 토스페이 결제 요청');

    // 토스페이는 DIRECT 모드로 easyPay 지정
    await requestCardPayment(
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      customerName: customerName,
      customerEmail: customerEmail,
      flowMode: 'DIRECT',
      easyPay: 'TOSSPAY',
    );
  }

  /// 계좌이체 결제 요청
  Future<void> requestTransferPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
  }) async {
    _ensureInitialized();

    debugPrint('🏦 [PaymentServiceWeb] 계좌이체 결제 요청');

    try {
      final request = PaymentRequest(
        method: 'TRANSFER',
        amount: AmountJS(
          currency: 'KRW',
          value: amount,
        ),
        orderId: orderId,
        orderName: orderName,
        successUrl: config.PaymentConfig.successUrl,
        failUrl: config.PaymentConfig.failUrl,
        customerName: customerName,
        customerEmail: customerEmail,
      );

      final promise = _payment!.requestPayment(request);
      await _promiseToFuture(promise);

      debugPrint('✅ [PaymentServiceWeb] 계좌이체 결제 요청 성공');
    } catch (e) {
      debugPrint('❌ [PaymentServiceWeb] 계좌이체 결제 요청 실패: $e');
      rethrow;
    }
  }

  /// 가상계좌 결제 요청
  Future<void> requestVirtualAccountPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
  }) async {
    _ensureInitialized();

    debugPrint('🏧 [PaymentServiceWeb] 가상계좌 결제 요청');

    try {
      final request = PaymentRequest(
        method: 'VIRTUAL_ACCOUNT',
        amount: AmountJS(
          currency: 'KRW',
          value: amount,
        ),
        orderId: orderId,
        orderName: orderName,
        successUrl: config.PaymentConfig.successUrl,
        failUrl: config.PaymentConfig.failUrl,
        customerName: customerName,
        customerEmail: customerEmail,
      );

      final promise = _payment!.requestPayment(request);
      await _promiseToFuture(promise);

      debugPrint('✅ [PaymentServiceWeb] 가상계좌 발급 요청 성공');
    } catch (e) {
      debugPrint('❌ [PaymentServiceWeb] 가상계좌 발급 요청 실패: $e');
      rethrow;
    }
  }

  /// 통합 결제 요청 (DEFAULT 모드 - 토스 SDK가 모든 결제수단 표시)
  ///
  /// 토스페이먼츠 SDK의 CARD 결제 방식으로 호출하면
  /// SDK가 자체적으로 모든 결제수단(카드, 토스페이, 계좌이체 등)을 표시합니다.
  ///
  /// [orderId]: 주문 ID (백엔드에서 생성)
  /// [amount]: 결제 금액
  /// [orderName]: 주문명 (예: "EZStay 계약금 결제")
  /// [customerName]: 구매자 이름 (선택)
  /// [customerEmail]: 구매자 이메일 (선택)
  Future<void> requestPayment({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
  }) async {
    debugPrint('💳 [PaymentServiceWeb] 통합 결제 요청 (DEFAULT 모드)');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');
    debugPrint('  - orderName: $orderName');

    // DEFAULT 모드로 카드 결제 요청 (모든 결제수단 표시)
    await requestCardPayment(
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      customerName: customerName,
      customerEmail: customerEmail,
      flowMode: 'DEFAULT',
    );
  }

  /// 통합 결제 요청 (contractId 포함)
  ///
  /// successUrl/failUrl에 contractId를 쿼리 파라미터로 추가하여
  /// callback 페이지에서 contractId를 직접 사용할 수 있도록 합니다.
  ///
  /// [contractId]: 계약 ID
  /// [orderId]: 주문 ID (백엔드에서 생성)
  /// [amount]: 결제 금액
  /// [orderName]: 주문명
  /// [customerName]: 구매자 이름 (선택)
  /// [customerEmail]: 구매자 이메일 (선택)
  Future<void> requestPaymentWithContractId({
    required int contractId,
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
  }) async {
    _ensureInitialized();

    debugPrint('💳 [PaymentServiceWeb] 통합 결제 요청 (contractId 포함)');
    debugPrint('  - contractId: $contractId');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - amount: $amount');

    try {
      // successUrl/failUrl에 contractId를 쿼리 파라미터로 추가
      final baseSuccessUrl = config.PaymentConfig.successUrl;
      final baseFailUrl = config.PaymentConfig.failUrl;

      final successUrl = '$baseSuccessUrl?contractId=$contractId';
      final failUrl = '$baseFailUrl?contractId=$contractId';

      final request = PaymentRequest(
        method: 'CARD',
        amount: AmountJS(
          currency: 'KRW',
          value: amount,
        ),
        orderId: orderId,
        orderName: orderName,
        successUrl: successUrl,
        failUrl: failUrl,
        customerName: customerName,
        customerEmail: customerEmail,
        card: CardOptionsJS(
          useEscrow: false,
          flowMode: 'DEFAULT',
          useCardPoint: false,
          useAppCardOnly: false,
        ),
      );

      final promise = _payment!.requestPayment(request);
      await _promiseToFuture(promise);

      debugPrint('✅ [PaymentServiceWeb] 결제 요청 성공 (리다이렉트 중...)');
    } catch (e) {
      debugPrint('❌ [PaymentServiceWeb] 결제 요청 실패: $e');
      rethrow;
    }
  }

  /// Promise를 Future로 변환
  Future<T> _promiseToFuture<T>(Promise promise) {
    final completer = Completer<T>();

    promise.then(
      allowInterop((result) {
        completer.complete(result as T);
      }),
      allowInterop((error) {
        completer.completeError(error);
      }),
    );

    return completer.future;
  }
}
