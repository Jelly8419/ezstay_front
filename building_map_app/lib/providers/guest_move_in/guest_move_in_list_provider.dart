import 'package:flutter/foundation.dart';
import '../../models/guest_move_in/guest_move_in.dart';
import '../../services/guest_move_in_service.dart';

/// 게스트 입주 준비 서비스 목록 화면 상태
///
/// - 본인 케이스 목록 페이지네이션
/// - 상태 필터 (PENDING_PAYMENT / PAID / COMPLETED / 전체)
/// - 카운트는 서버 응답 합계(`pagination.total`)를 상태별로 집계 (필터 변경 시 재요청)
class GuestMoveInListProvider extends ChangeNotifier {
  GuestMoveInListProvider({GuestMoveInService? service})
      : _service = service ?? GuestMoveInService();

  final GuestMoveInService _service;

  // ----- 상태 -----
  List<GuestMoveInRequestListItem> _items = const [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  GuestMoveInException? _error;

  // 페이지네이션
  int _page = 1;
  final int _limit = 20;
  int _total = 0;
  int _totalPages = 0;

  // 필터
  GuestMoveInStatus? _statusFilter;

  // ----- 게터 -----
  List<GuestMoveInRequestListItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  GuestMoveInException? get error => _error;

  int get page => _page;
  int get totalPages => _totalPages;
  int get total => _total;
  GuestMoveInStatus? get statusFilter => _statusFilter;

  // ----- 액션 -----

  Future<void> load() => _fetch(page: 1);

  Future<void> goToPage(int page) => _fetch(page: page);

  Future<void> setStatusFilter(GuestMoveInStatus? status) {
    _statusFilter = status;
    return _fetch(page: 1);
  }

  Future<void> _fetch({required int page}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getMyRequests(
        status: _statusFilter,
        page: page,
        limit: _limit,
      );
      _items = result.items;
      _page = result.pagination.page;
      _total = result.pagination.total;
      _totalPages = result.pagination.totalPages;
      _hasLoadedOnce = true;
    } on GuestMoveInException catch (e) {
      _error = e;
    } catch (e) {
      _error = GuestMoveInException.network(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
