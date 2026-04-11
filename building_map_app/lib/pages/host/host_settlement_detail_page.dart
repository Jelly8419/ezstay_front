import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import '../../utils/format_utils.dart';
import '../../widgets/settlement/deposit_deduction_badge.dart';

/// 호스트 정산 상세 페이지
/// React HostSettlementDetail.tsx와 동일한 UI
class HostSettlementDetailPage extends StatefulWidget {
  final int contractId;

  const HostSettlementDetailPage({
    super.key,
    required this.contractId,
  });

  @override
  State<HostSettlementDetailPage> createState() =>
      _HostSettlementDetailPageState();
}

class _HostSettlementDetailPageState extends State<HostSettlementDetailPage> {
  final SettlementService _settlementService = SettlementService();

  SettlementDetail? _detail;
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

    try {
      final detail =
          await _settlementService.getSettlementDetail(widget.contractId);

      if (detail != null) {
        setState(() {
          _detail = detail;
        });
      } else {
        setState(() {
          _error = '정산 내역을 불러오는데 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _error = '정산 내역을 불러오는데 실패했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(56),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 896), // max-w-4xl
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      // 뒤로가기 버튼
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.chevron_left, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                      // 제목
                      Expanded(
                        child: Text(
                          '상세 내역',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // 오른쪽 여백 (모바일에서 뒤로가기 버튼과 균형)
                      SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.blue500),
      );
    }

    if (_error != null || _detail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? '정산 내역을 찾을 수 없습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: isDesktop ? 32 : 80, // pb-20 lg:pb-8
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 896), // max-w-4xl
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 정산 정보 카드
                _buildSettlementInfoCard(detail),
                SizedBox(height: 16),
                // 정산 금액 카드
                _buildSettlementAmountCard(detail),
                SizedBox(height: 16),
                // 입금 계좌 카드
                _buildBankAccountCard(detail),
                SizedBox(height: 16),
                // 안내 메시지
                _buildStatusMessage(detail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementInfoCard(SettlementDetail detail) {
    final contract = detail.contract;
    final room = detail.room;
    final guest = detail.guest;
    final settlement = detail.settlement;

    // 날짜 포맷
    final checkInDate = FormatUtils.tryParseDate(contract.checkInDate) != null
        ? FormatUtils.formatDateApi(FormatUtils.tryParseDate(contract.checkInDate)!)
        : contract.checkInDate;
    final checkOutDate = FormatUtils.tryParseDate(contract.checkOutDate) != null
        ? FormatUtils.formatDateApi(FormatUtils.tryParseDate(contract.checkOutDate)!)
        : contract.checkOutDate;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '정산 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12),
          // 정보 목록
          _buildInfoRow('정산일', settlement.settlementDate),
          SizedBox(height: 8),
          _buildInfoRow('방 이름', room.title),
          SizedBox(height: 8),
          _buildInfoRow(
            '주소',
            room.address,
            valueAlign: TextAlign.right,
          ),
          SizedBox(height: 8),
          _buildInfoRow('계약자', guest.name),
          SizedBox(height: 8),
          _buildInfoRow(
            '계약기간',
            '$checkInDate ~ $checkOutDate',
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementAmountCard(SettlementDetail detail) {
    final breakdown = detail.breakdown;
    final refund = detail.refund;
    final settlementInfo = detail.settlement;
    final isRefund = refund.hasRefund;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '정산 금액',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12),
          // 금액 내역
          if (!isRefund) ...[
            // 일반 정산
            _buildAmountRow('임대료', breakdown.rentalFee),
            SizedBox(height: 12),
            _buildAmountRow('관리비', breakdown.maintenanceFee),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '청소비',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray600,
                      ),
                    ),
                    if (breakdown.hasEzCleaningService) ...[
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EZ청소',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blue600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  FormatUtils.formatKRW(breakdown.cleaningFee),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // 이용 금액 구분선
            Container(
              padding: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.gray200),
                ),
              ),
              child: _buildAmountRow(
                '이용 금액',
                breakdown.subtotal,
                isBold: true,
              ),
            ),
            SizedBox(height: 12),
            // 수수료 구분선
            Container(
              padding: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.gray200),
                ),
              ),
              child: _buildAmountRow(
                '플랫폼 수수료 (${breakdown.platformFeeRate.toStringAsFixed(1)}%)',
                -breakdown.platformFee,
                isNegative: true,
              ),
            ),
          ] else ...[
            // 환불 정산
            // 이용 금액 섹션
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '이용 금액',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  _buildAmountRow(
                    '임대료',
                    breakdown.rentalFee,
                    labelColor: AppColors.gray600,
                  ),
                  SizedBox(height: 8),
                  _buildAmountRow(
                    '관리비',
                    breakdown.maintenanceFee,
                    labelColor: AppColors.gray600,
                  ),
                  SizedBox(height: 8),
                  _buildAmountRow(
                    '청소비',
                    breakdown.cleaningFee,
                    labelColor: AppColors.gray600,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // 환불 금액 섹션
            if (refund.refundDetails != null) ...[
              Container(
                padding: EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.gray200),
                  ),
                ),
                child: Text(
                  '환불 금액',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    _buildAmountRow(
                      '임대료 환불',
                      -refund.refundDetails!.rentalFeeRefund,
                      isNegative: true,
                    ),
                    SizedBox(height: 8),
                    _buildAmountRow(
                      '관리비 환불',
                      -refund.refundDetails!.maintenanceFeeRefund,
                      isNegative: true,
                    ),
                    SizedBox(height: 8),
                    _buildAmountRow(
                      '청소비 환불',
                      -refund.refundDetails!.cleaningFeeRefund,
                      isNegative: true,
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12),
            // 수수료
            _buildAmountRow(
              '플랫폼 수수료 (${breakdown.platformFeeRate.toStringAsFixed(1)}%)',
              -breakdown.platformFee,
              isNegative: true,
            ),
          ],
          // 보증금 차감 지급 섹션 (차감이 있을 때만)
          if (detail.depositDeduction != null)
            _buildDepositDeductionSection(detail.depositDeduction!),
          SizedBox(height: 16),
          // 최종 정산 금액
          Container(
            padding: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '총 정산 금액',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  FormatUtils.formatKRW(settlementInfo.finalAmount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(SettlementDetail detail) {
    final settlement = detail.settlement;
    final bankInfo = settlement.bankInfo;

    String accountDisplay = '미등록';
    if (bankInfo != null) {
      accountDisplay =
          '${bankInfo.bankName} ${bankInfo.accountNumber} (${bankInfo.accountHolder})';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '입금 계좌',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12),
          // 계좌 정보
          _buildInfoRow('계좌 정보', accountDisplay),
          SizedBox(height: 12),
          _buildInfoRow('입금일', settlement.settlementDate),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(SettlementDetail detail) {
    final settlement = detail.settlement;
    final isRefund = detail.refund.hasRefund;

    const pendingStatuses = ['PENDING', 'READY', 'PROCESSING', 'ON_HOLD', 'FAILED'];
    if (pendingStatuses.contains(settlement.status)) {
      // 정산 예정
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정산 예정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.info700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '퇴실 후 7일 이내에 등록하신 계좌로 정산 금액이 입금됩니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.info700,
              ),
            ),
          ],
        ),
      );
    } else if (settlement.status == 'COMPLETED' && !isRefund) {
      // 정산 완료
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정산 완료',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.success700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '정산이 완료되었습니다. 입금 계좌를 확인해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.success700,
              ),
            ),
          ],
        ),
      );
    } else if (settlement.status == 'COMPLETED' && isRefund) {
      // 취소 환불 정산 완료
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '취소 환불 정산 완료',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.info700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '게스트 취소로 인한 수수료가 정산되었습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.info700,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDepositDeductionSection(SettlementDepositDeductionDetail deduction) {
    final isCompleted = deduction.status == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '보증금 차감 지급',
                style: TextStyle(fontSize: 14, color: AppColors.gray600),
              ),
              Text(
                '+ ${FormatUtils.formatKRW(deduction.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success700,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Text(
                '지급 예정일: ${deduction.payableAfter}',
                style: TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
              SizedBox(width: 8),
              buildDepositDeductionBadge(deduction.status),
            ],
          ),
          if (isCompleted && deduction.processedAt != null) ...[
            SizedBox(height: 4),
            Text(
              '처리일: ${deduction.processedAt}',
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ],
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push(
                  '/host/settlement/deduction/${widget.contractId}'),
              child: Text(
                '차감 상세 보기 →',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.blue600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextAlign valueAlign = TextAlign.left,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: valueAlign,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(
    String label,
    int amount, {
    bool isBold = false,
    bool isNegative = false,
    Color? labelColor,
  }) {
    final displayAmount = amount.abs();
    final prefix = isNegative ? '-' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isNegative
                ? AppColors.error600
                : labelColor ?? AppColors.gray600,
          ),
        ),
        Text(
          '$prefix${FormatUtils.formatCurrency(displayAmount)}원',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: isNegative ? AppColors.error600 : null,
          ),
        ),
      ],
    );
  }

}
