/// 알림 유형 정의
/// 백엔드 API 스펙과 1:1 매핑 (대문자 스네이크케이스)
enum NotificationType {
  // 공통 알림
  message,
  notice,
  inquiryAnswered,
  paymentCompleted,
  checkinToday,
  checkoutReminder,
  checkoutConfirmed,
  contractCanceled,
  // 게스트 전용
  contractRequestGuest,
  contractApproved,
  contractRejected,
  paymentPending,
  optionDeadline,
  // 호스트 전용
  contractRequestHost,
  propertyReviewResult,
  additionalOptionPayment,
  checkinConfirmed,
  checkoutRequest,
  // 정산/보증금 알림
  settlementCompleted,
  depositReturned,
  // 입주 리마인더 (D-1)
  checkinReminder,
  // 게스트 입주 준비 서비스
  moveInPaymentRequest,
  moveInPaymentCompleted,
  // 호스트 입주 준비 — 방 심사 결과
  moveInRoomReviewResult,
}

/// 딥링크 타입
enum DeeplinkType {
  contract,
  chat,
  notice,
  inquiry,
  room,
  home,
  moveIn,
  moveInRoom,
}

/// 알림 아이템 모델
/// API 응답 스펙에 맞게 정의
class NotificationItem {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DeeplinkType deeplink;
  // 딥링크용 관련 ID
  final int? relatedContractId;
  final int? relatedChatRoomId;
  final int? relatedNoticeId;
  final int? relatedInquiryId;
  final int? relatedRoomId;
  // 추가 메타데이터
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.deeplink = DeeplinkType.home,
    this.relatedContractId,
    this.relatedChatRoomId,
    this.relatedNoticeId,
    this.relatedInquiryId,
    this.relatedRoomId,
    this.metadata,
  });

  /// JSON에서 NotificationItem 생성
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      type: _parseNotificationType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      deeplink: _parseDeeplinkType(json['deeplink'] as String?),
      relatedContractId: json['relatedContractId'] as int?,
      relatedChatRoomId: json['relatedChatRoomId'] as int?,
      relatedNoticeId: json['relatedNoticeId'] as int?,
      relatedInquiryId: json['relatedInquiryId'] as int?,
      relatedRoomId: json['relatedRoomId'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// NotificationItem을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _notificationTypeToString(type),
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'deeplink': _deeplinkTypeToString(deeplink),
      'relatedContractId': relatedContractId,
      'relatedChatRoomId': relatedChatRoomId,
      'relatedNoticeId': relatedNoticeId,
      'relatedInquiryId': relatedInquiryId,
      'relatedRoomId': relatedRoomId,
      'metadata': metadata,
    };
  }

  /// isRead가 변경된 새 인스턴스 생성
  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      deeplink: deeplink,
      relatedContractId: relatedContractId,
      relatedChatRoomId: relatedChatRoomId,
      relatedNoticeId: relatedNoticeId,
      relatedInquiryId: relatedInquiryId,
      relatedRoomId: relatedRoomId,
      metadata: metadata,
    );
  }

  /// 문자열을 NotificationType으로 변환 (대문자 스네이크케이스)
  static NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null) return NotificationType.notice;

    switch (typeStr) {
      // 공통
      case 'MESSAGE':
        return NotificationType.message;
      case 'NOTICE':
        return NotificationType.notice;
      case 'INQUIRY_ANSWERED':
        return NotificationType.inquiryAnswered;
      case 'PAYMENT_COMPLETED':
        return NotificationType.paymentCompleted;
      case 'CHECKIN_TODAY':
        return NotificationType.checkinToday;
      case 'CHECKOUT_REMINDER':
        return NotificationType.checkoutReminder;
      case 'CHECKOUT_CONFIRMED':
        return NotificationType.checkoutConfirmed;
      case 'CONTRACT_CANCELED':
        return NotificationType.contractCanceled;
      // 게스트 전용
      case 'CONTRACT_REQUEST_GUEST':
        return NotificationType.contractRequestGuest;
      case 'CONTRACT_APPROVED':
        return NotificationType.contractApproved;
      case 'CONTRACT_REJECTED':
        return NotificationType.contractRejected;
      case 'PAYMENT_PENDING':
        return NotificationType.paymentPending;
      case 'OPTION_DEADLINE':
        return NotificationType.optionDeadline;
      // 호스트 전용
      case 'CONTRACT_REQUEST_HOST':
        return NotificationType.contractRequestHost;
      case 'PROPERTY_REVIEW_RESULT':
        return NotificationType.propertyReviewResult;
      case 'ADDITIONAL_OPTION_PAYMENT':
        return NotificationType.additionalOptionPayment;
      case 'CHECKIN_CONFIRMED':
        return NotificationType.checkinConfirmed;
      case 'CHECKOUT_REQUEST':
        return NotificationType.checkoutRequest;
      // 정산/보증금/리마인더
      case 'SETTLEMENT_COMPLETED':
        return NotificationType.settlementCompleted;
      case 'DEPOSIT_RETURNED':
        return NotificationType.depositReturned;
      case 'CHECKIN_REMINDER':
        return NotificationType.checkinReminder;
      case 'MOVE_IN_PAYMENT_REQUEST':
        return NotificationType.moveInPaymentRequest;
      case 'MOVE_IN_PAYMENT_COMPLETED':
        return NotificationType.moveInPaymentCompleted;
      case 'MOVE_IN_ROOM_REVIEW_RESULT':
        return NotificationType.moveInRoomReviewResult;
      default:
        return NotificationType.notice;
    }
  }

  /// NotificationType을 문자열로 변환
  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      // 공통
      case NotificationType.message:
        return 'MESSAGE';
      case NotificationType.notice:
        return 'NOTICE';
      case NotificationType.inquiryAnswered:
        return 'INQUIRY_ANSWERED';
      case NotificationType.paymentCompleted:
        return 'PAYMENT_COMPLETED';
      case NotificationType.checkinToday:
        return 'CHECKIN_TODAY';
      case NotificationType.checkoutReminder:
        return 'CHECKOUT_REMINDER';
      case NotificationType.checkoutConfirmed:
        return 'CHECKOUT_CONFIRMED';
      case NotificationType.contractCanceled:
        return 'CONTRACT_CANCELED';
      // 게스트 전용
      case NotificationType.contractRequestGuest:
        return 'CONTRACT_REQUEST_GUEST';
      case NotificationType.contractApproved:
        return 'CONTRACT_APPROVED';
      case NotificationType.contractRejected:
        return 'CONTRACT_REJECTED';
      case NotificationType.paymentPending:
        return 'PAYMENT_PENDING';
      case NotificationType.optionDeadline:
        return 'OPTION_DEADLINE';
      // 호스트 전용
      case NotificationType.contractRequestHost:
        return 'CONTRACT_REQUEST_HOST';
      case NotificationType.propertyReviewResult:
        return 'PROPERTY_REVIEW_RESULT';
      case NotificationType.additionalOptionPayment:
        return 'ADDITIONAL_OPTION_PAYMENT';
      case NotificationType.checkinConfirmed:
        return 'CHECKIN_CONFIRMED';
      case NotificationType.checkoutRequest:
        return 'CHECKOUT_REQUEST';
      // 정산/보증금/리마인더
      case NotificationType.settlementCompleted:
        return 'SETTLEMENT_COMPLETED';
      case NotificationType.depositReturned:
        return 'DEPOSIT_RETURNED';
      case NotificationType.checkinReminder:
        return 'CHECKIN_REMINDER';
      case NotificationType.moveInPaymentRequest:
        return 'MOVE_IN_PAYMENT_REQUEST';
      case NotificationType.moveInPaymentCompleted:
        return 'MOVE_IN_PAYMENT_COMPLETED';
      case NotificationType.moveInRoomReviewResult:
        return 'MOVE_IN_ROOM_REVIEW_RESULT';
    }
  }

  /// 문자열을 DeeplinkType으로 변환
  static DeeplinkType _parseDeeplinkType(String? deeplinkStr) {
    if (deeplinkStr == null) return DeeplinkType.home;

    switch (deeplinkStr) {
      case 'contract':
        return DeeplinkType.contract;
      case 'chat':
        return DeeplinkType.chat;
      case 'notice':
        return DeeplinkType.notice;
      case 'inquiry':
        return DeeplinkType.inquiry;
      case 'room':
        return DeeplinkType.room;
      case 'move-in':
      case 'moveIn':
        return DeeplinkType.moveIn;
      case 'move-in-room':
      case 'moveInRoom':
        return DeeplinkType.moveInRoom;
      case 'home':
      default:
        return DeeplinkType.home;
    }
  }

  /// DeeplinkType을 문자열로 변환
  static String _deeplinkTypeToString(DeeplinkType deeplink) {
    switch (deeplink) {
      case DeeplinkType.contract:
        return 'contract';
      case DeeplinkType.chat:
        return 'chat';
      case DeeplinkType.notice:
        return 'notice';
      case DeeplinkType.inquiry:
        return 'inquiry';
      case DeeplinkType.room:
        return 'room';
      case DeeplinkType.home:
        return 'home';
      case DeeplinkType.moveIn:
        return 'move-in';
      case DeeplinkType.moveInRoom:
        return 'move-in-room';
    }
  }
}

