import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';

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

  const GuestMoveInOptionCard({
    super.key,
    required this.option,
    required this.quantity,
    required this.selected,
    this.selectable = true,
    this.onToggle,
    this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = !option.available;

    return Opacity(
      opacity: unavailable ? 0.5 : 1.0,
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
            if (selectable)
              Checkbox(
                value: selected,
                onChanged: unavailable
                    ? null
                    : (v) => onToggle?.call(v ?? false),
                activeColor: AppColors.primary500,
              ),
            if (option.imageUrl != null && option.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  option.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderIcon(),
                ),
              )
            else
              _placeholderIcon(),
            SizedBox(width: AppSpacing.md),
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
                        _Tag(text: '품절', color: AppColors.error500),
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
            if (selectable && selected && !unavailable) ...[
              SizedBox(width: AppSpacing.sm),
              _QuantityStepper(
                quantity: quantity,
                onChange: (v) => onQuantityChange?.call(v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChange;

  const _QuantityStepper({required this.quantity, required this.onChange});

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
            onTap: () => onChange(quantity + 1),
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
