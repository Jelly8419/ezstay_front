import 'package:flutter/foundation.dart';
import '../../models/guest_move_in/guest_move_in.dart';
import '../../services/guest_move_in_service.dart';

/// 게스트 입주 준비 상세/결제 화면 상태
///
/// - 케이스별 상세 (옵션 카탈로그 + 본인 주문)
/// - 결제 화면용 가벼운 옵션 응답 (`getRequestOptions`)
class GuestMoveInDetailProvider extends ChangeNotifier {
  GuestMoveInDetailProvider({GuestMoveInService? service})
      : _service = service ?? GuestMoveInService();

  final GuestMoveInService _service;

  // ----- 상태 -----
  int? _caseId;
  GuestMoveInRequestDetail? _detail;
  GuestMoveInOptionsResponse? _optionsContext;
  bool _isLoading = false;
  GuestMoveInException? _error;

  // ----- 게터 -----
  int? get caseId => _caseId;
  GuestMoveInRequestDetail? get detail => _detail;
  GuestMoveInOptionsResponse? get optionsContext => _optionsContext;
  bool get isLoading => _isLoading;
  GuestMoveInException? get error => _error;

  /// 상세 화면 진입 시 호출
  Future<void> loadDetail(int caseId) async {
    _caseId = caseId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _service.getRequestDetail(caseId);
    } on GuestMoveInException catch (e) {
      _error = e;
    } catch (e) {
      _error = GuestMoveInException.network(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 결제 화면 진입 시 호출 (가벼운 응답)
  Future<void> loadOptions(int caseId) async {
    _caseId = caseId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _optionsContext = await _service.getRequestOptions(caseId);
    } on GuestMoveInException catch (e) {
      _error = e;
    } catch (e) {
      _error = GuestMoveInException.network(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 결제 성공 후 상세 새로고침
  Future<void> refresh() async {
    if (_caseId != null) await loadDetail(_caseId!);
  }

  // ----- 환불 / 반품 액션 -----
  bool _isMutating = false;
  bool get isMutating => _isMutating;

  /// 옵션 취소 (즉시 환불). 성공 시 상세 재조회로 주문 상태 동기화.
  Future<GuestOrderRefundResponse?> cancelPaidOrder(
    int orderDbId, {
    String? reason,
  }) async {
    if (_isMutating || _caseId == null) return null;
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      final result =
          await _service.cancelPaidOrder(orderDbId, reason: reason);
      _detail = await _service.getRequestDetail(_caseId!);
      return result;
    } on GuestMoveInException catch (e) {
      _error = e;
      return null;
    } catch (e) {
      _error = GuestMoveInException.network(e);
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// 반품 요청 (관리자 승인 대상). 성공 시 상세 재조회.
  Future<GuestReturnRequestResponse?> requestReturn(
    int orderDbId, {
    String? reason,
  }) async {
    if (_isMutating || _caseId == null) return null;
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.requestReturn(orderDbId, reason: reason);
      _detail = await _service.getRequestDetail(_caseId!);
      return result;
    } on GuestMoveInException catch (e) {
      _error = e;
      return null;
    } catch (e) {
      _error = GuestMoveInException.network(e);
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  void reset() {
    _caseId = null;
    _detail = null;
    _optionsContext = null;
    _error = null;
    _isMutating = false;
    notifyListeners();
  }
}
