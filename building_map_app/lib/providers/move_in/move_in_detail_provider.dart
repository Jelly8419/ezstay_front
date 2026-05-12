import 'package:flutter/foundation.dart';
import '../../models/move_in/move_in.dart';
import '../../services/move_in_service.dart';

/// 입주 준비 등록 상세 페이지 상태 (Phase 5에서 본격 사용)
///
/// 한 페이지가 한 케이스를 다루므로 caseId당 별도 인스턴스로 만들어
/// 상세 페이지의 [ChangeNotifierProvider.create]에서 생성/dispose하는 것을 권장.
/// (글로벌이 아닌 페이지 스코프 Provider)
class MoveInDetailProvider extends ChangeNotifier {
  MoveInDetailProvider({required this.caseId, MoveInService? service})
      : _service = service ?? MoveInService();

  final int caseId;
  final MoveInService _service;

  MoveInCase? _case;
  bool _isLoading = false;
  MoveInException? _error;

  // 액션별 in-flight 플래그 — UI 버튼 중복 클릭 방지
  bool _isMutating = false;

  MoveInCase? get moveInCase => _case;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  MoveInException? get error => _error;

  // ============================================================
  // 조회
  // ============================================================

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _case = await _service.getMoveInCase(caseId);
    } on MoveInException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 케이스 정보 수정
  // ============================================================

  Future<MoveInCase?> updateCase(MoveInCaseUpdateRequest request) async {
    return _runMutation(() => _service.updateMoveInCase(caseId, request));
  }

  // ============================================================
  // 청소 액션
  // ============================================================

  Future<MoveInCase?> requestCleaning({String? cleaningRequestedDate}) {
    final body = cleaningRequestedDate == null
        ? null
        : CleaningRequestBody(cleaningRequestedDate: cleaningRequestedDate);
    // 백엔드가 부분 응답(caseId/cleaningStatus/cleaningFee)만 반환 →
    // 케이스 전체는 별도 재조회로 동기화.
    return _runCleaningAction(() => _service.requestCleaning(caseId, body: body));
  }

  Future<MoveInCase?> cancelCleaningRequest() {
    // 백엔드가 부분 응답(caseId/cleaningStatus)만 반환 → 케이스 재조회로 동기화.
    return _runCleaningAction(() => _service.cancelCleaningRequest(caseId));
  }

  // ============================================================
  // 임차인 결제 요청 액션
  // ============================================================

  /// send / resend는 응답이 PaymentRequestSendResponse라서 케이스 상태가 함께 오지 않음 →
  /// 호출 후 [load]로 케이스 재조회.
  Future<PaymentRequestSendResponse?> sendPaymentRequest() async {
    return _runRequestAction(() => _service.sendPaymentRequest(caseId));
  }

  Future<PaymentRequestSendResponse?> resendPaymentRequest() async {
    return _runRequestAction(() => _service.resendPaymentRequest(caseId));
  }

  Future<PaymentRequestSendResponse?> getPaymentRequestLink() async {
    // 링크 조회는 상태 변경 액션이 아니므로 mutation 플래그 제외, 에러만 보존.
    try {
      return await _service.getPaymentRequestLink(caseId);
    } on MoveInException catch (e) {
      _error = e;
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // 내부 헬퍼
  // ============================================================

  Future<MoveInCase?> _runMutation(Future<MoveInCase> Function() block) async {
    if (_isMutating) return null;
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await block();
      _case = updated;
      return updated;
    } on MoveInException catch (e) {
      _error = e;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// 청소 액션(request/cancel) 전용 헬퍼
  ///
  /// 백엔드가 부분 응답(caseId/cleaningStatus[/cleaningFee])만 내려주기 때문에
  /// 액션 후 [getMoveInCase] 로 케이스 전체를 재조회해야 detail UI 가 깡통으로 덮어쓰이지 않는다.
  Future<MoveInCase?> _runCleaningAction(Future<void> Function() block) async {
    if (_isMutating) return null;
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await block();
      _case = await _service.getMoveInCase(caseId);
      return _case;
    } on MoveInException catch (e) {
      _error = e;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<PaymentRequestSendResponse?> _runRequestAction(
    Future<PaymentRequestSendResponse> Function() block,
  ) async {
    if (_isMutating) return null;
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await block();
      // 케이스 상태 동기화 — 발송 후 paymentRequest.status 등이 바뀌었을 수 있음
      try {
        _case = await _service.getMoveInCase(caseId);
      } on MoveInException {
        // 재조회 실패는 본 액션 결과를 막지 않음 — 에러 무시
      }
      return result;
    } on MoveInException catch (e) {
      _error = e;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
