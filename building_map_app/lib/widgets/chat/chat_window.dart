import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../services/firebase_auth_service.dart';
import '../system_message_bubble.dart';
import 'message_item.dart';
import 'chat_read_only_banner.dart';
import 'chat_input_bar.dart';
import 'chat_window_header.dart';

/// 채팅 윈도우 위젯
/// React ChatWindow.tsx를 Flutter로 완전 복제
class ChatWindow extends StatefulWidget {
  final ChatRoom? chatRoom;
  final List<ChatMessage> messages;
  final int currentUserId;
  final VoidCallback onOpenContractInfo;
  final VoidCallback? onBack;
  final Future<void> Function(String message, List<XFile> images)? onSendMessage;

  const ChatWindow({
    super.key,
    required this.chatRoom,
    required this.messages,
    required this.currentUserId,
    required this.onOpenContractInfo,
    this.onBack,
    this.onSendMessage,
  });

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final List<XFile> _selectedImages = [];
  bool _hasText = false;
  bool _isSending = false;

  // 채팅 쓰기 제한 상태
  // REST API의 isReadOnly로 초기값 설정 → Firestore 구독으로 실시간 업데이트
  late bool _isWriteLocked;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _writeLockSub;

  @override
  void initState() {
    super.initState();
    _isWriteLocked = widget.chatRoom?.isReadOnly ?? false;
    _subscribeWriteLock();
  }

