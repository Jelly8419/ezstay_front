import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/move_in/move_in.dart';
import '../../../providers/move_in/move_in_detail_provider.dart';
import '../../../providers/move_in/move_in_list_provider.dart';
import '../../../services/cleaning_payment_controller.dart';
import '../../../utils/responsive_util.dart';
import '../../../widgets/common/custom_toast.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import '../../../widgets/payment_method_modal.dart';
import 'widgets/cleaning_quote_dialog.dart';
import 'widgets/move_in_case_edit_dialog.dart';
import 'widgets/move_in_cleaning_section.dart';
import 'widgets/move_in_detail_header.dart';
import 'widgets/move_in_payment_request_section.dart';

/// 입주 준비 등록 상세 (호스트) — 이미지 ③ 화면
///
/// 페이지 스코프 [MoveInDetailProvider] 사용 — 라우트 진입 시 생성, 이탈 시 dispose.
/// `?action=pay`로 진입하면 PG 결제 모달 자동 오픈 (Phase 6).
class MoveInDetailPage extends StatelessWidget {
  final int caseId;
  final String? initialAction;

  const MoveInDetailPage({
    super.key,
    required this.caseId,
    this.initialAction,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MoveInDetailProvider>(
      create: (_) => MoveInDetailProvider(caseId: caseId)..load(),
      child: _MoveInDetailBody(initialAction: initialAction),
    );
  }
}

class _MoveInDetailBody extends StatefulWidget {
  final String? initialAction;
  const _MoveInDetailBody({this.initialAction});

  @override
  State<_MoveInDetailBody> createState() => _MoveInDetailBodyState();
}

class _MoveInDetailBodyState extends State<_MoveInDetailBody> {
  final CleaningPaymentController _paymentController = CleaningPaymentController();
  bool _initialActionHandled = false;
  bool _isPaying = false;

  /// 알림톡 미연동 운영 단계 안내 — send/resend 응답에 `_note`가 포함됐을 때 보존
  String? _devNote;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoveInDetailProvider>();
    final isMobile = ResponsiveUtil.isMobile(context);

