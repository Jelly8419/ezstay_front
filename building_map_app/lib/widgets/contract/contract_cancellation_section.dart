import 'package:flutter/material.dart';
import '../../models/refund_policy.dart';
import '../../widgets/common/refund_policy_section.dart';

/// 계약 시작 페이지 — 환불 규정 섹션
class ContractCancellationSection extends StatelessWidget {
  final String refundPolicy;
  final RefundPolicy? refundPolicyData;
  final bool isLoadingPolicy;

  const ContractCancellationSection({
    super.key,
    required this.refundPolicy,
    required this.refundPolicyData,
    required this.isLoadingPolicy,
  });

  @override
  Widget build(BuildContext context) {
    final rules = refundPolicyData?.rules
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RefundPolicySection(
        rules: rules,
        isLoading: isLoadingPolicy,
      ),
    );
  }
}
