import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';
import '../models/guest_move_in/guest_move_in.dart';
import 'guest_move_in_service.dart';
import 'payment_service_web.dart'
    if (dart.library.io) 'payment_service_stub.dart';

/// 게스트 결제 단계별 결과
enum GuestMoveInPaymentStage {
  /// 사용자가 옵션 미선택 등으로 결제 시작 전 차단됨
  cancelledBeforeInit,

  /// PG SDK 호출 성공 + 백엔드 confirm 완료
  paid,

  /// PG SDK 성공 그러나 confirm 실패 (재시도 가능 — 주문 PENDING 유지)
  confirmFailed,

  /// PG SDK 단계에서 실패 또는 사용자 결제창 닫음
  pgFailed,

  /// init 단계 실패 (서버 가드 — D-5 경과/재고 부족/PENDING 충돌 등)
  initFailed,
}

/// 결제 결과 — 페이지가 토스트/네비게이션 분기에 사용
class GuestMoveInPaymentResult {
  final GuestMoveInPaymentStage stage;
  final GuestPaymentConfirmResponse? confirmation;
  final GuestPaymentInitResponse? initResponse;
  final GuestMoveInException? error;
  final bool mock;

  const GuestMoveInPaymentResult({
    required this.stage,
    this.confirmation,
    this.initResponse,
    this.error,
    this.mock = false,
  });

  bool get isPaid => stage == GuestMoveInPaymentStage.paid;
  String? get errorMessage => error?.message;
}

/// 게스트 입주 준비 PG 결제 흐름 통합 컨트롤러
///
/// 호스트 청소 결제와 동일한 PayTag SDK 패턴 — 단계는:
/// 1. init: 옵션 + 케이스로 백엔드에 INITIAL/ADDITIONAL 주문 생성
/// 2. PG SDK 호출 (Mock 모드면 즉시 confirm)
/// 3. confirm: 백엔드 결제 승인
class GuestMoveInPaymentController {
  GuestMoveInPaymentController({
    GuestMoveInService? service,
    PaymentServiceWeb? webService,
  })  : _service = service ?? GuestMoveInService(),
        _webService = _createWebService(webService);

  final GuestMoveInService _service;
  final PaymentServiceWeb? _webService;

  static const String _logTag = '[GUEST_MOVE_IN_PAY]';

  static PaymentServiceWeb? _createWebService(PaymentServiceWeb? injected) {
    if (injected != null) return injected;
    if (!kIsWeb) return null;
    try {
      return PaymentServiceWeb();
    } catch (e) {
      AppLogger.w('$_logTag PayTag SDK 초기화 실패: $e');
      return null;
    }
  }

  /// INITIAL 결제 — 케이스의 첫 결제
  ///
  /// `buyerName`/`customerPhone`은 백엔드 `pgPayload`에서 채워 내려주므로
  /// 호출 측에서 전달할 필요 없음 (계약 결제와 동일 패턴).
  /// [payType] — PayTag SDK 결제 수단 코드 (예: 'BC', 'KP', 'NP').
  Future<GuestMoveInPaymentResult> payInitial({
    required int caseId,
    required List<GuestSelectedItem> items,
    required String payType,
  }) =>
      _runPayment(
        caseId: caseId,
        items: items,
        isAdditional: false,
        payType: payType,
      );

  /// ADDITIONAL 결제 — INITIAL `PAID` 후 추가 옵션 결제
  Future<GuestMoveInPaymentResult> payAdditional({
    required int caseId,
    required List<GuestSelectedItem> items,
    required String payType,
  }) =>
      _runPayment(
        caseId: caseId,
        items: items,
        isAdditional: true,
        payType: payType,
      );

  Future<GuestMoveInPaymentResult> _runPayment({
    required int caseId,
    required List<GuestSelectedItem> items,
    required bool isAdditional,
    required String payType,
  }) async {
    if (items.isEmpty) {
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.cancelledBeforeInit,
      );
    }

