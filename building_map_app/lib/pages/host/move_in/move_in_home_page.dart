import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/move_in/move_in.dart';
import '../../../providers/move_in/move_in_list_provider.dart';
import '../../../utils/responsive_util.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import 'widgets/move_in_case_list.dart';
import 'widgets/move_in_empty_states.dart';
import 'widgets/move_in_summary_cards.dart';

/// 입주 준비 서비스 홈 (호스트) — 이미지 ① 화면
///
/// `MoveInListProvider`(글로벌)를 watch — 첫 진입 시 [load] 자동 호출.
/// 다른 화면에서 돌아왔을 때는 캐시된 목록 즉시 표시 + 필요 시 사용자가 새로고침 버튼으로 갱신.
class MoveInHomePage extends StatefulWidget {
  const MoveInHomePage({super.key});

  @override
  State<MoveInHomePage> createState() => _MoveInHomePageState();
}

class _MoveInHomePageState extends State<MoveInHomePage> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MoveInListProvider>();
    _searchController = TextEditingController(text: provider.search);
    // 첫 진입 시 한 번 로드 — 이미 로드되어 있으면 갱신 없이 즉시 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!provider.hasLoadedOnce) provider.load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _goCreate() => context.go('/host/move-in/new');

  void _goDetail(MoveInCase c) => context.go('/host/move-in/${c.id}');

  /// 청소 결제 — 상세 페이지에서 결제 모달이 자동 오픈되도록 쿼리 파라미터 전달
  void _goPay(MoveInCase c) => context.go('/host/move-in/${c.id}?action=pay');

  MoveInSummaryFilter _currentFilter(MoveInListProvider p) {
    if (p.cleaningStatus == CleaningStatus.paymentPending) {
      return MoveInSummaryFilter.cleaningPending;
    }
    if (p.cleaningStatus == CleaningStatus.paid) {
      return MoveInSummaryFilter.cleaningPaid;
    }
    return MoveInSummaryFilter.all;
  }

  void _onSummarySelected(MoveInSummaryFilter filter) {
    final provider = context.read<MoveInListProvider>();
    switch (filter) {
      case MoveInSummaryFilter.all:
        provider.setFilters(
          requestStatus: null,
          cleaningStatus: null,
          search: provider.search,
        );
      case MoveInSummaryFilter.cleaningPending:
        provider.setFilters(
          requestStatus: null,
          cleaningStatus: CleaningStatus.paymentPending,
          search: provider.search,
        );
      case MoveInSummaryFilter.cleaningPaid:
        provider.setFilters(
          requestStatus: null,
          cleaningStatus: CleaningStatus.paid,
          search: provider.search,
        );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final provider = context.read<MoveInListProvider>();
      provider.setFilters(
        requestStatus: provider.requestStatus,
        cleaningStatus: provider.cleaningStatus,
        search: value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoveInListProvider>();
    final isMobile = ResponsiveUtil.isMobile(context);

    return ResponsivePageLayout(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, provider, isMobile),
            SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : 0,
              ),
              child: MoveInSummaryCards(
                counts: provider.counts,
                selected: _currentFilter(provider),
                onSelected: _onSummarySelected,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : 0,
              ),
              child: _buildSearchField(),
            ),
            SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : 0,
              ),
              child: _buildBody(context, provider),
            ),
            SizedBox(height: AppSpacing.lg),
            if (provider.hasLoadedOnce && provider.cases.isNotEmpty)
              MoveInPaginator(
                currentPage: provider.page,
                totalPages: provider.totalPages,
                onPageChanged: (p) =>
                    context.read<MoveInListProvider>().goToPage(p),
              ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: '방 이름, 주소, 임차인 이름 검색',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary500, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MoveInListProvider provider,
    bool isMobile,
  ) {
    final children = <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('입주 준비 서비스', style: AppTextStyles.headingLarge),
            SizedBox(height: AppSpacing.xs),
            Text(
              '외부에서 계약된 건을 위해 임대인이 청소를 신청하고, '
              '임차인은 필요한 입주용품을 직접 결제하도록 요청할 수 있어요.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      if (!isMobile) ...[
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '새로고침',
          onPressed: provider.isLoading ? null : () => provider.load(),
        ),
        SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: _goCreate,
          icon: const Icon(Icons.add),
          label: const Text('새 입주 준비 등록'),
        ),
      ],
    ];

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: children),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _goCreate,
                icon: const Icon(Icons.add),
                label: const Text('새 입주 준비 등록'),
              ),
            ),
          ],
        ),
      );
    }
    return Row(children: children);
  }

  Widget _buildBody(BuildContext context, MoveInListProvider provider) {
    if (!provider.hasLoadedOnce && provider.isLoading) {
      return const MoveInLoadingPlaceholder();
    }
    if (provider.error != null && provider.cases.isEmpty) {
      return MoveInErrorState(
        message: provider.error!.message,
        onRetry: () => provider.load(),
      );
    }
    if (provider.cases.isEmpty) {
      final hasFilters =
          provider.requestStatus != null ||
          provider.cleaningStatus != null ||
          provider.search.isNotEmpty;
      return MoveInEmptyState(
        hasFilters: hasFilters,
        onCreateNew: _goCreate,
        onClearFilters: () {
          _searchController.clear();
          provider.clearFilters();
        },
      );
    }
    return Stack(
      children: [
        MoveInCaseList(
          cases: provider.cases,
          onTapDetail: _goDetail,
          onTapPay: _goPay,
        ),
        if (provider.isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
