import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 마이페이지 공통 다이얼로그
///
/// 성공/에러/안내 다이얼로그를 top-level 함수로 제공합니다.
/// 호스트/게스트 마이페이지 모두에서 사용 가능합니다.

void showMyPageSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('성공', style: AppTextStyles.headingSmall),
      content: Text(message, style: AppTextStyles.bodyMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            '확인',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral0,
            ),
          ),
        ),
      ],
    ),
  );
}

void showMyPageErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('오류', style: AppTextStyles.headingSmall),
      content: Text(message, style: AppTextStyles.bodyMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            '확인',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral0,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 회원 탈퇴 확인 다이얼로그
///
/// 확인 시 true, 취소 시 false를 반환합니다.
Future<bool> showWithdrawalConfirmDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('회원 탈퇴', style: AppTextStyles.headingSmall),
      content: Text(
        '정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
        style: AppTextStyles.bodyMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '취소',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            '탈퇴',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral0,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

void showMyPageInfoDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppTextStyles.headingSmall),
      content: Text(message, style: AppTextStyles.bodyMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            '확인',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral0,
            ),
          ),
        ),
      ],
    ),
  );
}
