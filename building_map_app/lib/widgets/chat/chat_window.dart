import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../system_message_bubble.dart';
import 'message_item.dart';

/// 채팅 윈도우 위젯
/// React ChatWindow.tsx를 Flutter로 완전 복제
class ChatWindow extends StatefulWidget {
  final ChatRoom? chatRoom;
  final List<ChatMessage> messages;
  final int currentUserId;
  final VoidCallback onOpenContractInfo;
  final VoidCallback? onBack;
  final Function(String message, List<File> images)? onSendMessage;

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
  final List<File> _selectedImages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 메시지가 변경되면 스크롤 맨 아래로
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
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
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _handleRemoveImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _handleSend() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty || _selectedImages.isNotEmpty) {
      widget.onSendMessage?.call(message, List.from(_selectedImages));
      _messageController.clear();
      setState(() {
        _selectedImages.clear();
      });
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
          _buildHeader(isDesktop),

          // Contract Period Banner
          _buildContractPeriodBanner(),

          // Messages
          Expanded(
            child: _buildMessageArea(messageGroups),
          ),

          // Input Area
          _buildInputArea(),
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

  /// 헤더 위젯
  Widget _buildHeader(bool isDesktop) {
    final otherUser = widget.chatRoom!.getOtherUser(widget.currentUserId);
    final otherUserName = widget.chatRoom!.getOtherUserName(widget.currentUserId);
    final otherUserAvatar = otherUser?.profileImageUrl ?? '';
    final propertyTitle = widget.chatRoom!.getRoomDisplayName();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0, // bg-white
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 1), // border-gray-200
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16, // px-4 sm:px-6
          vertical: 16, // py-4
        ),
        child: Row(
          children: [
            // Mobile Back Button
            if (widget.onBack != null && !isDesktop) ...[
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                color: AppColors.gray900,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 8),
            ],

            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(9999), // rounded-full
              child: otherUserAvatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: otherUserAvatar,
                      width: isDesktop ? 40 : 32, // w-8 sm:w-10
                      height: isDesktop ? 40 : 32, // h-8 sm:h-10
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => _buildAvatarPlaceholder(isDesktop),
                      errorWidget: (ctx, url, error) => _buildAvatarPlaceholder(isDesktop),
                    )
                  : _buildAvatarPlaceholder(isDesktop),
            ),
            const SizedBox(width: 12), // gap-3

            // Title and Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          propertyTitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gray900, // text-gray-900
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // PC Web: 계약정보 버튼을 방 제목 옆에 배치
                      if (isDesktop) ...[
                        const SizedBox(width: 8), // gap-2
                        _buildContractInfoButton(compact: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    otherUserName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600, // text-gray-600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Mobile: 계약정보 버튼을 오른쪽에 배치
            if (!isDesktop) _buildContractInfoButton(compact: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isDesktop) {
    final size = isDesktop ? 40.0 : 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: const Icon(Icons.person, size: 20, color: AppColors.neutral500),
    );
  }

  /// 계약정보 버튼
  Widget _buildContractInfoButton({required bool compact}) {
    return Material(
      color: AppColors.neutral100, // bg-gray-100
      borderRadius: BorderRadius.circular(8), // rounded-lg
      child: InkWell(
        onTap: widget.onOpenContractInfo,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.gray200, // hover:bg-gray-200
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12, // px-3
            vertical: compact ? 6 : 8, // py-1.5 : py-2
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description,
                size: 16, // w-4 h-4
                color: AppColors.gray600, // text-gray-600
              ),
              const SizedBox(width: 6), // gap-1.5
              Text(
                '계약정보',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
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
          Text(
            '계약 기간: ${_formatContractPeriod()}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.blue900, // text-blue-900
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

  /// 입력 영역
  Widget _buildInputArea() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0, // bg-white
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 1), // border-gray-200
        ),
      ),
      padding: const EdgeInsets.all(12), // p-3 sm:p-4
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 이미지 첨부 버튼
              IconButton(
                onPressed: _handleImageSelect,
                icon: const Icon(Icons.attach_file),
                color: AppColors.gray600, // text-gray-600
                padding: const EdgeInsets.all(10), // p-2.5
              ),

              // 메시지 입력 필드
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral400,
                    ),
                    filled: true,
                    fillColor: AppColors.neutral0,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, // px-3 sm:px-4
                      vertical: 12, // py-2 sm:py-3
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8), // rounded-lg
                      borderSide: const BorderSide(color: AppColors.gray300), // border-gray-300
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.blue500, width: 2), // focus:ring-2 focus:ring-blue-500
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 44, // minHeight: '44px'
                      maxHeight: 120, // maxHeight: '120px'
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8), // gap-2

              // 전송 버튼
              Material(
                color: _messageController.text.trim().isNotEmpty || _selectedImages.isNotEmpty
                    ? AppColors.blue600 // bg-blue-600
                    : AppColors.gray300, // disabled:bg-gray-300
                borderRadius: BorderRadius.circular(8), // rounded-lg
                child: InkWell(
                  onTap: _messageController.text.trim().isNotEmpty || _selectedImages.isNotEmpty
                      ? _handleSend
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10), // p-2.5
                    child: Icon(
                      Icons.send,
                      size: 20, // w-5 h-5
                      color: AppColors.neutral0, // text-white
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 이미지 미리보기
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12), // mt-3
            SizedBox(
              height: 72, // w-16 h-16 + padding
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8), // gap-2
                itemBuilder: (context, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8), // rounded-lg
                        child: Image.file(
                          _selectedImages[index],
                          width: 64, // w-16
                          height: 64, // h-16
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4, // top-1
                        right: 4, // right-1
                        child: GestureDetector(
                          onTap: () => _handleRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4), // p-1
                            decoration: BoxDecoration(
                              color: AppColors.neutral500, // bg-gray-500
                              borderRadius: BorderRadius.circular(9999), // rounded-full
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16, // w-4 h-4
                              color: AppColors.neutral0, // text-white
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
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
