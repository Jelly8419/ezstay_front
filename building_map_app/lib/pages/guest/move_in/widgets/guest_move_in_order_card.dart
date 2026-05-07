import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';

/// 상세 화면용 주문 카드 (옵션 라인 + 배송 상태 + 금액)
class GuestMoveInOrderCard extends StatelessWidget {
  final GuestMoveInOrder order;

  const GuestMoveInOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OrderTypeTag(orderType: order.orderType),
              SizedBox(width: AppSpacing.sm),
              _DeliveryTag(status: order.deliveryStatus),
              Spacer(),
              Text(
                order.orderId,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ...order.items
              .where((i) => i.status == OrderItemStatus.active)
              .map((item) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.quantity > 1
                                ? '${item.name ?? "옵션"} × ${item.quantity}'
                                : (item.name ?? '옵션'),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          GuestMoveInFormat.formatPrice(item.totalPrice),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  )),
          Divider(color: AppColors.border, height: AppSpacing.lg),
          Row(
            children: [
              Text('결제 금액',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              Spacer(),
              Text(
                GuestMoveInFormat.formatPrice(order.paidAmount),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (order.paidAt != null) ...[
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text('결제 일시',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                Spacer(),
                Text(
                  GuestMoveInFormat.formatDateTime(order.paidAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderTypeTag extends StatelessWidget {
  final OrderType orderType;
  const _OrderTypeTag({required this.orderType});

  @override
  Widget build(BuildContext context) {
    final isInitial = orderType == OrderType.initial;
    final color = isInitial ? AppColors.primary500 : AppColors.success500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use_from_same_package
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        orderType.label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeliveryTag extends StatelessWidget {
  final DeliveryStatus status;
  const _DeliveryTag({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
