import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/contract_detail.dart';
import '../../widgets/common/refund_policy_section.dart';

/// 게스트 계약 상세 — 환불 규정 섹션
class GuestContractCancellationSection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractCancellationSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final snapshot = contract.refundPolicySnapshot;

    final rules = snapshot?.rules
            .map((r) => RefundRuleItem(
                  daysBeforeMin: r.daysBeforeMin,
                  daysBeforeMax: r.daysBeforeMax,
                  refundRate: r.refundRate,
                  isSameDayCancellation: r.isSameDayCancellation,
                  description: r.description,
                ))
            .toList() ??
        [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: RefundPolicySection(rules: rules),
    );
  }
}
