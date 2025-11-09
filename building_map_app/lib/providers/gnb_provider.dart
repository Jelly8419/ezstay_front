import 'package:flutter/foundation.dart';

/// GNB(Global Navigation Bar) 상태 관리
/// 알림 및 채팅의 미확인 상태를 관리합니다.
class GNBProvider extends ChangeNotifier {
  // ==================== 상태 ====================
  bool _hasUnreadNotifications = false;
  bool _hasUnreadChats = false;

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

  // ==================== 초기화 ====================
  /// 모든 알림 상태 초기화
  void reset() {
    _hasUnreadNotifications = false;
    _hasUnreadChats = false;
    notifyListeners();
  }
}
