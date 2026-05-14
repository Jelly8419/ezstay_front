import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/guest_move_in/guest_move_in.dart';
import '../../../providers/guest_move_in/guest_move_in_detail_provider.dart';
import '../../../services/guest_move_in_payment_controller.dart';
import '../../../utils/price_calculator.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import '../../../widgets/payment_method_modal.dart';
import 'utils/guest_move_in_format.dart';
import 'widgets/guest_move_in_info_banner.dart';
import 'widgets/guest_move_in_option_card.dart';
import 'widgets/guest_move_in_room_header.dart';
import 'widgets/guest_move_in_summary_box.dart';

/// 게스트 결제 화면 — `/guest/move-in/requests/:caseId/payment`
///
/// 옵션 선택 + PG 결제 시작 (PG SDK 통합은 Phase 7).
class GuestMoveInPaymentPage extends StatefulWidget {
  final int caseId;

  const GuestMoveInPaymentPage({super.key, required this.caseId});

  @override
  State<GuestMoveInPaymentPage> createState() =>
      _GuestMoveInPaymentPageState();
}

class _GuestMoveInPaymentPageState extends State<GuestMoveInPaymentPage> {
  /// optionId → quantity
  final Map<int, int> _selectedQuantities = {};

  final _controller = GuestMoveInPaymentController();
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GuestMoveInDetailProvider>().loadOptions(widget.caseId);
    });
  }

  void _toggleOption(GuestMoveInOption option, bool selected) {
    setState(() {
      if (selected) {
        _selectedQuantities[option.optionId] = 1;
      } else {
        _selectedQuantities.remove(option.optionId);
      }
    });
  }

  void _changeQuantity(GuestMoveInOption option, int quantity) {
    setState(() {
      _selectedQuantities[option.optionId] = quantity;
    });
  }

  /// 선택된 옵션의 합계 금액
  int _calcTotalAmount(GuestMoveInOptionsResponse ctx) {
    final priceById = {for (final o in ctx.options) o.optionId: o.price};
    return _selectedQuantities.entries
        .fold<int>(0, (sum, e) => sum + (priceById[e.key] ?? 0) * e.value);
  }

  /// 결제 시작 — INITIAL/ADDITIONAL 분기는 detail 의 hasPaidInitial 로 판단
  Future<void> _onPayPressed() async {
    final items = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => GuestSelectedItem(optionId: e.key, quantity: e.value))
        .toList();
    if (items.isEmpty) return;

    final ctx = context.read<GuestMoveInDetailProvider>().optionsContext;
    if (ctx == null) return;
    final totalAmount = _calcTotalAmount(ctx);

    // 최소 금액 가드 (PG 정책 — 옵션 상품 합계 10,000원 이상)
    if (PriceCalculator.isInvalidRentalAmount(totalAmount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PriceCalculator.rentalAmountErrorMessage(
            currentAmount: totalAmount,
          )),
        ),
      );
      return;
    }

    // 결제 수단 선택 (게스트 계약 결제와 동일 패턴)
    final selectedMethod = await showPaymentMethodModal(
      context,
      totalAmount: totalAmount,
    );
    if (selectedMethod == null || !mounted) return;

    setState(() => _paying = true);
    try {
      // 추가 결제 여부 — 상세 응답이 있으면 그걸 보고 판단
      final detail = context.read<GuestMoveInDetailProvider>().detail;
      final isAdditional = detail?.hasPaidInitial ?? false;

      // buyerName/customerPhone 은 백엔드 pgPayload 에서 채워 내려옴
      final result = isAdditional
          ? await _controller.payAdditional(
              caseId: widget.caseId,
              items: items,
              payType: selectedMethod.value,
            )
          : await _controller.payInitial(
              caseId: widget.caseId,
              items: items,
              payType: selectedMethod.value,
            );

      if (!mounted) return;
      _handleResult(result);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _handleResult(GuestMoveInPaymentResult result) {
    switch (result.stage) {
      case GuestMoveInPaymentStage.paid:
        final paymentId = result.confirmation?.paymentId ??
            result.initResponse?.paymentId;
        if (paymentId != null) {
          context.go('/guest/move-in/payments/$paymentId/complete');
        } else {
          context.go('/guest/move-in/requests/${widget.caseId}');
        }
        break;

      case GuestMoveInPaymentStage.cancelledBeforeInit:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제할 옵션을 선택해주세요.')),
        );
        break;

      case GuestMoveInPaymentStage.initFailed:
        _showInitErrorDialog(result.error!);
        break;

      case GuestMoveInPaymentStage.pgFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ??
                '결제가 완료되지 않았습니다. 선택한 옵션을 확인한 뒤 다시 결제해주세요.'),
          ),
        );
        break;

      case GuestMoveInPaymentStage.confirmFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ??
                '결제 승인에 실패했습니다. 다시 시도해주세요.'),
          ),
        );
        break;
    }
  }

  Future<void> _showInitErrorDialog(GuestMoveInException error) async {
    String? actionLabel;
    VoidCallback? action;

    if (error.isPendingOrderExists) {
      actionLabel = '주문 내역 보기';
      action = () => context.go(
            '/guest/move-in/requests/${widget.caseId}',
          );
    } else if (error.isAmountMismatch || error.isStockInsufficient) {
      actionLabel = '새로고침';
      action = () => context
          .read<GuestMoveInDetailProvider>()
          .loadOptions(widget.caseId);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('결제를 시작할 수 없습니다'),
        content: Text(error.message),
        actions: [
          if (action != null && actionLabel != null)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                action!();
              },
              child: Text(actionLabel),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePageLayout(
      child: Consumer<GuestMoveInDetailProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.optionsContext == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _ErrorView(
              message: provider.error!.message,
              onRetry: () => provider.loadOptions(widget.caseId),
            );
          }
          final ctx = provider.optionsContext;
          if (ctx == null) {
            return const Center(child: Text('데이터를 불러올 수 없습니다.'));
          }
          return _buildBody(ctx);
        },
      ),
    );
  }

  Widget _buildBody(GuestMoveInOptionsResponse ctx) {
    final hasSelection = _selectedQuantities.values.any((v) => v > 0);
    final totalAmount = _calcTotalAmount(ctx);
    final isBelowMinimum = PriceCalculator.isInvalidRentalAmount(totalAmount);
    final ctaEnabled = ctx.canPay && hasSelection && !isBelowMinimum && !_paying;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuestMoveInRoomHeader(
            // 결제 화면에서는 룸 정보 노출 최소화 (옵션 응답에 미포함) — 더미 룸
            room: const GuestMoveInRoom(),
            checkInDate: ctx.checkInDate,
            checkOutDate: ctx.checkOutDate,
          ),
          SizedBox(height: AppSpacing.lg),
          if (!ctx.canPay)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: GuestMoveInInfoBanner(
                icon: Icons.warning_amber_outlined,
                message: '입주일 5일 전까지만 결제할 수 있습니다.\n'
                    '결제 마감: ${GuestMoveInFormat.formatDate(ctx.paymentDeadline)}',
              ),
            ),
          GuestMoveInInfoBanner(
            message: '청소 서비스는 임대인(호스트)이 별도로 제공하는 서비스입니다.\n'
                '이 페이지에서는 입주용품·침구류만 선택하고 결제해주세요.',
          ),
          SizedBox(height: AppSpacing.lg),
          Text('옵션 선택', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.md),
          ...ctx.options.map((option) {
            final qty = _selectedQuantities[option.optionId] ?? 0;
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: GuestMoveInOptionCard(
                option: option,
                quantity: qty == 0 ? 1 : qty,
                selected: qty > 0,
                onToggle: (v) => _toggleOption(option, v),
                onQuantityChange: (q) => _changeQuantity(option, q),
              ),
            );
          }),
          SizedBox(height: AppSpacing.lg),
          GuestMoveInSummaryBox(
            options: ctx.options,
            selectedQuantities: _selectedQuantities,
          ),
          if (isBelowMinimum) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error500),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: AppColors.error500),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      PriceCalculator.rentalAmountErrorMessage(
                        currentAmount: totalAmount,
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: ctaEnabled ? _onPayPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary500,
                disabledBackgroundColor: AppColors.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _paying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '결제하기',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
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
