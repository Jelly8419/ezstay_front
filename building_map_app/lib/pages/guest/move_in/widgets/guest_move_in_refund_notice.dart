import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in_refund_policy.dart';
import '../utils/guest_move_in_format.dart';

/// 환불/반품 안내 박스 — 입주 준비 서비스 상세/결제 화면 공용.
///
/// 왕복배송비 수치는 [MoveInRefundPolicy.returnShippingFee] 단일 출처를 사용.
class GuestMoveInRefundNotice extends StatelessWidget {
  const GuestMoveInRefundNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불/반품 안내',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.sm),
          _bullet('배송 전 취소 시 전액 환불됩니다.'),
          SizedBox(height: AppSpacing.xs),
          _bullet(
            '배송이 시작된 이후 반품 요청을 접수할 수 있으며, 승인되면 '
            '왕복배송비 ${GuestMoveInFormat.formatPrice(MoveInRefundPolicy.returnShippingFee)}'
            '가 차감됩니다.',
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '· ',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
