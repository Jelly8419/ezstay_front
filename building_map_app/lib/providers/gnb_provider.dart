import 'dart:async';
import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/// GNB(Global Navigation Bar) 상태 관리
/// 알림 및 채팅의 미확인 상태를 관리합니다.
class GNBProvider extends ChangeNotifier {
  // lazy initialization — Provider 생성 시점에 Firebase 접근 방지
  NotificationService? _notificationServiceInstance;
  NotificationService get _notificationService =>
      _notificationServiceInstance ??= NotificationService();

  // ==================== 상태 ====================
  bool _hasUnreadNotifications = false;
  bool _hasUnreadChats = false;
  bool _isCheckingUnread = false;

  // ==================== 채팅 폴링 ====================
  // Firestore 컬렉션 전체 구독(reads 폭발) 대신 REST API 30초 폴링으로 교체.
  // GNB 레드닷은 최대 30초 지연 허용 — 채팅 목록 자체는 whereIn 구독으로 실시간 반영됨.
  Timer? _pollTimer;
  String? _pollingUserMode;
  int? _watchingUserId;

  // ==================== Getters ====================
  /// 미확인 알림이 있는지 여부
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  /// 미확인 채팅이 있는지 여부
  bool get hasUnreadChats => _hasUnreadChats;

  // ==================== 알림 관리 ====================
  /// 미확인 알림 상태 설정
  void setUnreadNotifications(bool hasUnread) {
    if (_hasUnreadNotifications != hasUnread) {
      _hasUnreadNotifications = hasUnread;
      notifyListeners();
    }
  }

  /// 알림을 읽음으로 표시 (Red Dot 제거)
  void markNotificationsAsRead() {
    if (_hasUnreadNotifications) {
      _hasUnreadNotifications = false;
      notifyListeners();
    }
  }

  // ==================== 채팅 관리 ====================
  /// 미확인 채팅 상태 설정
  void setUnreadChats(bool hasUnread) {
    if (_hasUnreadChats != hasUnread) {
      _hasUnreadChats = hasUnread;
      notifyListeners();
    }
  }

  /// 채팅을 읽음으로 표시 (Red Dot 제거)
  void markChatsAsRead() {
    if (_hasUnreadChats) {
      _hasUnreadChats = false;
      notifyListeners();
    }
  }

  // ==================== 채팅 폴링 ====================

  /// 채팅 미확인 폴링 시작
  /// 로그인 후 호출 — 30초마다 REST API로 레드닷 상태 갱신
  Future<void> startChatUnreadWatch(int userId, {required String userMode}) async {
    // 동일 유저·모드 재호출 시 스킵
    if (_watchingUserId == userId && _pollingUserMode == userMode && _pollTimer != null) {
      return;
    }

    stopChatUnreadWatch();
    _watchingUserId = userId;
    _pollingUserMode = userMode;

    AppLogger.d('🔔 [GNB] 채팅 미확인 폴링 시작 (userId: $userId, mode: $userMode)');

    // 즉시 1회 체크
    await checkGnbBadgeStatus(userMode);

    // 30초 주기 폴링
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkGnbBadgeStatus(_pollingUserMode ?? userMode);
    });
  }

  /// 채팅 미확인 폴링 해제
  void stopChatUnreadWatch() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _watchingUserId = null;
    _pollingUserMode = null;
  }

  // ==================== API 연동 ====================
  /// GNB 배지 상태 조회 (알림 미확인 + 채팅 미확인 통합 API)
  /// GNB가 마운트되거나 로그인/모드 전환 후 호출해야 합니다.
  Future<void> checkGnbBadgeStatus(String userMode) async {
    if (_isCheckingUnread) return;
    _isCheckingUnread = true;

    try {
      final response = await _notificationService.getGnbBadgeStatus(userMode: userMode);
      setUnreadNotifications(response.unreadNotificationCount > 0);
      setUnreadChats(response.hasUnreadChat);
    } catch (e) {
      // 에러 시 상태 변경하지 않음
    } finally {
      _isCheckingUnread = false;
    }
  }

  // ==================== 초기화 ====================
  /// 모든 알림 상태 초기화 (로그아웃 시 호출)
  void reset() {
    stopChatUnreadWatch();
    _hasUnreadNotifications = false;
    _hasUnreadChats = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopChatUnreadWatch();
    super.dispose();
  }
}
