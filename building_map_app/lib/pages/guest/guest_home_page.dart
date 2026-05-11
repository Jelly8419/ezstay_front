import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../models/user.dart';
import '../../providers/promotion_provider.dart';
import '../../services/region_alert_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/custom_toast.dart';
import '../../widgets/common/guest_date_range_picker_dialog.dart';
import '../../widgets/home/cta_button.dart';
import '../../widgets/home/home_hero.dart';
import '../../widgets/home/home_section.dart';
import '../../widgets/home/info_card.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/step_card.dart';
import '../../widgets/home/step_guide_grid.dart';
import '../../widgets/modals/region_alert_modal.dart';
import '../../widgets/modals/opening_event_modal.dart';
import '../../features/web/web_layout.dart';
import '../../widgets/common/app_footer.dart';
import '../../core/utils/seo_helper.dart';
import '../../utils/responsive_util.dart' as responsive;

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

  // 오픈 전 배너 노출 여부 (세션당 1회 — localStorage 기반)
  bool _showOpeningBanner = false;

  @override
  void initState() {
    super.initState();
    // Firebase 초기화 후 Analytics 사용
    _analytics = AnalyticsService();
    // 🔥 게스트 홈 화면 진입 이벤트 기록
    _initOpeningBanner();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _analytics.logHomeViewGuest();
      SeoHelper.updatePage(
        title: '이지스테이(EZstay) ― 서울 단기임대 5월 오픈 · 선착순 100명 2만원 할인',
        description:
            '서울 단기임대 플랫폼 이지스테이(EZstay) 5월 오픈. 사전등록 선착순 100명 첫 계약 2만원 할인. 1주~90일 서울 전역 단기 계약 가능한 원룸·오피스텔·아파트.',
        canonicalPath: '/',
      );

      // 정적 랜딩에서 `?action=` 쿼리로 진입한 경우 즉시 해당 플로우 실행
      final action = Uri.base.queryParameters['action'];
      if (action == 'host-register' && mounted) {
        final authService = context.read<AuthService>();
        _handleHostRedirect(authService);
        return;
      }

      // 프로모션 이벤트 로드 완료 후에만 모달 노출 (이벤트 없으면 미노출)
      final promotion = context.read<PromotionProvider>();
      await promotion.loadActivePromotions();
      if (!mounted) return;
      if (promotion.guestEvent == null && promotion.hostEvent == null) return;
      final authService = context.read<AuthService>();

      // `?action=alert`면 24시간 숨김 무시하고 강제 오픈
      if (action == 'alert') {
        OpeningEventModal.forceShow(
          context,
          onAlertRequest: () => _handleAlertRequest(authService),
          onHostRedirect: () => _handleHostRedirect(authService),
        );
      } else {
        OpeningEventModal.maybeShow(
          context,
          onAlertRequest: () => _handleAlertRequest(authService),
          onHostRedirect: () => _handleHostRedirect(authService),
        );
      }
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
            // 오픈 전 배너
            _buildOpeningBanner(authService),
            const SizedBox(height: 50),
            // 입주 준비 서비스 진입 섹션 (이미 계약한 사용자용)
            _buildMoveInPromoSection(authService),
            // 히어로 섹션
            _buildHero(),

            // STEP 가이드 섹션 (임차인 + 임대인)
            _buildGuestStepSection(),
            _buildHostStepSection(),

            // 배송 서비스 섹션
            _buildDeliverySection(),

            // 안전한 이유 섹션
            _buildSafetySection(),

            // CTA 섹션
            _buildCTASection(),

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
            // 오픈 전 배너
            _buildOpeningBanner(authService),
            // 입주 준비 서비스 진입 섹션 (이미 계약한 사용자용)
            _buildMoveInPromoSection(authService),
            // 히어로 섹션
            _buildHero(),

            // STEP 가이드 섹션 (임차인 + 임대인)
            _buildGuestStepSection(),
            _buildHostStepSection(),

            // 배송 서비스 섹션
            _buildDeliverySection(),

            // 안전한 이유 섹션
            _buildSafetySection(),

            // CTA 섹션
            _buildCTASection(),

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
                      // 오픈 전 배너
                      _buildOpeningBanner(authService),
                      // 입주 준비 서비스 진입 섹션 (이미 계약한 사용자용)
                      _buildMoveInPromoSection(authService),
                      // 히어로 섹션
                      _buildHero(),

                      // STEP 가이드 섹션 (임차인 + 임대인)
                      _buildGuestStepSection(),
                      _buildMoveInEntrySection(),
                      _buildHostStepSection(),

                      // 배송 서비스 섹션
                      _buildDeliverySection(),

                      // 안전한 이유 섹션
                      _buildSafetySection(),

                      // CTA 섹션
                      _buildCTASection(),

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
  Widget _buildHero() {
    return HomeHero(
      checkIn: _checkInDate,
      checkOut: _checkOutDate,
      onTapDate: _showDateSelectionDialog,
      onSearch: _handleSearch,
      trustPoints: const ['에스크로 안심 결제', '100% 방 검증', '안전한 계약 프로세스'],
      notice: '현재 서울 지역만 서비스 중입니다',
    );
  }

  // ==================== 날짜 선택 다이얼로그 ====================
  /// DateRangePicker 다이얼로그를 직접 호출하여 날짜 선택
  Future<void> _showDateSelectionDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => GuestDateRangePickerDialog(
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

  // ==================== 임차인 STEP 가이드 섹션 ====================
  Widget _buildGuestStepSection() {
    return HomeSection(
      backgroundColor: AppColors.background,
      verticalScale: VerticalPaddingScale.md,
      child: Column(
        children: [
          const SectionHeader(title: '임차인 이용 방법', subtitle: '예약부터 입주까지 간단하게'),
          SizedBox(height: AppSpacing.xl),
          const StepGuideGrid(
            steps: [
              StepCard(
                icon: LucideIcons.search,
                stepNumber: '01',
                title: '방 검색',
                description: '임대기간, 임대료, 지역 등\n원하는 방을 검색',
                variant: StepCardVariant.guest,
              ),
              StepCard(
                icon: LucideIcons.fileText,
                stepNumber: '02',
                title: '계약 요청',
                description: '마음에 드는 방에\n계약을 요청',
                variant: StepCardVariant.guest,
              ),
              StepCard(
                icon: LucideIcons.creditCard,
                stepNumber: '03',
                title: '계약 결제',
                description: '임대인 승인 후 필요한\n물품과 함께 결제',
                variant: StepCardVariant.guest,
              ),
              StepCard(
                icon: LucideIcons.home,
                stepNumber: '04',
                title: '입주 및 퇴실',
                description: '안내를 받아 입주하고\n퇴실 후 자동으로 보증금 수령',
                variant: StepCardVariant.guest,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 입주 준비 서비스 프로모 섹션 (이미 계약한 사용자 대상) ====================
  Widget _buildMoveInPromoSection(AuthService authService) {
    return HomeSection(
      backgroundColor: AppColors.background,
      maxWidth: AppSizes.contentMaxWidthWide,
      verticalScale: VerticalPaddingScale.sm,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.cardDefault,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = AppBreakpoints.isDesktop(context);
            if (isDesktop) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildMoveInPromoIntro(authService),
                      ),
                      SizedBox(width: AppSpacing.xl),
                      Expanded(
                        flex: 7,
                        child: _buildMoveInPromoCards(horizontal: true),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl),
                  _buildMoveInPromoButtons(authService, stacked: false),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoveInPromoIntro(authService),
                SizedBox(height: AppSpacing.xl),
                _buildMoveInPromoCards(
                  horizontal: !AppBreakpoints.isMobile(context),
                ),
                SizedBox(height: AppSpacing.xl),
                _buildMoveInPromoButtons(authService, stacked: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoveInPromoIntro(AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 안내 칩
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '이미 단기임대 계약을 하셨나요?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          '입주 준비 서비스만\n따로 이용할 수 있어요!',
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: AppTextStyles.responsiveFontSize(
              context,
              mobile: 24,
              desktop: 32,
            ),
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          '직접 준비가 부담되는 입주용품, 침구류 준비, 청소를\n필요한 서비스만 선택해 간편하게 이용할 수 있어요.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        // Feature item: 필요한 옵션만 선택
        _buildMoveInPromoFeature(
          icon: LucideIcons.shoppingBag,
          iconBg: AppColors.primary50,
          iconColor: AppColors.primary600,
          title: '필요한 옵션만 선택',
          description: '입주용품, 침구류, 청소 등 필요한 서비스만 골라보세요.',
        ),
        SizedBox(height: AppSpacing.md),
        Divider(color: AppColors.divider, height: 1),
        SizedBox(height: AppSpacing.md),
        _buildMoveInPromoFeature(
          icon: LucideIcons.calendar,
          iconBg: AppColors.primary50,
          iconColor: AppColors.primary600,
          title: '입주 일정에 맞춰 제공',
          description: '원하는 날짜에 맞춰 배송·준비가 진행돼요.',
        ),
      ],
    );
  }

  Widget _buildMoveInPromoFeature({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 20, color: iconColor),
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
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoveInPromoCards({required bool horizontal}) {
    final cards = const [
      _MoveInPromoCardData(
        icon: LucideIcons.shoppingBag,
        iconColor: Color(0xFF2563EB), // blue-600
        bgColor: Color(0xFFEFF6FF), // blue-50
        title: '입주용품 세트',
        description: '구매하기 번거로운 생활용품을\n입주일에 맞춰 준비해드려요.',
        emoji: '🧺',
      ),
      _MoveInPromoCardData(
        icon: LucideIcons.bed,
        iconColor: Color(0xFF059669), // emerald-600
        bgColor: Color(0xFFECFDF5), // emerald-50
        title: '침구류 대여',
        description: '침구를 직접 챙기지 않아도\n입주일에 맞춰 준비해드려요.',
        emoji: '🛏️',
      ),
      _MoveInPromoCardData(
        icon: LucideIcons.sprayCan,
        iconColor: Color(0xFFEA580C), // orange-600
        bgColor: Color(0xFFFFF7ED), // orange-50
        title: '청소 서비스',
        description: '퇴실 후 청소가 필요할 때\n간편하게 신청하세요.',
        emoji: '🧴',
      ),
    ];

    if (horizontal) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: _buildMoveInPromoCard(cards[i])),
              if (i != cards.length - 1) SizedBox(width: AppSpacing.md),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          _buildMoveInPromoCard(cards[i]),
          if (i != cards.length - 1) SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildMoveInPromoCard(_MoveInPromoCardData data) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 우측 상단 아이콘 뱃지
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(data.icon, size: 18, color: data.iconColor),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // 일러스트 영역 (실제 이미지 없이 이모지로 대체)
          AspectRatio(
            aspectRatio: 1.2,
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            data.title,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: data.iconColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            data.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveInPromoButtons(
    AuthService authService, {
    required bool stacked,
  }) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            text: '임대인으로 사용',
            icon: LucideIcons.user,
            onPressed: () => _handleMoveInHostEntry(authService),
          ),
          SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            text: '임차인으로 사용',
            icon: LucideIcons.user,
            onPressed: () => context.go('/guest/move-in'),
          ),
        ],
      );
    }
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          SizedBox(
            width: 220,
            child: AppPrimaryButton(
              text: '임대인으로 사용',
              icon: LucideIcons.user,
              onPressed: () => _handleMoveInHostEntry(authService),
            ),
          ),
          SizedBox(
            width: 220,
            child: AppSecondaryButton(
              text: '임차인으로 사용',
              icon: LucideIcons.user,
              onPressed: () => context.go('/guest/move-in'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMoveInHostEntry(AuthService authService) async {
    if (!authService.isLoggedIn) {
      context.go('/login');
      return;
    }
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    // 이미 호스트 모드면 바로 이동
    if (currentUser.mode == UserMode.host) {
      context.go('/host/move-in');
      return;
    }

    // 본인인증 미완료 → 호스트 가입 플로우
    if (!currentUser.phoneVerified) {
      context.go('/register/host/kakao');
      return;
    }

    // 계좌 미등록 → 계좌 입력 페이지
    if (!currentUser.hasBank) {
      context.go('/host/account-setup-standalone');
      return;
    }

    // 호스트 모드 전환 후 이동
    try {
      final ok = await authService.switchUserMode(UserMode.host);
      if (!ok || !mounted) return;
      context.go('/host/move-in');
    } on SwitchModeRequiresBankException {
      if (mounted) context.go('/host/account-setup-standalone');
    }
  }

  // ==================== 입주 준비 서비스 진입 카드 ====================
  Widget _buildMoveInEntrySection() {
    return HomeSection(
      backgroundColor: AppColors.background,
      verticalScale: VerticalPaddingScale.sm,
      child: Material(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go('/guest/move-in'),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary100, width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.package,
                      size: 24,
                      color: AppColors.primary700,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '입주 준비 서비스',
                          style: AppTextStyles.headingSmall,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '입주에 필요한 옵션을 한 번에 선택하고 결제하세요.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 임대인 STEP 가이드 섹션 ====================
  Widget _buildHostStepSection() {
    return HomeSection(
      backgroundColor: AppColors.surface,
      verticalScale: VerticalPaddingScale.md,
      child: Column(
        children: [
          const SectionHeader(title: '임대인 이용 방법', subtitle: '방 등록부터 정산까지 간단하게'),
          SizedBox(height: AppSpacing.xl),
          const StepGuideGrid(
            steps: [
              StepCard(
                icon: LucideIcons.clipboardList,
                stepNumber: '01',
                title: '방 등록',
                description: '임대할 방 정보를 등록',
                variant: StepCardVariant.host,
              ),
              StepCard(
                icon: LucideIcons.userCheck,
                stepNumber: '02',
                title: '계약 관리',
                description: '임차인 계약 요청을\n확인하고 승인하세요',
                variant: StepCardVariant.host,
              ),
              StepCard(
                icon: LucideIcons.wallet,
                stepNumber: '03',
                title: '정산',
                description: '임차인 입주 시\n임대인에게 정산금 자동 지급',
                variant: StepCardVariant.host,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 안전한 이유 섹션 ====================
  Widget _buildSafetySection() {
    return HomeSection(
      backgroundColor: AppColors.background,
      verticalScale: VerticalPaddingScale.md,
      child: Column(
        children: [
          const SectionHeader(
            title: '이지스테이가 안전한 이유',
            subtitle: '안심하고 거래할 수 있는 시스템을 제공합니다',
          ),
          SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = AppBreakpoints.isMobile(context);

              if (isMobile) {
                return Column(
                  children: [
                    InfoCard(
                      icon: LucideIcons.shieldCheck,
                      iconColor: AppColors.primary500,
                      title: '안전한 결제 시스템',
                      description: '에스크로 방식으로 안전하게 결제하고, 계약 확정 후 정산금을 지급합니다.',
                    ),
                    SizedBox(height: AppSpacing.md),
                    InfoCard(
                      icon: LucideIcons.badgeCheck,
                      iconColor: AppColors.primary500,
                      title: '방 검증',
                      description: '모든 매물은 검증 절차를 거쳐 등록되며, 허위 매물을 방지합니다.',
                    ),
                    SizedBox(height: AppSpacing.md),
                    InfoCard(
                      icon: LucideIcons.fileText,
                      iconColor: AppColors.primary500,
                      title: '투명한 계약',
                      description: '모든 계약 내용이 명확하게 기록되고, 분쟁 시 증빙 자료로 활용됩니다.',
                    ),
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: InfoCard(
                        icon: LucideIcons.shieldCheck,
                        iconColor: AppColors.primary500,
                        title: '안전한 결제 시스템',
                        description: '에스크로 방식으로 안전하게 결제하고, 계약 확정 후 정산금을 지급합니다.',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: InfoCard(
                        icon: LucideIcons.badgeCheck,
                        iconColor: AppColors.primary500,
                        title: '방 검증',
                        description: '모든 매물은 검증 절차를 거쳐 등록되며, 허위 매물을 방지합니다.',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: InfoCard(
                        icon: LucideIcons.fileText,
                        iconColor: AppColors.primary500,
                        title: '투명한 계약',
                        description: '모든 계약 내용이 명확하게 기록되고, 분쟁 시 증빙 자료로 활용됩니다.',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== 배송 서비스 섹션 ====================
  Widget _buildDeliverySection() {
    return HomeSection(
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.purple50, AppColors.primary50],
      ),
      verticalScale: VerticalPaddingScale.md,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.cardDefault,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = AppBreakpoints.isMobile(context);

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildDeliveryIcon(),
                  SizedBox(height: AppSpacing.lg),
                  _buildDeliveryContent(center: true),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildDeliveryIcon(),
                SizedBox(width: AppSpacing.xl),
                Expanded(child: _buildDeliveryContent(center: false)),
              ],
            );
          },
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
      child: Icon(LucideIcons.truck, size: 48, color: AppColors.purple600),
    );
  }

  Widget _buildDeliveryContent({required bool center}) {
    final crossAxis = center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.left;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          '입주 필수품 배송 서비스',
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: center ? 24 : 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: textAlign,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          '임차인은 계약 시, 필요한 용품을 이지스테이에서 함께 구매할 수 있어요\n구매한 상품은 입주할 방으로 배송해 드려요',
          style: AppTextStyles.bodyLarge.copyWith(fontSize: center ? 14 : 16),
          textAlign: textAlign,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          '생활용품, 침구류 등 입주에 필요한 물품을 이지스테이에서 준비할 수 있어요\n임대인은 방에 용품을 구비해둘 필요 없어요',
          style: AppTextStyles.bodyMediumSecondary,
          textAlign: textAlign,
        ),
      ],
    );
  }

  // ==================== CTA 섹션 ====================
  Widget _buildCTASection() {
    return HomeSection(
      backgroundColor: AppColors.primary600,
      maxWidth: AppSizes.contentMaxWidthNarrow,
      verticalScale: VerticalPaddingScale.lg,
      child: Column(
        children: [
          Text(
            '지금 바로 시작하세요',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: AppTextStyles.responsiveFontSize(
                context,
                mobile: 28,
                desktop: 36,
              ),
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '이지스테이와 함께 안전하고 쉬운\n단기임대를 경험하세요',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          CTAButton(
            text: '방 검색하기',
            trailingIcon: LucideIcons.arrowRight,
            variant: CTAButtonVariant.onPrimary,
            onPressed: _handleSearch,
          ),
        ],
      ),
    );
  }

  // ==================== 오픈 전 배너 ====================

  void _initOpeningBanner() {
    setState(() {
      _showOpeningBanner = true;
    });
  }

  Future<void> _handleAlertRequest(AuthService authService) async {
    if (!authService.isLoggedIn) {
      context.go('/login');
      return;
    }
    final result = await RegionAlertService().requestAlert();
    if (!mounted) return;
    if (result == null) {
      CustomToast.error(context, '알림 신청에 실패했습니다. 다시 시도해주세요.');
      return;
    }
    await RegionAlertModal.show(
      context,
      alreadyRegistered: result.alreadyRegistered,
    );
  }

  Future<void> _handleHostRedirect(AuthService authService) async {
    if (!authService.isLoggedIn) {
      context.go('/login');
      return;
    }

    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    // 이미 호스트 모드면 바로 방 등록 페이지로
    if (currentUser.mode == UserMode.host) {
      context.go('/host/room-registration');
      return;
    }

    // 본인인증 미완료 → 호스트 가입 플로우
    if (!currentUser.phoneVerified) {
      context.go('/register/host/kakao');
      return;
    }

    // 본인인증 완료 + 계좌 미등록 → 계좌 입력 페이지
    if (!currentUser.hasBank) {
      context.go('/host/account-setup-standalone');
      return;
    }

    // 본인인증 + 계좌 모두 완료 → 호스트 모드 전환 후 방 등록 페이지
    try {
      final ok = await authService.switchUserMode(UserMode.host);
      if (!ok || !mounted) return;
      context.go('/host/room-registration');
    } on SwitchModeRequiresBankException {
      if (mounted) context.go('/host/account-setup-standalone');
    }
  }

  Widget _buildOpeningBanner(AuthService authService) {
    if (!_showOpeningBanner) return const SizedBox.shrink();

    // 진행 중 이벤트가 전혀 없으면 배너 숨김 (게스트는 호스트/게스트 이벤트 모두 노출 대상)
    // 로드 완료 전에는 배너를 그리지 않아 '보였다 사라지는' 깜빡임 방지
    final promotion = context.watch<PromotionProvider>();
    if (!promotion.hasLoadedOnce) return const SizedBox.shrink();
    if (promotion.guestEvent == null && promotion.hostEvent == null) {
      return const SizedBox.shrink();
    }

    final isMobile = responsive.ResponsiveUtil.isMobile(context);

    return HomeSection(
      backgroundColor: AppColors.background,
      maxWidth: AppSizes.contentMaxWidthWide,
      padding: const EdgeInsets.only(bottom: 50),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: isMobile ? double.infinity : 400,
        ),
        child: ClipRRect(
          borderRadius: isMobile ? BorderRadius.zero : AppRadius.radiusLg,
          child: AspectRatio(
            aspectRatio: isMobile ? 800 / 600 : 1920 / 500,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  isMobile
                      ? 'assets/images/banner_mobile.jpg'
                      : 'assets/images/banner_desktop.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '오픈 전 참여 혜택',
                            style: AppTextStyles.headingLarge.copyWith(
                              fontSize: AppTextStyles.responsiveFontSize(
                                context,
                                mobile: 22,
                                desktop: 32,
                              ),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '임차인은 오픈 알림 신청 후 첫 계약 시 2만원 할인\n(선착순 100명 마감 시, 혜택은 종료됩니다)',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: AppTextStyles.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    desktop: 17,
                                  ),
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '임대인은 방 등록 시, 8월까지 정산 수수료 무료 (등록한 모든 방에 적용)',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: AppTextStyles.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    desktop: 17,
                                  ),
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppPrimaryButton(
                                text: '알림 받기',
                                fullWidth: false,
                                height: isMobile ? AppSizes.buttonHeightMd : 52,
                                onPressed: () =>
                                    _handleAlertRequest(authService),
                              ),
                              SizedBox(width: AppSpacing.md),
                              AppSecondaryButton(
                                text: '방 등록하기',
                                fullWidth: false,
                                height: isMobile ? AppSizes.buttonHeightMd : 52,
                                onPressed: () =>
                                    _handleHostRedirect(authService),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    context.go('/map', extra: extra.isNotEmpty ? extra : null);
  }
}

/// 입주 준비 서비스 프로모 카드 데이터.
class _MoveInPromoCardData {
  const _MoveInPromoCardData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.description,
    required this.emoji,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String description;
  final String emoji;
}
