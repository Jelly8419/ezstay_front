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
  int? _minPrice;
  int? _maxPrice;

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

            // 안내 섹션
            _buildFeaturesSection(isMobile: true),

            // STEP 가이드 섹션
            _buildStepGuideSection(isMobile: true),

            // 🔥 안전한 이유 섹션
            _buildSafetySection(isMobile: true),

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

            // 안내 섹션
            _buildFeaturesSection(isMobile: false),

            // STEP 가이드 섹션
            _buildStepGuideSection(isMobile: false),

            // 🔥 안전한 이유 섹션
            _buildSafetySection(isMobile: false),

            // CTA 섹션
            _buildCTASection(isMobile: true),

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

                      // 안내 섹션
                      WebContainer(
                        child: _buildFeaturesSection(isMobile: false),
                      ),

                      // STEP 가이드 섹션
                      WebContainer(
                        child: _buildStepGuideSection(isMobile: false),
                      ),

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
            AppColors.primary50,
            AppColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
          vertical: AppSpacing.xl * 2,
        ),
        child: Column(
          children: [
            // 헤드라인
            Text(
              '이지스테이에서 편하고 안전한\n단기임대를 시작해보세요',
              style: isMobile
                  ? AppTextStyles.headingLarge.copyWith(fontSize: 28)
                  : AppTextStyles.displayLarge,
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

            SizedBox(height: AppSpacing.xl),

            // 서울 전용 서비스 배너
            _buildSeoulBanner(isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  // ==================== 서울 전용 서비스 배너 ====================
  Widget _buildSeoulBanner({required bool isMobile}) {
    return Container(
      constraints: BoxConstraints(maxWidth: 900),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
        vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0), // warning50 대체
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: Color(0xFFFFE0B2), // warning300 대체
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Color(0xFFFFECB3), // warning100 대체
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.location_city,
              color: Color(0xFFF57C00), // warning700 대체
              size: isMobile ? 20 : 24,
            ),
          ),

          SizedBox(width: AppSpacing.md),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 서울 지역만 서비스 중입니다',
                  style: (isMobile
                          ? AppTextStyles.labelMedium
                          : AppTextStyles.labelLarge)
                      .copyWith(
                    color: Color(0xFFE65100), // warning900 대체
                  ),
                ),
                if (!isMobile) ...[
                  SizedBox(height: 2),
                  Text(
                    '빠른 시일 내에 전국으로 확대할 예정입니다',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFFF57C00), // warning700 대체
                    ),
                  ),
                ],
              ],
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
        SizedBox(height: AppSpacing.md),

        // 금액 설정
        _buildPriceInput(),
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
        Expanded(
          flex: 2,
          child: _buildDateInput(),
        ),
        SizedBox(width: AppSpacing.md),

        // 금액 설정
        Expanded(
          flex: 2,
          child: _buildPriceInput(),
        ),
        SizedBox(width: AppSpacing.md),

        // 검색 버튼
        SizedBox(
          width: 120,
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
          color: AppColors.surface,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: hasDate ? AppColors.primary500 : AppColors.border,
            width: hasDate ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
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
                  color: hasDate ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // 금액 입력 필드
  Widget _buildPriceInput() {
    final hasPrice = _minPrice != null || _maxPrice != null;

    return InkWell(
      onTap: _showPriceRangeDialog,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: hasPrice ? AppColors.primary500 : AppColors.border,
            width: hasPrice ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: hasPrice ? AppColors.primary600 : AppColors.textSecondary,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hasPrice
                    ? '₩${_formatPrice(_minPrice)} - ₩${_formatPrice(_maxPrice)}'
                    : '금액을 설정하세요',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasPrice ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
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
                              color: AppColors.neutral0.withOpacity(0.9),
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
                          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
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
                          withinRangeTextStyle: TextStyle(color: AppColors.textPrimary),
                          outsideDaysVisible: false,
                        ),
                        onDaySelected: (selectedDay, focused) {
                          setDialogState(() {
                            focusedDay = focused;

                            // 첫 번째 선택 (체크인)
                            if (rangeStart == null || (rangeStart != null && rangeEnd != null)) {
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
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: rangeStart != null && rangeEnd != null
                          ? Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.success50,
                                borderRadius: AppRadius.radiusSm,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 18, color: AppColors.success600),
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
                                  Icon(Icons.info_outline, size: 18, color: AppColors.primary600),
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

  // ==================== 금액 범위 다이얼로그 ====================
  Future<void> _showPriceRangeDialog() async {
    final minController = TextEditingController(
      text: _minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('금액 범위 설정', style: AppTextStyles.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '일일 임대료 기준',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '최소 금액 (원/일)',
                  hintText: '예: 50000',
                  prefixText: '₩ ',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '최대 금액 (원/일)',
                  hintText: '예: 200000',
                  prefixText: '₩ ',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            AppTextButton(
              text: '초기화',
              onPressed: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                });
                Navigator.of(dialogContext).pop();
              },
            ),
            AppTextButton(
              text: '취소',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppPrimaryButton(
              text: '확인',
              onPressed: () {
                final minValue = int.tryParse(minController.text);
                final maxValue = int.tryParse(maxController.text);

                if (minValue != null && maxValue != null && minValue > maxValue) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('최소 금액이 최대 금액보다 클 수 없습니다.'),
                      backgroundColor: AppColors.error500,
                    ),
                  );
                  return;
                }

                setState(() {
                  _minPrice = minValue;
                  _maxPrice = maxValue;
                });
                Navigator.of(dialogContext).pop();
              },
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }

  // ==================== 안내 섹션 ====================
  Widget _buildFeaturesSection({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
        vertical: AppSpacing.xl * 2,
      ),
      child: isMobile
          ? Column(
              children: [
                _buildFeatureCard(
                  icon: Icons.account_balance_wallet,
                  title: '보증금은 이지스테이가 안전하게 보관하며,',
                  subtitle: '계약 종료 후 즉시 반환됩니다.',
                ),
                SizedBox(height: AppSpacing.lg),
                _buildFeatureCard(
                  icon: Icons.local_shipping_outlined,
                  title: '계약 결제 시, 필요한 상품을 함께 구매하면',
                  subtitle: '입주할 방으로 배송해드려요',
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.account_balance_wallet,
                    title: '보증금은 이지스테이가 안전하게 보관하며,',
                    subtitle: '계약 종료 후 즉시 반환됩니다.',
                  ),
                ),
                SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.local_shipping_outlined,
                    title: '계약 결제 시, 필요한 상품을 함께 구매하면',
                    subtitle: '입주할 방으로 배송해드려요',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.primary600,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 가이드 섹션 ====================
  Widget _buildStepGuideSection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      color: AppColors.neutral50,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
        vertical: AppSpacing.xl * 2,
      ),
      child: isMobile
          ? Column(
              children: [
                _buildStepColumn(
                  title: '호스트',
                  steps: [
                    'STEP 1  방 등록하기',
                    'STEP 2  계약 승인',
                    'STEP 3  계약 정산 받기',
                  ],
                  color: AppColors.success500,
                ),
                SizedBox(height: AppSpacing.xl),
                _buildStepColumn(
                  title: '게스트',
                  steps: [
                    'STEP 1  방 검색하기',
                    'STEP 2  계약 요청하기',
                    'STEP 3  계약 결제하기',
                    'STEP 4  입주',
                  ],
                  color: AppColors.primary500,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildStepColumn(
                    title: '호스트',
                    steps: [
                      'STEP 1  방 등록하기',
                      'STEP 2  계약 승인',
                      'STEP 3  계약 정산 받기',
                    ],
                    color: AppColors.success500,
                  ),
                ),
                SizedBox(width: AppSpacing.xl * 2),
                Expanded(
                  child: _buildStepColumn(
                    title: '게스트',
                    steps: [
                      'STEP 1  방 검색하기',
                      'STEP 2  계약 요청하기',
                      'STEP 3  계약 결제하기',
                      'STEP 4  입주',
                    ],
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
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

  // ==================== CTA 섹션 ====================
  Widget _buildCTASection({required bool isMobile}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl * 2,
        vertical: AppSpacing.xl * 2,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.xl : AppSpacing.xl * 3,
        vertical: AppSpacing.xl * 3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary600,
            AppColors.primary700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '지금 바로 시작하세요',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.neutral0,
              fontSize: isMobile ? 24 : 32,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '이지스테이에서 쉽고 안전한 단기임대를 경험해보세요',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.neutral0.withValues(alpha: 0.9),
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
                backgroundColor: AppColors.neutral0,
                foregroundColor: AppColors.primary700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '숙소 찾기',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 2,
        ),
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
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // 제목
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              color: color,
            ),
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

  Widget _buildStepColumn({
    required String title,
    required List<String> steps,
    required Color color,
  }) {
    // 이모지 아이콘 정의 (게스트 vs 호스트)
    final emojis = title == '게스트'
        ? ['🔍', '📝', '💳', '🏠']  // 게스트: 검색, 계약, 결제, 입주
        : ['📋', '🤝', '💰'];       // 호스트: 등록, 승인, 정산

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headingLarge.copyWith(
            color: color,
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Progress Line과 Step 카드
        Stack(
          children: [
            // 🔥 Progress Line (수직 연결선)
            Positioned(
              left: 28,
              top: 40,
              bottom: 40,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),

            // Step 카드들
            Column(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final emoji = index < emojis.length ? emojis[index] : '✨';
                final isLast = index == steps.length - 1;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : AppSpacing.lg,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 Emoji 아이콘 (원형 배경)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),

                      // Step 텍스트
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                            horizontal: AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.radiusMd,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            step,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
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
            Text(
              '단기임대 숙소의 모든 것',
              style: AppTextStyles.bodySmallSecondary,
            ),
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
        child: Text(
          text,
          style: AppTextStyles.bodySmallSecondary,
        ),
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

    // 금액이 설정되었을 때만 전달
    if (_minPrice != null) {
      extra['minPrice'] = _minPrice;
    }
    if (_maxPrice != null) {
      extra['maxPrice'] = _maxPrice;
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