  @override
  void didUpdateWidget(ChatWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 채팅방이 바뀌면 구독 갱신
    if (widget.chatRoom?.firebaseChatRoomId !=
        oldWidget.chatRoom?.firebaseChatRoomId) {
      // 채팅방 변경 시 즉시 REST API 값으로 초기화 후 Firestore 구독
      setState(() => _isWriteLocked = widget.chatRoom?.isReadOnly ?? false);
      _subscribeWriteLock();
    }
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  /// chatWritableUntil 실시간 구독
  /// permission-denied 발생 시 재인증 후 자동 재구독 (ID Token 만료 대응)
  void _subscribeWriteLock() {
    _writeLockSub?.cancel();
    final chatRoomId = widget.chatRoom?.firebaseChatRoomId;
    if (chatRoomId == null) return;

    _writeLockSub = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data();
      final writableUntil =
          (data?['chatWritableUntil'] as Timestamp?)?.toDate();
      // chatWritableUntil이 있고 만료된 경우에만 Firestore로 잠금
      // 필드가 없으면 REST API의 isReadOnly 값을 그대로 유지
      final firestoreLocked =
          writableUntil != null && DateTime.now().isAfter(writableUntil);
      final restLocked = widget.chatRoom?.isReadOnly ?? false;
      final locked = firestoreLocked || restLocked;
      if (locked != _isWriteLocked) {
        setState(() => _isWriteLocked = locked);
      }
    }, onError: (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        AppLogger.w('⚠️ [CHAT_WINDOW] writeLock 권한 없음 — 재인증 후 재구독');
        // 재인증 후 재구독
        _firebaseAuth.signInWithCustomToken().then((_) {
          if (mounted) _subscribeWriteLock();
        }).catchError((err) {
          AppLogger.e('❌ [CHAT_WINDOW] 재인증 실패: $err');
        });
        return;
      }
      AppLogger.w('⚠️ [CHAT_WINDOW] writeLock 구독 에러: $e');
    });
  }

  @override
  void dispose() {
    _writeLockSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleImageSelect() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // 최대 5개까지만 선택 가능
        if (_selectedImages.length + images.length > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미지는 최대 5개까지만 첨부할 수 있습니다.'),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      AppLogger.e('Error picking images: $e');
    }
  }

  void _handleRemoveImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if ((message.isNotEmpty || _selectedImages.isNotEmpty) && !_isSending) {
      final imagesToSend = List<XFile>.from(_selectedImages);
      _messageController.clear();
      setState(() {
        _hasText = false;
        _selectedImages.clear();
        _isSending = true;
      });
      try {
        await widget.onSendMessage?.call(message, imagesToSend);
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  /// 메시지를 날짜별로 그룹화
  List<_MessageGroup> _groupMessagesByDate() {
    if (widget.messages.isEmpty) return [];

    final groups = <_MessageGroup>[];

    for (final msg in widget.messages) {
      final dateStr = _formatDate(msg.timestamp);
      final lastGroup = groups.isNotEmpty ? groups.last : null;

      if (lastGroup != null && lastGroup.date == dateStr) {
        lastGroup.messages.add(msg);
      } else {
        groups.add(_MessageGroup(date: dateStr, messages: [msg]));
      }
    }

    return groups;
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// 계약 기간 포맷팅
  String _formatContractPeriod() {
    if (widget.chatRoom?.contract == null) return '';
    final start = widget.chatRoom!.contract!.checkInDate;
    final end = widget.chatRoom!.contract!.checkOutDate;
    return '${start.month}/${start.day} ~ ${end.month}/${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    // chatRoom이 없을 때 빈 상태 표시
    if (widget.chatRoom == null) {
      return _buildEmptyState();
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024; // lg breakpoint
    final messageGroups = _groupMessagesByDate();

    return Container(
      color: AppColors.neutral0, // bg-white
      child: Column(
        children: [
          // Header with Contract Info
          ChatWindowHeader(
            chatRoom: widget.chatRoom!,
            currentUserId: widget.currentUserId,
            onOpenContractInfo: widget.onOpenContractInfo,
            onBack: widget.onBack,
            isDesktop: isDesktop,
          ),

          // Contract Period Banner
          _buildContractPeriodBanner(),

          // Messages
          Expanded(
            child: _buildMessageArea(messageGroups),
          ),

          // Input Area
          if (_isWriteLocked)
            const ChatReadOnlyBanner()
          else
            ChatInputBar(
              messageController: _messageController,
              selectedImages: _selectedImages,
              isSending: _isSending,
              hasText: _hasText,
              onImageSelect: _handleImageSelect,
              onSend: _handleSend,
              onTextChanged: (value) {
                final hasText = value.trim().isNotEmpty;
                if (hasText != _hasText) {
                  setState(() => _hasText = hasText);
                }
              },
              onRemoveImage: _handleRemoveImage,
            ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      color: AppColors.gray50, // bg-gray-50
      child: Center(
        child: Text(
          '채팅방을 선택해주세요',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral500, // text-gray-500
          ),
        ),
      ),
    );
  }

  /// 계약 기간 배너
  Widget _buildContractPeriodBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 sm:px-6 py-3
      decoration: const BoxDecoration(
        color: AppColors.blue50, // bg-blue-50
        border: Border(
          top: BorderSide(color: AppColors.blue100, width: 1), // border-blue-100
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16, // w-4 h-4
            color: AppColors.blue600, // text-blue-600
          ),
          const SizedBox(width: 8), // gap-2
          Expanded(
            child: Text(
              '계약 기간: ${_formatContractPeriod()}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.blue900, // text-blue-900
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 영역
  Widget _buildMessageArea(List<_MessageGroup> messageGroups) {
    final otherUser = widget.chatRoom!.getOtherUser(widget.currentUserId);
    final otherUserAvatar = otherUser?.profileImageUrl ?? '';
    final myRole = widget.chatRoom!.getMyRole(widget.currentUserId);

    return Container(
      color: AppColors.gray50, // bg-gray-50
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // px-4 sm:px-6 py-4
        itemCount: messageGroups.length,
        itemBuilder: (context, groupIndex) {
          final group = messageGroups[groupIndex];
          return Column(
            children: [
              // Date Separator
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
                  decoration: BoxDecoration(
                    color: AppColors.gray200, // bg-gray-200
                    borderRadius: BorderRadius.circular(9999), // rounded-full
                  ),
                  child: Text(
                    group.date,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral700, // text-gray-700
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // space-y-4

              // Messages for this date
              ...group.messages.map((msg) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16), // space-y-4
                  // 시스템 메시지는 SystemMessageBubble 사용
                  child: msg.type == MessageType.system
                      ? SystemMessageBubble(message: msg)
                      : MessageItem(
                          message: msg,
                          currentUserRole: myRole,
                          otherPartyAvatar: otherUserAvatar,
                          currentUserId: widget.currentUserId,
                        ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

}

/// 메시지 그룹 (날짜별)
class _MessageGroup {
  final String date;
  final List<ChatMessage> messages;

  _MessageGroup({required this.date, required this.messages});
}
