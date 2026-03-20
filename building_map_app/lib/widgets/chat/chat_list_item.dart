import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../utils/contract_utils.dart';
import '../contract/contract_status_badge.dart';

/// 채팅 목록 아이템 위젯
/// React ChatList.tsx의 개별 아이템을 Flutter로 완전 복제
class ChatListItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final int currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
  });

  /// 계약 기간 포맷팅
  String _formatContractPeriod() {
    if (chatRoom.contract == null) return '';
    final start = chatRoom.contract!.checkInDate;
    final end = chatRoom.contract!.checkOutDate;
    return '${start.month}/${start.day} ~ ${end.month}/${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = chatRoom.getOtherUser(currentUserId);
    final otherUserName = chatRoom.getOtherUserName(currentUserId);
    final otherUserAvatar = otherUser?.profileImageUrl ?? '';
    final propertyTitle = chatRoom.getRoomDisplayName();
    final statusString = chatRoom.contract?.status ?? 'PENDING_APPROVAL';

    return Material(
      color: isSelected ? AppColors.blue50 : AppColors.neutral0, // bg-blue-50 : bg-white
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.gray50, // hover:bg-gray-50
        child: Container(
          padding: const EdgeInsets.all(16), // p-4
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.neutral100, // border-gray-100
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with unread badge
              _buildAvatar(otherUserAvatar, otherUserName),
              const SizedBox(width: 12), // gap-3

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Property title + Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                        const SizedBox(width: 8), // pr-2
                        Text(
                          chatRoom.getFormattedLastMessageTime(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutral500, // text-gray-500
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // mb-1

                    // Row 2: Other party name + Status badge
                    Row(
                      children: [
                        Text(
                          otherUserName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray600, // text-gray-600
                          ),
                        ),
                        const SizedBox(width: 8), // gap-2
                        ContractStatusBadge(
                          status: statusString,
                          showIcon: false,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // mb-1

                    // Row 3: Contract period
                    Text(
                      _formatContractPeriod(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutral500, // text-gray-500
                      ),
                    ),
                    const SizedBox(height: 4), // mb-1

                    // Row 4: Last message
                    Text(
                      chatRoom.lastMessage ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral500, // text-gray-500
                      ),
                      maxLines: 1,
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

  /// 아바타 + 읽지 않은 메시지 배지
  Widget _buildAvatar(String avatarUrl, String name) {
    return SizedBox(
      width: 48, // w-12
      height: 48, // h-12
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(9999), // rounded-full
            child: avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ContractUtils.getFullImageUrl(avatarUrl),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _buildAvatarPlaceholder(name),
                    errorWidget: (ctx, url, error) => _buildAvatarPlaceholder(name),
                  )
                : _buildAvatarPlaceholder(name),
          ),

          // Unread count badge
          if ((chatRoom.unreadCount ?? 0) > 0)
            Positioned(
              top: -4, // -top-1
              right: -4, // -right-1
              child: Container(
                width: 20, // w-5
                height: 20, // h-5
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), // bg-red-500
                  borderRadius: BorderRadius.circular(9999), // rounded-full
                ),
                child: Center(
                  child: Text(
                    '${chatRoom.unreadCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral0, // text-white
                      fontSize: 10, // text-xs
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ),
    );
  }
}
