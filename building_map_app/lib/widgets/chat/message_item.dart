import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';

/// 채팅 메시지 아이템 위젯
/// React MessageItem.tsx를 Flutter로 완전 복제
class MessageItem extends StatelessWidget {
  final ChatMessage message;
  final SenderRole currentUserRole;
  final String otherPartyAvatar;
  final int currentUserId;

  const MessageItem({
    super.key,
    required this.message,
    required this.currentUserRole,
    required this.otherPartyAvatar,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // System messages
    if (message.type == MessageType.system && !message.isContractMessage) {
      return _buildSystemMessage();
    }

    // Contract messages
    if (message.isContractMessage) {
      return _buildContractMessage();
    }

    // User messages
    final isOwnMessage = message.senderId == currentUserId;

    if (isOwnMessage) {
      return _buildOwnMessage(context);
    }

    return _buildOtherMessage(context);
  }

  /// 시스템 메시지 (React: bg-gray-200 text-gray-700 px-4 py-2 rounded-full text-sm)
  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
        decoration: BoxDecoration(
          color: AppColors.gray200, // bg-gray-200
          borderRadius: BorderRadius.circular(9999), // rounded-full
        ),
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md (28rem = 448px)
        child: Text(
          message.text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral700, // text-gray-700
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 계약 메시지 (React: bg-green-50 border border-green-200 text-green-800)
  Widget _buildContractMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
        decoration: BoxDecoration(
          color: AppColors.success50, // bg-green-50
          border: Border.all(color: AppColors.green100), // border-green-200
          borderRadius: BorderRadius.circular(8), // rounded-lg
        ),
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CheckCircle2 icon
            Padding(
              padding: const EdgeInsets.only(top: 2), // mt-0.5
              child: Icon(
                Icons.check_circle,
                size: 20, // w-5 h-5
                color: AppColors.green600, // text-green-600
              ),
            ),
            const SizedBox(width: 8), // gap-2
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16, // w-4 h-4
                        color: AppColors.success700, // text-green-800
                      ),
                      const SizedBox(width: 8), // gap-2
                      Text(
                        '계약 체결',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success700, // text-green-800
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4), // mb-1
                  // 내용
                  Text(
                    message.text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success700, // text-green-800
                    ),
                  ),
                  const SizedBox(height: 8), // mt-2
                  // 시간
                  Text(
                    FormatUtils.formatChatTime(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.green600, // text-green-600
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 내 메시지 (React: flex justify-end, bg-blue-600 text-white rounded-2xl rounded-br-sm)
  Widget _buildOwnMessage(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 시간 (왼쪽에 표시)
              Padding(
                padding: const EdgeInsets.only(bottom: 4), // mb-1
                child: Text(
                  FormatUtils.formatChatTime(message.timestamp),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral500, // text-gray-500
                  ),
                ),
              ),
              const SizedBox(width: 8), // gap-2
              // 메시지 버블
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7, // max-w-[70%]
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
                  decoration: BoxDecoration(
                    color: AppColors.blue600, // bg-blue-600
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), // rounded-2xl
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4), // rounded-br-sm
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 텍스트 내용 (비어있지 않을 때만)
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral0, // text-white
                          ),
                        ),
                      // 이미지 (있는 경우)
                      if (message.imageUrl != null) ...[
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                        _buildChatImage(context, message.imageUrl!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 상대방 메시지 (React: flex justify-start, bg-white border border-gray-200 rounded-2xl rounded-tl-sm)
  Widget _buildOtherMessage(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아바타
        ClipRRect(
          borderRadius: BorderRadius.circular(9999), // rounded-full
          child: CachedNetworkImage(
            imageUrl: ContractUtils.getFullImageUrl(otherPartyAvatar),
            width: 32, // w-8
            height: 32, // h-8
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(
              width: 32,
              height: 32,
              color: AppColors.neutral200,
              child: const Icon(Icons.person, size: 20),
            ),
            errorWidget: (ctx, url, error) => Container(
              width: 32,
              height: 32,
              color: AppColors.neutral200,
              child: const Icon(Icons.person, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8), // gap-2
        // 메시지 영역
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메시지 버블
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7, // max-w-[70%]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
                decoration: BoxDecoration(
                  color: AppColors.neutral0, // bg-white
                  border: Border.all(color: AppColors.gray200), // border-gray-200
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4), // rounded-tl-sm
                    topRight: Radius.circular(16), // rounded-2xl
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 텍스트 내용 (비어있지 않을 때만)
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    // 이미지 (있는 경우)
                    if (message.imageUrl != null) ...[
                      if (message.text.isNotEmpty) const SizedBox(height: 8),
                      _buildChatImage(context, message.imageUrl!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4), // mt-1
              // 시간
              Padding(
                padding: const EdgeInsets.only(left: 8), // ml-2
                child: Text(
                  FormatUtils.formatChatTime(message.timestamp),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral500, // text-gray-500
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 채팅 이미지 위젯 (웹 CORS 호환)
  Widget _buildChatImage(BuildContext context, String imageUrl) {
    final url = ContractUtils.getFullImageUrl(imageUrl);

    return GestureDetector(
      onTap: () => _showFullScreenImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 150,
                color: AppColors.neutral200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              AppLogger.e('❌ [CHAT] 이미지 로딩 실패: $error');
              AppLogger.e('❌ [CHAT] URL: $url');
              return Container(
                width: 200,
                height: 150,
                color: AppColors.neutral200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, color: AppColors.neutral500),
                    const SizedBox(height: 4),
                    Text(
                      '이미지 로딩 실패',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 이미지 전체 화면 보기
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => _FullScreenImageViewer(imageUrl: imageUrl),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// 전체 화면 이미지 뷰어
class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformController = TransformationController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _transformController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        body: Stack(
          children: [
            // 배경 탭 시 닫기
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // 이미지 (핀치 줌 + 더블탭 줌)
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // 닫기 버튼
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
