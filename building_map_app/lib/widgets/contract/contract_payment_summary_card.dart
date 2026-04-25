import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/calculated_pricing.dart';
import '../../models/promotion.dart';
import '../../utils/format_utils.dart';
import '../../utils/price_calculator.dart';

/// 결제/예상 금액 카드
/// [isMobile] true → 모바일 스타일("예상 금액"), false → 데스크톱 고정 카드("결제 금액")
/// [onSubmit], [isLoading], [canSubmit] → 데스크톱 카드 하단 버튼 (isMobile=false 일 때만 표시)
class ContractPaymentSummaryCard extends StatelessWidget {
  final CalculatedPricing pricing;
  final DateTime? checkInDate;
  final bool isMobile;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final bool canSubmit;

  const ContractPaymentSummaryCard({
    super.key,
    required this.pricing,
    required this.checkInDate,
    required this.isMobile,
    this.onSubmit,
    this.isLoading = false,
    this.canSubmit = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = pricing.discount > 0;

    // 6일 정책 체크
    final canIncludeRentalItems = PriceCalculator.canSelectRentalItems(
      checkInDate: checkInDate,
    );

    // 6일 정책 위반 시 렌탈 아이템 비용 제외
    final actualRentalItemsFee =
        canIncludeRentalItems ? pricing.rentalItemsFee : 0;
    final adjustedTotalUsageFee =
        pricing.totalUsageFee - (pricing.rentalItemsFee - actualRentalItemsFee);
    final adjustedFinalTotalAmount =
        pricing.finalTotalAmount -
        (pricing.rentalItemsFee - actualRentalItemsFee);

    if (isMobile) {
      return _buildMobileCard(
        hasDiscount: hasDiscount,
        actualRentalItemsFee: actualRentalItemsFee,
        adjustedTotalUsageFee: adjustedTotalUsageFee,
        adjustedFinalTotalAmount: adjustedFinalTotalAmount,
      );
    } else {
      return _buildDesktopCard(
        hasDiscount: hasDiscount,
        actualRentalItemsFee: actualRentalItemsFee,
        adjustedTotalUsageFee: adjustedTotalUsageFee,
        adjustedFinalTotalAmount: adjustedFinalTotalAmount,
      );
    }
  }

  /// 모바일용 카드 (컨텐츠 중간 위치)
  Widget _buildMobileCard({
    required bool hasDiscount,
    required int actualRentalItemsFee,
    required int adjustedTotalUsageFee,
    required int adjustedFinalTotalAmount,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('예상 금액', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          _buildPriceRow('임대료 (${pricing.totalDays}일)', pricing.rentalFee),
          if (hasDiscount) ...[
            const SizedBox(height: 10),
            _buildPriceRow(
              _discountLabel(pricing.discountType),
              -pricing.discount,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 10),
          _buildPriceRow('관리비 (${pricing.totalDays}일)', pricing.maintenanceFee),
          const SizedBox(height: 10),
          _buildPriceRow('청소비', pricing.cleaningFee),
          if (actualRentalItemsFee > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow('옵션 상품', actualRentalItemsFee),
          ],
          const SizedBox(height: 10),
          _buildPriceRow('계약 수수료', pricing.platformFeeOriginal),
          if (pricing.platformFeeDiscount > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow(
              '수수료 할인 (${pricing.appliedPromotions.length}건)',
              -pricing.platformFeeDiscount,
              isDiscount: true,
            ),
            ..._buildPromotionEventLines(pricing.appliedPromotions),
          ],
          const Divider(height: 32),
          _buildPriceRow(
            '실이용 금액',
            adjustedTotalUsageFee,
            isBold: true,
            fontSize: 15,
            valueColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          const Divider(height: 32),
          _buildPriceRow('보증금(퇴실 후 환급)', pricing.deposit, isGrey: true),
          const SizedBox(height: 8),
          const Divider(height: 32),
          Text(
            '* 보증금은 3자 예치기관에 보관되며, 퇴실 완료 후 2일 내 자동 환급\n됩니다.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          _buildPriceRow(
            '최종 예상 금액',
            adjustedFinalTotalAmount,
            isBold: true,
            fontSize: 18,
            valueColor: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 20),
          _buildMoveInEtiquetteCompact(),
        ],
      ),
    );
  }

  /// 데스크톱용 카드 (오른쪽 고정)
  Widget _buildDesktopCard({
    required bool hasDiscount,
    required int actualRentalItemsFee,
    required int adjustedTotalUsageFee,
    required int adjustedFinalTotalAmount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('결제 금액', style: AppTextStyles.headingSmall)],
            ),
          ),

          // 금액 상세
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPriceRow('임대료 (${pricing.totalDays}일)', pricing.rentalFee),
                if (hasDiscount) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow(
                    _discountLabel(pricing.discountType),
                    -pricing.discount,
                    isDiscount: true,
                  ),
                ],
                const SizedBox(height: 10),
                _buildPriceRow(
                  '관리비 (${pricing.totalDays}일)',
                  pricing.maintenanceFee,
                ),
                const SizedBox(height: 10),
                _buildPriceRow('청소비', pricing.cleaningFee),
                if (actualRentalItemsFee > 0) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow('옵션 상품', actualRentalItemsFee),
                ],
                const SizedBox(height: 10),
                _buildPriceRow('계약 수수료', pricing.platformFeeOriginal),
                if (pricing.platformFeeDiscount > 0) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow(
                    '수수료 할인 (${pricing.appliedPromotions.length}건)',
                    -pricing.platformFeeDiscount,
                    isDiscount: true,
                  ),
                  ..._buildPromotionEventLines(pricing.appliedPromotions),
                ],
                const Divider(height: 32),
                _buildPriceRow(
                  '실이용 금액',
                  adjustedTotalUsageFee,
                  isBold: true,
                  fontSize: 15,
                  valueColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                const Divider(height: 32),
                _buildPriceRow(
                  '보증금(퇴실 후 환급)',
                  pricing.deposit,
                  isGrey: true,
                ),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(left: 4)),
                const Divider(height: 32),
                Text(
                  '* 보증금은 3자 예치기관에 보관되며, 퇴실 완료 후 2일 내 자동 환급됩니다.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                _buildPriceRow(
                  '최종 예상 금액',
                  adjustedFinalTotalAmount,
                  isBold: true,
                  fontSize: 18,
                  valueColor: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 20),
                _buildMoveInEtiquetteCompact(),
              ],
            ),
          ),

          // 계약 요청 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  /// 계약 요청 버튼 (데스크톱 카드 하단)
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canSubmit && !isLoading ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit
              ? const Color(0xFF1D4ED8)
              : Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                canSubmit ? '계약 요청하기' : '날짜를 선택해주세요',
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 15,
                  color: canSubmit ? Colors.white : Colors.grey[500],
                ),
              ),
      ),
    );
  }

  /// 입주 매너 안내 (컴팩트)
  Widget _buildMoveInEtiquetteCompact() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '방 입주 매너',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletTextCompact('실내에서는 슬리퍼나 양말을 착용해주세요.'),
                _buildBulletTextCompact(
                  '쓰레기는 반드시 날짜 혹은 요일을 준수해서 손쉽게 버려주셔야 합니다.',
                ),
                _buildBulletTextCompact('입주 전 반려동물 동반 및 흡연은 금지입니다.'),
                _buildBulletTextCompact('입주 48시간 이내 방문은 언제든지 방문해주세요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 불릿 텍스트 (컴팩트)
  Widget _buildBulletTextCompact(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 가격 행
  Widget _buildPriceRow(
    String label,
    int price, {
    bool isBold = false,
    bool isGrey = false,
    bool isDiscount = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isGrey ? Colors.grey[600] : Colors.black87,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}${FormatUtils.formatCurrency(price.abs())}원',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color:
                valueColor ??
                (isDiscount
                    ? const Color(0xFF2563EB)
                    : (isGrey ? Colors.grey[600] : Colors.black87)),
          ),
        ),
      ],
    );
  }

  /// 적용된 프로모션 이벤트명을 수수료 할인 아래에 들여쓰기로 나열
  List<Widget> _buildPromotionEventLines(List<EligiblePromotion> promotions) {
    if (promotions.isEmpty) return const [];
    return [
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: promotions
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '· ${p.eventName}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ];
  }

  /// 할인 라벨
  String _discountLabel(String? discountType) {
    switch (discountType) {
      case 'long_term':
        return '장기계약 할인';
      case 'quick_move_in':
        return '빠른 입주 할인';
      default:
        return '할인';
    }
  }
}
