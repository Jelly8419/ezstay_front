import 'package:flutter/material.dart';
import '../../models/contract.dart';
import '../../core/theme/app_colors.dart';

/// 호스트 퇴실 관련 섹션 (checkoutStatus별 UI)
class HostCheckoutSection extends StatelessWidget {
  final ContractListItem contract;
  final Future<void> Function(int contractId, int roomId) onCheckoutConfirm;
  final Future<void> Function(int contractId) onCheckoutPending;
  final Future<void> Function(ContractListItem contract) onDepositAgreement;

  const HostCheckoutSection({
    super.key,
    required this.contract,
    required this.onCheckoutConfirm,
    required this.onCheckoutPending,
    required this.onDepositAgreement,
  });

  @override
  Widget build(BuildContext context) {
    // IN_PROGRESS 또는 COMPLETED 상태에서 checkoutStatus별 UI
    if (contract.status == ContractStatus.inProgress ||
        contract.status == ContractStatus.completed) {
      final checkoutStatus = contract.checkoutStatus;

      // GUEST_COMPLETED: 게스트 퇴실 완료 → 호스트 확인/보류 버튼
      if (checkoutStatus == CheckoutStatus.guestCompleted) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // yellow-100
                  border: Border.all(color: const Color(0xFFFDE68A)), // yellow-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '게스트가 퇴실을 완료했습니다. 확인해주세요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF92400E), // yellow-800
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onCheckoutConfirm(contract.id, contract.roomId),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary600,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCheckoutPending(contract.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFF97316)), // orange-500
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '퇴실 확인 보류',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF97316), // orange-500
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // HOLD_REQUESTED: 보증금 반환 보류 신청 → 관리자 승인 대기
      if (checkoutStatus == CheckoutStatus.holdRequested) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // orange-50
              border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보증금 반환 보류를 신청했습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A3412), // orange-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '관리자 승인을 기다리고 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // HOST_CONFIRMED: 호스트 확인 완료
      if (checkoutStatus == CheckoutStatus.hostConfirmed) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // green-100
              border: Border.all(color: const Color(0xFFBBF7D0)), // green-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '퇴실 확인이 완료되었습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534), // green-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '보증금 환급 절차가 진행 중입니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // HOST_PENDING: 호스트 확인 보류 + 합의 내용 제출 버튼
      if (checkoutStatus == CheckoutStatus.hostPending) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // orange-50
                  border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 퇴실 확인이 보류되었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412), // orange-800
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '관리자가 확인 중입니다. 게스트와 합의가 되었다면 합의 내용을 제출해주세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              // ACCEPTED 상태면 버튼 비노출
              if (contract.depositAgreementStatus != 'ACCEPTED') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onDepositAgreement(contract),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFF97316), // orange-500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      contract.depositAgreementStatus == 'SUBMITTED' ? '합의 내용 수정' : '합의 내용 제출',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // AGREEMENT_SUBMITTED: 합의 내용 제출 완료
      if (checkoutStatus == CheckoutStatus.agreementSubmitted) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '합의 내용이 제출되었습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF), // blue-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '게스트 확인을 기다리고 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // AUTO_RETURNED: 보증금 전액 반환 완료
      if (checkoutStatus == CheckoutStatus.autoReturned) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // green-100
              border: Border.all(color: const Color(0xFFBBF7D0)), // green-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보증금 전액 반환 완료',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534), // green-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '합의 기한이 경과하여 보증금이 게스트에게 전액 반환되었습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // COMPLETED 상태 + HOST_CONFIRMED
    if (contract.status == ContractStatus.completed &&
        contract.checkoutStatus == CheckoutStatus.hostConfirmed) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '✅ 퇴실 확인 완료',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
