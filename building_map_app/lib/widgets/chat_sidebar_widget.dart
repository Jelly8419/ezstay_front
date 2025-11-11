import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../pages/chat/chat_list_page.dart';
import '../pages/chat/chat_detail_page.dart';
import '../constants/app_constants.dart';

/// 오른쪽 고정 채팅 사이드바 위젯 (데스크톱 전용) - 오버레이 방식
class ChatSidebarWidget extends StatelessWidget {
  const ChatSidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.isOpen) {
          return const SizedBox.shrink();
        }

        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.cardRadius),
                bottomLeft: Radius.circular(AppConstants.cardRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(-4, 0),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(-8, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.cardRadius),
                bottomLeft: Radius.circular(AppConstants.cardRadius),
              ),
              child: Column(
                children: [
                  // 헤더
                  _buildHeader(context, chatProvider),
                  // 컨텐츠
                  Expanded(
                    child: chatProvider.isListView
                        ? const _ChatListWrapper()
                        : _ChatDetailWrapper(
                            chatRoomId: chatProvider.selectedChatRoom!.firebaseChatRoomId,
                            contractId: chatProvider.selectedChatRoom!.contractId,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!chatProvider.isListView)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: chatProvider.backToList,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (!chatProvider.isListView) const SizedBox(width: 12),
          Expanded(
            child: Text(
              chatProvider.isListView ? '채팅' : '채팅 상세',
              style: AppTextStyles.heading3.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: chatProvider.closeChat,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// 채팅 목록 래퍼 (스크롤 없이 ChatListPage의 내용만 표시)
class _ChatListWrapper extends StatelessWidget {
  const _ChatListWrapper();

  @override
  Widget build(BuildContext context) {
    // ChatListPage의 body 부분만 표시
    return const ChatListPage();
  }
}

/// 채팅 상세 래퍼
class _ChatDetailWrapper extends StatelessWidget {
  final String chatRoomId;
  final int contractId;

  const _ChatDetailWrapper({
    required this.chatRoomId,
    required this.contractId,
  });

  @override
  Widget build(BuildContext context) {
    return ChatDetailPage(
      chatRoomId: chatRoomId,
      contractId: contractId,
    );
  }
}
