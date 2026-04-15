import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';

/// 호스트 계약 상태별 액션 버튼 섹션
///
/// - APPROVED: 승인 철회 버튼
/// - PAYMENT_COMPLETED: 없음 (계약 취소는 계약관리 페이지에서 처리)
/// - IN_PROGRESS + NOT_STARTED: 퇴실 확인(시간 도래 시) + 취소 요청 버튼
class HostContractActionButtons extends StatelessWidget {
  final ContractDetail contract;
  final VoidCallback onRequestCheckout;
  final VoidCallback onRequestCancellation;
  final VoidCallback? onReject;

  const HostContractActionButtons({
    super.key,
    required this.contract,
    required this.onRequestCheckout,
    required this.onRequestCancellation,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = ContractStatus.fromString(contract.status);
    final checkoutStatus = CheckoutStatus.fromString(contract.checkoutStatus);

    // APPROVED: 승인 철회 버튼
    if (status == ContractStatus.approved) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 16),
            label: Text(
              '승인 철회',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    // IN_PROGRESS + NOT_STARTED (또는 checkoutStatus 없음)
    if (status == ContractStatus.inProgress &&
        (checkoutStatus == null || checkoutStatus == CheckoutStatus.notStarted)) {
      final isCheckoutTimeReached =
          ContractUtils.isCheckoutTimeReachedFromDetail(contract);
      final isCheckoutRequested = contract.checkoutRequestedAt != null;
      final shouldShowCheckoutButton = isCheckoutTimeReached || isCheckoutRequested;

      if (shouldShowCheckoutButton) {
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onRequestCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '퇴실 확인',
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRequestCancellation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.error600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '취소 요청',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // 퇴실 시간 미도래 & 퇴실 요청 없음: 취소 요청만 표시
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onRequestCancellation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.error600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '취소 요청',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error600,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
