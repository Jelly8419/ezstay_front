import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 쓰기 잠금 채팅방에서 입력창 대신 표시되는 읽기 전용 배너
class ChatReadOnlyBanner extends StatelessWidget {
  const ChatReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.neutral400),
          const SizedBox(width: 8),
          Text(
            '종료된 계약의 채팅방입니다. 메시지를 보낼 수 없습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }
}
