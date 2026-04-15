import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_room.dart';
import 'chat_list_item.dart';

/// 채팅 목록 페이지 — 왼쪽 사이드바 (목록 + 필터 + 헤더)
class ChatListSidebar extends StatelessWidget {
  final bool isDesktop;
  final bool isHostMode;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final bool isLoading;
  final String? error;
  final List<ChatRoom> filteredChatRooms;
  final int currentUserId;
  final String? selectedChatId;
  final ValueChanged<String> onSelectChat;
  final VoidCallback onRetry;

  const ChatListSidebar({
    super.key,
    required this.isDesktop,
    required this.isHostMode,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.isLoading,
    required this.error,
    required this.filteredChatRooms,
    required this.currentUserId,
    required this.selectedChatId,
    required this.onSelectChat,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isDesktop) _ChatMobileHeader(),
        _ChatFilterSection(
          isHostMode: isHostMode,
          statusFilter: statusFilter,
          onStatusFilterChanged: onStatusFilterChanged,
        ),
        Expanded(child: _buildChatList(context)),
      ],
    );
  }

  Widget _buildChatList(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error500),
            const SizedBox(height: 16),
            Text('채팅방 목록을 불러올 수 없습니다',
                style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            Text(
              error!,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (filteredChatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.neutral300),
            const SizedBox(height: 16),
            Text(
              '채팅 내역이 없습니다',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.neutral500),
            ),
          ],
        ),
      );
    }

    return SelectionContainer.disabled(
      child: RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: ListView.builder(
          itemCount: filteredChatRooms.length,
          itemBuilder: (context, index) {
            final chat = filteredChatRooms[index];
            final isSelected = selectedChatId == chat.firebaseChatRoomId;
            return ChatListItem(
              chatRoom: chat,
              currentUserId: currentUserId,
              isSelected: isSelected,
              onTap: () => onSelectChat(chat.firebaseChatRoomId),
            );
          },
        ),
      ),
    );
  }
}

class _ChatMobileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '채팅',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatFilterSection extends StatelessWidget {
  final bool isHostMode;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;

  const _ChatFilterSection({
    required this.isHostMode,
    required this.statusFilter,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChatStatusDropdown(
              value: statusFilter,
              onChanged: onStatusFilterChanged,
            ),
          ),
          const SizedBox(width: 8),
          if (isHostMode) const _AutoMessageButton(),
        ],
      ),
    );
  }
}

class _ChatStatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ChatStatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more,
              size: 16, color: AppColors.neutral400),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral900),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('계약 상태')),
            DropdownMenuItem(value: 'PENDING_APPROVAL', child: Text('승인 대기')),
            DropdownMenuItem(value: 'APPROVED', child: Text('결제 대기')),
            DropdownMenuItem(
                value: 'PAYMENT_COMPLETED', child: Text('결제 완료')),
            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('임대 중')),
            DropdownMenuItem(value: 'COMPLETED', child: Text('계약 종료')),
            DropdownMenuItem(
                value: 'CANCELLED_BY_GUEST', child: Text('임차인 취소')),
            DropdownMenuItem(
                value: 'CANCELLED_BY_HOST', child: Text('임대인 취소')),
            DropdownMenuItem(value: 'REJECTED', child: Text('거절됨')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _AutoMessageButton extends StatelessWidget {
  const _AutoMessageButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/host/chat/auto-message'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blue600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.neutral0),
            const SizedBox(width: 8),
            Text(
              '자동메시지',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.neutral0),
            ),
          ],
        ),
      ),
    );
  }
}
