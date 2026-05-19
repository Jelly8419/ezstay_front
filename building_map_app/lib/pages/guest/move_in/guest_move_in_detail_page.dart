import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/guest_move_in/guest_move_in.dart';
import '../../../providers/guest_move_in/guest_move_in_detail_provider.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import 'utils/guest_move_in_format.dart';
import 'widgets/guest_move_in_order_card.dart';
import 'widgets/guest_move_in_refund_modal.dart';
import 'widgets/guest_move_in_room_header.dart';
import 'widgets/guest_move_in_status_chip.dart';

/// 게스트 입주 준비 상세 (조회/재확인) — `/guest/move-in/requests/:caseId`
///
/// 결제 완료 후 진입: 주문 내역 + 배송 상태 확인 + 추가 결제 진입
class GuestMoveInDetailPage extends StatefulWidget {
  final int caseId;

  const GuestMoveInDetailPage({super.key, required this.caseId});

  @override
  State<GuestMoveInDetailPage> createState() => _GuestMoveInDetailPageState();
}

class _GuestMoveInDetailPageState extends State<GuestMoveInDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GuestMoveInDetailProvider>().loadDetail(widget.caseId);
    });
  }

  /// 취소/반품 통합 모달 오픈. 모달이 콜백으로 provider 액션을 호출하고,
  /// 성공 시 true 를 pop → 여기서 결과 토스트 표시.
  Future<void> _onManageOrder(
    GuestMoveInOrder order,
    GuestMoveInRequestDetail detail,
  ) async {
    final checkIn = DateTime.tryParse(detail.checkInDate);
    final checkOut = DateTime.tryParse(detail.checkOutDate);
    if (checkIn == null || checkOut == null) return;

    final provider = context.read<GuestMoveInDetailProvider>();
    GuestOrderRefundResponse? cancelResult;
    GuestReturnRequestResponse? returnResult;

    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GuestMoveInRefundModal(
        order: order,
        checkInDate: checkIn,
        checkOutDate: checkOut,
        onCancel: (orderDbId, reason, items) async {
          cancelResult = await provider.cancelPaidOrder(
            orderDbId,
            reason: reason.isEmpty ? null : reason,
            items: items,
          );
          return cancelResult;
        },
        onReturn: (orderDbId, reason, items) async {
          returnResult = await provider.requestReturn(
            orderDbId,
            reason: reason.isEmpty ? null : reason,
            items: items,
          );
          return returnResult;
        },
      ),
    );
    if (done != true || !mounted) return;

    if (cancelResult != null) {
      final r = cancelResult!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.partial
                ? '선택한 옵션이 부분 취소되어 ${GuestMoveInFormat.formatPrice(r.refundAmount)} 환불 처리되었습니다.'
                : '주문이 취소되어 ${GuestMoveInFormat.formatPrice(r.refundAmount)} 환불 처리되었습니다.',
          ),
        ),
      );
    } else if (returnResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('반품 요청이 접수되었습니다. 관리자 승인 후 환불 처리됩니다.'),
        ),
      );
    } else {
      _showActionError(provider.error);
    }
  }

  void _showActionError(GuestMoveInException? error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error?.message ?? '요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePageLayout(
      child: Consumer<GuestMoveInDetailProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.detail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _ErrorView(
              message: provider.error!.message,
              onRetry: () => provider.loadDetail(widget.caseId),
            );
          }
          final detail = provider.detail;
          if (detail == null) {
            return const Center(child: Text('데이터를 불러올 수 없습니다.'));
          }
          return _buildBody(context, detail);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, GuestMoveInRequestDetail detail) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('입주 준비 서비스', style: AppTextStyles.headingLarge),
              ),
              GuestMoveInStatusChip(status: detail.status),
              SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: '새로고침',
                icon: const Icon(Icons.refresh),
                onPressed: () => context
                    .read<GuestMoveInDetailProvider>()
                    .loadDetail(widget.caseId),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          GuestMoveInRoomHeader(
            room: detail.room,
            checkInDate: detail.checkInDate,
            checkOutDate: detail.checkOutDate,
          ),
          SizedBox(height: AppSpacing.lg),
          if (detail.status == GuestMoveInStatus.pendingPayment)
            _PendingPaymentCta(
              canPay: detail.canPay,
              onPay: () => context.go(
                '/guest/move-in/requests/${widget.caseId}/payment',
              ),
            )
          else ...[
            Text('주문 내역', style: AppTextStyles.headingSmall),
            SizedBox(height: AppSpacing.md),
            ...detail.orders.map(
              (o) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: GuestMoveInOrderCard(
                  order: o,
                  checkInDate: detail.checkInDate,
                  checkOutDate: detail.checkOutDate,
                  isMutating: context
                      .watch<GuestMoveInDetailProvider>()
                      .isMutating,
                  onManage: (order) => _onManageOrder(order, detail),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (detail.hasPaidInitial && detail.canPay)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go(
                    '/guest/move-in/requests/${widget.caseId}/payment',
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '추가 옵션 결제',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PendingPaymentCta extends StatelessWidget {
  final bool canPay;
  final VoidCallback onPay;

  const _PendingPaymentCta({required this.canPay, required this.onPay});

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('아직 결제하지 않은 요청입니다',
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: AppSpacing.xs),
          Text(
            canPay
                ? '필요한 옵션을 선택해 결제를 완료해주세요.'
                : '입주일 5일 전이 지나 결제할 수 없습니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: canPay ? onPay : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary500,
                disabledBackgroundColor: AppColors.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '옵션 선택 후 결제하기',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/guest/move-in'),
              child: const Text('목록으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
