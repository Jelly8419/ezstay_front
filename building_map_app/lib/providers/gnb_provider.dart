import 'dart:async';
import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseApp;
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/firebase_auth_service.dart';

/// GNB(Global Navigation Bar) 상태 관리
/// 알림 및 채팅의 미확인 상태를 관리합니다.
class GNBProvider extends ChangeNotifier {
  // lazy initialization — Provider 생성 시점에 Firebase 접근 방지
  NotificationService? _notificationServiceInstance;
  NotificationService get _notificationService =>
      _notificationServiceInstance ??= NotificationService();

  FirebaseAuthService? _firebaseAuthInstance;
  FirebaseAuthService get _firebaseAuth =>
      _firebaseAuthInstance ??= FirebaseAuthService();

  /// main.dart에서 백그라운드로 실행된 Firebase 초기화 Future
  /// startChatUnreadWatch 호출 전 완료 대기에 사용
  Future<FirebaseApp>? firebaseInitFuture;

  // ==================== 상태 ====================
  bool _hasUnreadNotifications = false;
  bool _hasUnreadChats = false;
  bool _isCheckingUnread = false;

  // ==================== 채팅 실시간 구독 ====================
  StreamSubscription<QuerySnapshot>? _hostRoomSub;
  StreamSubscription<QuerySnapshot>? _guestRoomSub;
  int? _watchingUserId;

  // 두 구독(host/guest)의 최신 unread 합산을 위한 상태
  bool _hostHasUnread = false;
  bool _guestHasUnread = false;

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

  // ==================== 채팅 실시간 구독 ====================

  /// Firestore 실시간 구독 시작
  /// 로그인 후 호출 — 앱 어디서든 레드닷 실시간 반영
  /// hostId/guestId 두 쿼리로 신규 채팅방도 자동 감지
  Future<void> startChatUnreadWatch(int userId) async {
    // 동일 유저 재호출 시 스킵
    if (_watchingUserId == userId &&
        _hostRoomSub != null &&
        _guestRoomSub != null) {
      return;
    }

    stopChatUnreadWatch();
    _watchingUserId = userId;
    _hostHasUnread = false;
    _guestHasUnread = false;

    // Firebase 초기화 완료 대기 (백그라운드 초기화 패턴 대응)
    if (firebaseInitFuture != null) {
      await firebaseInitFuture;
    }

    // Firebase Custom Token 인증 확인 (Firestore 보안 규칙 통과 필수)
    await _firebaseAuth.ensureAuthenticated();

    AppLogger.d('🔔 [GNB] 채팅 실시간 구독 시작 (userId: $userId)');

    // Firestore에 hostId/guestId가 string으로 저장되므로 string으로 쿼리
    final userIdStr = userId.toString();

    _hostRoomSub = FirebaseFirestore.instance
        .collection('chatRooms')
        .where('hostId', isEqualTo: userIdStr)
        .snapshots()
        .listen(
      (snap) => _onRoomsSnapshot(snap, userId, isHost: true),
      onError: (e) => _onSubscriptionError(e, userId),
    );

    _guestRoomSub = FirebaseFirestore.instance
        .collection('chatRooms')
        .where('guestId', isEqualTo: userIdStr)
        .snapshots()
        .listen(
      (snap) => _onRoomsSnapshot(snap, userId, isHost: false),
      onError: (e) => _onSubscriptionError(e, userId),
    );
  }

  /// Firestore 실시간 구독 해제
  void stopChatUnreadWatch() {
    _hostRoomSub?.cancel();
    _guestRoomSub?.cancel();
    _hostRoomSub = null;
    _guestRoomSub = null;
    _watchingUserId = null;
    _hostHasUnread = false;
    _guestHasUnread = false;
  }

  /// 스냅샷 수신 처리 (host/guest 구독 공통)
  void _onRoomsSnapshot(
    QuerySnapshot snap,
    int userId, {
    required bool isHost,
  }) {
    bool hasUnread = false;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
      final rawUnread = unreadMap[userId.toString()] ?? 0;
      final unread = rawUnread is int ? rawUnread : (rawUnread as num).toInt();
      if (unread > 0) {
        hasUnread = true;
        break;
      }
    }

    if (isHost) {
      _hostHasUnread = hasUnread;
    } else {
      _guestHasUnread = hasUnread;
    }

    // 두 구독 결과를 OR로 합산
    setUnreadChats(_hostHasUnread || _guestHasUnread);
  }

  /// 구독 에러 처리 — permission-denied 시 재인증 후 재구독
  void _onSubscriptionError(dynamic e, int userId) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      AppLogger.w('⚠️ [GNB] 채팅 구독 권한 없음 — 재인증 후 재구독');
      // _watchingUserId 초기화 후 재호출해야 스킵 로직을 통과함
      _watchingUserId = null;
      _firebaseAuth.signInWithCustomToken().then((_) {
        startChatUnreadWatch(userId);
      }).catchError((err) {
        AppLogger.e('❌ [GNB] 재인증 실패: $err');
      });
      return;
    }
    AppLogger.w('⚠️ [GNB] 채팅 구독 에러: $e');
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
