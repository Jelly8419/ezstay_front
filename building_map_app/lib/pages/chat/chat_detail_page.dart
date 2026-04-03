import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/format_utils.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart' show ChatService, ChatPermissionDeniedException;
import '../../services/firebase_auth_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/system_message_bubble.dart';
import '../../widgets/chat/chat_read_only_banner.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_message_input_field.dart';

/// 채팅 상세 페이지
class ChatDetailPage extends StatefulWidget {
  final String chatRoomId;
  final int? contractId;

  const ChatDetailPage({
    super.key,
    required this.chatRoomId,
    this.contractId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isSendingNotifier = ValueNotifier<bool>(false);

  ChatRoom? _chatRoom;
  int? _currentUserId;  // 현재 사용자 ID 저장
  bool _isLoading = true;
  String? _error;
  Timer? _readHeartbeatTimer;  // 30초 heartbeat 타이머
  List<ChatMessage>? _cachedMessages;  // 재진입 시 깜빡임 방지 캐시

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _readHeartbeatTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _isSendingNotifier.dispose();
    super.dispose();
  }

  /// 초기화 및 채팅방 정보 로드
  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 1. Provider에서 전역 AuthService 가져오기 (await 전에 가져와야 함)
      final authService = Provider.of<AuthService>(context, listen: false);

      // 2. Firebase 인증 확인
      await _firebaseAuth.ensureAuthenticated();

      // 3. 현재 사용자 ID 가져오기 및 저장
      final currentUserIdStr = authService.currentUser?.id;
      if (currentUserIdStr != null) {
        _currentUserId = int.tryParse(currentUserIdStr) ?? 0;
      }

      // 4. 채팅방 정보 로드
      final chatRoom = await _chatService.getChatRoomDetail(widget.chatRoomId);

      // 4. Firestore 읽음 처리
      if (_currentUserId != null) {
        await _chatService.markAsRead(
          chatRoomId: widget.chatRoomId,
          userId: _currentUserId!,
        );
      }

      // 5. 서버 읽음 처리 + 30초 heartbeat 시작 (알림톡 차단용)
      _chatService.markAsReadOnServer(widget.chatRoomId);
      _startReadHeartbeat();

      setState(() {
        _chatRoom = chatRoom;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.e('❌ [CHAT_DETAIL] 초기화 실패: $e');
    }
  }

  /// 30초 heartbeat 시작 (채팅방에 머무는 동안 상대방 알림 차단)
  void _startReadHeartbeat() {
    _readHeartbeatTimer?.cancel();
    _readHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _chatService.markAsReadOnServer(widget.chatRoomId),
    );
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingNotifier.value) return;

    try {
      _isSendingNotifier.value = true;

      // 저장된 사용자 ID 사용
      if (_currentUserId == null) {
        throw Exception('로그인이 필요합니다');
      }

      await _chatService.sendMessageWithNotification(
        chatRoomId: widget.chatRoomId,
        senderId: _currentUserId!,
        text: text,
      );

      _messageController.clear();

      // 스크롤을 최하단으로 이동
      _scrollToBottom();
    } on ChatPermissionDeniedException {
      AppLogger.w('⚠️ [CHAT_DETAIL] 권한 거부: 종료된 계약 채팅방');
      if (mounted) _showPermissionDeniedDialog();
    } catch (e) {
      AppLogger.e('❌ [CHAT_DETAIL] 메시지 전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    } finally {
      _isSendingNotifier.value = false;
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 전송 불가'),
        content: const Text('종료된 계약의 채팅방에는 메시지를 보낼 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스크롤을 최하단으로 이동
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final otherUser = _currentUserId != null
        ? _chatRoom?.getOtherUser(_currentUserId!)
        : null;

    return AppBar(
      title: _isLoading
          ? const Text('로딩 중...')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  otherUser?.displayName ?? '채팅',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (_chatRoom?.room != null)
                  Text(
                    _chatRoom!.getRoomDisplayName(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
      backgroundColor: AppColors.primary500,
      foregroundColor: Colors.white,
      elevation: 0,
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
              color: AppColors.error500,
            ),
            const SizedBox(height: 16),
            Text(
              '채팅방을 불러올 수 없습니다',
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
              onPressed: _initialize,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final isReadOnly = _chatRoom?.isReadOnly ?? false;

    return Column(
      children: [
        // 읽기 전용 안내 배너
        if (isReadOnly) const ChatReadOnlyBanner(),
        // 메시지 목록
        Expanded(
          child: _buildMessageList(),
        ),
        // 메시지 입력 필드 (읽기 전용이 아닐 때만)
        if (!isReadOnly) _buildMessageInput(),
      ],
    );
  }

  /// 메시지 목록
  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getMessages(widget.chatRoomId),
      initialData: _cachedMessages,
      builder: (context, snapshot) {
        // 새 데이터가 오면 캐시 업데이트
        if (snapshot.hasData) {
          _cachedMessages = snapshot.data;
        }

        // 캐시가 있으면 로딩 스피너 대신 캐시된 메시지 표시 (깜빡임 방지)
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedMessages == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '메시지를 불러올 수 없습니다\n${snapshot.error}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error500,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final messages = snapshot.data ?? _cachedMessages ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '첫 메시지를 보내보세요!',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // 스크롤을 최하단으로 (메시지 로드 후)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = _currentUserId != null && message.senderId == _currentUserId;
            final showDate = index == 0 ||
                !_isSameDay(messages[index - 1].timestamp, message.timestamp);

            return Column(
              children: [
                if (showDate) _buildDateSeparator(message.timestamp),
                // 메시지 타입별 분기
                if (message.type == MessageType.system)
                  SystemMessageBubble(message: message)
                else
                  ChatBubble(
                    message: message,
                    isMe: isMe,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// 날짜 구분선
  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  /// 메시지 입력 필드
  Widget _buildMessageInput() {
    return ChatMessageInputField(
      controller: _messageController,
      isSendingNotifier: _isSendingNotifier,
      onSend: _sendMessage,
    );
  }

  /// 같은 날짜인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '오늘';
    } else if (messageDate == yesterday) {
      return '어제';
    } else if (now.year == date.year) {
      return FormatUtils.formatDateKorean(date);
    } else {
      return FormatUtils.formatDateKoreanFull(date);
    }
  }
}

