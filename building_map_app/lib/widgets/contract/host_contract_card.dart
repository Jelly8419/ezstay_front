import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../models/contract.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/contract/host_checkout_section.dart';
import '../../widgets/contract/contract_pricing_section.dart';
import '../../widgets/contract/contract_status_helper.dart';

/// 호스트 계약 카드 위젯
class HostContractCard extends StatelessWidget {
  final ContractListItem contract;

  // 액션 콜백
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancelByHost;
  final VoidCallback onRequestCheckout;
  final VoidCallback? onRequestCancellation;
  final Future<void> Function(int contractId, int roomId) onCheckoutConfirm;
  final Future<void> Function(int contractId) onCheckoutPendingTap; // 보류 신청/재신청 버튼 탭
  final Future<void> Function(ContractListItem contract) onDepositAgreement;

  const HostContractCard({
    super.key,
    required this.contract,
    required this.onApprove,
    required this.onReject,
    required this.onCancelByHost,
    required this.onRequestCheckout,
    this.onRequestCancellation,
    required this.onCheckoutConfirm,
    required this.onCheckoutPendingTap,
    required this.onDepositAgreement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 뱃지 + 안내 메시지 (수평) + 상세 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatusBadge(contract.status),
              if (contract.checkoutStatus == CheckoutStatus.holdRequested) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // orange-50
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
                  ),
                  child: Text(
                    '보증금 반환 보류 신청중',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(child: _buildStatusMessage(contract.status)),
              _buildDetailButton(context, contract),
            ],
          ),

          const SizedBox(height: 16),

          // 방 정보 (사진 + 텍스트)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 방 사진
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: contract.roomThumbnail != null
                    ? Image.network(
                        ContractUtils.getFullImageUrl(contract.roomThumbnail),
                        width: 128,
                        height: 128,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 128,
                          height: 128,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.home,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 128,
                        height: 128,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.home,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // 계약 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 방 이름
                    Text(
                      contract.roomName,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('주소', contract.roomAddress),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '계약 기간',
                      '${FormatUtils.formatDateWithDay(contract.checkInDate)} - ${FormatUtils.formatDateWithDay(contract.checkOutDate)} (${contract.totalDays}일)',
                    ),
                    const SizedBox(height: 8),
                    _buildGuestRow(context, contract),
                  ],
                ),
              ),
            ],
          ),

          // 게스트 메시지
          if (contract.guestMessage != null) ...[
            const SizedBox(height: 12),
            _buildGuestMessage(contract.guestMessage!),
          ],

          // 계약 금액 정보
          const SizedBox(height: 16),
          ContractPricingSection(contract: contract),

          // 퇴실 상태 표시 (IN_PROGRESS 또는 COMPLETED)
          HostCheckoutSection(
            contract: contract,
            onCheckoutConfirm: onCheckoutConfirm,
            onCheckoutPendingTap: onCheckoutPendingTap,
            onDepositAgreement: onDepositAgreement,
          ),

          // 버튼 영역
          if (contract.status == ContractStatus.pendingApproval) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],

          // APPROVED: 승인 철회 버튼
          if (contract.status == ContractStatus.approved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 16),
                label: Text(
                  '승인 철회',
                  style: AppTextStyles.labelLarge,
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],

          // PAYMENT_COMPLETED: 계약 취소 버튼
          if (contract.status == ContractStatus.paymentCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancelByHost,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '계약 취소',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ],

          // IN_PROGRESS + 퇴실 전(NOT_STARTED/null): 취소 요청 (항상) + 퇴실 확인 (퇴실 시간 도래 시만)
          if (contract.status == ContractStatus.inProgress &&
              (contract.checkoutStatus == null ||
               contract.checkoutStatus == CheckoutStatus.notStarted)) ...[
            const SizedBox(height: 16),
            _HostInProgressActions(
              contract: contract,
              onRequestCheckout: onRequestCheckout,
              onRequestCancellation: onRequestCancellation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ContractStatus status) {
    final config = ContractStatusHelper.getStatusBadgeConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.text,
        style: AppTextStyles.labelMedium.copyWith(
          color: config.textColor,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(ContractStatus status) {
    String message = '';
    Color color = Colors.grey;

    if (status == ContractStatus.pendingApproval) {
      message = '임차인의 계약 요청을 검토해주세요.';
      color = const Color(0xFFCA8A04);
    } else if (status == ContractStatus.approved) {
      message = '임차인이 결제하면 계약이 확정됩니다.';
      color = AppColors.primary600;
    } else if (status == ContractStatus.paymentCompleted) {
      message = '입주일에 맞춰 임차인을 맞이해주세요.';
      color = const Color(0xFF059669);
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Text(message, style: AppTextStyles.bodyMedium.copyWith(color: color));
  }

  Widget _buildDetailButton(BuildContext context, ContractListItem contract) {
    return GestureDetector(
      onTap: () {
        context.go('/host/contracts/${contract.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 16, color: AppColors.primary600),
            const SizedBox(width: 6),
            Text(
              '계약 상세',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRow(BuildContext context, ContractListItem contract) {
    final showChat = [
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
      ContractStatus.completed,
    ].contains(contract.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '임차인',
            style: AppTextStyles.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          contract.partnerDisplayName,
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
        ),
        if (showChat) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              context.go('/chat-list?contractId=${contract.id}');
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '임차인 메시지',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: onApprove,
          icon: const Icon(Icons.check, size: 16, color: Colors.white),
          label: Text(
            '승인하기',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.close, size: 16),
          label: Text(
            '거절하기',
            style: AppTextStyles.labelLarge,
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF6B7280),
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

/// IN_PROGRESS 상태에서 퇴실 전 액션 버튼 (퇴실 확인 / 취소 요청)
class _HostInProgressActions extends StatelessWidget {
  final ContractListItem contract;
  final VoidCallback onRequestCheckout;
  final VoidCallback? onRequestCancellation;

  const _HostInProgressActions({
    required this.contract,
    required this.onRequestCheckout,
    required this.onRequestCancellation,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckoutTimeReached = ContractUtils.isCheckoutTimeReached(contract);
    final isCheckoutRequested = contract.checkoutRequested == true;
    final isCancellationRequested = contract.cancellationRequested == true;

    if (isCheckoutTimeReached || isCheckoutRequested) {
      // 퇴실 시간 도래: 퇴실 확인 + 취소 요청 둘 다 표시
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onRequestCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary600,
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
          const SizedBox(width: 8),
          Expanded(
            child: _CancellationButton(
              isCancellationRequested: isCancellationRequested,
              onRequestCancellation: onRequestCancellation,
            ),
          ),
        ],
      );
    }

    // 퇴실 시간 미도래: 취소 요청만 표시
    return SizedBox(
      width: double.infinity,
      child: _CancellationButton(
        isCancellationRequested: isCancellationRequested,
        onRequestCancellation: onRequestCancellation,
      ),
    );
  }
}

class _CancellationButton extends StatelessWidget {
  final bool isCancellationRequested;
  final VoidCallback? onRequestCancellation;

  const _CancellationButton({
    required this.isCancellationRequested,
    required this.onRequestCancellation,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCancellationRequested ? AppColors.gray300 : const Color(0xFFF97316);
    return OutlinedButton(
      onPressed: isCancellationRequested ? null : onRequestCancellation,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        isCancellationRequested ? '취소 요청됨' : '취소 요청',
        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
