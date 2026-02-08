import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification_item.dart';
import '../../models/user.dart';
import '../../providers/gnb_provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/app_footer.dart';

/// 알림 페이지
/// React: NotificationPage.tsx 1:1 복제
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationItem> _notifications = [];
  NotificationPagination _pagination = const NotificationPagination();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _userMode = 'guest';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeAndLoad();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAndLoad() {
    // 현재 사용자 모드 확인
    final authService = context.read<AuthService>();
    final isHostMode = authService.currentUser?.mode == UserMode.host;
    _userMode = isHostMode ? 'host' : 'guest';

    _loadNotifications();
  }

  /// 스크롤 이벤트 (무한 스크롤)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  /// 알림 목록 로드
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final response = await _notificationService.getNotifications(
      userMode: _userMode,
      page: 1,
    );

    setState(() {
      _notifications = response.notifications;
      _pagination = response.pagination;
      _isLoading = false;
    });

    // 읽지 않은 알림이 있으면 전체 읽음 처리
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (hasUnread) {
      await _notificationService.markAllAsRead(userMode: _userMode);

      // UI에서 즉시 읽음 처리 반영
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });

      // GNB Red Dot 제거
      if (mounted) {
        context.read<GNBProvider>().markNotificationsAsRead();
      }
    }
  }

  /// 다음 페이지 로드 (무한 스크롤)
  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_pagination.hasMore) return;

    setState(() => _isLoadingMore = true);

    final response = await _notificationService.getNotifications(
      userMode: _userMode,
      page: _pagination.currentPage + 1,
    );

    setState(() {
      _notifications.addAll(response.notifications);
      _pagination = response.pagination;
      _isLoadingMore = false;
    });
  }

  /// 상대 시간 표시 (예: "3시간 전")
  /// React: getRelativeTime 함수 1:1 복제
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final diffMins = diff.inMinutes;
    final diffHours = diff.inHours;
    final diffDays = diff.inDays;

    if (diffMins < 1) return '방금 전';
    if (diffMins < 60) return '$diffMins분 전';
    if (diffHours < 24) return '$diffHours시간 전';
    if (diffDays < 7) return '$diffDays일 전';

    // 7일 이상은 날짜 표시
    return '${dateTime.month}월 ${dateTime.day}일';
  }

  /// 알림 클릭 시 딥링크 처리
  /// API deeplink 필드 기반 네비게이션
  /// NotificationType에 따른 폴백 로직 포함
  void _handleNotificationClick(NotificationItem notification) {
    final isHostMode = _userMode == 'host';

    // 1. 계약 거절 알림은 계약 상세 페이지로 이동
    if (notification.type == NotificationType.contractRejected) {
      _navigateToContract(notification, isHostMode);
      return;
    }

    // 2. 기타 계약 관련 알림은 계약 목록 페이지로 이동
    if (_isContractRelatedType(notification.type)) {
      _navigateToContractList(isHostMode);
      return;
    }

    // 2. 메시지 타입은 채팅 페이지로 이동
    if (notification.type == NotificationType.message) {
      _navigateToChat(notification);
      return;
    }

    // 3. 공지사항 타입은 공지 페이지로 이동
    if (notification.type == NotificationType.notice) {
      _navigateToNotice(notification);
      return;
    }

    // 4. 1:1 문의 답변 타입은 문의 페이지로 이동
    if (notification.type == NotificationType.inquiryAnswered) {
      _navigateToInquiry(notification);
      return;
    }

    // 5. 방 심사 결과 타입은 방 관리 페이지로 이동
    if (notification.type == NotificationType.propertyReviewResult) {
      _navigateToRoom(notification);
      return;
    }

    // 6. deeplink 필드 기반 네비게이션 (폴백)
    switch (notification.deeplink) {
      case DeeplinkType.contract:
        _navigateToContract(notification, isHostMode);
        break;

      case DeeplinkType.chat:
        _navigateToChat(notification);
        break;

      case DeeplinkType.notice:
        _navigateToNotice(notification);
        break;

      case DeeplinkType.inquiry:
        _navigateToInquiry(notification);
        break;

      case DeeplinkType.room:
        _navigateToRoom(notification);
        break;

      case DeeplinkType.home:
        if (isHostMode) {
          context.go('/host');
        } else {
          context.go('/guest');
        }
        break;
    }
  }

  /// 계약 관련 알림 타입인지 확인
  bool _isContractRelatedType(NotificationType type) {
    return type == NotificationType.contractRequestHost ||
        type == NotificationType.contractRequestGuest ||
        type == NotificationType.contractApproved ||
        type == NotificationType.contractRejected ||
        type == NotificationType.contractCanceled ||
        type == NotificationType.paymentCompleted ||
        type == NotificationType.paymentPending ||
        type == NotificationType.checkinToday ||
        type == NotificationType.checkinConfirmed ||
        type == NotificationType.checkoutReminder ||
        type == NotificationType.checkoutConfirmed ||
        type == NotificationType.checkoutRequest ||
        type == NotificationType.optionDeadline ||
        type == NotificationType.additionalOptionPayment;
  }

  /// 계약 목록 페이지로 이동 (계약 요청 알림용)
  void _navigateToContractList(bool isHostMode) {
    if (isHostMode) {
      context.push('/host/contracts');
    } else {
      context.push('/guest/contracts');
    }
  }

  /// 계약 페이지로 이동 (상세 또는 목록)
  void _navigateToContract(NotificationItem notification, bool isHostMode) {
    if (notification.relatedContractId != null) {
      // 계약 상세 페이지로 이동
      if (isHostMode) {
        context.push('/host/contracts/${notification.relatedContractId}');
      } else {
        context.push('/guest/contracts/${notification.relatedContractId}');
      }
    } else {
      // 계약 목록 페이지로 이동
      _navigateToContractList(isHostMode);
    }
  }

  /// 채팅 페이지로 이동
  void _navigateToChat(NotificationItem notification) {
    if (notification.relatedChatRoomId != null) {
      context.push('/chat-list/${notification.relatedChatRoomId}');
    } else {
      context.push('/chat-list');
    }
  }

  /// 공지사항 페이지로 이동
  void _navigateToNotice(NotificationItem notification) {
    if (notification.relatedNoticeId != null) {
      context.push('/support/notices/${notification.relatedNoticeId}');
    } else {
      context.push('/support?tab=notices');
    }
  }

  /// 1:1 문의 페이지로 이동
  void _navigateToInquiry(NotificationItem notification) {
    if (notification.relatedInquiryId != null) {
      context.push('/support/inquiries/${notification.relatedInquiryId}/edit');
    } else {
      context.push('/support?tab=inquiries');
    }
  }

  /// 방 관리 페이지로 이동
  void _navigateToRoom(NotificationItem notification) {
    if (notification.relatedRoomId != null) {
      context.push('/host/room-registration/${notification.relatedRoomId}');
    } else {
      context.push('/host/room-management');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // React: bg-gray-50
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        // React: <PageHeader title="알림" onBack={onBack} />
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.gray200,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    // React: max-w-4xl mx-auto px-4 py-6 pb-24 lg:py-8 lg:pb-8
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return _notifications.isEmpty
        ? _buildEmptyState(isDesktop)
        : _buildNotificationList(isDesktop);
  }

  /// 빈 상태 UI
  /// React: 빈 상태 div 1:1 복제
  Widget _buildEmptyState(bool isDesktop) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            // React: px-4 py-6 pb-24 lg:py-8 lg:pb-8
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: isDesktop ? 32 : 24,
              bottom: isDesktop ? 32 : 96,
            ),
            child: Padding(
              // React: py-20 = 80px
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // React: w-16 h-16 text-gray-300
                  Icon(
                    Icons.notifications_outlined,
                    size: 64,
                    color: AppColors.neutral300,
                  ),
                  // React: mb-4 = 16px
                  const SizedBox(height: 16),
                  // React: text-gray-500 text-lg
                  const Text(
                    '아직 도착한 알림이 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.neutral500,
                    ),
                  ),
                  // React: mb-2 = 8px
                  const SizedBox(height: 8),
                  // React: text-gray-400 text-sm
                  const Text(
                    '계약 요청, 메시지, 결제 등의 알림이 여기에 표시됩니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  /// 알림 리스트
  /// React: space-y-2 = 8px gap
  Widget _buildNotificationList(bool isDesktop) {
    // +1 for footer, +1 for loading indicator if loading more
    final itemCount = _notifications.length + 1 + (_isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 로딩 인디케이터 (footer 전에 표시)
        if (_isLoadingMore && index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Footer (마지막 아이템)
        if (index == itemCount - 1) {
          return const AppFooter();
        }

        final notification = _notifications[index];
        return Padding(
          // React: space-y-2 = 8px gap + px-4 py-6 pb-24 lg:py-8 lg:pb-8
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: index == 0 ? (isDesktop ? 32 : 24) : 0,
            bottom: index < _notifications.length - 1 ? 8 : (isDesktop ? 32 : 96),
          ),
          child: _buildNotificationCard(notification),
        );
      },
    );
  }

  /// 알림 카드
  /// React: button 요소 1:1 복제
  Widget _buildNotificationCard(NotificationItem notification) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationClick(notification),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            // React: bg-white
            color: AppColors.surface,
            // React: rounded-lg = 8px
            borderRadius: BorderRadius.circular(8),
            // React: border border-gray-200
            border: Border.all(color: AppColors.gray200),
          ),
          // React: p-4 = 16px
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // React: flex-1 min-w-0
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 시간 Row
                    // React: flex items-start justify-between gap-2 mb-1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // React: text-sm font-bold text-gray-900
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        // React: gap-2 = 8px
                        const SizedBox(width: 8),
                        // React: text-xs text-gray-500 whitespace-nowrap
                        Text(
                          _getRelativeTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    // React: mb-1 = 4px
                    const SizedBox(height: 4),
                    // React: text-sm text-gray-600 line-clamp-2
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
