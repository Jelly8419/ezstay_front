import 'package:flutter/material.dart';
import '../../constants/notice_texts.dart';
import '../../models/contract.dart';
import '../../models/contract_detail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/format_utils.dart';

/// 환불 계산기 모달
///
/// 계약 취소 시 환불 금액을 계산하고 표시하는 모달
/// - 전체 취소 vs 옵션만 환불 선택
/// - 환불 정책에 따른 금액 계산
/// - 배송 상태에 따른 배송비 차감
class RefundCalculationModal extends StatefulWidget {
  final Contract contract;
  final bool isHost;
  final VoidCallback onClose;
  final Function(double? additionalPayment) onConfirm;

  /// 계약 시점의 환불 정책 스냅샷 (서버에서 제공)
  /// null이면 contract.refundPolicy 문자열 기반 폴백 사용
  final RefundPolicySnapshot? refundPolicySnapshot;

  const RefundCalculationModal({
    super.key,
    required this.contract,
    this.isHost = false,
    required this.onClose,
    required this.onConfirm,
    this.refundPolicySnapshot,
  });

  @override
  State<RefundCalculationModal> createState() => _RefundCalculationModalState();
}

class _RefundCalculationModalState extends State<RefundCalculationModal> {
  // 환불 유형: 'all' (전체 취소) or 'options_only' (옵션만 환불)
  String _refundType = 'all';

