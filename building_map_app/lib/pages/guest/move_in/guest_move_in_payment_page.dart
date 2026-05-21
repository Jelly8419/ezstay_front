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
import 'widgets/guest_move_in_deadline_banner.dart';
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
      // 옵션 카탈로그만 로드 — 백엔드가 옵션별 ownedQuantity /
      // remainingQuantity / maxPerOption 을 동봉해주므로 주문 내역 별도 조회 불필요.
      context.read<GuestMoveInDetailProvider>().loadOptions(widget.caseId);
    });
  }

  void _toggleOption(GuestMoveInOption option, bool selected) {
    if (selected) {
      // 보유 한도 도달 옵션은 선택 차단 (카드 UI 가 이미 잠그지만 안전망)
      if (_remainingForOption(option.optionId) <= 0) return;
    }
    setState(() {
      if (selected) {
        _selectedQuantities[option.optionId] = 1;
      } else {
        _selectedQuantities.remove(option.optionId);
      }
    });
  }

  void _changeQuantity(GuestMoveInOption option, int quantity) {
    // 품목당 최대 5개 (입주용품 구매 / 침구류 대여 공통).
    // 추가 결제는 기보유 수량을 반영한 잔여 만큼만 허용.
    final remaining = _remainingForOption(option.optionId);
    if (remaining <= 0) {
      setState(() => _selectedQuantities.remove(option.optionId));
      return;
    }
    final clamped = quantity.clamp(1, remaining);
    setState(() {
      _selectedQuantities[option.optionId] = clamped;
    });
  }

  /// 선택된 옵션의 합계 금액
  int _calcTotalAmount(GuestMoveInOptionsResponse ctx) {
    final priceById = {for (final o in ctx.options) o.optionId: o.price};
    return _selectedQuantities.entries
        .fold<int>(0, (sum, e) => sum + (priceById[e.key] ?? 0) * e.value);
  }

  /// 옵션 카탈로그 응답에서 옵션별 정보를 조회 (백엔드가 ownedQuantity /
  /// remainingQuantity / maxPerOption 을 동봉).
  GuestMoveInOption? _findOption(int optionId) {
    final ctx = context.read<GuestMoveInDetailProvider>().optionsContext;
    if (ctx == null) return null;
    for (final o in ctx.options) {
      if (o.optionId == optionId) return o;
    }
    return null;
  }

  /// 옵션별 추가 결제 가능 잔여 수량. 옵션 미발견 시 0 (안전).
  int _remainingForOption(int optionId) =>
      _findOption(optionId)?.remainingQuantity ?? 0;

  /// 옵션별 기보유 수량 (에러 안내·로그용).
  int _ownedForOption(int optionId) =>
      _findOption(optionId)?.ownedQuantity ?? 0;

  /// 케이스 내 PAID/PARTIAL_REFUND ACTIVE 보유가 하나라도 있으면 추가 결제로 간주.
  bool _hasAnyOwned(GuestMoveInOptionsResponse ctx) =>
      ctx.options.any((o) => o.ownedQuantity > 0);

  /// 결제 시작 — INITIAL/ADDITIONAL 분기는 detail 의 hasPaidInitial 로 판단
  Future<void> _onPayPressed() async {
    final items = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => GuestSelectedItem(optionId: e.key, quantity: e.value))
        .toList();
    if (items.isEmpty) return;

    // 품목당 최대 5개 가드 — 옵션 응답의 remainingQuantity 기반 (서버 4816 동일 정책).
    for (final i in items) {
      final remaining = _remainingForOption(i.optionId);
      if (i.quantity > remaining) {
        final ownedQty = _ownedForOption(i.optionId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ownedQty > 0
                  ? '이미 보유한 수량($ownedQty개)을 포함해 품목당 최대 $kGuestMoveInMaxQuantityPerItem개까지만 가능합니다.'
                  : '품목당 최대 $kGuestMoveInMaxQuantityPerItem개까지만 선택할 수 있습니다.',
            ),
          ),
        );
        return;
      }
    }

    final ctx = context.read<GuestMoveInDetailProvider>().optionsContext;
    if (ctx == null) return;
    final totalAmount = _calcTotalAmount(ctx);

    // INITIAL 최소 금액 가드 — 추가 결제(ADDITIONAL)는 면제.
    // (이미 결제 이력이 있는 케이스라 PG 최소금액 정책 재적용 불필요)
    final isAdditional = _hasAnyOwned(ctx);
    if (!isAdditional &&
        PriceCalculator.isInvalidRentalAmount(totalAmount)) {
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

  /// 4816 응답 details([{name, max, alreadyOwned, requested}, ...])를
  /// 사람이 읽는 안내 문구로 변환. 형식이 다르면 null.
  String? _optionQtyExceededDetail(GuestMoveInException error) {
    final d = error.details;
    if (d is! List || d.isEmpty) return null;
    final lines = <String>[];
    for (final e in d) {
      if (e is! Map) continue;
      final name = e['name']?.toString() ?? '옵션';
      final max = (e['max'] as num?)?.toInt() ?? 5;
      final owned = (e['alreadyOwned'] as num?)?.toInt();
      final requested = (e['requested'] as num?)?.toInt();
      if (owned != null && requested != null) {
        lines.add('· $name: 보유 $owned개 + 요청 $requested개 (최대 $max개)');
      } else {
        lines.add('· $name (최대 $max개)');
      }
    }
    return lines.isEmpty ? null : lines.join('\n');
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

    final detailText =
        error.isOptionQtyExceeded ? _optionQtyExceededDetail(error) : null;
    final bodyText = detailText == null
        ? error.message
        : '${error.message}\n\n$detailText';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('결제를 시작할 수 없습니다'),
        content: Text(bodyText),
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
    // 추가 결제 여부 판정 — 옵션 응답의 ownedQuantity(PAID/PARTIAL_REFUND
    // ACTIVE 라인 합산, 백엔드 동봉)가 0보다 크면 이미 결제 이력 있음.
    final isAdditional = _hasAnyOwned(ctx);
    // 추가 결제(ADDITIONAL) 는 PG 최소금액 가드 면제 — 기존 결제 이력 있음.
    final isBelowMinimum =
        !isAdditional && PriceCalculator.isInvalidRentalAmount(totalAmount);
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
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: GuestMoveInDeadlineBanner(
              deadline: ctx.paymentDeadline,
              expired: !ctx.canPay,
            ),
          ),
          Text('옵션 선택', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.md),
          ...ctx.options.map((option) {
            final qty = _selectedQuantities[option.optionId] ?? 0;
            final remaining = _remainingForOption(option.optionId);
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: GuestMoveInOptionCard(
                option: option,
                quantity: qty == 0 ? 1 : qty,
                selected: qty > 0,
                maxQuantity: remaining,
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
