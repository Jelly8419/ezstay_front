import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../features/web/web_layout.dart';
import '../../widgets/common/app_footer.dart';

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
    return ColoredBox(
      color: AppColors.background,
      child: SingleChildScrollView(
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

            // 안전한 이유 섹션
            _buildSafetySection(isMobile: true),

            // CTA 섹션
            _buildCTASection(isMobile: true),

            const AppFooter(),
          ],
        ),
      ),
    );
  }

  // ==================== 태블릿 레이아웃 ====================
  Widget _buildTabletLayout(AuthService authService) {
    return ColoredBox(
      color: AppColors.background,
      child: SingleChildScrollView(
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

            // 안전한 이유 섹션
            _buildSafetySection(isMobile: false),

            // CTA 섹션
            _buildCTASection(isMobile: false),

            const AppFooter(),
          ],
        ),
      ),
    );
  }

  // ==================== 데스크톱 레이아웃 ====================
  Widget _buildDesktopLayout(AuthService authService) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
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

                      const AppFooter(),
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
  /// DateRangePicker 다이얼로그를 직접 호출하여 날짜 선택
  Future<void> _showDateSelectionDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => _GuestDateRangePickerDialog(
        initialCheckIn: _checkInDate,
        initialCheckOut: _checkOutDate,
        onDateRangeSelected: (checkIn, checkOut) {
          setState(() {
            _checkInDate = checkIn;
            _checkOutDate = checkOut;
          });

          // 🔥 날짜 선택 완료 이벤트 기록
          _analytics.logHomeSelectPeriod(
            checkInDate: checkIn,
            checkOutDate: checkOut,
          );
        },
        onDateCleared: () {
          setState(() {
            _checkInDate = null;
            _checkOutDate = null;
          });
        },
      ),
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
            final childAspectRatio = isMobile ? 0.75 : 0.8;

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
            child: Text(emoji, style: AppTextStyles.displayLarge.copyWith(fontSize: isMobile ? 28 : 40)),
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

// ==================== 게스트 날짜 선택 다이얼로그 ====================
/// 게스트 홈 검색용 날짜 범위 선택 다이얼로그
/// - minContractDays: 7일 (게스트 기본)
/// - maxContractDays: 90일 (게스트 기본)
class _GuestDateRangePickerDialog extends StatefulWidget {
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final void Function(DateTime checkIn, DateTime checkOut) onDateRangeSelected;
  final void Function()? onDateCleared;

  const _GuestDateRangePickerDialog({
    this.initialCheckIn,
    this.initialCheckOut,
    required this.onDateRangeSelected,
    this.onDateCleared,
  });

  @override
  State<_GuestDateRangePickerDialog> createState() =>
      _GuestDateRangePickerDialogState();
}

