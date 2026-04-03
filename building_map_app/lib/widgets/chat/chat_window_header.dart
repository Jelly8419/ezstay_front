import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../utils/contract_utils.dart';

/// 채팅 윈도우 헤더 — 아바타, 방 제목, 상대방 이름, 계약정보 버튼
class ChatWindowHeader extends StatelessWidget {
  final ChatRoom chatRoom;
  final int currentUserId;
  final VoidCallback onOpenContractInfo;
  final VoidCallback? onBack;
  final bool isDesktop;

  const ChatWindowHeader({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onOpenContractInfo,
    this.onBack,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = chatRoom.getOtherUser(currentUserId);
    final otherUserName = chatRoom.getOtherUserName(currentUserId);
    final otherUserAvatar = otherUser?.profileImageUrl ?? '';
    final propertyTitle = chatRoom.getRoomDisplayName();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: 16,
        ),
        child: Row(
          children: [
            if (onBack != null && !isDesktop) ...[
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                color: AppColors.gray900,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 8),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: otherUserAvatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ContractUtils.getFullImageUrl(otherUserAvatar),
                      width: isDesktop ? 40 : 32,
                      height: isDesktop ? 40 : 32,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) =>
                          _avatarPlaceholder(isDesktop),
                      errorWidget: (ctx, url, error) =>
                          _avatarPlaceholder(isDesktop),
                    )
                  : _avatarPlaceholder(isDesktop),
            ),
            const SizedBox(width: 12),
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
                            color: AppColors.gray900,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 8),
                        _ContractInfoButton(
                          onTap: onOpenContractInfo,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    otherUserName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isDesktop)
              _ContractInfoButton(
                onTap: onOpenContractInfo,
                compact: false,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _avatarPlaceholder(bool isDesktop) {
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
}

class _ContractInfoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const _ContractInfoButton({required this.onTap, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.gray200,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 6 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 16, color: AppColors.gray600),
              const SizedBox(width: 6),
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
}
