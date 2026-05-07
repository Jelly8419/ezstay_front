import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/guest_move_in/guest_move_in.dart';
import '../../../services/guest_move_in_service.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import 'utils/guest_move_in_format.dart';
import 'widgets/guest_move_in_order_card.dart';
import 'widgets/guest_move_in_room_header.dart';

/// 게스트 결제 완료 화면 — `/guest/move-in/payments/:paymentId/complete`
///
/// 결제 직후 노출. 주문 정보 + 룸 정보 + CTA 3개.
class GuestMoveInCompletePage extends StatefulWidget {
  final int paymentId;

  const GuestMoveInCompletePage({super.key, required this.paymentId});

  @override
  State<GuestMoveInCompletePage> createState() =>
      _GuestMoveInCompletePageState();
}

class _GuestMoveInCompletePageState extends State<GuestMoveInCompletePage> {
  final _service = GuestMoveInService();
  bool _loading = true;
  GuestMoveInException? _error;
  GuestPaymentResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getPaymentResult(widget.paymentId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on GuestMoveInException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ResponsivePageLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return ResponsivePageLayout(
        child: _ErrorView(message: _error!.message, onRetry: _load),
      );
    }
    final result = _result;
    if (result == null) {
      return const ResponsivePageLayout(
        child: Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }
    return ResponsivePageLayout(child: _buildBody(result));
  }

  Widget _buildBody(GuestPaymentResult result) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SuccessHeader(),
          SizedBox(height: AppSpacing.lg),
          GuestMoveInRoomHeader(
            room: result.caseInfo.room,
            checkInDate: result.caseInfo.checkInDate,
            checkOutDate: result.caseInfo.checkOutDate,
          ),
          SizedBox(height: AppSpacing.lg),
          Text('주문 내역', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.md),
          GuestMoveInOrderCard(order: result.order),
          SizedBox(height: AppSpacing.lg),
          _PaymentMeta(result: result),
          SizedBox(height: AppSpacing.lg),
          _CtaSection(caseId: result.caseInfo.requestId),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 36,
            color: AppColors.success700,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text('결제가 완료되었습니다',
            style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
        SizedBox(height: AppSpacing.xs),
        Text(
          '선택하신 입주 준비 옵션은 입주 일정에 맞춰 준비됩니다.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PaymentMeta extends StatelessWidget {
  final GuestPaymentResult result;
  const _PaymentMeta({required this.result});

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
        children: [
          _MetaRow(
            label: '주문번호',
            value: result.payment.orderId,
          ),
          SizedBox(height: AppSpacing.xs),
          _MetaRow(
            label: '결제 일시',
            value: GuestMoveInFormat.formatDateTime(result.payment.paidAt),
          ),
          SizedBox(height: AppSpacing.xs),
          _MetaRow(
            label: '총 결제 금액',
            value: GuestMoveInFormat.formatPrice(result.payment.amount),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _MetaRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: emphasize
              ? AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                )
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _CtaSection extends StatelessWidget {
  final int caseId;
  const _CtaSection({required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => context.go('/guest/move-in'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '내 입주 준비 서비스 보기',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () =>
                context.go('/guest/move-in/requests/$caseId'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '배송 준비 상태 확인',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('홈으로 이동'),
        ),
      ],
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
