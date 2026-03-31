import 'package:flutter/material.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';

/// 호스트 계약 상태별 액션 버튼 섹션
///
/// - PAYMENT_COMPLETED: 계약 취소 버튼
/// - IN_PROGRESS + NOT_STARTED: 퇴실 확인(시간 도래 시) + 취소 요청 버튼
class HostContractActionButtons extends StatelessWidget {
  final ContractDetail contract;
  final VoidCallback onCancelByHost;
  final VoidCallback onRequestCheckout;
  final VoidCallback onRequestCancellation;

  const HostContractActionButtons({
    super.key,
    required this.contract,
    required this.onCancelByHost,
    required this.onRequestCheckout,
    required this.onRequestCancellation,
  });

  @override
  Widget build(BuildContext context) {
    final status = contract.status;
    final checkoutStatus = contract.checkoutStatus;

    // PAYMENT_COMPLETED: 계약 취소 버튼
    if (status == 'PAYMENT_COMPLETED') {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCancelByHost,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFDC2626)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '계약 취소',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ),
      );
    }

    // IN_PROGRESS + NOT_STARTED
    if (status == 'IN_PROGRESS' &&
        (checkoutStatus == null || checkoutStatus == 'NOT_STARTED')) {
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
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '퇴실 확인',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRequestCancellation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '취소 요청',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
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
              side: const BorderSide(color: Color(0xFFDC2626)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '취소 요청',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
