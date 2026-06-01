import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../models/user.dart';
import '../../providers/promotion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/guest_date_range_picker_dialog.dart';
import '../../widgets/home/cta_button.dart';
import '../../widgets/home/home_hero.dart';
import '../../widgets/home/home_section.dart';
import '../../widgets/home/info_card.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/step_card.dart';
import '../../widgets/home/step_guide_grid.dart';
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
        title: '이지스테이(EZstay) ― 서울 단기임대 · 임대인 8월까지 정산 수수료 무료',
        description:
            '서울 단기임대 플랫폼 이지스테이(EZstay). 임대인 방 등록 후 임대 계약 시 8월까지 정산 수수료 무료. 1주~90일 서울 전역 단기 계약 가능한 원룸·오피스텔·아파트.',
        canonicalPath: '/',
      );

      // 정적 랜딩에서 `?action=host-register` 쿼리로 진입한 경우 즉시 호스트 플로우 실행
      final action = Uri.base.queryParameters['action'];
      if (action == 'host-register' && mounted) {
        final authService = context.read<AuthService>();
        _handleHostRedirect(authService);
        return;
      }

      // 프로모션 이벤트는 배너로만 노출 (홈 진입 팝업은 제거됨).
      // _buildOpeningBanner 가 watch 로 자동 갱신하므로 여기서는 로드만 트리거.
      final promotion = context.read<PromotionProvider>();
      await promotion.loadActivePromotions();
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
            // 모바일은 배너~프로모션 섹션 간격을 좁게 (기존 50 → 12)
            const SizedBox(height: 12),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoveInPromoIntro(authService),
                SizedBox(height: AppSpacing.xl),
                _buildMoveInPromoSteps(horizontal: isDesktop),
                SizedBox(height: AppSpacing.xl),
                _buildMoveInPromoButtons(authService, stacked: !isDesktop),
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
            '이미 다른곳에서 단기임대 계약을 하셨나요?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        // 제목: "입주 서비스만" (검정) + "따로 이용할 수 있어요!" (파랑)
        RichText(
          text: TextSpan(
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: AppTextStyles.responsiveFontSize(
                context,
                mobile: 24,
                desktop: 32,
              ),
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
            children: [
              const TextSpan(text: '입주 서비스만 '),
              TextSpan(
                text: '따로 이용할 수 있어요!',
                style: TextStyle(color: AppColors.primary600),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          '임대인은 한 번만 입력하면 끝! 이후 임차인 안내는 이지스테이가 알아서 진행합니다.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // 4단계 입주 준비 서비스 진행 스텝 데이터
  static const List<_MoveInStepData> _moveInSteps = [
    _MoveInStepData(
      step: 1,
      accent: Color(0xFF2563EB), // blue-600
      title: '예약 정보 등록',
      imagePath: 'assets/images/move_in_step1_register.png',
      description: '임대인은 다른 플랫폼에서\n계약한 정보를 입력하고\n신청하면 끝',
      highlight: '입력하고\n신청하면 끝',
      roleLabel: '임대인',
      roleIcon: LucideIcons.user,
    ),
    _MoveInStepData(
      step: 2,
      accent: Color(0xFF059669), // emerald-600
      title: '자동 안내',
      imagePath: 'assets/images/move_in_step2_notify.png',
      description: '이지스테이가 임차인에게\n입주 준비를 안내합니다.',
      highlight: '안내',
      roleLabel: '이지스테이',
      roleIcon: LucideIcons.messageCircle,
    ),
    _MoveInStepData(
      step: 3,
      accent: Color(0xFFEA580C), // orange-600
      title: '항목 선택',
      imagePath: 'assets/images/move_in_step3_select.png',
      description: '임차인이 필요한\n침구·수건·입주 생활용품을\n직접 선택하고 결제합니다.',
      highlight: '선택하고 결제',
      roleLabel: '임차인',
      roleIcon: LucideIcons.user,
    ),
    _MoveInStepData(
      step: 4,
      accent: Color(0xFF7C3AED), // violet-600
      title: '입주일에 맞춰 배송',
      imagePath: 'assets/images/move_in_step4_delivery.png',
      description: '선택한 상품을\n입주일에 맞춰 배송해드립니다.',
      highlight: '배송해드립니다',
      roleLabel: '이지스테이',
      roleIcon: LucideIcons.package,
      imageScale: 1.7, // 트럭 일러스트가 가로형이라 영역 내에서 확대 보정
    ),
  ];

  Widget _buildMoveInPromoSteps({required bool horizontal}) {
    if (horizontal) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _moveInSteps.length; i++) ...[
              Expanded(child: _buildMoveInStepCard(_moveInSteps[i])),
              if (i != _moveInSteps.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Center(child: _buildStepArrow(horizontal: true)),
                ),
            ],
          ],
        ),
      );
    }

    // 모바일: 컴팩트 카드(역할칩 제거, 이미지 높이 제한)로 세로 길이 단축
    return Column(
      children: [
        for (var i = 0; i < _moveInSteps.length; i++) ...[
          _buildMoveInStepCard(_moveInSteps[i], compact: true),
          if (i != _moveInSteps.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: _buildStepArrow(horizontal: false),
            ),
        ],
      ],
    );
  }

  // 스텝 사이 점선 화살표 ( ···> )
  Widget _buildStepArrow({required bool horizontal}) {
    final color = AppColors.primary600;
    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '···',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: color),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '⋮',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Icon(LucideIcons.chevronDown, size: 16, color: color),
      ],
    );
  }

  Widget _buildMoveInStepCard(_MoveInStepData data, {bool compact = false}) {
    // 단계 배지
    final badge = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: data.accent, shape: BoxShape.circle),
      child: Text(
        '${data.step}',
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final title = Text(
      data.title,
      style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.w700),
    );

    if (compact) {
      // 모바일: 번호+제목 한 줄 + 이미지(좌)·설명(우) 가로 배치 → 세로 길이 최소화
      return Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.cardDefault,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                badge,
                SizedBox(width: AppSpacing.sm),
                title,
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 이미지 좌측: 박스는 고정 크기(여백 방지), 작은 트럭만 scale로
                // 박스 내 확대(가로형이라 세로 침범 없음).
                SizedBox(
                  width: 100,
                  height: 110,
                  child: Transform.scale(
                    scale: data.imageScale,
                    child: Image.asset(
                      data.imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                // 설명 우측 (autoWrap: 좁은 폭에 맞춰 자동 줄바꿈)
                Expanded(
                  child: _buildStepDescription(data, center: false, autoWrap: true),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 데스크탑: 세로 카드 (배지→제목→이미지→설명→역할칩)
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.cardDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          badge,
          SizedBox(height: AppSpacing.sm),
          title,
          SizedBox(height: AppSpacing.md),
          // AspectRatio가 이미지 영역(레이아웃 공간)을 실제로 차지 → contain된
          // 이미지가 영역 안에 담겨 아래 설명 텍스트를 침범하지 않음.
          // 세로로 긴 비율(0.72)이라 폰(2·3)이 크게 들어가 내부 텍스트 가독성 확보.
          // 가로형(노트북·트럭)은 폭에 맞춰지므로 작은 트럭만 imageScale로 영역 내 확대.
          AspectRatio(
            aspectRatio: 0.72,
            child: Center(
              child: Transform.scale(
                scale: data.imageScale,
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          _buildStepDescription(data),
          // 설명 줄 수가 카드마다 달라도 칩을 카드 바닥에 통일 정렬
          SizedBox(height: AppSpacing.md),
          const Spacer(),
          // 하단 역할 칩
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.roleIcon, size: 16, color: data.accent),
                SizedBox(width: AppSpacing.xs),
                Text(
                  data.roleLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: data.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 설명문에서 highlight 부분만 accent 색으로 강조
  // center: 중앙 정렬 여부 / autoWrap: true면 \n을 공백으로 치환해 폭에 맞춰 자동 줄바꿈
  Widget _buildStepDescription(
    _MoveInStepData data, {
    bool center = true,
    bool autoWrap = false,
  }) {
    final align = center ? TextAlign.center : TextAlign.start;
    final base = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.5,
      fontSize: 14, // bodySmall(12) 대비 +2
    );
    final description =
        autoWrap ? data.description.replaceAll('\n', ' ') : data.description;
    final highlight =
        autoWrap ? data.highlight.replaceAll('\n', ' ') : data.highlight;
    final idx = description.indexOf(highlight);
    if (idx < 0) {
      return Text(description, textAlign: align, style: base);
    }
    return RichText(
      textAlign: align,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: description.substring(0, idx)),
          TextSpan(
            text: highlight,
            style: base.copyWith(
              color: data.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: description.substring(idx + highlight.length)),
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
                        Text('입주 준비 서비스', style: AppTextStyles.headingSmall),
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
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
    if (promotion.hostEvent == null) return const SizedBox.shrink();

    final isMobile = responsive.ResponsiveUtil.isMobile(context);
    final textShadow = Shadow(
      color: Colors.black.withValues(alpha: 0.5),
      offset: const Offset(0, 1),
      blurRadius: 3,
    );

    return HomeSection(
      backgroundColor: AppColors.background,
      maxWidth: AppSizes.contentMaxWidthWide,
      // 모바일은 하단 여백을 줄여 다음 섹션과 밀착 (데스크탑은 기존 50 유지)
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 50),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // 배너 높이를 기존 대비 30% 축소 (400 → 280)
          maxHeight: isMobile ? double.infinity : 280,
        ),
        child: ClipRRect(
          borderRadius: isMobile ? BorderRadius.zero : AppRadius.radiusLg,
          child: AspectRatio(
            // 세로를 30% 줄인 비율 (모바일 600→420, 데스크탑 500→350)
            aspectRatio: isMobile ? 800 / 420 : 1920 / 350,
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
                            '임대인 방 등록 혜택',
                            style: AppTextStyles.headingLarge.copyWith(
                              fontSize: AppTextStyles.responsiveFontSize(
                                context,
                                mobile: 22,
                                desktop: 32,
                              ),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              shadows: [textShadow],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '방 등록 후 임대 계약 시, 8월까지 정산 수수료 무료',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: AppTextStyles.responsiveFontSize(
                                context,
                                mobile: 14,
                                desktop: 17,
                              ),
                              color: Colors.white,
                              shadows: [textShadow],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppPrimaryButton(
                            text: '방 등록하기',
                            fullWidth: false,
                            height: isMobile ? AppSizes.buttonHeightMd : 52,
                            onPressed: () => _handleHostRedirect(authService),
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

/// 입주 준비 서비스 4단계 진행 스텝 데이터.
class _MoveInStepData {
  const _MoveInStepData({
    required this.step,
    required this.accent,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.highlight,
    required this.roleLabel,
    required this.roleIcon,
    this.imageScale = 1.0, // 폰·노트북은 AspectRatio(0.72) 영역에 꽉 차므로 1.0
  });

  final int step;
  final Color accent;
  final String title;
  final String imagePath;
  final String description;
  final String highlight;
  final String roleLabel;
  final IconData roleIcon;
  final double imageScale; // 일러스트 개별 크기 배율 (트럭 등 작은 이미지 보정)
}
