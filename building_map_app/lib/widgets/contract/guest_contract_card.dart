import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract.dart';
import '../../widgets/contract/contract_status_helper.dart';
import '../../widgets/contract/contract_room_info_section.dart';
import '../../widgets/contract/checkout_status_section.dart';
import '../../widgets/contract/contract_options_section.dart';
import '../../widgets/modals/cancel_request_modal.dart';
import '../../widgets/contract/host_recommendation_banner.dart';

/// 게스트 계약 카드 위젯
class GuestContractCard extends StatelessWidget {
  final ContractListItem contract;

  // 옵션 관련 상태
  final bool isEditing;
  final List<RentalItem> currentOptions;
  final bool canEdit;
  final bool canAddOption;
  final bool isAfterPayment;
  final List<OptionChange> optionChanges;
  final int totalDiff;

  // 콜백
  final VoidCallback onPayment;
  final VoidCallback onCancelPending;
  final VoidCallback onShowRefundInfoAndCancel;
  final VoidCallback onShowDepositAgreementReview;
  final VoidCallback onEditButtonClick;
  final VoidCallback onShowAddOptionModal;
  final VoidCallback onShowCancelOptionModal;
  final void Function(int contractId, String itemId, int delta) onOptionQuantityChange;
  final VoidCallback onSaveOptionChanges;
  final VoidCallback onCancelOptionChanges;
  final int Function(int contractId, String itemName) getOriginalQuantity;
  final VoidCallback onGuestCheckout;
  final Future<void> Function(String reason) onCancelRequest;

  const GuestContractCard({
    super.key,
    required this.contract,
    required this.isEditing,
    required this.currentOptions,
    required this.canEdit,
    required this.canAddOption,
    required this.isAfterPayment,
    required this.optionChanges,
    required this.totalDiff,
    required this.onPayment,
    required this.onCancelPending,
    required this.onShowRefundInfoAndCancel,
    required this.onShowDepositAgreementReview,
    required this.onEditButtonClick,
    required this.onShowAddOptionModal,
    required this.onShowCancelOptionModal,
    required this.onOptionQuantityChange,
    required this.onSaveOptionChanges,
    required this.onCancelOptionChanges,
    required this.getOriginalQuantity,
    required this.onGuestCheckout,
    required this.onCancelRequest,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ContractStatusHelper.getStatusColor(contract.status);
    final statusBgColor = ContractStatusHelper.getStatusBgColor(contract.status);
    final statusMessage = ContractStatusHelper.getStatusMessage(contract.status);
    final showChatButton = [
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
      ContractStatus.completed,
    ].contains(contract.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지 + 안내 메시지 + 상세 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconTheme(
                            data: IconThemeData(color: statusColor),
                            child: ContractStatusHelper.getStatusIcon(contract.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contract.status.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (statusMessage.isNotEmpty)
                      Text(
                        statusMessage,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 13,
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final path = '/guest/contracts/${contract.id}';
                  context.go(path);
                },
                icon: const Icon(Icons.article_outlined),
                color: AppColors.primary600,
                tooltip: '상세',
              ),
            ],
          ),

          const SizedBox(height: 16),

          ContractRoomInfoSection(
            contract: contract,
            showChatButton: showChatButton,
          ),

          CheckoutStatusSection(
            contract: contract,
            onShowDepositAgreementReview: onShowDepositAgreementReview,
          ),

          // 액션 버튼: 승인대기 → 요청 취소
          if (contract.status == ContractStatus.pendingApproval) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('계약 요청 취소'),
                      content: const Text('계약 요청을 취소하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('돌아가기'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            onCancelPending();
                          },
                          child: const Text('취소하기'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                    color: Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: const Text(
                  '요청 취소',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],

          // 액션 버튼: 승인됨 → 결제하기
          if (contract.status == ContractStatus.approved) ...[
            if (contract.recommendedItems != null &&
                contract.recommendedItems!.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              HostRecommendationBanner(
                recommendedItems: contract.recommendedItems!,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPayment,
                icon: const Icon(Icons.credit_card, size: 16),
                label: Text('결제하기', style: AppTextStyles.labelMedium),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          // 액션 버튼: 결제완료 → 계약 취소
          if (contract.status == ContractStatus.paymentCompleted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onShowRefundInfoAndCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                  ),
                  child: const Text(
                    '계약 취소',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ],

          // 액션 버튼: 입주중 → 취소 요청
          if (contract.status == ContractStatus.inProgress) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => CancelRequestModal(
                        onSubmit: (reason) {
                          Navigator.of(dialogContext).pop();
                          onCancelRequest(reason);
                        },
                        onClose: () => Navigator.of(dialogContext).pop(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                  ),
                  child: const Text(
                    '취소 요청',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ],

          // 옵션 상품 섹션
          ContractOptionsSection(
            contract: contract,
            isEditing: isEditing,
            currentOptions: currentOptions,
            canEdit: canEdit,
            canAddOption: canAddOption,
            isAfterPayment: isAfterPayment,
            changes: optionChanges,
            totalDiff: totalDiff,
            onEditButtonClick: onEditButtonClick,
            onShowAddOptionModal: onShowAddOptionModal,
            onShowCancelOptionModal: onShowCancelOptionModal,
            onOptionQuantityChange: onOptionQuantityChange,
            onSaveOptionChanges: onSaveOptionChanges,
            onCancelOptionChanges: onCancelOptionChanges,
            getOriginalQuantity: getOriginalQuantity,
          ),

          // 퇴실 완료 버튼
          if (contract.status == ContractStatus.completed &&
              (contract.checkoutStatus == null ||
                  contract.checkoutStatus == CheckoutStatus.notStarted)) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onGuestCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '퇴실 완료',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
