import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../features/web/web_layout.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/chat_sidebar_widget.dart';
import '../../providers/chat_provider.dart';

/// 게스트 홈 페이지 - 심플하고 모던한 랜딩 페이지
class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final ScrollController _scrollController = ScrollController();
  late final AnalyticsService _analytics;

  // 검색 필터 상태
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  @override
  void initState() {
    super.initState();
    // Firebase 초기화 후 Analytics 사용
    _analytics = AnalyticsService();
    // 🔥 게스트 홈 화면 진입 이벤트 기록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logHomeViewGuest();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return ResponsiveLayout(
          mobile: _buildMobileLayout(authService),
          tablet: _buildTabletLayout(authService),
          desktop: _buildDesktopLayout(authService),
        );
      },
    );
  }

  // ==================== 모바일 레이아웃 ====================
  Widget _buildMobileLayout(AuthService authService) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGNB(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 히어로 섹션
            _buildHeroSection(isMobile: true),

            // 서울 전용 서비스 배너
            _buildSeoulBanner(isMobile: true),

            // STEP 가이드 섹션
            _buildStepGuideSection(isMobile: true),

            // 배송 서비스 섹션
            _buildDeliverySection(isMobile: true),

            // 🔥 안전한 이유 섹션
            _buildSafetySection(isMobile: true),

            // CTA 섹션
            _buildCTASection(isMobile: true),

            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ==================== 태블릿 레이아웃 ====================
  Widget _buildTabletLayout(AuthService authService) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGNB(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 히어로 섹션
            _buildHeroSection(isMobile: false),

            // 서울 전용 서비스 배너
            _buildSeoulBanner(isMobile: false),

            // STEP 가이드 섹션
            _buildStepGuideSection(isMobile: false),

            // 배송 서비스 섹션
            _buildDeliverySection(isMobile: false),

            // 🔥 안전한 이유 섹션
            _buildSafetySection(isMobile: false),

            // CTA 섹션
            _buildCTASection(isMobile: false),

            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ==================== 데스크톱 레이아웃 ====================
  Widget _buildDesktopLayout(AuthService authService) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGNB(),
      body: Column(
        children: [
          // 메인 컨텐츠
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // 히어로 섹션
                      _buildHeroSection(isMobile: false),

                      // 서울 전용 서비스 배너
                      _buildSeoulBanner(isMobile: false),

                      // STEP 가이드 섹션
                      WebContainer(
                        child: _buildStepGuideSection(isMobile: false),
                      ),

                      // 배송 서비스 섹션
                      _buildDeliverySection(isMobile: false),

                      // 안전한 이유 섹션
                      _buildSafetySection(isMobile: false),

                      // CTA 섹션
                      _buildCTASection(isMobile: false),

                      SizedBox(height: AppSpacing.xl * 2),

                      // 푸터
                      _buildFooter(),
                    ],
                  ),
                ),

                // 스크롤 탑 버튼
                ScrollToTopButton(scrollController: _scrollController),

                // 채팅 사이드바 (오버레이)
                const ChatSidebarWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 히어로 섹션 ====================
  Widget _buildHeroSection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary600, // Primary-600
            AppColors.primary700, // Primary-700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
          vertical: AppSpacing.xl * 2,
        ),
        child: Column(
          children: [
            // 서브 타이틀 (Blue-50) - 작은 글씨
            Text(
              '누구나 쉽고 안전하게 사용할 수 있어요',
              style:
                  (isMobile
                          ? AppTextStyles.bodyLarge
                          : AppTextStyles.headingLarge)
                      .copyWith(
                        color: AppColors.blue50,
                        fontWeight: FontWeight.w600,
                      ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSpacing.md),

            // 헤드라인 (흰색) - 큰 글씨
            Text(
              '가장 안전하고 쉬운 단기임대는 이지스테이',
              style:
                  (isMobile
                          ? AppTextStyles.headingLarge.copyWith(fontSize: 28)
                          : AppTextStyles.displayLarge)
                      .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSpacing.xl * 2),

            // 검색 입력
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 900),
              child: isMobile
                  ? _buildSearchInputsMobile()
                  : _buildSearchInputsDesktop(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 서울 전용 서비스 배너 (전체 너비) ====================
  Widget _buildSeoulBanner({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blue50, // Blue-50 배경
        border: Border(
          top: BorderSide(color: AppColors.blue100, width: 1),
          bottom: BorderSide(color: AppColors.blue100, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, color: AppColors.blue900, size: 20),
          SizedBox(width: AppSpacing.sm),
          Text(
            '현재 서울 지역만 서비스 중입니다',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.blue900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 검색 입력 (모바일 - 세로 배치)
  Widget _buildSearchInputsMobile() {
    return Column(
      children: [
        // 날짜 선택
        _buildDateInput(),
        SizedBox(height: AppSpacing.lg),

        // 검색 버튼
        SizedBox(
          width: double.infinity,
          height: 56,
          child: AppPrimaryButton(
            text: '검색',
            icon: Icons.search,
            onPressed: _handleSearch,
          ),
        ),
      ],
    );
  }

  // 검색 입력 (데스크톱 - 가로 배치)
  Widget _buildSearchInputsDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 선택
        Expanded(child: _buildDateInput()),
        SizedBox(width: AppSpacing.md),

        // 검색 버튼
        SizedBox(
          width: 160,
          height: 56,
          child: AppPrimaryButton(
            text: '검색',
            icon: Icons.search,
            onPressed: _handleSearch,
          ),
        ),
      ],
    );
  }

  // 날짜 입력 필드
  Widget _buildDateInput() {
    final hasDate = _checkInDate != null && _checkOutDate != null;

    return InkWell(
      onTap: _showDateSelectionDialog,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white, // 흰색 배경
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: hasDate ? AppColors.blue600 : AppColors.border,
            width: hasDate ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), // 강한 그림자
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: hasDate ? AppColors.primary600 : AppColors.textSecondary,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hasDate
                    ? '${DateFormat('MM.dd').format(_checkInDate!)} - ${DateFormat('MM.dd').format(_checkOutDate!)}'
                    : '날짜를 선택하세요',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasDate
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ==================== 날짜 선택 다이얼로그 ====================
  Future<void> _showDateSelectionDialog() async {
    DateTime? rangeStart = _checkInDate;
    DateTime? rangeEnd = _checkOutDate;
    DateTime focusedDay = _checkInDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.md),
                          topRight: Radius.circular(AppRadius.md),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '체크인/체크아웃 선택',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.neutral0,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            rangeStart != null && rangeEnd != null
                                ? '${DateFormat('MM.dd').format(rangeStart!)} - ${DateFormat('MM.dd').format(rangeEnd!)} (${rangeEnd!.difference(rangeStart!).inDays}일)'
                                : '날짜를 선택하세요 (최소 7일)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral0.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 달력
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(Duration(days: 365)),
                        focusedDay: focusedDay,
                        locale: 'ko_KR',
                        rangeSelectionMode: RangeSelectionMode.enforced,
                        rangeStartDay: rangeStart,
                        rangeEndDay: rangeEnd,
                        calendarFormat: CalendarFormat.month,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: AppTextStyles.headingSmall,
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: AppColors.textPrimary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: AppColors.primary500,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary200,
                            shape: BoxShape.circle,
                          ),
                          rangeStartDecoration: BoxDecoration(
                            color: AppColors.primary500,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: BoxDecoration(
                            color: AppColors.primary500,
                            shape: BoxShape.circle,
                          ),
                          rangeHighlightColor: AppColors.primary100,
                          withinRangeTextStyle: TextStyle(
                            color: AppColors.textPrimary,
                          ),
                          outsideDaysVisible: false,
                        ),
                        onDaySelected: (selectedDay, focused) {
                          setDialogState(() {
                            focusedDay = focused;

                            // 첫 번째 선택 (체크인)
                            if (rangeStart == null ||
                                (rangeStart != null && rangeEnd != null)) {
                              rangeStart = selectedDay;
                              rangeEnd = null;
                            }
                            // 두 번째 선택 (체크아웃)
                            else if (rangeStart != null && rangeEnd == null) {
                              // 체크아웃이 체크인보다 이전이면 체크인을 새로 선택한 날짜로
                              if (selectedDay.isBefore(rangeStart!)) {
                                rangeStart = selectedDay;
                                rangeEnd = null;
                              } else {
                                rangeEnd = selectedDay;
                              }
                            }
                          });
                        },
                        onRangeSelected: (start, end, focused) {
                          setDialogState(() {
                            focusedDay = focused;
                            rangeStart = start;
                            rangeEnd = end;
                          });
                        },
                        onPageChanged: (focused) {
                          focusedDay = focused;
                        },
                      ),
                    ),

                    // 안내 메시지
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: rangeStart != null && rangeEnd != null
                          ? Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.success50,
                                borderRadius: AppRadius.radiusSm,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppColors.success600,
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      '총 ${rangeEnd!.difference(rangeStart!).inDays}일 (${(rangeEnd!.difference(rangeStart!).inDays / 7).ceil()}주) 선택됨',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.success700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: AppRadius.radiusSm,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: AppColors.primary600,
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      rangeStart == null
                                          ? '체크인 날짜를 선택하세요'
                                          : '체크아웃 날짜를 선택하세요 (최소 7일 후)',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
              actions: [
                AppTextButton(
                  text: '취소',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                AppPrimaryButton(
                  text: '확인',
                  onPressed: rangeStart == null || rangeEnd == null
                      ? null
                      : () {
                          // 최소 7일 검증
                          final days = rangeEnd!.difference(rangeStart!).inDays;
                          if (days < 7) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('최소 계약 기간은 1주일(7일)입니다.'),
                                backgroundColor: AppColors.error500,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _checkInDate = rangeStart;
                            _checkOutDate = rangeEnd;
                          });

                          // 🔥 날짜 선택 완료 이벤트 기록
                          _analytics.logHomeSelectPeriod(
                            checkInDate: rangeStart!,
                            checkOutDate: rangeEnd!,
                          );

                          Navigator.of(dialogContext).pop();
                        },
                  fullWidth: false,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== STEP 가이드 섹션 (Grid 레이아웃) ====================
  Widget _buildStepGuideSection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
        vertical: AppSpacing.xl * 2,
      ),
      child: Column(
        children: [
          // 게스트 4-Step 가이드
          _buildStepGuideBlock(
            title: '게스트 이용 방법',
            subtitle: '예약부터 입주까지 간단하게',
            steps: [
              _StepInfo(
                emoji: '🔍',
                stepNumber: 1,
                title: '매물 검색',
                description: '임대기간, 임대료, 지역 등\n원하는 매물을 검색',
              ),
              _StepInfo(
                emoji: '📝',
                stepNumber: 2,
                title: '계약 요청',
                description: '마음에 드는 매물에\n계약을 요청',
              ),
              _StepInfo(
                emoji: '💳',
                stepNumber: 3,
                title: '계약 결제',
                description: '호스트 승인 후 필요한\n물품과 함께 결제',
              ),
              _StepInfo(
                emoji: '🏠',
                stepNumber: 4,
                title: '입주 및 퇴실',
                description: '안내를 받아 입주하고\n퇴실 후 자동으로 보증금 수령',
              ),
            ],
            isMobile: isMobile,
          ),

          SizedBox(height: AppSpacing.xl * 3),

          // 호스트 3-Step 가이드
          Container(
            padding: EdgeInsets.all(AppSpacing.xl * 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLg,
            ),
            child: _buildStepGuideBlock(
              title: '호스트 이용 방법',
              subtitle: '매물 등록부터 정산까지 간단하게',
              steps: [
                _StepInfo(
                  emoji: '📋',
                  stepNumber: 1,
                  title: '매물 등록',
                  description: '임대할 방 정보를 등록하고\n관리자 승인을 받으세요',
                ),
                _StepInfo(
                  emoji: '🤝',
                  stepNumber: 2,
                  title: '계약 관리',
                  description: '게스트 계약 요청을\n확인하고 승인하세요',
                ),
                _StepInfo(
                  emoji: '💰',
                  stepNumber: 3,
                  title: '정산',
                  description: '계약 완료 후\n정산금을 받으세요',
                ),
              ],
              isMobile: isMobile,
              isGreenTheme: true,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 가이드 블록 (제목 + Grid)
  Widget _buildStepGuideBlock({
    required String title,
    required String subtitle,
    required List<_StepInfo> steps,
    required bool isMobile,
    bool isGreenTheme = false,
  }) {
    return Column(
      children: [
        // 제목
        Text(
          title,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xl * 2),

        // Grid 레이아웃
        LayoutBuilder(
          builder: (context, constraints) {
            // 모바일: 2열, 데스크톱: 4열 (게스트) 또는 3열 (호스트)
            final crossAxisCount = isMobile ? 2 : steps.length;
            final childAspectRatio = isMobile ? 0.8 : 0.85;

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: isMobile ? AppSpacing.md : AppSpacing.lg,
                mainAxisSpacing: isMobile ? AppSpacing.md : AppSpacing.lg,
              ),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return _buildStepCard(
                  emoji: steps[index].emoji,
                  stepNumber: steps[index].stepNumber,
                  title: steps[index].title,
                  description: steps[index].description,
                  isMobile: isMobile,
                  isGreenTheme: isGreenTheme,
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Step 카드 (세로 중앙 정렬 - React 스타일)
  Widget _buildStepCard({
    required String emoji,
    required int stepNumber,
    required String title,
    required String description,
    required bool isMobile,
    bool isGreenTheme = false,
  }) {
    final gradientColors = isGreenTheme
        ? [AppColors.green500, AppColors.green600]
        : [AppColors.primary500, AppColors.primary600];
    final shadowColor = isGreenTheme ? AppColors.green500 : AppColors.primary500;
    final badgeColor = isGreenTheme ? AppColors.green100 : AppColors.primary100;
    final badgeTextColor = isGreenTheme
        ? AppColors.green600
        : AppColors.primary600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Gradient Emoji Box
        Container(
          width: isMobile ? 64 : 96,
          height: isMobile ? 64 : 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: isMobile ? 28 : 40)),
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // 2. STEP Label
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'STEP $stepNumber',
            style: AppTextStyles.labelSmall.copyWith(
              color: badgeTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // 3. Title
        Text(
          title,
          style: (isMobile ? AppTextStyles.bodyMedium : AppTextStyles.bodyLarge)
              .copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),

        // 4. Description
        Text(
          description,
          style: isMobile
              ? AppTextStyles.bodySmallSecondary
              : AppTextStyles.bodyMediumSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== 안전한 이유 섹션 ====================
  Widget _buildSafetySection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
        vertical: AppSpacing.xl * 2,
      ),
      color: AppColors.background,
      child: Column(
        children: [
          // 제목
          Text(
            '이지스테이가 안전한 이유',
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: isMobile ? 28 : 36,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '안심하고 거래할 수 있는 시스템을 제공합니다',
            style: AppTextStyles.bodyMediumSecondary,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl * 2),

          // 카드 그리드
          isMobile
              ? Column(
                  children: [
                    _buildSafetyCard(
                      icon: Icons.verified_user,
                      title: '안전한 결제 시스템',
                      description: '에스크로 방식으로 안전하게 결제하고, 계약 확정 후 정산이 진행됩니다.',
                      color: AppColors.primary500,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildSafetyCard(
                      icon: Icons.check_circle_outline,
                      title: '매물 검증',
                      description: '모든 매물은 검증 절차를 거쳐 등록되며, 허위 매물을 방지합니다.',
                      color: AppColors.success600,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildSafetyCard(
                      icon: Icons.description_outlined,
                      title: '투명한 계약',
                      description: '모든 계약 내용이 명확하게 기록되고, 분쟁 시 증빙 자료로 활용됩니다.',
                      color: AppColors.info600,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSafetyCard(
                        icon: Icons.verified_user,
                        title: '안전한 결제 시스템',
                        description: '에스크로 방식으로 안전하게 결제하고, 계약 확정 후 정산이 진행됩니다.',
                        color: AppColors.primary500,
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _buildSafetyCard(
                        icon: Icons.check_circle_outline,
                        title: '매물 검증',
                        description: '모든 매물은 검증 절차를 거쳐 등록되며, 허위 매물을 방지합니다.',
                        color: AppColors.success600,
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _buildSafetyCard(
                        icon: Icons.description_outlined,
                        title: '투명한 계약',
                        description: '모든 계약 내용이 명확하게 기록되고, 분쟁 시 증빙 자료로 활용됩니다.',
                        color: AppColors.info600,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ==================== 배송 서비스 섹션 (가로 배치 - React 스타일) ====================
  Widget _buildDeliverySection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
        vertical: AppSpacing.xl * 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple50, // Purple-50
            AppColors.blue50, // Blue-50
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          padding: EdgeInsets.all(isMobile ? AppSpacing.xl : AppSpacing.xl * 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  children: [
                    _buildDeliveryIcon(),
                    SizedBox(height: AppSpacing.xl),
                    _buildDeliveryContent(isMobile: true),
                  ],
                )
              : Row(
                  children: [
                    _buildDeliveryIcon(),
                    SizedBox(width: AppSpacing.xl * 2),
                    Expanded(child: _buildDeliveryContent(isMobile: false)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDeliveryIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        Icons.local_shipping_outlined,
        size: 48,
        color: AppColors.purple600,
      ),
    );
  }

  Widget _buildDeliveryContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          '입주 필수품 배송 서비스',
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          '계약 결제 시, 필요한 상품을 함께 구매하면\n입주할 방으로 배송해드려요',
          style: AppTextStyles.bodyLarge.copyWith(fontSize: isMobile ? 14 : 16),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          '생활용품, 침구류 등 입주에 필요한 물품을 이지스테이에서 준비할 수 있어요',
          style: AppTextStyles.bodyMediumSecondary,
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }

  // ==================== CTA 섹션 (React 스타일 - 강력한 전환 디자인) ====================
  Widget _buildCTASection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl * 4),
      decoration: BoxDecoration(
        color: AppColors.blue600, // Blue-600 단색 배경
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
          ),
          child: Column(
            children: [
              Text(
                '지금 바로 시작하세요',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                '이지스테이와 함께 안전하고 쉬운 단기임대를 경험하세요',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.blue100, // Blue-100
                  fontSize: isMobile ? 16 : 20,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl * 2),
              SizedBox(
                width: isMobile ? double.infinity : 280,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.blue600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '매물 검색하기',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: AppColors.blue600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 아이콘
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          SizedBox(height: AppSpacing.lg),

          // 제목
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),

          // 설명
          Text(
            description,
            style: AppTextStyles.bodyMediumSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== 푸터 ====================
  Widget _buildFooter() {
    return WebFooter(
      backgroundColor: AppColors.neutral100,
      children: [
        // 회사 정보
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EZStay', style: AppTextStyles.headingMedium),
            SizedBox(height: AppSpacing.sm),
            Text('단기임대 숙소의 모든 것', style: AppTextStyles.bodySmallSecondary),
          ],
        ),

        // 링크
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('서비스', style: AppTextStyles.labelMedium),
            SizedBox(height: AppSpacing.sm),
            _buildFooterLink('숙소 찾기'),
            _buildFooterLink('호스트 되기'),
            _buildFooterLink('계약 관리'),
          ],
        ),

        // 고객 지원
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('고객 지원', style: AppTextStyles.labelMedium),
            SizedBox(height: AppSpacing.sm),
            _buildFooterLink('자주 묻는 질문'),
            _buildFooterLink('이용약관'),
            _buildFooterLink('개인정보처리방침'),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: () {},
        child: Text(text, style: AppTextStyles.bodySmallSecondary),
      ),
    );
  }

  // ==================== 이벤트 핸들러 ====================
  void _handleSearch() {
    // 🔥 지도 검색 클릭 이벤트 기록
    final hasDateSelected = _checkInDate != null && _checkOutDate != null;
    _analytics.logHomeGoMap(hasDateSelected: hasDateSelected);

    // /map으로 이동 (필터 파라미터 포함 - 선택사항)
    final extra = <String, dynamic>{};

    // 날짜가 선택되었을 때만 전달
    if (_checkInDate != null && _checkOutDate != null) {
      extra['checkInDate'] = _checkInDate;
      extra['checkOutDate'] = _checkOutDate;
    }

    context.go('/map', extra: extra.isNotEmpty ? extra : null);
  }

  // ==================== 유틸리티 ====================
  String _formatPrice(int? price) {
    if (price == null) return '미설정';
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }
}

// ==================== Step Info 모델 ====================
class _StepInfo {
  final String emoji;
  final int stepNumber;
  final String title;
  final String description;

  _StepInfo({
    required this.emoji,
    required this.stepNumber,
    required this.title,
    required this.description,
  });
}
