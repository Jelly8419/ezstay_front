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

  /// CANCEL_REQUESTED 아이템 표시 (체크박스 없이 비활성 + 취소선)
  static Widget disabledItemRow(RentalOrderItemDetail item) {
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
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.warning500),
            ),
            child: Text(
              '반품 신청됨',
              style: TextStyle(fontSize: 10, color: AppColors.warning700),
            ),
          ),
        ],
      ),
    );
  }

}
