import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../models/user.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logHomeViewGuest();
      SeoHelper.updatePage(
        title: 'EZStay — 단기임대 No.1, 편리하고 안전한 단기 숙소 찾기',
        description:
            '출장, 이사, 한달살기에 필요한 단기임대 숙소를 쉽고 빠르게. 1주일부터 계약 가능한 전국의 원룸, 오피스텔, 아파트를 찾아보세요.',
        canonicalPath: '/',
      );
      final authService = context.read<AuthService>();
      OpeningEventModal.maybeShow(
        context,
        onAlertRequest: () => _handleAlertRequest(authService),
        onHostRedirect: () => _handleHostRedirect(authService),
      );
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
      tagline: '누구나 쉽고 안전하게 사용할 수 있어요',
      headline: '단기임대를 편리하고 안전하게',
      brandWord: '이지스테이',
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
                            '오픈 전 참여하면 2만원 혜택',
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '• 임차인은 오픈 알림 신청 후 첫 계약 시 2만원 할인',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: AppTextStyles.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    desktop: 17,
                                  ),
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• 임대인은 방 등록 후 첫 계약 정산 수수료 2만원 할인',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: AppTextStyles.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    desktop: 17,
                                  ),
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '5월 초 오픈 전 각 선착순 100명 마감 시, 혜택은 종료됩니다',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: AppTextStyles.responsiveFontSize(
                                context,
                                mobile: 12,
                                desktop: 14,
                              ),
                              color: Colors.white.withValues(alpha: 0.85),
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
