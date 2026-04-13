import 'package:flutter/material.dart';
import '../../constants/fee_constants.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart' show FormatUtils;

/// 게스트 보증금 합의 확인 모달
///
/// 호스트가 제출한 보증금 합의 내용을 게스트가 확인하고 동의하는 모달입니다.
///
/// **사용 시나리오:**
/// - checkoutStatus가 AGREEMENT_SUBMITTED (합의 내용 제출됨) 상태
/// - 게스트가 "확인하기" 버튼을 클릭했을 때
///
/// **프로세스:**
/// 1. 합의 내용 (차감 금액, 사유) 확인
/// 2. "동의" 클릭 시 acceptDepositAgreement API 호출
/// 3. 합의 성립 → 관리자 지급 처리 트리거
class DepositAgreementReviewModal extends StatelessWidget {
  /// 보증금 합의 정보
  final DepositAgreement agreement;

  /// 동의 버튼 콜백
  final VoidCallback onAccept;

  /// 닫기 버튼 콜백
  final VoidCallback onClose;

  const DepositAgreementReviewModal({
    super.key,
    required this.agreement,
    required this.onAccept,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final deposit = agreement.deposit ?? FeeConstants.depositAmount;
    final deductAmount = agreement.deductAmount;
    final refundAmount = agreement.refundableAmount ?? (deposit - deductAmount);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 448),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  child: const Text('🤝', style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '보증금 합의 내용',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '임대인이 제출한 합의 내용을 확인해주세요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 금액 정보 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  // 보증금 총액
                  _buildAmountRow(
                    '보증금 총액',
                    FormatUtils.formatKRW(deposit),
                    const Color(0xFF111827),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  // 차감 금액
                  _buildAmountRow(
                    '차감 금액',
                    '- ${FormatUtils.formatKRW(deductAmount)}',
                    const Color(0xFFDC2626),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  // 환급 금액
                  _buildAmountRow(
                    '환급 금액',
                    FormatUtils.formatKRW(refundAmount),
                    const Color(0xFF2563EB),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 합의 내용
            const Text(
              '합의 내용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                agreement.agreementText.isNotEmpty
                    ? agreement.agreementText
                    : '합의 내용이 없습니다.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFFD1D5DB),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '동의',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 금액 행 위젯
  Widget _buildAmountRow(
    String label,
    String amount,
    Color amountColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF4B5563),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}
