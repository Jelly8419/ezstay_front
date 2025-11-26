import 'package:flutter/material.dart';
import '../../models/contract.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import 'package:intl/intl.dart';

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

  const RefundCalculationModal({
    super.key,
    required this.contract,
    this.isHost = false,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<RefundCalculationModal> createState() => _RefundCalculationModalState();
}

class _RefundCalculationModalState extends State<RefundCalculationModal> {
  final NumberFormat _currencyFormat = NumberFormat('#,###');

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

  /// 환불 정책 가져오기 (임시로 'moderate' 사용, 실제로는 room.refundPolicy 또는 API에서 가져와야 함)
  String _getRefundPolicy() {
    // TODO: Room 모델에 refundPolicy 필드 추가 후 widget.contract.room?.refundPolicy 사용
    return 'moderate'; // 임시 기본값
  }

  /// 환불율 계산 (0, 50, 90, 100)
  int _getRefundRate() {
    if (_isPaidToday()) {
      return 90; // 결제 당일 특별 규정
    }

    final daysLeft = _getDaysUntilCheckIn();
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

  /// 환불 정책 설명
  String _getPolicyDescription() {
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
    // 하나라도 배송 준비면 전체 배송 준비
    if (items.any((item) => item.deliveryStatus == DeliveryStatus.preparing)) {
      return DeliveryStatus.preparing;
    }

    return DeliveryStatus.pending;
  }

  /// 환불 금액 계산
  Map<String, double> _calculateRefund() {
    final refundRate = _getRefundRate();
    final isPaidTodayFlag = _isPaidToday();

    double rentalRefund = 0;
    double platformFeeRefund = 0;
    double maintenanceRefund = 0;
    double cleaningRefund = 0;
    double depositRefund = 0;

    // 전체 취소인 경우만 방 요금 환불
    if (_refundType == 'all') {
      if (isPaidTodayFlag) {
        rentalRefund = widget.contract.rentalFee * 0.9;
        platformFeeRefund = widget.contract.platformFee * 0.9;
      } else {
        rentalRefund = widget.contract.rentalFee * (refundRate / 100);
        platformFeeRefund = 0; // 결제 당일 이후에는 계약수수료 환불 안 됨
      }
      maintenanceRefund = widget.contract.maintenanceFee.toDouble();
      cleaningRefund = widget.contract.cleaningFee.toDouble();
      depositRefund = widget.contract.deposit.toDouble();
    }

    // 옵션 상품 환불 계산
    double optionsRefund = 0;
    double shippingFee = 0;
    final items = widget.contract.rentalItems ?? [];

    if (_refundType == 'all') {
      // 전체 취소 시 모든 옵션 환불 (배송 완료 제외)
      for (final item in items) {
        if (item.deliveryStatus != DeliveryStatus.delivered) {
          optionsRefund += (item.price * item.quantity).toDouble();
        }
      }

      // 배송 중인 옵션이 있으면 왕복 배송비 차감
      if (items.any((item) => item.deliveryStatus == DeliveryStatus.inTransit)) {
        shippingFee = 7000;
      }
    } else {
      // 옵션만 환불
      for (final item in items) {
        final refundQty = _selectedOptions[item.id] ?? 0;
        if (refundQty > 0 && item.deliveryStatus != DeliveryStatus.delivered) {
          optionsRefund += (item.price * refundQty).toDouble();
        }
      }

      // 배송 중인 옵션이 선택되어 있으면 배송비 차감
      final hasInTransitOptions = items.any((item) =>
          item.deliveryStatus == DeliveryStatus.inTransit &&
          (_selectedOptions[item.id] ?? 0) > 0);
      if (hasInTransitOptions) {
        shippingFee = 7000;
      }
    }

    final totalRefund = rentalRefund +
        platformFeeRefund +
        maintenanceRefund +
        cleaningRefund +
        depositRefund +
        optionsRefund -
        shippingFee;

    final penalty = widget.contract.rentalFee -
        rentalRefund +
        (widget.contract.platformFee - platformFeeRefund);

    return {
      'rentalRefund': rentalRefund,
      'platformFeeRefund': platformFeeRefund,
      'maintenanceRefund': maintenanceRefund,
      'cleaningRefund': cleaningRefund,
      'depositRefund': depositRefund,
      'optionsRefund': optionsRefund,
      'shippingFee': shippingFee,
      'totalRefund': totalRefund,
      'penalty': penalty,
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

    // 옵션 상품만 환불이고 총 환불 금액이 마이너스인 경우
    if (_refundType == 'options_only' && totalRefund < 0) {
      final additionalPayment = totalRefund.abs();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('추가 결제 필요'),
          content: Text(
            '환불 상품 금액보다 왕복 배송비가 더 비싸므로 '
            '${_currencyFormat.format(additionalPayment)}원의 추가 결제가 필요합니다.\n\n'
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
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
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
        Icon(
          Icons.error_outline,
          color: Colors.orange[700],
          size: 24,
        ),
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
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
    final policyNames = {
      'flexible': '유연',
      'moderate': '보통',
      'strict': '엄격',
    };
    final policy = _getRefundPolicy();

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
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
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                ),
                child: Text(
                  policyNames[policy] ?? '보통',
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
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '공통 환불 정책',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '• 결제 당일 취소 시, 환불 규정과 관계없이 임대료와 계약수수료 합계의 10%만 위약금으로 부과됩니다.\n'
            '• 관리비, 청소비, 보증금은 전액 환불됩니다.\n'
            '• 결제 당일 이후에는 계약수수료가 환불되지 않습니다.\n'
            '• 옵션 상품은 배송 전에는 전액 환불, 배송이 시작된 이후에는 왕복 배송비 7,000원 차감 후 환불됩니다.',
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
  Widget _buildRefundTypeSelection(int refundRate, DeliveryStatus overallDeliveryStatus) {
    final items = widget.contract.rentalItems ?? [];

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[300]!, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 유형 선택',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.sm),

          // 전체 취소 옵션
          _buildRadioOption(
            value: 'all',
            title: '계약 전체 취소',
            subtitle: refundRate == 0
                ? '환불 불가 기간입니다. 옵션 상품만 환불 가능합니다.'
                : '해당 계약에서 결제했던 모든 내용을 환불',
            subtitleColor: refundRate == 0 ? Colors.red[600] : AppColors.textSecondary,
            isDisabled: refundRate == 0,
            additionalContent: _refundType == 'all' &&
                    overallDeliveryStatus == DeliveryStatus.inTransit
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
                          Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
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
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
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
                      fontWeight: subtitleColor != null ? FontWeight.bold : null,
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
  Widget _buildOptionsRefundList(List<RentalItem> items, DeliveryStatus overallDeliveryStatus) {
    final deliveryStatusLabels = {
      DeliveryStatus.pending: {'text': '배송 전', 'color': Colors.grey[100]!, 'textColor': Colors.grey[700]!},
      DeliveryStatus.preparing: {'text': '배송 준비', 'color': Colors.blue[100]!, 'textColor': Colors.blue[700]!},
      DeliveryStatus.inTransit: {'text': '배송 중', 'color': Colors.orange[100]!, 'textColor': Colors.orange[700]!},
      DeliveryStatus.delivered: {'text': '배송 완료', 'color': Colors.green[100]!, 'textColor': Colors.green[700]!},
    };

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
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
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deliveryStatusLabels[overallDeliveryStatus]!['color'] as Color,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                  child: Text(
                    deliveryStatusLabels[overallDeliveryStatus]!['text'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: deliveryStatusLabels[overallDeliveryStatus]!['textColor'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            // 배송 안내
            if (overallDeliveryStatus == DeliveryStatus.inTransit)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
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
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 정보
          Text(
            item.name,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
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
            '${_currencyFormat.format(item.price)}원 × ${item.quantity}개 = '
            '${_currencyFormat.format(item.price * item.quantity)}원',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          // 환불 수량 조절 (배송 완료가 아닐 때만)
          if (item.deliveryStatus != DeliveryStatus.delivered) ...[
            SizedBox(height: AppSpacing.xs),
            Container(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
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
                              color: selectedQty > 0 ? Colors.grey[300]! : Colors.grey[200]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: selectedQty > 0 ? AppColors.textSecondary : Colors.grey[400],
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$selectedQty',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
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
                            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
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
  Widget _buildCurrentSituation(int daysLeft, int refundRate, bool isPaidTodayFlag) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.yellow[200]!),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
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
          if (isPaidTodayFlag)
            Text(
              '• 결제 당일이므로 특별 규정이 적용됩니다. (10% 위약금)',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.yellow[900],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          else
            Text(
              '• 환불율: $refundRate%',
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
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 예정 금액 상세',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
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
            _buildRefundRow('관리비', refund['maintenanceRefund']!, isFullRefund: true),
            _buildRefundRow('청소비', refund['cleaningRefund']!, isFullRefund: true),
            _buildRefundRow('보증금', refund['depositRefund']!, isFullRefund: true),
          ],
          if (refund['optionsRefund']! > 0)
            _buildRefundRow('옵션 상품 합계', refund['optionsRefund']!, isFullRefund: true),
          if (refund['shippingFee']! > 0)
            _buildRefundRow('왕복 배송비 (차감)', -refund['shippingFee']!, isNegative: true),

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
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${refund['totalRefund']! < 0 ? '-' : ''}'
                  '${_currencyFormat.format(refund['totalRefund']!.abs())}원',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: refund['totalRefund']! < 0 ? Colors.red[600] : AppColors.primary500,
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
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Text(
                '${isNegative ? '-' : ''}${_currencyFormat.format(amount.abs())}원',
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

  /// 위약금 섹션 (호스트)
  Widget _buildPenaltySection(Map<String, double> refund) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '결제할 위약금',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          _buildPenaltyRow(
            '임대료 위약금',
            widget.contract.rentalFee - refund['rentalRefund']!,
          ),
          _buildPenaltyRow(
            '계약수수료 위약금',
            widget.contract.platformFee - refund['platformFeeRefund']!,
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
                  '${_currencyFormat.format(refund['penalty']!)}원',
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
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
            child: Text(
              '위약금 결제 후 계약이 취소되며, 해당 기간이 다시 임대 가능 상태로 변경됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            '${_currencyFormat.format(amount)}원',
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
              backgroundColor: widget.isHost ? Colors.red[600] : AppColors.primary500,
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
