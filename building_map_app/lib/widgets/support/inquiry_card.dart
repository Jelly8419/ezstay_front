import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/inquiry.dart';
import '../../constants/app_constants.dart';

/// 문의 카드 위젯
class InquiryCard extends StatelessWidget {
  final Inquiry inquiry;
  final VoidCallback onTap;

  const InquiryCard({
    super.key,
    required this.inquiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리와 상태 뱃지
              Row(
                children: [
                  // 카테고리 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(inquiry.categoryType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      inquiry.categoryType.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 상태 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inquiry.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      inquiry.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 답변 완료 아이콘
                  if (inquiry.status == InquiryStatus.answered)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 제목
              Text(
                inquiry.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 내용 미리보기
              if (inquiry.content.isNotEmpty)
                Text(
                  inquiry.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // 날짜 정보
              Row(
                children: [
                  // 작성일
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '작성: ${_formatDate(inquiry.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // 답변일 (있는 경우)
                  if (inquiry.answeredAt != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.question_answer,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '답변: ${_formatDate(inquiry.answeredAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카테고리별 색상
  Color _getCategoryColor(InquiryCategoryType categoryType) {
    switch (categoryType) {
      case InquiryCategoryType.general:
        return AppColors.info;
      case InquiryCategoryType.reservation:
        return AppColors.primary;
      case InquiryCategoryType.payment:
        return AppColors.warning;
      case InquiryCategoryType.room:
        return AppColors.accent;
      case InquiryCategoryType.account:
        return const Color(0xFF9B59B6); // Purple
      case InquiryCategoryType.other:
        return AppColors.textSecondary;
    }
  }

  /// 상태별 색상
  Color _getStatusColor(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.pending:
        return AppColors.warning;
      case InquiryStatus.answered:
        return AppColors.success;
      case InquiryStatus.closed:
        return AppColors.textSecondary;
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘 ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('yyyy.MM.dd').format(date);
    }
  }
}
