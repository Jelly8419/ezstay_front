import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import 'contract_info_basic_section.dart';
import 'contract_info_party_section.dart';
import 'contract_info_pricing_section.dart';
import 'contract_info_items_section.dart';
import '../common/refund_policy_section.dart';

/// 계약 정보 모달 위젯
class ContractInfoModal extends StatelessWidget {
  final ContractDetail contract;
  final String userMode; // 'host' | 'guest'
  final VoidCallback onClose;

  const ContractInfoModal({
    super.key,
    required this.contract,
    required this.userMode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContractInfoBasicSection(
                        contract: contract, userMode: userMode),
                    const SizedBox(height: 24),

                    ContractInfoPartySection(
                        contract: contract, userMode: userMode),
                    const SizedBox(height: 24),

                    ContractInfoPricingSection(
                        contract: contract, userMode: userMode),
                    const SizedBox(height: 24),

                    if (userMode == 'guest' &&
                        contract.rentalItems.isNotEmpty) ...[
                      ContractInfoRentalItemsSection(contract: contract),
                      const SizedBox(height: 24),
                    ],

                    if (userMode == 'guest' &&
                        contract.paymentHistory.isNotEmpty) ...[
                      ContractInfoPaymentHistorySection(contract: contract),
                      const SizedBox(height: 24),
                    ],

                    if (contract.refundPolicySnapshot != null ||
                        contract.refundPolicyDetail.isNotEmpty) ...[
                      RefundPolicySection(
                        rules: contract.refundPolicySnapshot?.rules
                                .map((r) => RefundRuleItem(
                                      daysBeforeMin: r.daysBeforeMin,
                                      daysBeforeMax: r.daysBeforeMax,
                                      refundRate: r.refundRate,
                                      isSameDayCancellation:
                                          r.isSameDayCancellation,
                                      description: r.description,
                                    ))
                                .toList() ??
                            [],
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildNoticeSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('계약 상세 정보',
              style:
                  AppTextStyles.headingMedium.copyWith(color: AppColors.gray900)),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              hoverColor: AppColors.neutral100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeSection() {
    const notices = [
      '옵션 상품(침구류, 어메니티 키트, 헤어드라이기 등)은 임대인 계약 정보에 표시되지 않습니다.',
      '보증금은 제3자 예치기관에 보관되며, 정산 금액에 포함되지 않습니다.',
      '정산은 입주 후 영업일 기준 1~2일 내에 진행됩니다.',
      '보증금 환급은 계약 종료 후 영업일 기준 1~2일 내에 진행됩니다.',
      '임차인은 계약을 위반하거나 시설을 손상한 경우 보증금에서 차감될 수 있습니다.',
      '계약 취소 시 취소 정책에 따라 위약금이 부과될 수 있습니다.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('안내사항',
            style:
                AppTextStyles.headingSmall.copyWith(color: AppColors.gray900)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCE8),
            border: Border.all(color: const Color(0xFFFDE68A)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notices
                .map((text) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $text',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF854D0E),
                          height: 1.6,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// ContractInfoModal을 표시하는 헬퍼 함수
void showContractInfoModal(
  BuildContext context, {
  required ContractDetail contract,
  required String userMode,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => ContractInfoModal(
      contract: contract,
      userMode: userMode,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
