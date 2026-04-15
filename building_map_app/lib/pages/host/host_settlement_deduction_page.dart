import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import '../../utils/format_utils.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/settlement/deposit_deduction_badge.dart';

/// 보증금 차감 상세 페이지
/// GET /api/host/settlements/:contractId/deposit-deduction
class HostSettlementDeductionPage extends StatefulWidget {
  final int contractId;

  const HostSettlementDeductionPage({
    super.key,
    required this.contractId,
  });

  @override
  State<HostSettlementDeductionPage> createState() =>
      _HostSettlementDeductionPageState();
}

class _HostSettlementDeductionPageState
    extends State<HostSettlementDeductionPage> {
  final SettlementService _service = SettlementService();

  DepositDeductionDetailResponse? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result =
        await _service.getDepositDeductionDetail(widget.contractId);
    if (mounted) {
      setState(() {
        _detail = result;
        _isLoading = false;
        if (result == null) _error = '보증금 차감 상세를 불러오는데 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const AppGNB(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.blue500));
    }

    if (_error != null || _detail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? '알 수 없는 오류가 발생했습니다.',
              style: TextStyle(color: AppColors.error500),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetail,
              child: Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final detail = _detail!;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 페이지 제목
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '보증금 차감 상세',
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                // 계약 개요 카드
                _buildOverviewCard(detail),
                SizedBox(height: 16),
                // 지급 정보 카드
                _buildPayoutCard(detail.payout),
                SizedBox(height: 16),
                // 합의 이력 카드
                _buildHistoryCard(detail.history),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(DepositDeductionDetailResponse detail) {
    return _card(
      title: '계약 정보',
      child: Column(
        children: [
          _infoRow('계약 번호', detail.contractNumber),
          _divider(),
          _infoRow('보증금', FormatUtils.formatKRW(detail.deposit)),
          _divider(),
          _infoRow(
            '차감 금액',
            FormatUtils.formatKRW(detail.depositDeduction),
            valueColor: AppColors.warning700,
            valueFontWeight: FontWeight.w600,
          ),
          _divider(),
          _infoRow(
            '환급 보증금',
            FormatUtils.formatKRW(detail.refundableDeposit),
          ),
          _divider(),
          _infoRow('차감 사유', detail.deductionReason),
          _divider(),
          _infoRowWidget(
            '보증금 상태',
            buildDepositDeductionBadge(detail.depositStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(DeductionPayout payout) {
    final isCompleted = payout.status == 'COMPLETED';
    return _card(
      title: '지급 정보',
      child: Column(
        children: [
          _infoRow(
            '지급 금액',
            FormatUtils.formatKRW(payout.amount),
            valueFontWeight: FontWeight.w700,
          ),
          _divider(),
          _infoRow('지급 예정일', payout.payableAfter),
          _divider(),
          _infoRowWidget('지급 상태', buildDepositDeductionBadge(payout.status)),
          if (isCompleted && payout.processedAt != null) ...[
            _divider(),
            _infoRow('처리일', payout.processedAt!),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(List<DeductionAgreementHistory> history) {
    return _card(
      title: '합의 이력',
      child: history.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '합의 이력이 없습니다.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
              ),
            )
          : Column(
              children: history.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (idx > 0) _divider(),
                    _buildHistoryItem(item),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildHistoryItem(DeductionAgreementHistory item) {
    final color = _historyStatusColor(item.status);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (item.requestedAt != null)
                Text(
                  item.requestedAt!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
                ),
            ],
          ),
          if (item.holdReason.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              '사유: ${item.holdReason}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
            ),
          ],
          if (item.deductAmount != null) ...[
            SizedBox(height: 4),
            Text(
              '차감액: ${FormatUtils.formatKRW(item.deductAmount!)}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.warning700,
              ),
            ),
          ],
          if (item.agreementText != null && item.agreementText!.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              item.agreementText!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
            ),
          ],
          if (item.rejectedReason != null &&
              item.rejectedReason!.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              '거절 사유: ${item.rejectedReason!}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error500),
            ),
          ],
          // 처리 날짜 타임라인
          _buildHistoryDates(item),
        ],
      ),
    );
  }

  Widget _buildHistoryDates(DeductionAgreementHistory item) {
    final dates = <String>[];
    if (item.submittedAt != null) dates.add('제출: ${item.submittedAt!}');
    if (item.adminApprovedAt != null) {
      dates.add('관리자 승인: ${item.adminApprovedAt!}');
    }
    if (item.acceptedAt != null) dates.add('수락: ${item.acceptedAt!}');
    if (item.rejectedAt != null) dates.add('거절: ${item.rejectedAt!}');

    if (dates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 2,
        children: dates
            .map((d) => Text(
                  d,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral400,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Color _historyStatusColor(String status) {
    switch (status) {
      case 'HOLD_REQUESTED':
      case 'HOLD_APPROVED':
        return AppColors.warning600;
      case 'AGREEMENT_REQUESTED':
      case 'AGREEMENT_ACCEPTED':
        return AppColors.blue600;
      case 'HOLD_REJECTED':
      case 'AGREEMENT_REJECTED':
        return AppColors.error500;
      case 'COMPLETED':
        return AppColors.success700;
      default:
        return AppColors.neutral500;
    }
  }

  // ── 공통 레이아웃 헬퍼 ──────────────────────────────

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge,
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 16, color: AppColors.gray200);

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: valueFontWeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRowWidget(String label, Widget widget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        widget,
      ],
    );
  }
}
