import 'package:flutter/foundation.dart';
import '../../models/move_in/move_in.dart';
import '../../services/move_in_service.dart';

/// 입주 준비 서비스 홈 화면 상태 (Phase 3에서 본격 사용)
///
/// - 케이스 목록 페이지네이션
/// - 필터 (요청 상태 / 청소 상태) + 검색어
/// - 요약 카드 카운트 (서버가 안 주면 클라 집계)
/// - 단일 케이스 갱신 후 목록 자리 교체 ([replaceCase])
class MoveInListProvider extends ChangeNotifier {
  MoveInListProvider({MoveInService? service})
      : _service = service ?? MoveInService();

  final MoveInService _service;

  // ----- 상태 -----
  List<MoveInCase> _cases = const [];
  MoveInCaseCounts _counts = const MoveInCaseCounts(
    total: 0,
    cleaningPending: 0,
    cleaningPaid: 0,
    paymentRequestPending: 0,
    inProgress: 0,
  );
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  MoveInException? _error;

  // 페이지네이션
  int _page = 1;
  int _limit = 20;
  int _total = 0;
  int _totalPages = 0;

  // 필터
  PaymentRequestStatus? _requestStatus;
  CleaningStatus? _cleaningStatus;
  String _search = '';

  // ----- 게터 -----
  List<MoveInCase> get cases => _cases;
  MoveInCaseCounts get counts => _counts;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  MoveInException? get error => _error;

  int get page => _page;
  int get totalPages => _totalPages;
  int get total => _total;

  PaymentRequestStatus? get requestStatus => _requestStatus;
  CleaningStatus? get cleaningStatus => _cleaningStatus;
  String get search => _search;

  // ----- 액션 -----

  /// 첫 진입 / 새로고침
  Future<void> load() => _fetch(page: 1);

  /// 페이지 이동
  Future<void> goToPage(int page) => _fetch(page: page);

  /// 필터 변경 — 1페이지로 리셋
  Future<void> setFilters({
    PaymentRequestStatus? requestStatus,
    CleaningStatus? cleaningStatus,
    String? search,
  }) {
    _requestStatus = requestStatus;
    _cleaningStatus = cleaningStatus;
    if (search != null) _search = search;
    return _fetch(page: 1);
  }

  /// 필터 초기화 (전체 보기)
  Future<void> clearFilters() {
    _requestStatus = null;
    _cleaningStatus = null;
    _search = '';
    return _fetch(page: 1);
  }

  /// 단일 케이스 변경 (상세에서 액션 후 목록 동기화)
  void replaceCase(MoveInCase updated) {
    final index = _cases.indexWhere((c) => c.id == updated.id);
    if (index < 0) return;
    final newList = List<MoveInCase>.from(_cases);
    newList[index] = updated;
    _cases = newList;
    _counts = MoveInCaseCounts.fromCases(_cases);
    notifyListeners();
  }

  Future<void> _fetch({required int page}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getMoveInCases(
        page: page,
        limit: _limit,
        requestStatus: _requestStatus,
        cleaningStatus: _cleaningStatus,
        search: _search.isEmpty ? null : _search,
      );
      _cases = response.cases;
      _page = response.page;
      _limit = response.limit;
      _total = response.total;
      _totalPages = response.totalPages;
      _counts = response.counts ?? MoveInCaseCounts.fromCases(_cases);
    } on MoveInException catch (e) {
      _error = e;
    } finally {
      _hasLoadedOnce = true;
      _isLoading = false;
      notifyListeners();
    }
  }
}
