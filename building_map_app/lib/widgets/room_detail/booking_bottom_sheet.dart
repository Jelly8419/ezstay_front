import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';
import '../../models/rental_item.dart';
import '../../models/booking_state.dart';
import '../../models/selected_rental_item.dart';
import '../../utils/price_calculator.dart';
import '../common/date_range_picker.dart';

/// 모바일용 예약 Bottom Sheet (React UI 스타일)
/// 날짜 선택, 옵션 선택, 가격 분석을 포함합니다.
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
                      errorMessage: validationError,
                      onDateSelected: (checkIn, checkOut) {
                        _updateState(
                          _bookingState.copyWith(
                            checkInDate: checkIn,
                            checkOutDate: checkOut,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: AppSpacing.md),

                    // 옵션 상품 섹션
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '옵션 상품(EZstay에서 제공해드려요)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '옵션 상품은 계약 승인 후에도 구매할 수 있어요.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),

                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.radiusXl,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: _buildRentalItemsList()),
                    ),

                    // 최소 주문 금액 안내
                    if (priceBreakdown.rentalItemsFee > 0 &&
                        priceBreakdown.rentalItemsFee < 10000) ...[
                      SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // amber-50
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: const Color(0xFFD97706), // amber-600
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '옵션 상품은 최소 10,000원 이상 주문 가능합니다',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFFD97706), // amber-600
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// 렌탈 아이템 리스트 생성
  List<Widget> _buildRentalItemsList() {
    final items = <Widget>[];

    if (widget.room.availableRentalItems == null)
      return [
        Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Text(
            '옵션 상품이 없습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ];

    final allItems = [
      ...widget.room.availableRentalItems!.beddingSets,
      ...widget.room.availableRentalItems!.amenityKits,
      ...widget.room.availableRentalItems!.hairDryers,
      ...widget.room.availableRentalItems!.towelSets,
    ];

    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i];
      items.add(_buildCompactRentalItem(item));

      if (i < allItems.length - 1) {
        items.add(Divider(height: AppSpacing.md * 2, color: AppColors.divider));
      }
    }

    return items;
  }

  /// 컴팩트한 렌탈 아이템 (리액트 UI 스타일)
  Widget _buildCompactRentalItem(RentalItem item) {
    final currentQuantity = _bookingState.getQuantity(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상품명과 설명
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.xs),

        // 가격 및 수량 조절
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 왼쪽: 단가 + 수량 조절
            Row(
              children: [
                Text(
                  PriceCalculator.formatKRW(item.price),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: currentQuantity > 0
                            ? () {
                                _updateState(
                                  _bookingState.updateRentalItem(
                                    SelectedRentalItem(
                                      id: item.id,
                                      name: item.name,
                                      description: item.description,
                                      price: item.price,
                                      quantity: currentQuantity - 1,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: currentQuantity > 0
                                ? AppColors.textSecondary
                                : AppColors.neutral400,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '$currentQuantity',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: currentQuantity < 4
                            ? () {
                                _updateState(
                                  _bookingState.updateRentalItem(
                                    SelectedRentalItem(
                                      id: item.id,
                                      name: item.name,
                                      description: item.description,
                                      price: item.price,
                                      quantity: currentQuantity + 1,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: currentQuantity < 4
                                ? AppColors.textSecondary
                                : AppColors.neutral400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        _buildPriceRow('청소비', breakdown.cleaningFee),
        _buildPriceRow('계약 수수료', breakdown.contractFee),
        if (breakdown.rentalItemsFee > 0)
          _buildPriceRow('옵션 상품', breakdown.rentalItemsFee),
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

  Widget _buildBottomBar(PriceBreakdown breakdown, String? validationError) {
    final bool canRequestContract =
        _bookingState.hasSelectedDates && validationError == null;

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
