import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';

/// 상세 화면용 주문 카드 (옵션 라인 + 배송 상태 + 금액 + 취소/반품 액션)
class GuestMoveInOrderCard extends StatelessWidget {
  final GuestMoveInOrder order;

  /// 취소/반품 모달 열기 콜백 — null 이면 버튼 미노출(완료 화면 등)
  final ValueChanged<GuestMoveInOrder>? onManage;

  /// 액션 진행 중 — 버튼 비활성
  final bool isMutating;

  const GuestMoveInOrderCard({
    super.key,
    required this.order,
    this.onManage,
    this.isMutating = false,
  });

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
          if (order.hasPendingReturn) _buildPendingReturnNotice(),
          _buildActions(),
        ],
      ),
    );
  }

  /// 진행 중(PENDING) 반품요청 안내 배지
  Widget _buildPendingReturnNotice() {
    final totalQty = order.refundRequests
        .expand((r) => r.targetItems.values)
        .fold<int>(0, (s, q) => s + q);
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment_return_outlined,
                size: 16, color: AppColors.textSecondary),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                totalQty > 0
                    ? '반품 요청 $totalQty개 진행 중 — 관리자 승인 후 환불 처리됩니다.'
                    : '반품 요청이 접수되었습니다. 관리자 승인 후 환불 처리됩니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 취소/반품 액션 영역 — 서버 정책 평가(`order.canCancel`/`canReturn`)
  /// 중 하나라도 true 면 단일 버튼 노출, 클릭 시 부모가 모달을 띄움.
  /// 프론트는 deliveryStatus·시점을 직접 검사하지 않음 (가이드 2.4).
  Widget _buildActions() {
    if (onManage == null) return const SizedBox.shrink();
    if (!order.canCancel && !order.canReturn) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: isMutating ? null : () => onManage!(order),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.border),
          ),
          child: const Text('취소 / 반품'),
        ),
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
