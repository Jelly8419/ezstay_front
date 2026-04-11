import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/rental_order_service.dart';
import '../../utils/format_utils.dart';
import '../../widgets/contract/refund_row.dart';
import '../../widgets/modals/deposit_agreement_review_modal.dart';

/// 렌탈 결제 완료 다이얼로그
void showRentalPaymentSuccessDialog(
  BuildContext context, {
  required Map<String, dynamic> result,
  VoidCallback? onConfirm,
}) {
  final paidAmount = result['paidAmount'] as int?;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success500, size: 28),
          const SizedBox(width: 8),
          const Text('결제 완료'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('옵션 상품 결제가 완료되었습니다!'),
          if (paidAmount != null) ...[
            const SizedBox(height: 12),
            Text(
              '결제 금액: ${FormatUtils.formatCurrency(paidAmount)}원',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
          ),
          child: const Text('확인', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// 팝업 차단 안내 다이얼로그
void showPopupBlockedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('팝업 차단 감지'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결제창을 열기 위해 팝업 차단을 해제해주세요.'),
          SizedBox(height: 12),
          Text('해제 방법:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('• 주소창 오른쪽의 팝업 차단 아이콘 클릭'),
          Text('• "팝업 허용" 선택 후 페이지 새로고침'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

/// 게스트 퇴실 완료 확인 다이얼로그
/// 반환값: true면 퇴실 확인, false/null이면 취소
Future<bool?> showGuestCheckoutConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('퇴실 완료'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('퇴실을 완료하시겠습니까?\n호스트가 퇴실 상태를 확인한 후 보증금 환급이 진행됩니다.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '방 도어락 비밀번호를 임의 변경 후 퇴실하셨을 경우, \n퇴실 확인 전에 호스트에게 비밀번호를 안내하지 않으면 보증금 환급 절차에 불이익이 발생할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF991B1B),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('돌아가기'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
          ),
          child: const Text('퇴실 완료'),
        ),
      ],
    ),
  );
}

/// 보증금 합의 확인 모달 표시
void showDepositAgreementReviewDialog(
  BuildContext context, {
  required dynamic agreement,
  required Future<void> Function() onAccept,
  required void Function(String message, bool isSuccess) onShowMessage,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => DepositAgreementReviewModal(
      agreement: agreement,
      onAccept: () async {
        Navigator.of(dialogContext).pop();
        await onAccept();
      },
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// 환불 정보 및 취소 다이얼로그
/// [refundData]: 서버에서 받은 환불 정보
/// [onConfirmRefund]: 사유와 함께 환불 요청 실행
/// [cancelBlocked]: true이면 미결 옵션 주문이 있어 취소 버튼 비활성화
/// [pendingAdditionalOrders]: 먼저 환불해야 할 옵션 주문 목록
void showRefundInfoDialog(
  BuildContext context, {
  required Map<String, dynamic>? refundData,
  required Future<void> Function() onConfirmRefund,
  required void Function(String message, bool isSuccess) onShowMessage,
  bool cancelBlocked = false,
  List<Map<String, dynamic>> pendingAdditionalOrders = const [],
}) {

  showDialog(
    context: context,
    builder: (dialogContext) {
      final totalRefund = refundData?['finalRefundAmount'] ?? 0;
      final penalty = refundData?['penaltyAmount'] ?? 0;
      final refundRate = refundData?['rentalFeeRefundRate'] ?? 100;
      final policyName = refundData?['policyDisplayName'] ?? '';
      final ruleDesc = refundData?['applicableRuleDescription'] ?? '';
      final serverMessage = refundData?['message'] ?? '';
      final platformFeeDeducted = refundData?['platformFeeDeducted'] ?? 0;
      final isSameDay = refundData?['isSameDayCancellation'] ?? false;

      // 항목별 환불 금액
      final rentalFeeRefund = refundData?['rentalFeeRefundAmount'] ?? 0;
      final maintenanceFeeRefund =
          refundData?['maintenanceFeeRefundAmount'] ?? 0;
      final cleaningFeeRefund = refundData?['cleaningFeeRefundAmount'] ?? 0;
      final rentalItemsRefund = refundData?['rentalItemsFeeRefundAmount'] ?? 0;
      final depositRefund = refundData?['depositRefundAmount'] ?? 0;
      final guestServiceFeeRefunded =
          refundData?['guestServiceFeeRefunded'] ?? false;

      // 원금액
      final originalRentalFee = refundData?['originalRentalFee'] ?? 0;
      final originalMaintenanceFee = refundData?['originalMaintenanceFee'] ?? 0;
      final originalCleaningFee = refundData?['originalCleaningFee'] ?? 0;
      final originalRentalItemsFee = refundData?['originalRentalItemsFee'] ?? 0;
      final originalDeposit = refundData?['originalDeposit'] ?? 0;
      final originalPlatformFee = refundData?['originalPlatformFee'] ?? 0;

      return AlertDialog(
        title: const Text('계약 취소 및 환불 안내'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환불 정책 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (policyName.isNotEmpty)
                      Text(
                        '환불 정책: $policyName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    if (ruleDesc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ruleDesc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    if (isSameDay) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '결제 당일 취소 — 전액 환불',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 항목별 환불 내역
              const Text(
                '환불 내역',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              RefundRow(
                label: '임대료 ($refundRate% 환불)',
                value: '${FormatUtils.formatCurrency(rentalFeeRefund as num)}원',
                subLabel:
                    '결제액 ${FormatUtils.formatCurrency(originalRentalFee as num)}원',
              ),
              if ((originalMaintenanceFee as num) > 0)
                RefundRow(
                  label: '관리비',
                  value:
                      '${FormatUtils.formatCurrency(maintenanceFeeRefund as num)}원',
                  subLabel:
                      '결제액 ${FormatUtils.formatCurrency(originalMaintenanceFee)}원',
                ),
              if ((originalCleaningFee as num) > 0)
                RefundRow(
                  label: '청소비',
                  value:
                      '${FormatUtils.formatCurrency(cleaningFeeRefund as num)}원',
                  subLabel:
                      '결제액 ${FormatUtils.formatCurrency(originalCleaningFee)}원',
                ),
              if ((originalRentalItemsFee as num) > 0)
                RefundRow(
                  label: '옵션상품',
                  value:
                      '${FormatUtils.formatCurrency(rentalItemsRefund as num)}원',
                  subLabel:
                      '결제액 ${FormatUtils.formatCurrency(originalRentalItemsFee)}원',
                ),
              if ((originalDeposit as num) > 0)
                RefundRow(
                  label: '보증금',
                  value: '${FormatUtils.formatCurrency(depositRefund as num)}원',
                  subLabel:
                      '결제액 ${FormatUtils.formatCurrency(originalDeposit)}원',
                ),
              RefundRow(
                label: '서비스 수수료',
                value: guestServiceFeeRefunded
                    ? '${FormatUtils.formatCurrency(originalPlatformFee as num)}원'
                    : '환불 대상 제외',
                subLabel:
                    '결제액 ${FormatUtils.formatCurrency(originalPlatformFee as num)}원',
                isWarning: !guestServiceFeeRefunded,
              ),
              const Divider(height: 20),

              if ((penalty as num) > 0)
                RefundRow(
                  label: '위약금',
                  value: '-${FormatUtils.formatCurrency(penalty)}원',
                  isWarning: true,
                ),
              if ((platformFeeDeducted as num) > 0)
                RefundRow(
                  label: '차감 수수료',
                  value: '-${FormatUtils.formatCurrency(platformFeeDeducted)}원',
                  isWarning: true,
                ),
              RefundRow(
                label: '최종 환불 예정 금액',
                value: '${FormatUtils.formatCurrency(totalRefund as num)}원',
                isBold: true,
                isHighlight: true,
              ),
              const SizedBox(height: 12),

              // 서버 안내 메시지
              if (serverMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    serverMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),

              // 미결 옵션 주문 경고 (cancelBlocked == true일 때만 표시)
              if (cancelBlocked && pendingAdditionalOrders.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Color(0xFFB45309),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '취소 전 옵션 주문을 먼저 환불해주세요',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...pendingAdditionalOrders.map((order) {
                        final orderId = order['orderId'] ?? '-';
                        final status = order['status'] ?? '-';
                        final amount = order['totalAmount'] as num? ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '주문번호: $orderId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ),
                              Text(
                                '$status  ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              Text(
                                '${FormatUtils.formatCurrency(amount)}원',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('돌아가기'),
          ),
          ElevatedButton(
            onPressed: cancelBlocked
                ? null
                : () async {
                    Navigator.of(dialogContext).pop();
                    await onConfirmRefund();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: cancelBlocked
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF9CA3AF),
              disabledForegroundColor: Colors.white,
            ),
            child: const Text('환불 요청'),
          ),
        ],
      );
    },
  );
}

/// 반품 preview 확인 다이얼로그 content 위젯
Widget buildReturnPreviewConfirmContent(ReturnPreviewResponse? preview) {
  if (preview == null) {
    return const Text('선택한 상품의 반품을 신청하시겠습니까?\n\n실제 환불 금액은 관리자 처리 후 최종 확정됩니다.');
  }
  final summary = preview.summary;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '상품 금액',
            style: TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
          Text(
            '${FormatUtils.formatCurrency(summary.totalItemAmount)}원',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      if (summary.totalShippingDeduction > 0) ...[
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '수거비 차감',
              style: TextStyle(fontSize: 13, color: AppColors.error600),
            ),
            Text(
              '-${FormatUtils.formatCurrency(summary.totalShippingDeduction)}원',
              style: TextStyle(fontSize: 13, color: AppColors.error600),
            ),
          ],
        ),
      ],
      ...preview.orderPreviews
          .where((op) => op.shippingDeductionReason.isNotEmpty)
          .map(
            (op) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '※ ${op.shippingDeductionReason}',
                style: TextStyle(fontSize: 11, color: AppColors.neutral500),
              ),
            ),
          ),
      const Divider(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '예상 환불 합계',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '${FormatUtils.formatCurrency(summary.totalRefundAmount)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.blue600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '* 실제 환불 금액은 관리자 처리 후 최종 확정됩니다.',
        style: TextStyle(fontSize: 11, color: AppColors.neutral500),
      ),
    ],
  );
}

/// 공용 에러 다이얼로그
Future<void> showErrorDialog(BuildContext context, String message) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('오류'),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error600),
          child: const Text('확인', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
