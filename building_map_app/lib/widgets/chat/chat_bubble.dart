import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_message.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';

/// 채팅 말풍선 위젯 (chat_detail_page 전용)
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
          bottomLeft:
              isMe ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight:
              isMe ? const Radius.circular(4) : const Radius.circular(20),
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
      FormatUtils.formatChatTime(message.timestamp),
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
    );
  }
}
