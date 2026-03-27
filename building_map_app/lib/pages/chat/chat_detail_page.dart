import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/system_message_bubble.dart';

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

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: _currentUserId!,
        text: text,
      );

      // 알림톡 요청 (fire-and-forget)
      _chatService.notifyChatMessage(widget.chatRoomId);

      _messageController.clear();

      // 스크롤을 최하단으로 이동
      _scrollToBottom();
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
        if (isReadOnly) _buildReadOnlyBanner(),
        // 메시지 목록
        Expanded(
          child: _buildMessageList(),
        ),
        // 메시지 입력 필드 (읽기 전용이 아닐 때만)
        if (!isReadOnly) _buildMessageInput(),
      ],
    );
  }

  /// 읽기 전용 안내 배너
  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF3F4F6),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _chatRoom?.readOnlyReason ?? '종료된 계약의 채팅방입니다. 메시지를 보낼 수 없습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 목록
  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getMessages(widget.chatRoomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        final messages = snapshot.data ?? [];

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
                  SystemMessageBubble(message: message)  // 시스템 메시지
                else
                  _ChatBubble(  // 일반 메시지
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
    return _MessageInputField(
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

/// 채팅 말풍선 위젯
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            _buildTime(),
            const SizedBox(width: 8),
          ],
          _buildBubble(),
          if (!isMe) ...[
            const SizedBox(width: 8),
            _buildTime(),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: EdgeInsets.symmetric(
        horizontal: message.isImageMessage && message.text.isEmpty ? 4 : 16,
        vertical: message.isImageMessage && message.text.isEmpty ? 4 : 10,
      ),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary500 : AppColors.neutral200,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.text.isNotEmpty)
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          if (message.imageUrl != null) ...[
            if (message.text.isNotEmpty) const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: ContractUtils.getFullImageUrl(message.imageUrl),
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (ctx, url, error) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTime() {
    return Text(
      FormatUtils.formatTime(message.timestamp),
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
    );
  }
}

/// 메시지 입력 필드 위젯 (포커스 유지를 위해 별도 StatefulWidget으로 분리)
class _MessageInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueNotifier<bool> isSendingNotifier;
  final VoidCallback onSend;

  const _MessageInputField({
    required this.controller,
    required this.isSendingNotifier,
    required this.onSend,
  });

  @override
  State<_MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    widget.onSend();
    // 메시지 전송 후 포커스 복원
    Future.microtask(() {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: AppColors.primary500.withValues(alpha: 0.3), width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: widget.isSendingNotifier,
              builder: (context, isSending, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary500.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isSending ? null : _handleSend,
                    icon: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
