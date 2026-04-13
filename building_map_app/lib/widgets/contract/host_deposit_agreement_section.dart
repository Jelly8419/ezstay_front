import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/contract.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';

/// 보증금 합의 섹션
///
/// HOST_PENDING: 합의 제출 안내 + 데드라인 카운트다운 + 버튼
/// AGREEMENT_SUBMITTED: 제출 완료 + 합의 내용 표시
class HostDepositAgreementSection extends StatelessWidget {
  final ContractDetail contract;
  final VoidCallback onSubmitAgreement;

  const HostDepositAgreementSection({
    super.key,
    required this.contract,
    required this.onSubmitAgreement,
  });

  @override
  Widget build(BuildContext context) {
    final status = ContractStatus.fromString(contract.status);
    final checkoutStatus = CheckoutStatus.fromString(contract.checkoutStatus);

    // HOST_PENDING
    if (status == ContractStatus.inProgress &&
        checkoutStatus == CheckoutStatus.hostPending) {
      final agreement = contract.depositAgreement ?? contract.depositAgreements.firstOrNull;
      DateTime? deadline = agreement?.agreementDeadline ??
          DateTime.tryParse(contract.checkOutDate)?.add(const Duration(days: 10));

      final now = DateTime.now();
      final isExpired = deadline != null && now.isAfter(deadline);
      final daysRemaining =
          deadline != null ? deadline.difference(now).inDays : null;

      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning500.withValues(alpha: 0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '보증금 합의',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 퇴실 확인이 보류되었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '임차인과 합의가 되었다면 합의 내용을 제출해주세요.',
                      style: TextStyle(fontSize: 13, color: AppColors.warning700),
                    ),
                    if (daysRemaining != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        isExpired
                            ? '⏰ 제출 기한이 만료되었습니다. 보증금이 임차인에게 전액 반환됩니다.'
                            : '⏰ 제출 기한: $daysRemaining일 남음',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? AppColors.error600 : AppColors.warning500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (agreement?.status != 'ACCEPTED') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isExpired ? null : onSubmitAgreement,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.warning500,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.gray300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      agreement?.status == 'SUBMITTED' ? '합의 내용 수정' : '합의 내용 제출',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // AGREEMENT_SUBMITTED
    if (status == ContractStatus.inProgress &&
        checkoutStatus == CheckoutStatus.agreementSubmitted) {
      final agreement = contract.depositAgreement ?? contract.depositAgreements.firstOrNull;
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '보증금 합의',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '합의 내용이 제출되었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '임차인 확인을 기다리고 있습니다.',
                      style: TextStyle(fontSize: 13, color: AppColors.blue900),
                    ),
                  ],
                ),
              ),
              if (agreement != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  '보증금 차감 금액',
                  '${FormatUtils.formatCurrency(agreement.deductAmount)}원',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  '환급 예정 금액',
                  '${FormatUtils.formatCurrency(contract.deposit - agreement.deductAmount)}원',
                ),
                const SizedBox(height: 8),
                Text(
                  '합의 내용',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    agreement.agreementText,
                    style: TextStyle(fontSize: 14, color: AppColors.neutral700),
                  ),
                ),
                if (agreement.submittedAt != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    '제출 시각',
                    DateTime.tryParse(agreement.submittedAt!) != null
                        ? FormatUtils.formatDateTime(DateTime.parse(agreement.submittedAt!))
                        : agreement.submittedAt!,
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }
}