/// 알림 목록 응답 모델
class NotificationListResponse {
  final List<NotificationItem> notifications;
  final NotificationPagination pagination;

  const NotificationListResponse({
    required this.notifications,
    required this.pagination,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final notificationsList = data['notifications'] as List<dynamic>? ?? [];

    return NotificationListResponse(
      notifications: notificationsList
          .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
          .toList(),
      pagination: NotificationPagination.fromJson(
        data['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// 알림 페이지네이션 모델
class NotificationPagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasMore;

  const NotificationPagination({
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.hasMore = false,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      totalCount: json['totalCount'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// 읽지 않은 알림 수 응답 모델
class UnreadCountResponse {
  final int? guestCount;
  final int? hostCount;
  final int? totalCount;
  final int? singleModeCount;

  const UnreadCountResponse({
    this.guestCount,
    this.hostCount,
    this.totalCount,
    this.singleModeCount,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final unreadCount = data['unreadCount'];

    // userMode 없이 호출한 경우: { guest: 5, host: 3, total: 8 }
    if (unreadCount is Map<String, dynamic>) {
      return UnreadCountResponse(
        guestCount: unreadCount['guest'] as int?,
        hostCount: unreadCount['host'] as int?,
        totalCount: unreadCount['total'] as int?,
      );
    }

    // userMode로 호출한 경우: { unreadCount: 5 }
    return UnreadCountResponse(
      singleModeCount: unreadCount as int? ?? 0,
    );
  }

  /// 특정 모드의 읽지 않은 알림 수 반환
  int getCount({String? userMode}) {
    if (userMode == 'guest') return guestCount ?? singleModeCount ?? 0;
    if (userMode == 'host') return hostCount ?? singleModeCount ?? 0;
    return totalCount ?? singleModeCount ?? 0;
  }
}

/// GET /api/gnb/badge-status 응답 모델
class GnbBadgeStatusResponse {
  final int unreadNotificationCount;
  final bool hasUnreadChat;

  const GnbBadgeStatusResponse({
    required this.unreadNotificationCount,
    required this.hasUnreadChat,
  });

  factory GnbBadgeStatusResponse.fromJson(Map<String, dynamic> json, {String? userMode}) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final unreadCount = data['unreadCount'];
    final hasUnreadChat = data['hasUnreadChat'];

    // userMode 없이 호출: 두 필드 모두 Map
    if (unreadCount is Map<String, dynamic>) {
      final count = userMode != null
          ? (unreadCount[userMode] as int? ?? 0)
          : (unreadCount['total'] as int? ?? 0);
      final chatUnread = hasUnreadChat is Map<String, dynamic>
          ? (userMode != null
              ? hasUnreadChat[userMode] == true
              : (hasUnreadChat['guest'] == true || hasUnreadChat['host'] == true))
          : hasUnreadChat == true;
      return GnbBadgeStatusResponse(
        unreadNotificationCount: count,
        hasUnreadChat: chatUnread,
      );
    }

    // userMode 지정 호출: 두 필드 모두 단일값
    return GnbBadgeStatusResponse(
      unreadNotificationCount: unreadCount as int? ?? 0,
      hasUnreadChat: hasUnreadChat == true,
    );
  }

  static const GnbBadgeStatusResponse empty = GnbBadgeStatusResponse(
    unreadNotificationCount: 0,
    hasUnreadChat: false,
  );
}
