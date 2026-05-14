import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/guest_move_in/guest_move_in.dart';
import '../../../services/guest_move_in_service.dart';
import '../../../services/guest_move_in_session_storage.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import 'widgets/guest_move_in_info_banner.dart';
import 'widgets/guest_move_in_option_card.dart';
import 'widgets/guest_move_in_room_header.dart';
import 'widgets/guest_move_in_summary_box.dart';

/// 비로그인 미리보기 페이지 — `/move-in/payment/:token`
///
/// 임대인이 발송한 알림톡/SMS 링크 진입 시 노출.
/// optionalAuth: 로그인 토큰이 있으면 phone 매칭 결과까지 포함.
class MoveInInvitePreviewPage extends StatefulWidget {
  final String token;

  const MoveInInvitePreviewPage({super.key, required this.token});

  @override
  State<MoveInInvitePreviewPage> createState() =>
      _MoveInInvitePreviewPageState();
}

class _MoveInInvitePreviewPageState extends State<MoveInInvitePreviewPage> {
  final _service = GuestMoveInService();

  bool _loading = true;
  GuestMoveInException? _error;
  GuestMoveInInvitePreview? _preview;

  /// optionId → quantity (선택된 옵션만)
  final Map<int, int> _selectedQuantities = {};

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
      final preview = await _service.getInvite(widget.token);
      if (!mounted) return;
      // sessionStorage에서 이전 선택 복원 (PRD 10.1)
      final restored = GuestMoveInSessionStorage.load(widget.token);
      _selectedQuantities.clear();
      for (final item in restored) {
        _selectedQuantities[item.optionId] = item.quantity;
      }
      setState(() {
        _preview = preview;
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

  void _toggleOption(GuestMoveInOption option, bool selected) {
    setState(() {
      if (selected) {
        _selectedQuantities[option.optionId] = 1;
      } else {
        _selectedQuantities.remove(option.optionId);
      }
    });
    _persistSelection();
  }

  void _changeQuantity(GuestMoveInOption option, int quantity) {
    setState(() {
      _selectedQuantities[option.optionId] = quantity;
    });
    _persistSelection();
  }

  void _persistSelection() {
    final items = _selectedQuantities.entries
        .map((e) => GuestSelectedItem(optionId: e.key, quantity: e.value))
        .toList();
    GuestMoveInSessionStorage.save(widget.token, items);
  }

  Future<void> _onPayPressed() async {
    final preview = _preview;
    if (preview == null) return;

    final eligibility = preview.paymentEligibility;

    // 비로그인: 로그인으로 이동 (returnUrl 첨부)
    if (!eligibility.loggedIn) {
      _persistSelection();
      final returnUrl =
          Uri.encodeComponent('/move-in/payment/${widget.token}');
      if (!mounted) return;
      context.go('/login?returnUrl=$returnUrl');
      return;
    }

    // 로그인 + 번호 불일치
    if (!eligibility.phoneMatched) {
      _showPhoneMismatchDialog();
      return;
    }

    // 결제 가능 — bind 후 결제 화면으로
    if (eligibility.canPay) {
      try {
        await _service.bindInvite(widget.token);
      } on GuestMoveInException {
        // bind 실패해도 결제 화면 진입은 허용 (서버에서 한 번 더 가드)
      }
      if (!mounted) return;
      context.go('/guest/move-in/requests/${preview.requestId}/payment');
    }
  }

  Future<void> _showPhoneMismatchDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('연락처가 일치하지 않습니다'),
        content: const Text(
          '임대인이 등록한 임차인 연락처와 현재 계정의 본인확인 연락처가 일치하지 않습니다.\n'
          '임대인에게 등록된 연락처를 확인해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/');
            },
            child: const Text('홈으로 이동'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ResponsivePageLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return ResponsivePageLayout(
        child: _ErrorView(error: error, onRetry: _load),
      );
    }

    final preview = _preview;
    if (preview == null) {
      return const ResponsivePageLayout(
        child: Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }

    return ResponsivePageLayout(
      child: _buildContent(preview),
    );
  }

  Widget _buildContent(GuestMoveInInvitePreview preview) {
    final eligibility = preview.paymentEligibility;
    final canSelect = preview.options.isNotEmpty;
    final hasSelection = _selectedQuantities.values.any((v) => v > 0);
    final ctaEnabled = !eligibility.loggedIn || hasSelection;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (preview.authRequired)
            GuestMoveInInfoBanner(
              message: '임대인이 입주 준비 서비스를 연결했습니다.\n'
                  '로그인 후 결제 시 준비 및 배송을 진행합니다.',
            ),
          SizedBox(height: AppSpacing.md),
          GuestMoveInRoomHeader(
            room: preview.room,
            checkInDate: preview.checkInDate,
            checkOutDate: preview.checkOutDate,
          ),
          SizedBox(height: AppSpacing.lg),
          GuestMoveInInfoBanner(
            message: '청소 서비스는 임대인(호스트)이 별도로 제공하는 서비스입니다.\n'
                '이 페이지에서는 입주용품·침구류만 선택하고 결제해주세요.',
          ),
          SizedBox(height: AppSpacing.lg),
          Text('옵션 선택', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.md),
          if (!canSelect)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                '선택할 수 있는 옵션이 없습니다.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: preview.options.map((option) {
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
              }).toList(),
            ),
          SizedBox(height: AppSpacing.lg),
          GuestMoveInSummaryBox(
            options: preview.options,
            selectedQuantities: _selectedQuantities,
          ),
          SizedBox(height: AppSpacing.lg),
          if (eligibility.loggedIn && !eligibility.phoneMatched)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: GuestMoveInInfoBanner(
                icon: Icons.warning_amber_outlined,
                message: '임대인이 등록한 임차인 연락처와 현재 계정의 본인확인 연락처가 '
                    '일치하지 않아 결제할 수 없습니다.',
              ),
            ),
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
              child: Text(
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
  final GuestMoveInException error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isExpired = error.isTokenExpired;
    final isInvalid = error.isTokenInvalid;
    final showRetry = !isExpired && !isInvalid;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpired || isInvalid
                  ? Icons.link_off
                  : Icons.error_outline,
              size: 56,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              error.message,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            if (showRetry)
              FilledButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              )
            else
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('홈으로 이동'),
              ),
          ],
        ),
      ),
    );
  }
}
