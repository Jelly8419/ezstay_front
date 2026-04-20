import 'package:flutter/foundation.dart';
import '../models/promotion_event.dart';
import '../services/promotion_service.dart';

/// 진행 중 프로모션 이벤트 전역 상태.
///
/// - 홈 화면 진입 시 `loadActivePromotions()` 1회 호출
/// - 로그인 상태 변경/알림 신청 후 `refresh()`로 재조회
class PromotionProvider extends ChangeNotifier {
  PromotionProvider({PromotionService? service})
      : _service = service ?? PromotionService();

  final PromotionService _service;

  List<PromotionEvent> _events = const [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;

  List<PromotionEvent> get events => _events;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;

  /// 게스트 대상 이벤트 (없으면 null)
  PromotionEvent? get guestEvent {
    for (final event in _events) {
      if (event.targetRole == TargetRole.guest) return event;
    }
    return null;
  }

  /// 호스트 대상 이벤트 (없으면 null)
  PromotionEvent? get hostEvent {
    for (final event in _events) {
      if (event.targetRole == TargetRole.host) return event;
    }
    return null;
  }

  /// 홈 진입 시 호출. 이미 로딩 중이면 중복 호출 방지.
  Future<void> loadActivePromotions() async {
    if (_isLoading) return;
    await _fetch();
  }

  /// 로그인 상태 변경/참여 후 재조회.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.getActivePromotions();
    if (result != null) {
      _events = result;
    }
    _hasLoadedOnce = true;
    _isLoading = false;
    notifyListeners();
  }
}
