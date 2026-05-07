import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 정보성 안내 배너 (PRD 6.5.B)
///
/// "이 서비스는 임대인이 연결한 입주 준비 서비스입니다.
///  단기임대 계약 결제와는 별도로, 필요한 입주용품과 침구류만 선택하여 결제할 수 있습니다."
class GuestMoveInInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const GuestMoveInInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary100, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary700),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
