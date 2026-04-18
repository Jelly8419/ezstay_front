import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 방 등록 완료 후 혜택 대상 여부 안내 모달
/// - isBenefitApplied: true → 혜택 모달 표시
/// - isBenefitApplied: false → 모달 미표시 (호출 측에서 분기)
class BenefitResultModal extends StatelessWidget {
  const BenefitResultModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BenefitResultModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 축하 아이콘
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: AppColors.success600,
                size: 40,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // 타이틀
            Text(
              '방 등록 혜택이 적용되었습니다 🎉',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),

            // 설명
            Text(
              '등록하신 방이 승인되면 자동으로\n첫 계약 혜택이 적용됩니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
                child: Text('확인', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
