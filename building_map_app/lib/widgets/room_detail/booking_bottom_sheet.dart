import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';
import '../../models/booking_state.dart';
import '../../models/selected_rental_item.dart';
import '../../utils/price_calculator.dart';
import '../common/date_range_picker.dart';
import '../common/rental_item_selector.dart';

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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
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
                    // 날짜 선택 섹션
                    _buildSection(
                      title: '날짜 선택',
                      icon: Icons.calendar_today,
                      child: DateRangePicker(
                        checkInDate: _bookingState.checkInDate,
                        checkOutDate: _bookingState.checkOutDate,
                        minContractDays: widget.room.minContractDays,
                        errorMessage: validationError,
                        onDateSelected: (checkIn, checkOut) {
                          _updateState(_bookingState.copyWith(
                            checkInDate: checkIn,
                            checkOutDate: checkOut,
                          ));
                        },
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // 옵션 상품 섹션
                    if (widget.room.availableRentalItems != null &&
                        !widget.room.availableRentalItems!.isEmpty) ...[
                      _buildSection(
                        title: '옵션 상품',
                        icon: Icons.shopping_bag,
                        child: Column(
                          children: [
                            // 침구 세트
                            if (widget.room.availableRentalItems!.beddingSets.isNotEmpty)
                              ...widget.room.availableRentalItems!.beddingSets.map((item) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                                  child: RentalItemSelector(
                                    item: item,
                                    currentQuantity: _bookingState.getQuantity(item.id),
                                    onQuantityChanged: (quantity) {
                                      _updateState(_bookingState.updateRentalItem(
                                        SelectedRentalItem(
                                          id: item.id,
                                          name: item.name,
                                          description: item.description,
                                          price: item.price,
                                          quantity: quantity,
                                        ),
                                      ));
                                    },
                                  ),
                                );
                              }),

                            // 어메니티 키트
                            if (widget.room.availableRentalItems!.amenityKits.isNotEmpty)
                              ...widget.room.availableRentalItems!.amenityKits.map((item) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                                  child: RentalItemSelector(
                                    item: item,
                                    currentQuantity: _bookingState.getQuantity(item.id),
                                    onQuantityChanged: (quantity) {
                                      _updateState(_bookingState.updateRentalItem(
                                        SelectedRentalItem(
                                          id: item.id,
                                          name: item.name,
                                          description: item.description,
                                          price: item.price,
                                          quantity: quantity,
                                        ),
                                      ));
                                    },
                                  ),
                                );
                              }),

                            // 헤어드라이어
                            if (widget.room.availableRentalItems!.hairDryers.isNotEmpty)
                              ...widget.room.availableRentalItems!.hairDryers.map((item) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                                  child: RentalItemSelector(
                                    item: item,
                                    currentQuantity: _bookingState.getQuantity(item.id),
                                    onQuantityChanged: (quantity) {
                                      _updateState(_bookingState.updateRentalItem(
                                        SelectedRentalItem(
                                          id: item.id,
                                          name: item.name,
                                          description: item.description,
                                          price: item.price,
                                          quantity: quantity,
                                        ),
                                      ));
                                    },
                                  ),
                                );
                              }),

                            // 타올 세트
                            if (widget.room.availableRentalItems!.towelSets.isNotEmpty)
                              ...widget.room.availableRentalItems!.towelSets.map((item) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                                  child: RentalItemSelector(
                                    item: item,
                                    currentQuantity: _bookingState.getQuantity(item.id),
                                    onQuantityChanged: (quantity) {
                                      _updateState(_bookingState.updateRentalItem(
                                        SelectedRentalItem(
                                          id: item.id,
                                          name: item.name,
                                          description: item.description,
                                          price: item.price,
                                          quantity: quantity,
                                        ),
                                      ));
                                    },
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],

                    // 가격 분석 섹션
                    _buildSection(
                      title: '가격 분석',
                      icon: Icons.account_balance_wallet,
                      child: _buildPriceBreakdown(priceBreakdown),
                    ),

                    SizedBox(height: AppSpacing.xl),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary600),
            SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.headingSmall,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }

  Widget _buildPriceBreakdown(PriceBreakdown breakdown) {
    if (!_bookingState.hasSelectedDates) {
      return Text(
        '날짜를 선택하면 가격이 표시됩니다.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      children: [
        _buildPriceRow('임대료', breakdown.baseRent),
        _buildPriceRow('관리비', breakdown.maintenanceFee),
        _buildPriceRow('청소비', breakdown.cleaningFee),

        if (breakdown.rentalItemsFee > 0)
          _buildPriceRow('옵션 상품', breakdown.rentalItemsFee),

        if (breakdown.longTermDiscount > 0)
          _buildPriceRow(
            '장기 계약 할인',
            -breakdown.longTermDiscount,
            isDiscount: true,
          ),

        if (breakdown.quickMoveInDiscount > 0)
          _buildPriceRow(
            '빠른 입주 할인',
            -breakdown.quickMoveInDiscount,
            isDiscount: true,
          ),

        Divider(height: AppSpacing.lg * 2, color: AppColors.divider),

        _buildPriceRow('소계', breakdown.subtotal, isBold: true),
        _buildPriceRow('보증금', breakdown.deposit),
        _buildPriceRow('계약 수수료', breakdown.contractFee),

        Divider(height: AppSpacing.lg * 2, color: AppColors.divider),

        _buildPriceRow(
          '총 금액',
          breakdown.total,
          isBold: true,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    int amount, {
    bool isBold = false,
    bool isDiscount = false,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? AppColors.primary700 : AppColors.textPrimary,
                  )
                : AppTextStyles.bodyMedium,
          ),
          Text(
            PriceCalculator.formatKRW(amount.abs()),
            style: isBold
                ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPrimary
                        ? AppColors.primary700
                        : isDiscount
                            ? AppColors.error500
                            : AppColors.textPrimary,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    color: isDiscount ? AppColors.error500 : AppColors.textPrimary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PriceBreakdown breakdown, String? validationError) {
    final bool canRequestContract = _bookingState.hasSelectedDates &&
        validationError == null;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
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
                Text(
                  '총 금액',
                  style: AppTextStyles.headingSmall,
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                ),
              ),
              child: Text(
                canRequestContract
                    ? '계약 요청'
                    : '날짜를 선택해주세요',
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

  const MobileFloatingBar({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '요금·기간 확인하기',
                  style: AppTextStyles.buttonText,
                ),
                SizedBox(width: AppSpacing.sm),
                const Icon(Icons.arrow_upward, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
