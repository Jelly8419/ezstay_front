import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';

/// 입주용품 구매 / 침구류 대여 — 품목당 최대 선택 수량.
/// 옵션 카드 스테퍼 상한 + 결제 페이지 검증에서 공용 사용.
const int kGuestMoveInMaxQuantityPerItem = 5;

/// 옵션 카드 — 체크박스 + 옵션명/설명/가격 + 수량 컨트롤
///
/// 비로그인 미리보기와 결제 화면 공용.
/// `selectable: false` 시 체크박스/수량 미노출(읽기 전용 — 결제 완료 화면 등).
class GuestMoveInOptionCard extends StatelessWidget {
  final GuestMoveInOption option;
  final int quantity;
  final bool selected;
  final bool selectable;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<int>? onQuantityChange;

  /// 추가 결제 가능 잔여 수량 — 기보유 수량을 차감한 값.
  /// null/미지정 시 기본 [kGuestMoveInMaxQuantityPerItem](=5)로 동작.
  /// 0 이면 카드 전체 비활성(이미 5개 보유 상태 안내).
  final int? maxQuantity;

  const GuestMoveInOptionCard({
    super.key,
    required this.option,
    required this.quantity,
    required this.selected,
    this.selectable = true,
    this.onToggle,
    this.onQuantityChange,
    this.maxQuantity,
  });

  int get _effectiveMax =>
      maxQuantity ?? kGuestMoveInMaxQuantityPerItem;

  bool get _exhausted => selectable && _effectiveMax <= 0;

  @override
  Widget build(BuildContext context) {
    final unavailable = !option.available;
    final exhausted = _exhausted;
    final dimmed = unavailable || exhausted;

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selectable) ...[
              Checkbox(
                value: selected,
                onChanged: (unavailable || exhausted)
                    ? null
                    : (v) => onToggle?.call(v ?? false),
                activeColor: AppColors.primary500,
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.name,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (unavailable)
                        _Tag(text: '품절', color: AppColors.error500)
                      else if (exhausted)
                        _Tag(
                          text: '보유 한도 ($kGuestMoveInMaxQuantityPerItem개)',
                          color: AppColors.neutral500,
                        ),
                    ],
                  ),
                  if (option.description != null &&
                      option.description!.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      option.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    GuestMoveInFormat.formatPrice(option.price),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary700,
                    ),
                  ),
                ],
              ),
            ),
            if (selectable && selected && !unavailable && !exhausted) ...[
              SizedBox(width: AppSpacing.sm),
              _QuantityStepper(
                quantity: quantity,
                max: _effectiveMax,
                onChange: (v) => onQuantityChange?.call(v),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChange;

  const _QuantityStepper({
    required this.quantity,
    required this.max,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChange(quantity - 1) : null,
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text('$quantity', style: AppTextStyles.bodyLarge),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: quantity < max
                ? () => onChange(quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: disabled ? AppColors.textDisabled : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use_from_same_package
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
