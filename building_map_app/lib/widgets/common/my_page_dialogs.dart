import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 마이페이지 공통 다이얼로그
///
/// 성공/에러/안내 다이얼로그를 top-level 함수로 제공합니다.
/// 호스트/게스트 마이페이지 모두에서 사용 가능합니다.

/// 휴대폰번호 변경 완료 다이얼로그
///
/// 변경된 번호를 강조하여 표시합니다.
void showPhoneChangedDialog(BuildContext context, String newPhoneNumber) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      contentPadding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary500,
              size: 32,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '휴대폰번호 변경 완료',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '휴대폰번호가 변경되었습니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              newPhoneNumber,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            child: Text(
              '확인',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

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
