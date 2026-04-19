import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_buttons.dart';
import '../common/date_range_input.dart';
import 'home_section.dart';

/// 게스트 홈 히어로 섹션.
///
/// - 배경 그라데이션은 [HomeSection]을 통해 풀너비로 깔린다.
/// - 날짜 선택과 검색 버튼은 콜백 형태로 노출 — Analytics 이벤트 로깅을
///   외부(페이지) 쪽에서 주입할 수 있게 한다.
///
/// 사용 예시:
/// ```dart
/// HomeHero(
///   checkIn: _checkInDate,
///   checkOut: _checkOutDate,
///   onTapDate: () async {
///     _analytics.logHomeOpenDatePicker();
///     await _showDateDialog();
///   },
///   onSearch: () {
///     _analytics.logHomeGoMap(hasDateSelected: hasDate);
///     context.go('/map', extra: extra);
///   },
/// )
/// ```
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onTapDate,
    required this.onSearch,
    this.tagline = '누구나 쉽고 안전하게 사용할 수 있어요',
    this.headline = '단기임대를 편리하고 안전하게',
    this.brandWord = '이지스테이',
    this.notice,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;

  /// 날짜 입력창 탭 콜백. Analytics는 호출자에서 래핑.
  final VoidCallback onTapDate;

  /// 검색 버튼 클릭 콜백.
  final VoidCallback onSearch;

  final String tagline;
  final String headline;
  final String brandWord;

  /// 히어로 하단 안내 문구. null이면 표시 안 함.
  /// 지역 안내 띠를 별도 섹션으로 두는 경우 null로 지정.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    final headlineFontSize = AppTextStyles.responsiveFontSize(
      context,
      mobile: 28,
      desktop: 44,
    );
    final taglineStyle = isMobile
        ? AppTextStyles.bodyLarge
        : AppTextStyles.headingLarge;

    return HomeSection(
      maxWidth: AppSizes.contentMaxWidthWide,
      verticalScale: VerticalPaddingScale.lg,
      backgroundGradient: LinearGradient(
        colors: [AppColors.primary50, AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Text(
            tagline,
            style: taglineStyle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$headline\n'),
                TextSpan(
                  text: brandWord,
                  style: TextStyle(color: AppColors.primary500),
                ),
              ],
            ),
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: headlineFontSize,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl * 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: isMobile
                ? _buildSearchMobile(context)
                : _buildSearchDesktop(context),
          ),
          if (notice != null) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              notice!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchMobile(BuildContext context) {
    return Column(
      children: [
        DateRangeInput(
          checkIn: checkIn,
          checkOut: checkOut,
          onTap: onTapDate,
        ),
        SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: AppPrimaryButton(
            text: '검색',
            icon: Icons.search,
            onPressed: onSearch,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DateRangeInput(
            checkIn: checkIn,
            checkOut: checkOut,
            onTap: onTapDate,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 160,
          height: 56,
          child: AppPrimaryButton(
            text: '검색',
            icon: Icons.search,
            onPressed: onSearch,
          ),
        ),
      ],
    );
  }
}