    GuestPaymentInitResponse initResp;
    try {
      initResp = isAdditional
          ? await _service.initAdditional(caseId, items)
          : await _service.initPayment(caseId, items);
      AppLogger.d(
          '$_logTag init OK paymentId=${initResp.paymentId} mock=${initResp.pgPayload.mock}');
    } on GuestMoveInException catch (e) {
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.initFailed,
        error: e,
      );
    }

    if (initResp.pgPayload.mock) {
      return _confirmMock(
        caseId: caseId,
        paymentId: initResp.paymentId,
        isAdditional: isAdditional,
        initResp: initResp,
      );
    }

    if (!kIsWeb || _webService == null) {
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.pgFailed,
        error: GuestMoveInException(
          errorCode: GuestMoveInErrorCode.unknown,
          message: '실 PG 결제는 현재 웹에서만 지원됩니다.',
        ),
        initResponse: initResp,
      );
    }
    return _callPayTagAndConfirm(
      caseId: caseId,
      isAdditional: isAdditional,
      initResp: initResp,
      payType: payType,
    );
  }

  Future<GuestMoveInPaymentResult> _confirmMock({
    required int caseId,
    required int paymentId,
    required bool isAdditional,
    required GuestPaymentInitResponse initResp,
  }) async {
    try {
      final result = isAdditional
          ? await _service.confirmAdditional(
              caseId,
              paymentId: paymentId,
            )
          : await _service.confirmPayment(
              caseId,
              paymentId: paymentId,
            );
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.paid,
        confirmation: result,
        initResponse: initResp,
        mock: true,
      );
    } on GuestMoveInException catch (e) {
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.confirmFailed,
        error: e,
        initResponse: initResp,
        mock: true,
      );
    }
  }

  Future<GuestMoveInPaymentResult> _callPayTagAndConfirm({
    required int caseId,
    required bool isAdditional,
    required GuestPaymentInitResponse initResp,
    required String payType,
  }) async {
    final pg = initResp.pgPayload;
    final orderId = pg.orderId ?? initResp.orderId;
    final amount = pg.amount ?? initResp.amount;
    final productName = pg.productName ?? '입주 준비 옵션';
    final buyerName = pg.buyerName ?? '';
    final customerPhone = pg.customerPhone ?? '';

    try {
      final response = await _webService!.requestPayment(
        orderId: orderId,
        amount: amount,
        orderName: productName,
        payType: payType,
        customerName: buyerName,
        customerPhone: customerPhone,
      );

      if (!response.isSuccess || response.recvPayparam == null) {
        return GuestMoveInPaymentResult(
          stage: GuestMoveInPaymentStage.pgFailed,
          error: GuestMoveInException(
            errorCode: GuestMoveInErrorCode.paymentConfirmationFailed,
            message: response.errmsg.isEmpty
                ? '결제가 취소되었습니다.'
                : response.errmsg,
          ),
          initResponse: initResp,
        );
      }

      final confirmation = isAdditional
          ? await _service.confirmAdditional(
              caseId,
              paymentId: initResp.paymentId,
              recvPayparam: response.recvPayparam,
              payType: response.payType,
            )
          : await _service.confirmPayment(
              caseId,
              paymentId: initResp.paymentId,
              recvPayparam: response.recvPayparam,
              payType: response.payType,
            );
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.paid,
        confirmation: confirmation,
        initResponse: initResp,
      );
    } on GuestMoveInException catch (e) {
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.confirmFailed,
        error: e,
        initResponse: initResp,
      );
    } catch (e, st) {
      AppLogger.e('$_logTag PayTag SDK error: $e\n$st');
      return GuestMoveInPaymentResult(
        stage: GuestMoveInPaymentStage.pgFailed,
        error: GuestMoveInException(
          errorCode: GuestMoveInErrorCode.paymentConfirmationFailed,
          message: '결제창 호출에 실패했습니다.',
        ),
        initResponse: initResp,
      );
    }
  }
}
