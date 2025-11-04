import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/app_buttons.dart';
import '../features/web/web_layout.dart';

/// 게스트 홈 페이지 - 심플하고 모던한 랜딩 페이지
class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final ScrollController _scrollController = ScrollController();

  // 검색 필터 상태
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int? _minPrice;
  int? _maxPrice;

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
      appBar: _buildMobileAppBar(authService),
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
      appBar: _buildDesktopAppBar(authService),
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
      body: Column(
        children: [
          // 네비게이션 바
          DesktopNavBar(
            logo: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, color: AppColors.primary600, size: 28),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'EZStay',
                  style: AppTextStyles.headingMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: _buildDesktopActions(authService),
          ),

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

                      SizedBox(height: AppSpacing.xl * 2),

                      // 푸터
                      _buildFooter(),
                    ],
                  ),
                ),

                // 스크롤 탑 버튼
                ScrollToTopButton(scrollController: _scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 앱바 ====================
  PreferredSizeWidget _buildMobileAppBar(AuthService authService) {
    return AppBar(
      title: Text('EZStay', style: AppTextStyles.headingMedium),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.person, color: AppColors.primary600),
          onPressed: () => _showUserMenu(context, authService),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(AuthService authService) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.home, color: AppColors.primary600),
          SizedBox(width: AppSpacing.sm),
          Text('EZStay', style: AppTextStyles.headingMedium),
        ],
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      actions: _buildDesktopActions(authService),
    );
  }

  List<Widget> _buildDesktopActions(AuthService authService) {
    // 로그인 안 된 상태
    if (!authService.isLoggedIn) {
      return [
        AppTextButton(
          text: '로그인',
          icon: Icons.login,
          onPressed: () => context.go('/login'),
        ),
        SizedBox(width: AppSpacing.sm),
        AppPrimaryButton(
          text: '회원가입',
          onPressed: () => context.go('/login'),
          fullWidth: false,
        ),
      ];
    }

    // 로그인된 상태
    return [
      AppTextButton(
        text: '계약 관리',
        icon: Icons.description_outlined,
        onPressed: () => context.go('/guest/contracts'),
      ),
      SizedBox(width: AppSpacing.sm),
      PopupMenuButton<String>(
        icon: Icon(Icons.account_circle, color: AppColors.primary600),
        onSelected: (value) {
          if (value == 'logout') {
            _handleLogout(context, authService);
          } else if (value == 'switch_to_host') {
            _switchToHostMode(context, authService);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'switch_to_host',
            child: Row(
              children: [
                Icon(Icons.home_work, color: AppColors.success500),
                SizedBox(width: AppSpacing.sm),
                Text('호스트 모드로 전환', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: AppColors.error500),
                SizedBox(width: AppSpacing.sm),
                Text('로그아웃', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ];
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
          ],
        ),
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
                  subtitle: '일주일 방으로 배송해드려요',
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
                    subtitle: '일주일 방으로 배송해드려요',
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

  Widget _buildStepColumn({
    required String title,
    required List<String> steps,
    required Color color,
  }) {
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
        ...steps.map((step) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    step,
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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

  void _showUserMenu(BuildContext context, AuthService authService) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.description_outlined, color: AppColors.primary600),
              title: Text('계약 관리', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                context.go('/guest/contracts');
              },
            ),
            ListTile(
              leading: Icon(Icons.home_work, color: AppColors.success500),
              title: Text('호스트 모드로 전환', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _switchToHostMode(context, authService);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error500),
              title: Text('로그아웃', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context, authService);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그아웃', style: AppTextStyles.headingSmall),
          content: Text('정말 로그아웃하시겠습니까?', style: AppTextStyles.bodyMedium),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          actions: [
            AppTextButton(
              text: '취소',
              onPressed: () => Navigator.pop(context),
            ),
            AppPrimaryButton(
              text: '로그아웃',
              onPressed: () {
                authService.logout();
                Navigator.pop(context);
              },
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }

  void _switchToHostMode(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('호스트 모드로 전환', style: AppTextStyles.headingSmall),
          content: Text(
            '호스트 모드로 전환하시겠습니까?\n숙소 등록 및 관리 기능을 사용할 수 있습니다.',
            style: AppTextStyles.bodyMedium,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          actions: [
            AppTextButton(
              text: '취소',
              onPressed: () => Navigator.pop(context),
            ),
            AppPrimaryButton(
              text: '전환하기',
              onPressed: () async {
                Navigator.pop(context); // 먼저 다이얼로그 닫기
                await authService.switchUserMode(UserMode.host); // 모드 변경
                if (context.mounted) {
                  context.go('/host'); // 호스트 홈으로 이동
                }
              },
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }

  // ==================== 유틸리티 ====================
  String _formatPrice(int? price) {
    if (price == null) return '미설정';
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }
}
