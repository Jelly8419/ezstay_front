import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../../../../models/move_in/move_in_refund_policy.dart';
import '../utils/guest_move_in_format.dart';

/// 상세 화면용 주문 카드 (옵션 라인 + 배송 상태 + 금액 + 취소/반품 액션)
class GuestMoveInOrderCard extends StatelessWidget {
  final GuestMoveInOrder order;

  /// 케이스 입주/퇴실일 — 취소/반품 시점 가드 판정용 ('YYYY-MM-DD').
  /// 액션을 노출하지 않는 화면(결제 완료 등)에서는 생략 가능.
  final String? checkInDate;
  final String? checkOutDate;

  /// 옵션 취소(즉시 환불) 콜백 — null 이면 버튼 미노출
  final ValueChanged<GuestMoveInOrder>? onCancel;

  /// 반품 요청 콜백 — null 이면 버튼 미노출
  final ValueChanged<GuestMoveInOrder>? onReturn;

  /// 액션 진행 중 — 버튼 비활성
  final bool isMutating;

  const GuestMoveInOrderCard({
    super.key,
    required this.order,
    this.checkInDate,
    this.checkOutDate,
    this.onCancel,
    this.onReturn,
    this.isMutating = false,
  });

  DateTime? _parseDate(String? s) => s == null ? null : DateTime.tryParse(s);

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
          if (order.refundedAmount > 0) ...[
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text('환불 금액',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error600)),
                Spacer(),
                Text(
                  GuestMoveInFormat.formatPrice(order.refundedAmount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          _buildActions(),
        ],
      ),
    );
  }

  /// 취소/반품 액션 영역 — 정책상 가능할 때만 버튼 노출
  Widget _buildActions() {
    // 이미 환불/취소된 주문은 액션 없음
    if (order.status == GuestOrderStatus.fullyRefunded ||
        order.status == GuestOrderStatus.cancelled) {
      return const SizedBox.shrink();
    }
    final checkIn = _parseDate(checkInDate);
    final checkOut = _parseDate(checkOutDate);
    if (checkIn == null || checkOut == null) return const SizedBox.shrink();

    final hasActiveItem =
        order.items.any((i) => i.status == OrderItemStatus.active);
    final hasReturnRequested =
        order.items.any((i) => i.status == OrderItemStatus.returnRequested);

    final canCancel = onCancel != null &&
        hasActiveItem &&
        MoveInRefundPolicy.canCancelOrder(
          checkInDate: checkIn,
          isPaid: order.status == GuestOrderStatus.paid ||
              order.status == GuestOrderStatus.partialRefund,
          isDeliveryPending:
              order.deliveryStatus == DeliveryStatus.pending,
        );

    final canReturn = onReturn != null &&
        hasActiveItem &&
        !hasReturnRequested &&
        MoveInRefundPolicy.canRequestReturn(
          checkInDate: checkIn,
          checkOutDate: checkOut,
          isDelivered: order.deliveryStatus == DeliveryStatus.delivered,
        );

    if (hasReturnRequested) {
      return Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '반품 요청이 접수되었습니다. 관리자 승인 후 환불 처리됩니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (!canCancel && !canReturn) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (canReturn)
            OutlinedButton(
              onPressed: isMutating ? null : () => onReturn!(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border),
              ),
              child: const Text('반품 요청'),
            ),
          if (canReturn && canCancel) SizedBox(width: AppSpacing.sm),
          if (canCancel)
            OutlinedButton(
              onPressed: isMutating ? null : () => onCancel!(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error600,
                side: BorderSide(
                  color: AppColors.error500.withValues(alpha: 0.5),
                ),
              ),
              child: const Text('주문 취소'),
            ),
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
