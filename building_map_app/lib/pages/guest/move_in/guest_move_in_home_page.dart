import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/guest_move_in/guest_move_in.dart';
import '../../../providers/guest_move_in/guest_move_in_list_provider.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import 'widgets/guest_move_in_info_banner.dart';
import 'widgets/guest_move_in_request_card.dart';

/// 게스트 입주 준비 서비스 목록 — `/guest/move-in`
///
/// 본인확인된 휴대폰 번호로 매칭된 케이스만 노출.
/// 백엔드의 자동 bind hook으로 가입/본인인증 시점에 자동 연결됨.
class GuestMoveInHomePage extends StatefulWidget {
  const GuestMoveInHomePage({super.key});

  @override
  State<GuestMoveInHomePage> createState() => _GuestMoveInHomePageState();
}

class _GuestMoveInHomePageState extends State<GuestMoveInHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 페이지 진입 시 항상 최신 목록 로드.
      // (결제 완료 후 메인으로 복귀해도 결제 대기 배지로 남는 문제 방지)
      context.read<GuestMoveInListProvider>().load();
    });
  }

  void _onCardTap(GuestMoveInRequestListItem item) {
    if (item.status == GuestMoveInStatus.pendingPayment && item.canPay) {
      context.go('/guest/move-in/requests/${item.requestId}/payment');
    } else {
      context.go('/guest/move-in/requests/${item.requestId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePageLayout(
      child: Consumer<GuestMoveInListProvider>(
        builder: (_, provider, __) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('내 입주 준비 서비스',
                          style: AppTextStyles.headingLarge),
                    ),
                    IconButton(
                      tooltip: '새로고침',
                      icon: const Icon(Icons.refresh),
                      onPressed: provider.isLoading ? null : provider.load,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '임대인이 연결한 입주 준비 요청을 확인하고 결제할 수 있어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                GuestMoveInInfoBanner(
                  message: '알림이나 문자/이메일로 받은 링크를 클릭해도 '
                      '바로 입주 준비 서비스 페이지로 이동할 수 있어요.',
                ),
                SizedBox(height: AppSpacing.lg),
                _StatusFilterTabs(
                  current: provider.statusFilter,
                  onChange: provider.setStatusFilter,
                ),
                SizedBox(height: AppSpacing.lg),
                if (provider.isLoading && !provider.hasLoadedOnce)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null)
                  _ErrorBlock(
                    message: provider.error!.message,
                    onRetry: provider.load,
                  )
                else if (provider.items.isEmpty)
                  const _EmptyBlock()
                else
                  Column(
                    children: provider.items
                        .map((item) => Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.sm),
                              child: GuestMoveInRequestCard(
                                item: item,
                                onTap: () => _onCardTap(item),
                              ),
                            ))
                        .toList(),
                  ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 상태 필터 탭 (전체 / 결제 대기 / 결제 완료 / 완료)
class _StatusFilterTabs extends StatelessWidget {
  final GuestMoveInStatus? current;
  final ValueChanged<GuestMoveInStatus?> onChange;

  const _StatusFilterTabs({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final entries = <(_TabKey, String)>[
      (_TabKey.all, '전체'),
      (_TabKey.pending, '결제 대기'),
      (_TabKey.paid, '결제 완료'),
      (_TabKey.completed, '완료'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.map((e) {
          final isActive = _isActive(e.$1);
          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(e.$2),
              selected: isActive,
              onSelected: (_) => onChange(_toStatus(e.$1)),
              selectedColor: AppColors.primary100,
              backgroundColor: AppColors.surface,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppColors.primary700 : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isActive ? AppColors.primary500 : AppColors.border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isActive(_TabKey key) {
    switch (key) {
      case _TabKey.all:
        return current == null;
      case _TabKey.pending:
        return current == GuestMoveInStatus.pendingPayment;
      case _TabKey.paid:
        return current == GuestMoveInStatus.paid;
      case _TabKey.completed:
        return current == GuestMoveInStatus.completed;
    }
  }

  GuestMoveInStatus? _toStatus(_TabKey key) {
    switch (key) {
      case _TabKey.all:
        return null;
      case _TabKey.pending:
        return GuestMoveInStatus.pendingPayment;
      case _TabKey.paid:
        return GuestMoveInStatus.paid;
      case _TabKey.completed:
        return GuestMoveInStatus.completed;
    }
  }
}

enum _TabKey { all, pending, paid, completed }

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '연결된 입주 준비 요청이 없습니다',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '임대인이 입주 준비 서비스를 요청하면 자동으로 연결돼요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error500),
            SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
