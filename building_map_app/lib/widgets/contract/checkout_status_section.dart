import 'package:flutter/material.dart';
import '../../models/contract.dart';

/// 퇴실 상태 표시 섹션
///
/// 퇴실 진행 상태에 따라 색상과 메시지를 달리 표시합니다.
class CheckoutStatusSection extends StatelessWidget {
  final ContractListItem contract;
  final VoidCallback onShowDepositAgreementReview;

  const CheckoutStatusSection({
    super.key,
    required this.contract,
    required this.onShowDepositAgreementReview,
  });

  @override
  Widget build(BuildContext context) {
    if (contract.checkoutStatus == null ||
        contract.checkoutStatus == CheckoutStatus.notStarted) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    String title;
    String message;

    switch (contract.checkoutStatus!) {
      case CheckoutStatus.guestCompleted:
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        title = '퇴실 확인 대기중';
        message = '호스트가 퇴실 상태를 확인하고 있습니다.';
      case CheckoutStatus.hostConfirmed:
        bgColor = const Color(0xFFDCFCE7);
        borderColor = const Color(0xFFBBF7D0);
        textColor = const Color(0xFF166534);
        title = '퇴실 확인 완료';
        message = '보증금 환급 절차가 진행됩니다.';
      case CheckoutStatus.holdRequested:
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFED7AA);
        textColor = const Color(0xFF9A3412);
        title = '보증금 반환 보류 신청중';
        message = '호스트가 보증금 반환 보류를 신청했습니다. 관리자 승인을 기다리고 있습니다.';
      case CheckoutStatus.hostPending:
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFED7AA);
        textColor = const Color(0xFF9A3412);
        if (contract.depositAgreementStatus == 'ACCEPTED') {
          title = '✅ 합의 완료';
          message = '보증금 합의가 완료되었습니다. 차감 후 환급이 진행됩니다.';
          bgColor = const Color(0xFFDCFCE7);
          borderColor = const Color(0xFFBBF7D0);
          textColor = const Color(0xFF166534);
        } else if (contract.depositAgreementStatus == 'SUBMITTED') {
          title = '합의 내용 확인 요청';
          message = '호스트가 보증금 합의 내용을 제출했습니다. 확인해주세요.';
        } else {
          title = '⚠️ 퇴실 확인 보류';
          message = '호스트가 합의 내용을 작성 중입니다.';
        }
      case CheckoutStatus.agreementSubmitted:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFBFDBFE);
        textColor = const Color(0xFF1E40AF);
        title = '합의 내용 확인 요청';
        message = '호스트가 보증금 합의 내용을 제출했습니다. 확인해주세요.';
      case CheckoutStatus.autoReturned:
        bgColor = const Color(0xFFDCFCE7);
        borderColor = const Color(0xFFBBF7D0);
        textColor = const Color(0xFF166534);
        title = '보증금 전액 반환';
        message = '합의 기한이 경과하여 보증금이 전액 반환됩니다.';
      case CheckoutStatus.notStarted:
        return const SizedBox.shrink();
    }

    // 합의 데드라인 계산 (정책 7.9.1: 관리자 승인 시점 + 10일)
    String? deadlineText;
    if (contract.checkoutStatus == CheckoutStatus.hostPending ||
        contract.checkoutStatus == CheckoutStatus.agreementSubmitted) {
      DateTime deadline;
      if (contract.agreementDeadline != null) {
        deadline =
            DateTime.tryParse(contract.agreementDeadline!) ??
            contract.checkOutDate.add(const Duration(days: 10));
      } else {
        final checkoutTimeStr = contract.roomCheckoutTime ?? '11:00';
        final timeParts = checkoutTimeStr.split(':');
        final checkoutHour = int.tryParse(timeParts[0]) ?? 11;
        final checkoutMinute = timeParts.length > 1
            ? (int.tryParse(timeParts[1]) ?? 0)
            : 0;
        final checkOutDate = contract.checkOutDate;
        deadline = DateTime(
          checkOutDate.year,
          checkOutDate.month,
          checkOutDate.day,
          checkoutHour,
          checkoutMinute,
        ).add(const Duration(days: 10));
      }
      final remaining = deadline.difference(DateTime.now()).inDays;
      if (remaining > 0) {
        deadlineText =
            '합의 마감까지 D-$remaining일 (${deadline.month}/${deadline.day})';
      } else if (remaining == 0) {
        deadlineText = '합의 마감 오늘까지';
      } else {
        deadlineText = '합의 기한 경과';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  if (deadlineText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      deadlineText,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // AGREEMENT_SUBMITTED 또는 HOST_PENDING+SUBMITTED: "확인하기" 버튼
            if (contract.checkoutStatus == CheckoutStatus.agreementSubmitted ||
                (contract.checkoutStatus == CheckoutStatus.hostPending &&
                    contract.depositAgreementStatus == 'SUBMITTED')) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onShowDepositAgreementReview,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  side: BorderSide(color: textColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '확인하기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
