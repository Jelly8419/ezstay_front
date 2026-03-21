import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';
import '../../models/booking_state.dart';
import '../../models/rental_item.dart';
import '../../utils/price_calculator.dart';
import '../common/date_range_picker.dart';
import '../common/overlay_toast.dart';

/// 모바일용 예약 Bottom Sheet (React UI 스타일)
/// 날짜 선택 및 가격 분석을 포함합니다.
class BookingBottomSheet extends StatefulWidget {
  final Room room;
  final BookingState initialState;
  final Function(BookingState) onStateChanged;
  final VoidCallback onRequestContract;

  const BookingBottomSheet({
    super.key,
    required this.room,
    required this.initialState,
    required this.onStateChanged,
    required this.onRequestContract,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  late BookingState _bookingState;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _bookingState = widget.initialState;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateState(BookingState newState) {
    setState(() {
      _bookingState = newState;
    });
    widget.onStateChanged(newState);
  }

  @override
  Widget build(BuildContext context) {
    final priceBreakdown = PriceCalculator.calculate(
      room: widget.room,
      bookingState: _bookingState,
    );

    final validationError = PriceCalculator.validateDateSelection(
      room: widget.room,
      bookingState: _bookingState,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              _buildDragHandle(),

              // 스크롤 가능한 컨텐츠
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // 헤더: 주당 가격
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '예약 정보',
                          style: AppTextStyles.headingLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    //주당 가격
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          PriceCalculator.formatKRW(widget.room.weeklyRent),
                          style: AppTextStyles.headingLarge.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' /주',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // 장기계약 할인 정보
                    if (widget.room.longTermDiscount != null &&
                        widget.room.longTermDiscount! > 0) ...[
                      SizedBox(height: AppSpacing.md),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: AppRadius.radiusLg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.room.longTermWeeks}주 이상 계약 시 ${widget.room.longTermDiscount}% 할인',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '${PriceCalculator.formatKRW((widget.room.weeklyRent * (1 - widget.room.longTermDiscount! / 100)).round())}/주',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 빠른 입주 할인 정보
                    if (widget.room.quickMoveIn != null &&
                        widget.room.quickMoveInDiscount != null &&
                        widget.room.quickMoveInDiscount! > 0) ...[
                      SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: AppRadius.radiusLg,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.room.quickMoveIn}일 이내 입주 시 ${PriceCalculator.formatKRW(widget.room.quickMoveInDiscount!)} 할인',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: AppSpacing.md),

                    // 날짜 선택 섹션
                    Text(
                      '임대 기간',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    DateRangePicker(
                      checkInDate: _bookingState.checkInDate,
                      checkOutDate: _bookingState.checkOutDate,
                      minContractDays: widget.room.minContractDays,
                      maxContractDays: widget.room.maxContractDays,
                      unavailablePeriods: widget.room.unavailablePeriods,
                      onDateSelected: (checkIn, checkOut) {
                        _updateState(
                          _bookingState.copyWith(
                            checkInDate: checkIn,
                            checkOutDate: checkOut,
                          ),
                        );
                      },
                      onValidationError: (errorMessage) {
                        // 오버레이 토스트로 최상단에 표시
                        OverlayToast.show(
                          context,
                          message: errorMessage,
                          duration: const Duration(seconds: 3),
                          type: ToastType.error,
                        );
                      },
                    ),

                    SizedBox(height: AppSpacing.md),

                    // 렌탈 아이템 섹션 (EZStay 제공)
                    if (widget.room.availableRentalItems != null &&
                        widget.room.availableRentalItems!.hasItems) ...[
                      Divider(color: AppColors.divider),
                      SizedBox(height: AppSpacing.md),
                      _buildRentalItemsSection(),
                      SizedBox(height: AppSpacing.md),
                    ],

                    // 가격 분석 (날짜 선택 시만 표시)
                    if (_bookingState.hasSelectedDates) ...[
                      Divider(color: AppColors.divider),
                      SizedBox(height: AppSpacing.md),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '결제 예상 금액',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            PriceCalculator.formatKRW(priceBreakdown.total),
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 22,
                              color: AppColors.primary600,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSpacing.sm),
                      _buildPriceBreakdown(priceBreakdown),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),

              // 하단 고정 영역 (총액 + 계약 요청 버튼)
              _buildBottomBar(priceBreakdown, validationError),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: EdgeInsets.only(top: AppSpacing.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.neutral300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPriceBreakdown(PriceBreakdown breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRow(
          '임대료 (${_bookingState.selectedDays}일)',
          breakdown.baseRent,
        ),
        if (breakdown.quickMoveInDiscount > 0)
          _buildPriceRow(
            '빠른 입주 할인',
            -breakdown.quickMoveInDiscount,
            isDiscount: true,
          ),
        if (breakdown.longTermDiscount > 0)
          _buildPriceRow(
            '장기계약 할인',
            -breakdown.longTermDiscount,
            isDiscount: true,
          ),
        _buildPriceRow(
          '관리비 (${_bookingState.selectedDays}일)',
          breakdown.maintenanceFee,
        ),
        _buildPriceRow(
          widget.room.ezService?.cleaningService == true
              ? '청소비 (EZ서비스)'
              : '청소비',
          breakdown.cleaningFee,
        ),
        if (widget.room.ezService?.cleaningService == true)
          Padding(
            padding: EdgeInsets.only(left: 0, bottom: 4),
            child: Text(
              '기본 5만원 + 10평 초과시 10평당 2만원',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        _buildPriceRow('계약 수수료', breakdown.contractFee),
        if (breakdown.rentalItemsFee > 0)
          _buildPriceRow('옵션', breakdown.rentalItemsFee),
        _buildPriceRow('보증금(퇴실 후 환급)', breakdown.deposit),

        SizedBox(height: AppSpacing.sm),

        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: AppColors.primary100),
          ),
          child: Text(
            '보증금은 제3자 예치기관에 보관되며, 퇴실 완료 후 자동 환급됩니다.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDiscount
                  ? AppColors.primary600
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            PriceCalculator.formatKRW(amount.abs()),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDiscount ? AppColors.primary600 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 렌탈 아이템 섹션 (모바일 버전)
  /// 6일 정책: 입주일 6일 전까지만 옵션 상품 선택 가능
  Widget _buildRentalItemsSection() {
    final availableItems = widget.room.availableRentalItems!;
    final allItems = availableItems.allItems; // 평탄화된 리스트

    // 6일 정책 체크: 입주일 6일 전까지만 선택 가능
    final canSelectRental = PriceCalculator.canSelectRentalItems(
      checkInDate: _bookingState.checkInDate,
    );
    final disabledReason = PriceCalculator.getRentalItemsDisabledReason(
      checkInDate: _bookingState.checkInDate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Text(
          '옵션 상품(EZstay에서 제공해드려요)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '옵션 상품은 계약 승인 후에도 구매할 수 있어요.',
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // 6일 정책 비활성화 안내 메시지
        if (!canSelectRental && disabledReason != null) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.warning500),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.warning700,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    disabledReason,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
        ],

        // 단일 컨테이너에 모든 아이템 표시
        Opacity(
          opacity: canSelectRental ? 1.0 : 0.5,
          child: IgnorePointer(
            ignoring: !canSelectRental,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.radiusXl,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: allItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == allItems.length - 1;
                  return _buildRentalItemCard(item, isLast);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRentalItemCard(RentalItem item, bool isLast) {
    final currentQuantity = _bookingState.getRentalItemQuantity(item.id);

    return Container(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품명과 설명 (한 줄로)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs * 0.75),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    TextSpan(
                      text: ' (${item.description})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 가격 및 수량 조절
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 왼쪽: 단가 및 수량 조절
              Row(
                children: [
                  Text(
                    PriceCalculator.formatKRW(item.price),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFF4A5565),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _buildQuantitySelector(item),
                ],
              ),

              // 오른쪽: 총액
              Text(
                PriceCalculator.formatKRW(item.price * currentQuantity),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(RentalItem item) {
    final currentQuantity = _bookingState.getRentalItemQuantity(item.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 감소 버튼
          InkWell(
            onTap: currentQuantity > 0
                ? () {
                    _updateState(
                      _bookingState.addRentalItem(item.id, currentQuantity - 1),
                    );
                  }
                : null,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                size: 18,
                color: currentQuantity > 0
                    ? AppColors.textPrimary
                    : AppColors.neutral400,
              ),
            ),
          ),
          // 수량 표시
          Container(
            width: 40,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.neutral300),
              ),
            ),
            child: Text(
              '$currentQuantity',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // 증가 버튼
          InkWell(
            onTap: currentQuantity < item.availableStock
                ? () {
                    _updateState(
                      _bookingState.addRentalItem(item.id, currentQuantity + 1),
                    );
                  }
                : null,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                Icons.add,
                size: 18,
                color: currentQuantity < item.availableStock
                    ? AppColors.textPrimary
                    : AppColors.neutral400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PriceBreakdown breakdown, String? validationError) {
    // 렌탈 아이템 최소 금액 검증 (10,000원 이상)
    final hasInvalidRentalAmount = _bookingState.hasRentalItems &&
        breakdown.rentalItemsFee > 0 &&
        breakdown.rentalItemsFee < 10000;

    final bool canRequestContract = _bookingState.hasSelectedDates &&
        validationError == null &&
        !hasInvalidRentalAmount;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 총액 표시
          if (_bookingState.hasSelectedDates) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 금액', style: AppTextStyles.headingSmall),
                Text(
                  PriceCalculator.formatKRW(breakdown.total),
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
          ],

          // 렌탈 아이템 최소 금액 에러 메시지
          if (hasInvalidRentalAmount) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error50,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.error500),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: AppColors.error500),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '옵션상품은 최소 10,000원 이상 선택해주세요. (현재: ${PriceCalculator.formatKRW(breakdown.rentalItemsFee)})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sm),
          ],

          // 계약 요청 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canRequestContract ? widget.onRequestContract : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.neutral300,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
              ),
              child: Text(
                canRequestContract ? '계약 요청' : '날짜를 선택해주세요',
                style: AppTextStyles.buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 모바일 하단 고정 Bar (Bottom Sheet 열기 버튼)
class MobileFloatingBar extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const MobileFloatingBar({super.key, required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('요금·기간 확인하기', style: AppTextStyles.buttonText),
                SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
