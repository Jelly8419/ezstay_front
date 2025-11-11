import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/chat_provider.dart';
import '../../utils/responsive_util.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../constants/app_constants.dart';

/// 채팅방 목록 페이지
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadChatRooms();
  }

  /// Firebase 인증 후 채팅방 목록 로드
  Future<void> _initializeAndLoadChatRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 1. Firebase 인증 확인
      await _firebaseAuth.ensureAuthenticated();

      // 2. 채팅방 목록 로드
      final chatRooms = await _chatService.getChatRooms();

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('❌ [CHAT_LIST] 초기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 사이드바에서 렌더링될 때는 body만 반환
    final chatProvider = Provider.of<ChatProvider>(context);
    if (chatProvider.isOpen && ResponsiveUtil.isDesktop(context)) {
      return _buildBody();
    }

    // 전체 화면일 때는 Scaffold 사용
    return ResponsiveScaffold(
      scrollable: false,  // ListView가 자체 스크롤을 처리하므로 false
      usePadding: false,  // ListView가 자체 패딩을 처리하므로 false
      title: '채팅',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '채팅방 목록을 불러올 수 없습니다',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeAndLoadChatRooms,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '채팅방이 없습니다',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              '계약이 승인되면 호스트와 채팅할 수 있습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeAndLoadChatRooms,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _chatRooms.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chatRoom = _chatRooms[index];
          final authService = Provider.of<AuthService>(context, listen: false);
          final currentUserIdStr = authService.currentUser?.id;
          final currentUserId = currentUserIdStr != null ? (int.tryParse(currentUserIdStr) ?? 0) : 0;
          return _ChatRoomTile(
            chatRoom: chatRoom,
            currentUserId: currentUserId,
            onTap: () => _navigateToChatDetail(chatRoom),
          );
        },
      ),
    );
  }

  /// 채팅 상세 페이지로 이동
  void _navigateToChatDetail(ChatRoom chatRoom) {
    // 데스크톱에서는 사이드바에서 열기, 모바일에서는 전체 화면으로 이동
    if (ResponsiveUtil.isDesktop(context)) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.openChatDetail(chatRoom);
    } else {
      context.push(
        '/chat-detail',
        extra: {
          'chatRoomId': chatRoom.firebaseChatRoomId,
          'contractId': chatRoom.contractId,
        },
      );
    }
  }
}

/// 채팅방 타일 위젯
class _ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final int currentUserId;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = chatRoom.getOtherUser(currentUserId);
    final roomName = chatRoom.getRoomDisplayName();
    final hasUnread = (chatRoom.unreadCount ?? 0) > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundImage: otherUser?.profileImageUrl != null
            ? NetworkImage(otherUser!.profileImageUrl!)
            : null,
        child: otherUser?.profileImageUrl == null
            ? Text(
                otherUser?.name.substring(0, 1) ?? '?',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser?.name ?? '알 수 없음',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (chatRoom.lastMessageAt != null)
            Text(
              _formatTime(chatRoom.lastMessageAt!),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            roomName,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (chatRoom.lastMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              chatRoom.lastMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${chatRoom.unreadCount}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  /// 시간 포맷팅 (오늘: HH:mm, 어제 이전: MM/dd)
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // 오늘: 시간만 표시
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // 어제
      return '어제';
    } else if (now.year == dateTime.year) {
      // 올해: 월/일만 표시
      return DateFormat('MM/dd').format(dateTime);
    } else {
      // 작년 이전: 년/월/일 표시
      return DateFormat('yyyy/MM/dd').format(dateTime);
    }
  }
}