    // 케이스가 처음 로드되면 ?action=pay 처리 (Phase 6 결제 모달 hook)
    final c = provider.moveInCase;
    if (!_initialActionHandled && c != null && widget.initialAction == 'pay') {
      _initialActionHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (c.canPayCleaning) {
          _onPayCleaning();
        }
      });
    }

    return Stack(
      children: [
        ResponsivePageLayout(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: isMobile ? AppSpacing.md : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                SizedBox(height: AppSpacing.md),
                _buildBody(context, provider, isMobile),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        if (_isPaying)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('결제 진행 중입니다...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '입주 준비 서비스로 돌아가기',
          onPressed: () => context.go('/host/move-in'),
        ),
        SizedBox(width: AppSpacing.sm),
        Text('입주 준비 등록 상세', style: AppTextStyles.headingLarge),
      ],
    );
  }

  Widget _buildBody(BuildContext context, MoveInDetailProvider provider, bool isMobile) {
    if (provider.isLoading && provider.moveInCase == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final c = provider.moveInCase;
    if (c == null) {
      return _buildErrorBox(provider);
    }

    final isBusy = provider.isMutating || _isPaying;
    final cleaning = MoveInCleaningSection(
      moveInCase: c,
      isMutating: isBusy,
      onRequest: () => _onRequestCleaning(),
      onPay: () => _onPayCleaning(),
      onCancel: () => _onCancelCleaning(),
      onRefund: () => _onRefundCleaning(),
    );
    final paymentRequest = MoveInPaymentRequestSection(
      moveInCase: c,
      isMutating: isBusy,
      onSend: () => _onSendPaymentRequest(),
      onResend: () => _onResendPaymentRequest(),
      onCopyLink: () => _onCopyPaymentLink(),
      devNote: _devNote,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoveInDetailHeader(moveInCase: c, onEdit: _onEditCase),
        SizedBox(height: AppSpacing.md),
        if (isMobile) ...[
          cleaning,
          SizedBox(height: AppSpacing.md),
          paymentRequest,
        ] else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cleaning),
                SizedBox(width: AppSpacing.md),
                Expanded(child: paymentRequest),
              ],
            ),
          ),
        SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () => context.go('/host/move-in'),
            child: const Text('목록으로'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(MoveInDetailProvider provider) {
    final message = provider.error?.message ?? '케이스를 불러오지 못했습니다.';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.error50,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.error500.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error500),
          SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error700)),
          SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: provider.load,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 액션 핸들러
  // ============================================================

  Future<void> _onEditCase() async {
    final provider = context.read<MoveInDetailProvider>();
    final c = provider.moveInCase;
    if (c == null) return;

    final request = await showMoveInCaseEditDialog(context, moveInCase: c);
    if (request == null || !mounted) return;

    final phoneChanged = request.guestPhone != null;
    final updated = await provider.updateCase(request);
    if (!mounted) return;
    if (updated != null) {
      if (phoneChanged) {
        // 백엔드가 토큰 자동 재발급 + paymentRequest.status를 NOT_SENT로 초기화 (PRD 9.2)
        CustomToast.success(
          context,
          '계약 정보를 수정했습니다. 임차인 연락처가 변경되어 결제 요청이 다시 발송 가능 상태로 초기화되었습니다.',
        );
        // 발송된 적 있어 보존되던 dev note는 더 이상 의미 없음
        if (_devNote != null) setState(() => _devNote = null);
      } else {
        CustomToast.success(context, '계약 정보를 수정했습니다.');
      }
      _syncListProvider(updated);
    } else {
      _showProviderError();
    }
  }

  Future<void> _onRequestCleaning() async {
    final provider = context.read<MoveInDetailProvider>();
    final updated = await provider.requestCleaning();
    if (!mounted) return;
    if (updated != null) {
      CustomToast.success(context, '청소 서비스를 신청했습니다. 결제를 진행해주세요.');
      _syncListProvider(updated);
    } else {
      _showProviderError();
    }
  }

  Future<void> _onCancelCleaning() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('청소 신청을 취소하시겠습니까?'),
        content: const Text('취소 후 다시 신청할 수 있지만, 결제가 진행 중이면 PG 처리 정책에 따라 환불 절차가 필요할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('닫기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error500),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = context.read<MoveInDetailProvider>();
    final updated = await provider.cancelCleaningRequest();
    if (!mounted) return;
    if (updated != null) {
      CustomToast.success(context, '청소 신청을 취소했습니다.');
      _syncListProvider(updated);
    } else {
      _showProviderError();
    }
  }

  Future<void> _onRefundCleaning() async {
    final provider = context.read<MoveInDetailProvider>();
    // 모달 열기 직전 정책 재평가 (단일 진실 원천: evaluateCleaningRefund).
    // quote 실패 시 케이스 상세에 동봉된 cleaningRefund 로 폴백.
    final quote = await provider.fetchCleaningRefundQuote() ??
        provider.moveInCase?.cleaningRefund;
    if (!mounted) return;

    if (quote == null || !quote.canRefund) {
      CustomToast.warning(
        context,
        quote?.reason ?? '현재 환불할 수 없습니다.',
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    final cleaningFee = provider.moveInCase?.cleaningFee ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('청소 결제를 환불하시겠습니까?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환불 금액은 청소 희망일 기준 정책에 따라 산정됩니다.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.md),
            // 영수증 스타일 산정 내역
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _refundRow('결제 금액', _won(cleaningFee)),
                  if (quote.deduction > 0) ...[
                    SizedBox(height: AppSpacing.xs),
                    _refundRow(
                      '차감',
                      '- ${_won(quote.deduction)}',
                      valueColor: AppColors.error600,
                    ),
                  ],
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  _refundRow(
                    '환불 금액',
                    _won(quote.refundAmount),
                    labelBold: true,
                    valueColor: AppColors.primary600,
                    valueLarge: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '· 희망일 2일 전까지: 전액\n'
              '· 1일 전~당일: 10,000원 차감\n'
              '· 희망 시간 1시간 전부터: 환불 불가',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '환불 사유 (선택)',
                hintText: '예: 일정 취소',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('닫기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error500),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('환불하기'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final reason = reasonCtrl.text.trim();
    final result =
        await provider.refundCleaning(reason: reason.isEmpty ? null : reason);
    if (!mounted) return;
    if (result != null) {
      final msg = result.deduction > 0
          ? '청소 결제가 환불되었습니다. (${_won(result.deduction)} 차감 후 ${_won(result.refundAmount)} 환불)'
          : '청소 결제가 전액 환불되었습니다. (${_won(result.refundAmount)})';
      CustomToast.success(context, msg);
      final updated = provider.moveInCase;
      if (updated != null) _syncListProvider(updated);
    } else {
      _showProviderError();
    }
  }

  String _won(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }

  /// 환불 다이얼로그 영수증 행 (라벨 좌, 금액 우)
  Widget _refundRow(
    String label,
    String value, {
    bool labelBold = false,
    Color? valueColor,
    bool valueLarge = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: labelBold ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: (valueLarge ? AppTextStyles.headingSmall : AppTextStyles.bodyMedium)
              .copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _onPayCleaning() async {
    if (_isPaying) return;
    final detailProvider = context.read<MoveInDetailProvider>();
    final c = detailProvider.moveInCase;
    if (c == null) return;

    if (!c.canPayCleaning) {
      CustomToast.warning(
        context,
        c.isCleaningDeadlinePassed
            ? '결제 마감 기한이 지나 청소 결제를 진행할 수 없습니다.'
            : '지금은 결제할 수 없는 상태입니다. 청소 신청 상태와 청소용품 구비 여부를 확인해주세요.',
      );
      return;
    }

    setState(() => _isPaying = true);
    try {
      // 1단계: 견적 조회 + 사용자 확인
      final CleaningQuoteResponse quote;
      try {
        quote = await _paymentController.requestQuote(c.id);
      } on MoveInException catch (e) {
        if (!mounted) return;
        CustomToast.error(context, e.message);
        return;
      }
      if (!mounted) return;

      final confirmed = await showCleaningQuoteDialog(
        context,
        moveInCase: c,
        quote: quote,
      );
      if (confirmed != true || !mounted) return;

      // 결제 수단 선택 (게스트 계약 결제와 동일 패턴)
      final selectedMethod = await showPaymentMethodModal(
        context,
        totalAmount: quote.cleaningFee,
      );
      if (selectedMethod == null || !mounted) return;

      // 2~4단계: PG init → SDK → confirm
      final result = await _paymentController.pay(
        moveInCase: c,
        payType: selectedMethod.value,
      );
      if (!mounted) return;

      switch (result.stage) {
        case CleaningPaymentStage.paid:
          final mockSuffix = result.mock ? ' (Mock)' : '';
          CustomToast.success(
            context,
            '청소 결제가 완료되었습니다. 청소 일정에 맞춰 서비스가 진행됩니다.$mockSuffix',
          );
          // 케이스 재조회로 cleaningStatus → PAID 동기화
          await detailProvider.load();
          if (!mounted) return;
          final updated = detailProvider.moveInCase;
          if (updated != null) _syncListProvider(updated);
          break;

        case CleaningPaymentStage.confirmFailed:
          CustomToast.error(
            context,
            '결제 승인 단계에서 실패했습니다. 잠시 후 다시 시도해주세요.\n${result.errorMessage ?? ''}',
          );
          await detailProvider.load();
          break;

        case CleaningPaymentStage.pgFailed:
          CustomToast.error(
            context,
            '청소 결제가 완료되지 않았습니다. 다시 결제를 진행해주세요.\n${result.errorMessage ?? ''}',
          );
          break;

        case CleaningPaymentStage.cancelledBeforePg:
          // 사용자 취소 — 토스트 생략
          break;
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  Future<void> _onSendPaymentRequest() async {
    final provider = context.read<MoveInDetailProvider>();
    final result = await provider.sendPaymentRequest();
    if (!mounted) return;
    if (result == null) {
      _showProviderError();
      return;
    }
    _showSendResultToast(result, fallback: '임차인에게 결제 요청을 발송했습니다.');
    if (provider.moveInCase != null) _syncListProvider(provider.moveInCase!);
  }

  Future<void> _onResendPaymentRequest() async {
    final provider = context.read<MoveInDetailProvider>();
    final result = await provider.resendPaymentRequest();
    if (!mounted) return;
    if (result == null) {
      _showProviderError();
      return;
    }
    _showSendResultToast(result, fallback: '결제 요청을 재발송했습니다.');
    if (provider.moveInCase != null) _syncListProvider(provider.moveInCase!);
  }

  /// send/resend 응답 토스트.
  ///
  /// `_note`가 있으면 알림톡 미연동 운영 단계 — warning 톤으로 안내 + 섹션에 배너 보존.
  void _showSendResultToast(PaymentRequestSendResponse result, {required String fallback}) {
    final note = result.note;
    if (note != null && note.isNotEmpty) {
      setState(() => _devNote = note);
      CustomToast.warning(
        context,
        '$fallback\n(개발 모드: $note)',
      );
    } else {
      // note가 없는 정식 응답 → 이전에 표시되던 배너는 제거
      if (_devNote != null) setState(() => _devNote = null);
      CustomToast.success(context, fallback);
    }
  }

  Future<void> _onCopyPaymentLink() async {
    final provider = context.read<MoveInDetailProvider>();
    final result = await provider.getPaymentRequestLink();
    if (!mounted) return;
    if (result == null) {
      _showProviderError();
      return;
    }
    if (result.paymentLink.isEmpty) {
      CustomToast.warning(context, '결제 링크가 비어 있습니다.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: result.paymentLink));
    if (!mounted) return;
    CustomToast.success(context, '결제 링크가 복사되었습니다.');
  }

  // ============================================================
  // 헬퍼
  // ============================================================

  void _syncListProvider(MoveInCase updated) {
    context.read<MoveInListProvider>().replaceCase(updated);
  }

  void _showProviderError() {
    final error = context.read<MoveInDetailProvider>().error;
    if (error != null) {
      CustomToast.error(context, error.message);
    }
  }
}