class _GuestDateRangePickerDialogState
    extends State<_GuestDateRangePickerDialog> {
  // 게스트 기본 설정
  static const int _minContractDays = 7;
  static const int _maxContractDays = 90;

  late DateTime _focusedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusedMonth = widget.initialCheckIn ?? DateTime.now();
    _rangeStart = widget.initialCheckIn;
    _rangeEnd = widget.initialCheckOut;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('임대 기간 선택', style: AppTextStyles.headingMedium),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // 월 네비게이션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.neutral100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Text(
                  '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.neutral100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 요일 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  ['일', '월', '화', '수', '목', '금', '토'].asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final day = entry.value;
                  return SizedBox(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: index == 0
                            ? AppColors.error500
                            : index == 6
                                ? AppColors.primary600
                                : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 8),

            // 날짜 그리드
            _buildDateGrid(),

            // 에러 메시지
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error50,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error500,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 선택된 기간 표시
            if (_rangeStart != null && _rangeEnd != null) ...[
              const Divider(height: 32),
              Column(
                children: [
                  Text(
                    '임대 기간',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_rangeEnd!.difference(_rangeStart!).inDays}일',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.primary600,
                    ),
                  ),
                ],
              ),
            ],

            // 안내 메시지 (시작일만 선택된 상태)
            if (_rangeStart != null && _rangeEnd == null) ...[
              const Divider(height: 32),
              Container(
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
                        '최소 $_minContractDays일 ~ 최대 $_maxContractDays일 선택 가능',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 안내 메시지 (아무것도 선택 안됨)
            if (_rangeStart == null) ...[
              const Divider(height: 32),
              Text(
                '• 최소 $_minContractDays일부터 선택 가능합니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 초기화 및 확인 버튼
            if (_rangeStart != null && _rangeEnd != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _rangeStart = null;
                          _rangeEnd = null;
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      child: Text(
                        '초기화',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDateRangeSelected(_rangeStart!, _rangeEnd!);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      child: Text('선택 완료', style: AppTextStyles.buttonText),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 날짜 그리드 생성
  Widget _buildDateGrid() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final List<DateTime?> dateList = [];

    // 앞쪽 빈칸
    for (int i = 0; i < firstWeekday; i++) {
      dateList.add(null);
    }

    // 실제 날짜
    for (int day = 1; day <= daysInMonth; day++) {
      dateList.add(DateTime(_focusedMonth.year, _focusedMonth.month, day));
    }

    // 6주(42칸) 맞추기
    while (dateList.length < 42) {
      dateList.add(null);
    }

    return Column(
      children: [
        ...List.generate(6, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final index = weekIndex * 7 + dayIndex;
                final date = dateList[index];

                if (date == null) {
                  return const SizedBox(width: 36, height: 36);
                }

                return _buildDateCell(date);
              }),
            ),
          );
        }),
      ],
    );
  }

  /// 날짜 셀 생성
  Widget _buildDateCell(DateTime date) {
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

    final isStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isInRange =
        _rangeStart != null &&
        _rangeEnd != null &&
        date.isAfter(_rangeStart!) &&
        date.isBefore(_rangeEnd!);

    // 최소 계약기간 범위 확인
    final isInMinRange = _isInMinContractRange(date);

    Color? backgroundColor;
    Color? textColor;
    FontWeight? fontWeight;

    if (isStart || isEnd) {
      backgroundColor = AppColors.primary600;
      textColor = AppColors.textOnPrimary;
      fontWeight = FontWeight.w600;
    } else if (isInRange) {
      backgroundColor = AppColors.primary50;
      textColor = AppColors.primary600;
      fontWeight = FontWeight.normal;
    } else if (isInMinRange) {
      // 최소 계약기간 범위: 회색 (선택 불가 표시)
      backgroundColor = AppColors.neutral100;
      textColor = AppColors.textDisabled;
      fontWeight = FontWeight.normal;
    } else if (isToday) {
      backgroundColor = AppColors.primary50.withValues(alpha: 0.5);
      textColor = AppColors.primary600;
      fontWeight = FontWeight.w600;
    } else if (isPast) {
      textColor = AppColors.textDisabled;
      fontWeight = FontWeight.normal;
    } else {
      textColor = AppColors.textPrimary;
      fontWeight = FontWeight.normal;
    }

    return InkWell(
      onTap: isPast ? null : () => _onDateSelected(date),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${date.day}',
          style: AppTextStyles.caption.copyWith(
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// 최소 계약기간 범위 내인지 확인
  bool _isInMinContractRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd != null) return false;
    if (_isSameDay(date, _rangeStart!)) return false;

    final minEndDate = _rangeStart!.add(Duration(days: _minContractDays - 1));

    return date.isAfter(_rangeStart!) &&
        (date.isBefore(minEndDate) || _isSameDay(date, minEndDate));
  }

  /// 날짜 선택 핸들러
  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _errorMessage = null;

      // 1. 시작일만 선택된 상태에서 같은 날짜 클릭 → 선택 해제
      if (_rangeStart != null &&
          _rangeEnd == null &&
          _isSameDay(selectedDate, _rangeStart!)) {
        _rangeStart = null;
        _rangeEnd = null;
        widget.onDateCleared?.call();
        return;
      }

      // 2. 시작일만 선택된 상태 → 종료일 선택
      if (_rangeStart != null && _rangeEnd == null) {
        final DateTime earlierDate;
        final DateTime laterDate;

        if (selectedDate.isBefore(_rangeStart!)) {
          earlierDate = _normalizeDate(selectedDate);
          laterDate = _normalizeDate(_rangeStart!);
        } else {
          earlierDate = _normalizeDate(_rangeStart!);
          laterDate = _normalizeDate(selectedDate);
        }

        final duration = laterDate.difference(earlierDate).inDays;

        if (duration < _minContractDays) {
          _errorMessage = '최소 $_minContractDays일 이상 선택해주세요';
          return;
        }

        if (duration > _maxContractDays) {
          _errorMessage = '최대 $_maxContractDays일까지 선택 가능합니다';
          return;
        }

        _rangeStart = earlierDate;
        _rangeEnd = laterDate;
      }
      // 3. 범위가 이미 선택된 상태 → 초기화 후 새 시작일 설정
      else if (_rangeStart != null && _rangeEnd != null) {
        _rangeStart = _normalizeDate(selectedDate);
        _rangeEnd = null;
      }
      // 4. 아무것도 선택되지 않은 상태 → 시작일 설정
      else {
        _rangeStart = _normalizeDate(selectedDate);
        _rangeEnd = null;
      }
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
