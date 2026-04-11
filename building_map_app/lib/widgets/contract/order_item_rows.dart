import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/rental_order_service.dart';
import '../../utils/format_utils.dart';
import 'delivery_status_helper.dart';

/// 주문 아이템 관련 순수 UI 위젯 모음
class OrderItemRows {
  OrderItemRows._();

  /// 주문 카드 헤더 (전체선택 체크박스 + 주문번호 + 배송 상태 뱃지)
  static Widget orderCardHeader({
    required RentalOrder order,
    required bool allSelected,
    required ValueChanged<bool?> onSelectAll,
  }) {
    return Row(
      children: [
        Checkbox(
          value: allSelected,
          onChanged: onSelectAll,
          activeColor: AppColors.blue600,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: Text(
            '주문 #${order.orderId}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        DeliveryStatusHelper.badge(order.deliveryStatus),
      ],
    );
  }

  /// 아이템 체크박스 행 (선택 가능)
  static Widget itemCheckRow({
    required RentalOrderItemDetail item,
    required bool selected,
    required ValueChanged<bool?> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.blue600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? null : AppColors.neutral400,
              ),
            ),
          ),
          Text(
            '${FormatUtils.formatCurrency(item.price * item.quantity)}원',
            style: TextStyle(
              fontSize: 13,
              color: enabled ? AppColors.neutral700 : AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  /// 취소 수량 조절 행 (quantity > 1 이면 스피너 표시, 1 이면 체크박스만)
  ///
  /// [cancelQuantity] 0 = 선택 안 함, 1~quantity = 취소할 수량
  /// [onQuantityChanged] 수량 변경 콜백
  static Widget itemCancelQuantityRow({
    required RentalOrderItemDetail item,
    required int cancelQuantity,
    required ValueChanged<int> onQuantityChanged,
  }) {
    final bool selected = cancelQuantity > 0;
    final bool isMultiple = item.quantity > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 선택 체크박스
          Checkbox(
            value: selected,
            onChanged: (v) =>
                onQuantityChanged(v == true ? item.quantity : 0),
            activeColor: AppColors.blue600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          // 아이템명
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: selected ? null : AppColors.neutral400,
              ),
            ),
          ),
          // quantity > 1 이고 선택된 경우 수량 스피너 표시
          if (isMultiple && selected) ...[
            _QuantitySpinner(
              value: cancelQuantity,
              min: 1,
              max: item.quantity,
              onChanged: onQuantityChanged,
            ),
            const SizedBox(width: 8),
          ],
          // 취소 금액 (cancelQuantity × pricePerItem)
          Text(
            '${FormatUtils.formatCurrency(item.price * (selected ? cancelQuantity : item.quantity))}원',
            style: TextStyle(
              fontSize: 13,
              color: selected ? AppColors.neutral700 : AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  /// 비활성 아이템 행 (체크박스 없이 취소선 + 상태 뱃지)
  ///
  /// [label] 뱃지 텍스트 (기본: '반품 신청됨')
  /// [badgeColor] 뱃지 배경색 계열 — warning(기본) / neutral
  static Widget disabledItemRow(
    RentalOrderItemDetail item, {
    String label = '반품 신청됨',
    DisabledItemBadgeColor badgeColor = DisabledItemBadgeColor.warning,
  }) {
    final Color bgColor = badgeColor == DisabledItemBadgeColor.neutral
        ? AppColors.neutral100
        : AppColors.warning50;
    final Color borderColor = badgeColor == DisabledItemBadgeColor.neutral
        ? AppColors.neutral300
        : AppColors.warning500;
    final Color textColor = badgeColor == DisabledItemBadgeColor.neutral
        ? AppColors.neutral500
        : AppColors.warning700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral400,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

}

/// 비활성 아이템 행 뱃지 색상 종류
enum DisabledItemBadgeColor { warning, neutral }

/// 수량 증감 스피너 (취소 수량 선택용)
class _QuantitySpinner extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _QuantitySpinner({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _spinnerButton(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          alignment: Alignment.center,
          child: Text(
            '$value / $max',
            style: TextStyle(fontSize: 12, color: AppColors.neutral700),
          ),
        ),
        _spinnerButton(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }

  Widget _spinnerButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? AppColors.neutral300 : AppColors.neutral200,
          ),
          borderRadius: BorderRadius.circular(4),
          color: enabled ? Colors.white : AppColors.neutral100,
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? AppColors.neutral700 : AppColors.neutral300,
        ),
      ),
    );
  }
}
