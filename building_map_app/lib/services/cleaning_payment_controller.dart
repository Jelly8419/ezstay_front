import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';
import '../models/move_in/move_in.dart';
import 'move_in_service.dart';
import 'payment_service_web.dart'
    if (dart.library.io) 'payment_service_stub.dart';

/// 청소 PG 결제 단계별 결과 — UI 토스트/네비게이션 분기에 사용
enum CleaningPaymentStage {
  /// 사용자가 견적 다이얼로그에서 취소
  cancelledBeforePg,

  /// PG SDK 호출이 성공했고 백엔드 confirm까지 완료
  paid,

  /// PG SDK는 성공했으나 백엔드 confirm 단계에서 실패
  confirmFailed,

  /// PG SDK 단계에서 실패 또는 사용자 취소
  pgFailed,
}

class CleaningPaymentResult {
  final CleaningPaymentStage stage;
  final CleaningPaymentConfirmResponse? confirmation;
  final String? errorMessage;
  final bool mock;

  const CleaningPaymentResult({
    required this.stage,
    this.confirmation,
    this.errorMessage,
    this.mock = false,
  });

  bool get isPaid => stage == CleaningPaymentStage.paid;
}

/// 청소 PG 결제 흐름 통합 컨트롤러
///
/// 단계:
/// 1. 견적 조회 ([requestQuote])
/// 2. PG init → backend `paymentId/pgPayload` 수령 ([_initPayment])
/// 3. PG 호출
///    - Mock: backend가 자동 승인 처리 → 즉시 confirm
///    - 실제: PayTag SDK → recvPayparam 수신 → confirm
/// 4. 결과 [CleaningPaymentResult] 반환
class CleaningPaymentController {
  CleaningPaymentController({MoveInService? service, PaymentServiceWeb? webService})
      : _service = service ?? MoveInService(),
        _webService = _createWebService(webService);

  final MoveInService _service;
  final PaymentServiceWeb? _webService;

  static const String _logTag = '[CLEANING_PAYMENT]';

  /// 웹 환경에서만 PayTag SDK 초기화. 실패해도 Mock 결제는 진행 가능.
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

  /// 1단계: 견적 조회 — 견적 다이얼로그 노출에 사용
  Future<CleaningQuoteResponse> requestQuote(int caseId) {
    return _service.getCleaningQuote(caseId);
  }

  /// 2~4단계 통합: 결제 시작 → PG 호출 → confirm
  Future<CleaningPaymentResult> pay({required MoveInCase moveInCase}) async {
    final caseId = moveInCase.id;

    try {
      final initResp = await _service.initCleaningPayment(caseId);
      AppLogger.d('$_logTag init OK paymentId=${initResp.paymentId} mock=${initResp.isMock}');

      if (initResp.isMock) {
        return _confirmMock(caseId: caseId, paymentId: initResp.paymentId);
      }

      // 실제 PG — 웹에서만 지원 (모바일은 추후 WebView)
      if (!kIsWeb || _webService == null) {
        return CleaningPaymentResult(
          stage: CleaningPaymentStage.pgFailed,
          errorMessage: '실 PG 결제는 현재 웹에서만 지원됩니다.',
        );
      }
      return _callPayTagAndConfirm(
        caseId: caseId,
        moveInCase: moveInCase,
        initResp: initResp,
      );
    } on MoveInException catch (e) {
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.pgFailed,
        errorMessage: e.message,
      );
    } catch (e, st) {
      AppLogger.e('$_logTag pay() unexpected error: $e\n$st');
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.pgFailed,
        errorMessage: '결제를 진행하지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }

  Future<CleaningPaymentResult> _confirmMock({
    required int caseId,
    required int paymentId,
  }) async {
    try {
      final result = await _service.confirmCleaningPayment(
        caseId,
        CleaningPaymentConfirmRequest(paymentId: paymentId),
      );
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.paid,
        confirmation: result,
        mock: true,
      );
    } on MoveInException catch (e) {
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.confirmFailed,
        errorMessage: e.message,
        mock: true,
      );
    }
  }

  Future<CleaningPaymentResult> _callPayTagAndConfirm({
    required int caseId,
    required MoveInCase moveInCase,
    required CleaningPaymentInitResponse initResp,
  }) async {
    final pgPayload = initResp.pgPayload;
    final orderId = (pgPayload['orderId'] as String?) ?? initResp.orderId;
    final amount = (pgPayload['amount'] as num?)?.toInt() ?? initResp.amount;
    final productName =
        (pgPayload['productName'] as String?) ?? '입주 청소 서비스';
    final buyerName =
        (pgPayload['buyerName'] as String?) ?? moveInCase.guestName;
    // 청소 결제는 일반적으로 카드. PRD/가이드에 별도 명시 없으므로 'BC' 기본값.
    final payType = (pgPayload['payType'] as String?) ?? 'BC';

    try {
      final response = await _webService!.requestPayment(
        orderId: orderId,
        amount: amount,
        orderName: productName,
        payType: payType,
        customerName: buyerName,
        customerPhone: moveInCase.guestPhone,
      );

      if (!response.isSuccess || response.recvPayparam == null) {
        return CleaningPaymentResult(
          stage: CleaningPaymentStage.pgFailed,
          errorMessage: response.errmsg.isEmpty ? '결제가 취소되었습니다.' : response.errmsg,
        );
      }

      // confirm 단계
      final confirmation = await _service.confirmCleaningPayment(
        caseId,
        CleaningPaymentConfirmRequest(
          paymentId: initResp.paymentId,
          recvPayparam: response.recvPayparam,
          payType: response.payType,
        ),
      );
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.paid,
        confirmation: confirmation,
      );
    } on MoveInException catch (e) {
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.confirmFailed,
        errorMessage: e.message,
      );
    } catch (e, st) {
      AppLogger.e('$_logTag PayTag SDK error: $e\n$st');
      return CleaningPaymentResult(
        stage: CleaningPaymentStage.pgFailed,
        errorMessage: '결제창 호출에 실패했습니다.',
      );
    }
  }
}