  // 옵션별 환불 수량
  final Map<String, int> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    // 초기 환불 수량 설정 (전체 수량)
    for (final item in widget.contract.rentalItems ?? []) {
      _selectedOptions[item.id] = item.quantity;
    }
  }

  /// 결제 당일 여부 확인
  bool _isPaidToday() {
    final paidAt = widget.contract.paidAt;
    if (paidAt == null) return false;

    final today = DateTime.now();
    return paidAt.year == today.year &&
        paidAt.month == today.month &&
        paidAt.day == today.day;
  }

  /// 입주일까지 남은 일수
  int _getDaysUntilCheckIn() {
    final checkIn = widget.contract.checkInDate;
    final now = DateTime.now();
    final diff = checkIn.difference(now);
    return (diff.inHours / 24).ceil();
  }

  /// 환불 정책 가져오기
  String _getRefundPolicy() {
    return widget.contract.refundPolicy;
  }

  /// 호스트 환불 정책 기준 환불율 계산 (임대료에 적용)
  ///
  /// RefundPolicySnapshot이 있으면 스냅샷 기반, 없으면 refundPolicy 문자열 폴백
  int _getPolicyRefundRate() {
    final snapshot = widget.refundPolicySnapshot;
    final daysLeft = _getDaysUntilCheckIn();

    // 1순위: 서버 스냅샷 기반 환불율
    if (snapshot != null && snapshot.rules.isNotEmpty) {
      for (final rule in snapshot.rules) {
        if (rule.isSameDayCancellation) continue; // 결제 당일 규칙은 별도 처리
        final min = rule.daysBeforeMin;
        final max = rule.daysBeforeMax;
        // daysBeforeMin ~ daysBeforeMax 범위 매칭
        if (min != null && max != null) {
          if (daysLeft >= min && daysLeft <= max) return rule.refundRate;
        } else if (min != null) {
          if (daysLeft >= min) return rule.refundRate;
        } else if (max != null) {
          if (daysLeft <= max) return rule.refundRate;
        }
      }
      return 0;
    }

    // 2순위: refundPolicy 문자열 기반 폴백
    final policy = _getRefundPolicy();
    switch (policy) {
      case 'flexible':
        if (daysLeft >= 7) return 100;
        if (daysLeft >= 3) return 50;
        return 0;
      case 'moderate':
        if (daysLeft >= 14) return 100;
        if (daysLeft >= 7) return 50;
        return 0;
      case 'strict':
        if (daysLeft >= 30) return 100;
        if (daysLeft >= 14) return 50;
        return 0;
      default:
        return 0;
    }
  }

  /// 무료 취소 기간(환불율 100%) 여부
  bool _isInFreeCancellationPeriod() {
    return _getPolicyRefundRate() == 100;
  }

  /// 최종 환불율 계산 (결제 당일 상위 정책 반영)
  ///
  /// 정책 우선순위:
  /// 1. 결제 당일 + 무료 취소 기간 → 100% 전액 환불
  /// 2. 결제 당일 + 무료 취소 기간 아님 → 90% (임대료 10% 위약금)
  /// 3. 결제 당일 아님 → 호스트 환불 정책대로
  int _getRefundRate() {
    if (_isPaidToday()) {
      if (_isInFreeCancellationPeriod()) {
        return 100; // 무료 취소 기간이면 100% 전액 환불 우선
      }
      return 90; // 무료 취소 기간 아니면 결제 당일 특별 규정 (10% 위약금)
    }
    return _getPolicyRefundRate();
  }

  /// 환불 정책 설명
  String _getPolicyDescription() {
    // 스냅샷이 있으면 스냅샷의 rules에서 설명 생성
    final snapshot = widget.refundPolicySnapshot;
    if (snapshot != null && snapshot.rules.isNotEmpty) {
      final descriptions = snapshot.rules
          .where((r) => !r.isSameDayCancellation && r.description.isNotEmpty)
          .map((r) => r.description)
          .toList();
      if (descriptions.isNotEmpty) {
        return descriptions.join(' / ');
      }
    }

    // 폴백: refundPolicy 문자열 기반
    final policy = _getRefundPolicy();
    switch (policy) {
      case 'flexible':
        return '입주 7일 전: 100% / 3일 전: 50% / 3일 미만: 환불 불가';
      case 'moderate':
        return '입주 14일 전: 100% / 7일 전: 50% / 7일 미만: 환불 불가';
      case 'strict':
        return '입주 30일 전: 100% / 14일 전: 50% / 14일 미만: 환불 불가';
      default:
        return '';
    }
  }

  /// 전체 배송 상태 확인
  DeliveryStatus _getOverallDeliveryStatus() {
    final items = widget.contract.rentalItems ?? [];
    if (items.isEmpty) return DeliveryStatus.pending;

    // 하나라도 배송 완료면 전체 배송 완료
    if (items.any((item) => item.deliveryStatus == DeliveryStatus.delivered)) {
      return DeliveryStatus.delivered;
    }
    // 하나라도 배송 중이면 전체 배송 중
    if (items.any((item) => item.deliveryStatus == DeliveryStatus.inTransit)) {
      return DeliveryStatus.inTransit;
    }
    // preparing 값은 DB에 없으므로 제거

    return DeliveryStatus.pending;
  }

  /// 환불 금액 계산
  Map<String, double> _calculateRefund() {
    if (widget.isHost) {
      return _calculateHostFaultRefund();
    }
    return _calculateGuestFaultRefund();
  }

  /// 게스트 귀책 취소 환불 계산
  ///
  /// 정책 기준:
  /// - 보증금: 100% 환불
  /// - 관리비: 100% 환불
  /// - 청소비: 100% 환불
  /// - 임대료: 환불율 적용
  /// - 게스트 서비스 수수료:
  ///   - 무료 취소 기간 (refundRate == 100): 전액 환불
  ///   - 그 외 (결제 당일 포함): 환불 안 됨
  /// - 위약금 = 임대료에만 부과 (수수료는 위약금 대상 아님)
  Map<String, double> _calculateGuestFaultRefund() {
    final refundRate = _getRefundRate();

    double rentalRefund = 0;
    double platformFeeRefund = 0;
    double maintenanceRefund = 0;
    double cleaningRefund = 0;
    double depositRefund = 0;

    // 전체 취소인 경우만 방 요금 환불
    if (_refundType == 'all') {
      // 임대료 환불 = 임대료 × (환불율 / 100)
      rentalRefund = (widget.contract.rentalFee * (refundRate / 100)).floorToDouble();

      // 게스트 서비스 수수료: 무료 취소 기간(100%)에만 전액 환불, 그 외 0원
      if (refundRate == 100) {
        platformFeeRefund = widget.contract.platformFee.toDouble();
      } else {
        platformFeeRefund = 0;
      }

      // 관리비, 청소비, 보증금은 항상 전액 환불
      maintenanceRefund = widget.contract.maintenanceFee.toDouble();
      cleaningRefund = widget.contract.cleaningFee.toDouble();
      depositRefund = widget.contract.deposit.toDouble();
    }

    // 옵션 상품 환불 계산
    final optionsResult = _calculateOptionsRefund();

    final totalRefund =
        rentalRefund +
        platformFeeRefund +
        maintenanceRefund +
        cleaningRefund +
        depositRefund +
        optionsResult['optionsRefund']! -
        optionsResult['shippingFee']!;

    // 위약금 = 임대료 미환불분만 (수수료는 위약금 대상 아님)
    final penalty = (widget.contract.rentalFee - rentalRefund).toDouble();

    return {
      'rentalRefund': rentalRefund,
      'platformFeeRefund': platformFeeRefund,
      'maintenanceRefund': maintenanceRefund,
      'cleaningRefund': cleaningRefund,
      'depositRefund': depositRefund,
      'optionsRefund': optionsResult['optionsRefund']!,
      'shippingFee': optionsResult['shippingFee']!,
      'totalRefund': totalRefund,
      'penalty': penalty,
    };
  }

  /// 호스트 귀책 취소 환불 계산
  ///
  /// 정책:
  /// - 게스트: 결제 금액 100% 전액 환불 (수수료 포함)
  /// - 호스트 위약금:
  ///   - 무료 취소 기한 내: 0원
  ///   - 위약금 기간 내: 임대료 × 비환불율 + 게스트 수수료 보전
  Map<String, double> _calculateHostFaultRefund() {
    final refundRate = _getRefundRate();

    // 게스트는 전액 환불
    final guestTotalRefund = widget.contract.finalTotalAmount.toDouble();

    double rentalPenalty = 0;
    double guestFeeCompensation = 0;

    // 무료 취소 기한(100%) 내에는 호스트 위약금 0원
    if (refundRate < 100) {
      // 임대료 비환불분 (게스트 귀책이었다면 환불 안 됐을 금액)
      rentalPenalty = (widget.contract.rentalFee * ((100 - refundRate) / 100)).floorToDouble();
      // 게스트 수수료 보전 (호스트 귀책이므로 게스트 수수료를 호스트가 보전)
      guestFeeCompensation = widget.contract.platformFee.toDouble();
    }

    final hostPenalty = rentalPenalty + guestFeeCompensation;

    return {
      'guestTotalRefund': guestTotalRefund,
      'rentalPenalty': rentalPenalty,
      'guestFeeCompensation': guestFeeCompensation,
      'hostPenalty': hostPenalty,
      // 기존 키 호환 (build에서 사용)
      'totalRefund': guestTotalRefund,
      'penalty': hostPenalty,
    };
  }

  /// 옵션 환불 가능 여부 (7일 이내 체크)
  ///
  /// 정책: 임대 시작 후 7일 이내에만 옵션 환불 요청 가능
  bool _isOptionRefundAvailable() {
    final checkIn = widget.contract.checkInDate;
    final now = DateTime.now();

    // 입주 전이면 항상 환불 가능
    if (now.isBefore(checkIn)) return true;

    // 입주 후 7일 이내인지 확인
    final daysSinceCheckIn = now.difference(checkIn).inDays;
    return daysSinceCheckIn <= 7;
  }

  /// 옵션 상품 환불 계산 (공통)
  ///
  /// 정책:
  /// - 배송 전 (pending): 전액 환불
  /// - 배송 중 (inTransit): 전액 환불 + 배송비 차감
  /// - 배송 완료 (delivered): 환불 가능 + 배송비 차감
  /// - 임대 시작 후 7일 이내에만 환불 요청 가능
  Map<String, double> _calculateOptionsRefund() {
    double optionsRefund = 0;
    double shippingFee = 0;
    final items = widget.contract.rentalItems ?? [];

    // 7일 기한 초과 시 옵션 환불 불가
    if (!_isOptionRefundAvailable()) {
      return {'optionsRefund': 0, 'shippingFee': 0};
    }

    if (_refundType == 'all') {
      // 모든 옵션 상품 환불 (배송 상태 무관하게 환불 가능)
      for (final item in items) {
        optionsRefund += (item.price * item.quantity).toDouble();
      }
      // 배송 시작 이후(배송 중 또는 배송 완료) 상품이 있으면 배송비 차감
      if (items.any(
        (item) =>
            item.deliveryStatus == DeliveryStatus.inTransit ||
            item.deliveryStatus == DeliveryStatus.delivered,
      )) {
        shippingFee = 7000;
      }
    } else {
      for (final item in items) {
        final refundQty = _selectedOptions[item.id] ?? 0;
        if (refundQty > 0) {
          optionsRefund += (item.price * refundQty).toDouble();
        }
      }
      // 환불 대상 중 배송 시작 이후 상품이 있으면 배송비 차감
      final hasShippedOptions = items.any(
        (item) =>
            (item.deliveryStatus == DeliveryStatus.inTransit ||
                item.deliveryStatus == DeliveryStatus.delivered) &&
            (_selectedOptions[item.id] ?? 0) > 0,
      );
      if (hasShippedOptions) {
        shippingFee = 7000;
      }
    }

    return {
      'optionsRefund': optionsRefund,
      'shippingFee': shippingFee,
    };
  }

  /// 옵션 수량 변경
  void _handleOptionQuantityChange(String itemId, int delta) {
    final item = widget.contract.rentalItems?.firstWhere(
      (item) => item.id == itemId,
      orElse: () => RentalItem(
        id: '',
        name: '',
        price: 0,
        quantity: 0,
        deliveryStatus: DeliveryStatus.pending,
      ),
    );
    if (item == null || item.id.isEmpty) return;

    setState(() {
      final current = _selectedOptions[itemId] ?? 0;
      final newValue = (current + delta).clamp(0, item.quantity);
      _selectedOptions[itemId] = newValue;
    });
  }

  /// 확인 버튼 클릭
  void _handleConfirmClick() {
    final refund = _calculateRefund();
    final totalRefund = refund['totalRefund'] ?? 0;

    // 호스트 귀책 취소: 위약금 결제 금액을 additionalPayment로 전달
    if (widget.isHost) {
      final hostPenalty = refund['hostPenalty'] ?? refund['penalty'] ?? 0;
      if (hostPenalty > 0) {
        widget.onConfirm(hostPenalty);
      } else {
        // 무료 취소 기간이면 위약금 0원 → 바로 취소
        widget.onConfirm(null);
      }
      return;
    }

    // 옵션 상품만 환불이고 총 환불 금액이 마이너스인 경우
    if (_refundType == 'options_only' && totalRefund < 0) {
      final additionalPayment = totalRefund.abs();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('추가 결제 필요'),
          content: Text(
            '환불 상품 금액보다 왕복 배송비가 더 비싸므로 '
            '${FormatUtils.formatCurrency(additionalPayment)}원의 추가 결제가 필요합니다.\n\n'
            '결제를 진행하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onConfirm(additionalPayment);
              },
              child: const Text('결제하기'),
            ),
          ],
        ),
      );
      return;
    }

    widget.onConfirm(null);
  }

  @override
  Widget build(BuildContext context) {
    final refund = _calculateRefund();
    final refundRate = _getRefundRate();
    final daysLeft = _getDaysUntilCheckIn();
    final isPaidTodayFlag = _isPaidToday();
    final overallDeliveryStatus = _getOverallDeliveryStatus();
    final items = widget.contract.rentalItems ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl (672px)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.modal,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더
                _buildHeader(),
                SizedBox(height: AppSpacing.md),

                // 환불 정책 정보
                _buildRefundPolicyInfo(),
                SizedBox(height: AppSpacing.md),

                // 공통 정책
                _buildCommonPolicy(),
                SizedBox(height: AppSpacing.md),

                // 환불 유형 선택 (게스트만, 옵션이 있을 때만)
                if (!widget.isHost && items.isNotEmpty) ...[
                  _buildRefundTypeSelection(refundRate, overallDeliveryStatus),
                  SizedBox(height: AppSpacing.md),
                ],

                // 현재 상황
                _buildCurrentSituation(daysLeft, refundRate, isPaidTodayFlag),
                SizedBox(height: AppSpacing.md),

                // 환불 금액 상세 (게스트) 또는 위약금 (호스트)
                if (widget.isHost)
                  _buildPenaltySection(refund)
                else
                  _buildRefundDetailSection(refund),
                SizedBox(height: AppSpacing.md),

                // 버튼
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: Colors.orange[700], size: 24),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isHost ? '계약 취소 위약금' : '계약 취소 환불 금액',
                style: AppTextStyles.headingMedium,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                widget.contract.room?.name ?? '방 정보 없음',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  /// 환불 정책 정보
  Widget _buildRefundPolicyInfo() {
    final policyNames = {'flexible': '유연', 'moderate': '보통', 'strict': '엄격'};
    final policy = _getRefundPolicy();
    final snapshot = widget.refundPolicySnapshot;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '이 방의 환불 정책',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  snapshot?.displayName ?? policyNames[policy] ?? '보통',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            _getPolicyDescription(),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.blue[800],
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 공통 정책
  Widget _buildCommonPolicy() {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '공통 환불 정책',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            NoticeTexts.commonRefundPolicyBullets,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 환불 유형 선택
  Widget _buildRefundTypeSelection(
    int refundRate,
    DeliveryStatus overallDeliveryStatus,
  ) {
    final items = widget.contract.rentalItems ?? [];

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[300]!, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 유형 선택',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // 전체 취소 옵션
          _buildRadioOption(
            value: 'all',
            title: '계약 전체 취소',
            subtitle: refundRate == 0
                ? '환불 불가 기간입니다. 옵션 상품만 환불 가능합니다.'
                : '해당 계약에서 결제했던 모든 내용을 환불',
            subtitleColor: refundRate == 0
                ? Colors.red[600]
                : AppColors.textSecondary,
            isDisabled: refundRate == 0,
            additionalContent:
                _refundType == 'all' &&
                    (overallDeliveryStatus == DeliveryStatus.inTransit ||
                        overallDeliveryStatus == DeliveryStatus.delivered)
                ? Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              '배송이 시작된 이후 옵션 환불 시 왕복 배송비 7,000원이 차감됩니다.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSpacing.sm),

          // 옵션만 환불
          _buildRadioOption(
            value: 'options_only',
            title: '옵션 상품 환불',
            subtitle: '방 계약은 유지',
            additionalContent: _refundType == 'options_only'
                ? _buildOptionsRefundList(items, overallDeliveryStatus)
                : null,
          ),
        ],
      ),
    );
  }

  /// 라디오 옵션
  Widget _buildRadioOption({
    required String value,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    bool isDisabled = false,
    Widget? additionalContent,
  }) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _refundType = value;
              });
            },
      child: Container(
        padding: AppSpacing.paddingSm,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled ? AppColors.border : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isDisabled ? AppColors.surface : Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: _refundType,
              onChanged: isDisabled
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _refundType = val;
                        });
                      }
                    },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: subtitleColor ?? AppColors.textSecondary,
                      fontWeight: subtitleColor != null
                          ? FontWeight.bold
                          : null,
                      fontSize: 12,
                    ),
                  ),
                  if (additionalContent != null) additionalContent,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 옵션 환불 리스트
  Widget _buildOptionsRefundList(
    List<RentalItem> items,
    DeliveryStatus overallDeliveryStatus,
  ) {
    final deliveryStatusLabels = {
      DeliveryStatus.pending: {
        'text': '배송 전',
        'color': Colors.grey[100]!,
        'textColor': Colors.grey[700]!,
      },
      DeliveryStatus.inTransit: {
        'text': '배송 중',
        'color': Colors.orange[100]!,
        'textColor': Colors.orange[700]!,
      },
      DeliveryStatus.delivered: {
        'text': '배송 완료',
        'color': Colors.green[100]!,
        'textColor': Colors.green[700]!,
      },
    };

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '옵션 상품',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        deliveryStatusLabels[overallDeliveryStatus]!['color']
                            as Color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    deliveryStatusLabels[overallDeliveryStatus]!['text']
                        as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          deliveryStatusLabels[overallDeliveryStatus]!['textColor']
                              as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            // 7일 기한 초과 안내
            if (!_isOptionRefundAvailable())
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.red[600]),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '임대 시작 후 7일이 경과하여 옵션 환불이 불가합니다.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 배송 안내 (배송 시작 이후 상품이 있을 때)
            if (_isOptionRefundAvailable() &&
                (overallDeliveryStatus == DeliveryStatus.inTransit ||
                    overallDeliveryStatus == DeliveryStatus.delivered))
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '배송이 시작된 이후 옵션 환불 시 왕복 배송비 7,000원이 차감됩니다.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 옵션 아이템 리스트
            ...items.map((item) => _buildOptionRefundItem(item)),
          ],
        ),
      ),
    );
  }

  /// 옵션 환불 아이템
  Widget _buildOptionRefundItem(RentalItem item) {
    final selectedQty = _selectedOptions[item.id] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs),
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 정보
          Text(
            item.name,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs / 2),
            Text(
              item.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xs / 2),
          Text(
            '${FormatUtils.formatCurrency(item.price)}원 × ${item.quantity}개 = '
            '${FormatUtils.formatCurrency(item.price * item.quantity)}원',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          // 환불 수량 조절 (7일 이내이면 배송 상태 무관하게 환불 가능)
          if (_isOptionRefundAvailable()) ...[
            SizedBox(height: AppSpacing.xs),
            Container(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '환불 수량',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      // 감소 버튼
                      InkWell(
                        onTap: selectedQty > 0
                            ? () => _handleOptionQuantityChange(item.id, -1)
                            : null,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedQty > 0
                                  ? Colors.grey[300]!
                                  : Colors.grey[200]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: selectedQty > 0
                                ? AppColors.textSecondary
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$selectedQty',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      // 증가 버튼
                      InkWell(
                        onTap: selectedQty < item.quantity
                            ? () => _handleOptionQuantityChange(item.id, 1)
                            : null,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedQty < item.quantity
                                  ? AppColors.primary500
                                  : Colors.grey[200]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: selectedQty < item.quantity
                                ? AppColors.primary500
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 현재 상황
  Widget _buildCurrentSituation(
    int daysLeft,
    int refundRate,
    bool isPaidTodayFlag,
  ) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.yellow[200]!),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 상황',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.yellow[900],
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '• 입주일까지 $daysLeft일 남았습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.yellow[800],
              fontSize: 12,
            ),
          ),
          if (isPaidTodayFlag && refundRate == 100)
            Text(
              '• 결제 당일이며 무료 취소 기간이므로 전액 환불됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          else if (isPaidTodayFlag)
            Text(
              '• 결제 당일이므로 특별 규정이 적용됩니다. (임대료 10% 위약금, 수수료 미환불)',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.yellow[900],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          else if (refundRate == 100)
            Text(
              '• 무료 취소 기간입니다. (수수료 포함 전액 환불)',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          else
            Text(
              '• 환불율: $refundRate% (수수료 미환불)',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.yellow[800],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  /// 환불 금액 상세 (게스트)
  Widget _buildRefundDetailSection(Map<String, double> refund) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 예정 금액 상세',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // 항목별 환불 금액
          if (_refundType == 'all') ...[
            _buildRefundRow(
              '임대료',
              refund['rentalRefund']!,
              originalAmount: widget.contract.rentalFee.toDouble(),
            ),
            _buildRefundRow(
              '계약수수료',
              refund['platformFeeRefund']!,
              originalAmount: widget.contract.platformFee.toDouble(),
            ),
            _buildRefundRow(
              '관리비',
              refund['maintenanceRefund']!,
              isFullRefund: true,
            ),
            _buildRefundRow(
              '청소비',
              refund['cleaningRefund']!,
              isFullRefund: true,
            ),
            _buildRefundRow(
              '보증금',
              refund['depositRefund']!,
              isFullRefund: true,
            ),
          ],
          if (refund['optionsRefund']! > 0)
            _buildRefundRow(
              '옵션 상품 합계',
              refund['optionsRefund']!,
              isFullRefund: true,
            ),
          if (refund['shippingFee']! > 0)
            _buildRefundRow(
              '왕복 배송비 (차감)',
              -refund['shippingFee']!,
              isNegative: true,
            ),

          // 총 환불 금액
          Container(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            margin: EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 환불 금액',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${refund['totalRefund']! < 0 ? '-' : ''}'
                  '${FormatUtils.formatCurrency(refund['totalRefund']!.abs())}원',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: refund['totalRefund']! < 0
                        ? Colors.red[600]
                        : AppColors.primary500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 환불 항목 행
  Widget _buildRefundRow(
    String label,
    double amount, {
    double? originalAmount,
    bool isFullRefund = false,
    bool isNegative = false,
  }) {
    final refundRate = _getRefundRate();
    final isPartial = originalAmount != null && amount < originalAmount;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              Text(
                '${isNegative ? '-' : ''}${FormatUtils.formatCurrency(amount.abs())}원',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isPartial || isNegative
                      ? Colors.red[600]
                      : isFullRefund
                      ? Colors.black
                      : AppColors.textPrimary,
                  fontWeight: isFullRefund ? FontWeight.bold : null,
                ),
              ),
              if (isPartial)
                Text(
                  ' ($refundRate%)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 위약금 섹션 (호스트 귀책 취소)
  ///
  /// 정책:
  /// - 게스트: 결제 금액 100% 전액 환불
  /// - 호스트 결제: 임대료 위약금(비환불분) + 게스트 수수료 보전
  Widget _buildPenaltySection(Map<String, double> refund) {
    final rentalPenalty = refund['rentalPenalty'] ?? 0;
    final guestFeeCompensation = refund['guestFeeCompensation'] ?? 0;
    final hostPenalty = refund['hostPenalty'] ?? refund['penalty'] ?? 0;
    final guestTotalRefund = refund['guestTotalRefund'] ??
        widget.contract.finalTotalAmount.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 게스트 환불 안내
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '게스트 환불 금액',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '결제 금액 전액 환불',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    '${FormatUtils.formatCurrency(guestTotalRefund)}원',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '호스트 귀책 취소이므로 게스트에게 수수료 포함 전액 환불됩니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.green[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppSpacing.md),

        // 호스트 위약금
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[200]!, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '호스트 결제할 위약금',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
              SizedBox(height: AppSpacing.sm),

              _buildPenaltyRow(
                '임대료 위약금',
                rentalPenalty,
              ),
              _buildPenaltyRow(
                '게스트 수수료 보전',
                guestFeeCompensation,
              ),

              Container(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                margin: EdgeInsets.only(top: AppSpacing.xs),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.red[300]!, width: 2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 위약금',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatCurrency(hostPenalty)}원',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.sm),
              Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '위약금 결제 후 계약이 취소되며, 게스트에게 결제 금액이 전액 환불됩니다. '
                  '해당 기간은 다시 임대 가능 상태로 변경됩니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 위약금 항목 행
  Widget _buildPenaltyRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${FormatUtils.formatCurrency(amount)}원',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.red[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 버튼
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: AppColors.border, width: 2),
            ),
            child: Text(
              '닫기',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleConfirmClick,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isHost
                  ? Colors.red[600]
                  : AppColors.primary500,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              widget.isHost
                  ? '위약금 결제하고 취소'
                  : _refundType == 'all'
                  ? '계약 취소'
                  : '옵션 환불 요청',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
