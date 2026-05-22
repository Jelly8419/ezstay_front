import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 입주 준비 서비스 홈 — 빈 상태 / 로딩 / 에러 화면
class MoveInLoadingPlaceholder extends StatelessWidget {
  /// 표시할 스켈레톤 행 수
  final int rowCount;
  const MoveInLoadingPlaceholder({super.key, this.rowCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rowCount, (i) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: AppRadius.radiusMd,
          ),
        ),
      )),
    );
  }
}

class MoveInEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onCreateNew;
  final VoidCallback onClearFilters;

  const MoveInEmptyState({
    super.key,
    required this.hasFilters,
    required this.onCreateNew,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.cleaning_services_outlined, size: 56, color: AppColors.textDisabled),
          SizedBox(height: AppSpacing.md),
          Text(
            hasFilters ? '조건에 맞는 등록이 없습니다.' : '아직 등록된 입주 준비 건이 없습니다.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            hasFilters
                ? '필터를 초기화하거나 새 등록을 추가하세요.'
                : '외부 플랫폼 계약 1건을 등록해 청소·임차인 옵션 결제를 관리해보세요.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('필터 초기화'),
            )
          else
            FilledButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add),
              label: const Text('새 입주 준비 등록'),
            ),
        ],
      ),
    );
  }
}

class MoveInErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MoveInErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            '목록을 불러오지 못했습니다.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error700),
          ),
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

/// 페이지네이션 — 단순 [< 1 2 3 >] 형태
class MoveInPaginator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const MoveInPaginator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _calcVisiblePages();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navButton(
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        SizedBox(width: AppSpacing.xs),
        for (final p in pages) ...[
          if (p == -1)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('…', style: AppTextStyles.bodyMedium),
            )
          else
            _pageButton(p),
          SizedBox(width: AppSpacing.xs),
        ],
        _navButton(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }

  /// 현재 페이지 주변 5개 + 처음/끝 + 생략(…) 표시 — `-1` = 생략
  List<int> _calcVisiblePages() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int>{1, totalPages, currentPage};
    pages.addAll([currentPage - 1, currentPage + 1].where((p) => p > 0 && p <= totalPages));
    final sorted = pages.toList()..sort();
    final result = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(-1);
      result.add(sorted[i]);
    }
    return result;
  }

  Widget _pageButton(int page) {
    final isActive = page == currentPage;
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: isActive ? AppColors.primary500 : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: isActive ? AppColors.primary500 : AppColors.border),
        ),
        child: InkWell(
          onTap: isActive ? null : () => onPageChanged(page),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Center(
            child: Text(
              '$page',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
