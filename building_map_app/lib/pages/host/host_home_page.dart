import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/promotion_provider.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/room_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/web/web_layout.dart';
import '../../widgets/common/app_footer.dart';
import '../../utils/contract_utils.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/content_container.dart';
import '../../utils/responsive_util.dart' as responsive;

/// 호스트 모드 홈 화면 - 새 디자인 시스템 적용
class HostHomePage extends StatefulWidget {
  const HostHomePage({super.key});

  @override
  State<HostHomePage> createState() => _HostHomePageState();
}

class _HostHomePageState extends State<HostHomePage> {
  final _roomService = RoomService();
  late final AnalyticsService _analytics;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _inProgressRooms = [];

  @override
  void initState() {
    super.initState();
    // Firebase 초기화 후 Analytics 사용
    _analytics = AnalyticsService();
    // 🔥 호스트 홈 화면 진입 이벤트 기록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logHomeViewHost();
      if (!mounted) return;
      context.read<PromotionProvider>().loadActivePromotions();
    });
    _checkInProgressRooms();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 등록 중인 방 확인
  Future<void> _checkInProgressRooms() async {
    final rooms = await _roomService.getInProgressRooms();

    if (rooms != null && rooms.isNotEmpty) {
      List<Map<String, dynamic>> fetchedRooms = [];

      for (var room in rooms) {
        final roomId = room['id'] ?? room['roomId'];
        if (roomId == null) continue;

        final detail = await _roomService.getRoom(roomId);
        if (detail != null) {
          fetchedRooms.add({...detail, 'id': roomId});
        }
      }

      if (mounted) {
        setState(() {
          _inProgressRooms = fetchedRooms;
        });
      }
    }
  }

  /// 진행 중인 단계에 따라 페이지 이동
  void _continueRegistration(Map<String, dynamic> room) {
    final roomId = room['id'] ?? room['roomId'];
    // 모든 단계는 RoomRegistrationFlowPage에서 Step 위젯으로 처리
    // RoomRegistrationFlowPage가 내부적으로 진행 상태를 파악하여 적절한 단계를 표시함
    context.go('/host/room-registration/$roomId');
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventBanner(),
            _buildHeroSection(isMobile: true),
            SizedBox(height: AppSpacing.lg),
            _buildInProgressRoomsSection(),
            if (_inProgressRooms.isNotEmpty) SizedBox(height: AppSpacing.lg),
            _buildManagementGrid(),
            SizedBox(height: AppSpacing.xxl),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventBanner(),
            _buildHeroSection(isMobile: false),
            SizedBox(height: AppSpacing.xl),
            _buildInProgressRoomsSection(),
            if (_inProgressRooms.isNotEmpty) SizedBox(height: AppSpacing.xl),
            _buildManagementGrid(),
            SizedBox(height: AppSpacing.xxxl),
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
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _buildEventBanner(),
                      _buildHeroSection(isMobile: false),
                      SizedBox(height: AppSpacing.xxl),
                      _buildInProgressRoomsSection(),
                      if (_inProgressRooms.isNotEmpty)
                        SizedBox(height: AppSpacing.xl),
                      _buildManagementGrid(),
                      SizedBox(height: AppSpacing.xxl),
                      const AppFooter(),
                    ],
                  ),
                ),
                ScrollToTopButton(scrollController: _scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 등록 중인 방들 섹션 ====================
  Widget _buildInProgressRoomsSection() {
    if (_inProgressRooms.isEmpty) return const SizedBox.shrink();

    return ContentContainer(
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusLg,
          boxShadow: AppShadows.cardDefault,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 섹션 헤더 ---
            Row(
              children: [
                Icon(Icons.edit_outlined, size: 20, color: AppColors.blue600),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '등록 중인 방 (${_inProgressRooms.length})',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.lg),

            // --- 방 카드 리스트 ---
            Column(
              children: _inProgressRooms.map((room) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.space20),
                  child: _buildInProgressRoomBanner(room),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 등록 중인 방 배너 ====================
  Widget _buildInProgressRoomBanner(Map<String, dynamic> room) {
    final roomName = room['roomName'] ?? '등록 중인 방';
    final address = room['address'] ?? '주소 미입력';

    // photos 배열에서 URL 추출 (문자열 또는 객체 형태 모두 지원)
    final photos = room['photos'] as List<dynamic>?;
    String photoUrl = '';

    if (photos != null && photos.isNotEmpty) {
      final firstPhoto = photos.first;

      if (firstPhoto is String) {
        // 문자열인 경우 (URL 직접)
        photoUrl = firstPhoto;
      } else if (firstPhoto is Map) {
        // 객체인 경우 (url 또는 photoUrl 필드 추출)
        photoUrl =
            (firstPhoto['url'] ?? firstPhoto['photoUrl'] ?? '') as String;
      }

      // 상대 경로를 절대 URL로 변환
      photoUrl = ContractUtils.getFullImageUrl(photoUrl);
    }

    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: hasPhoto
                    ? ClipRRect(
                        borderRadius: AppRadius.radiusMd,
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.neutral100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary500,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            AppLogger.e('🖼️ [HOST] 에러: $error');
                            return Container(
                              color: AppColors.neutral100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 32,
                                    color: AppColors.neutral400,
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '이미지 없음',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Icon(
                          Icons.home_outlined,
                          size: 32,
                          color: AppColors.neutral400,
                        ),
                      ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      address,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _continueRegistration(room),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('이어서 등록하기'),
                  SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 이벤트 배너 ====================
  Widget _buildEventBanner() {
    // 호스트 대상 진행 중 이벤트가 없으면 배너 숨김
    // 로드 완료 전에는 배너를 그리지 않아 '보였다 사라지는' 깜빡임 방지
    final promotion = context.watch<PromotionProvider>();
    if (!promotion.hasLoadedOnce) return const SizedBox.shrink();
    if (promotion.hostEvent == null) return const SizedBox.shrink();

    final isMobile = responsive.ResponsiveUtil.isMobile(context);

    return ContentContainer(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: AppRadius.radiusMd,
        child: Stack(
          children: [
            // 배경 이미지
            Positioned.fill(
              child: Image.asset(
                isMobile
                    ? 'assets/images/banner_mobile.jpg'
                    : 'assets/images/banner_desktop.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            // 오버레이
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // 콘텐츠
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: isMobile
                  ? _buildEventBannerMobileContent()
                  : _buildEventBannerWideContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBannerBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.success100,
        borderRadius: AppRadius.radiusXs,
      ),
      child: Text(
        '진행 중',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.success600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEventBannerMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEventBannerBadge(),
        SizedBox(height: AppSpacing.sm),
        Text(
          '방 등록만 해도 바로 받는 혜택',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '8월까지 정산 수수료 무료 · 등록한 모든 방에 적용',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '오픈 전 등록 완료한 모든 임대인 대상',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AppPrimaryButton(
            text: '방 등록하기',
            fullWidth: true,
            icon: Icons.arrow_forward,
            onPressed: () => context.go('/host/room-registration'),
          ),
        ),
      ],
    );
  }

  Widget _buildEventBannerWideContent() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventBannerBadge(),
              SizedBox(height: AppSpacing.sm),
              Text(
                '방 등록만 해도 바로 받는 혜택',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '8월까지 정산 수수료 무료 · 등록한 모든 방에 적용\n(등록된 방은 5월 초 오픈 시 전체 공개됩니다)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '오픈 전 등록 완료한 모든 임대인 대상',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              AppPrimaryButton(
                text: '방 등록하기',
                fullWidth: false,
                icon: Icons.arrow_forward,
                onPressed: () => context.go('/host/room-registration'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== CTA 배너 ====================
  Widget _buildHeroSection({required bool isMobile}) {
    return ContentContainer(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue600, AppColors.blue700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.radiusXl,
          boxShadow: [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: 0.4),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 장식 원형 요소 (오른쪽 상단)
            Positioned(
              top: -128,
              right: -128,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 장식 원형 요소 (왼쪽 하단)
            Positioned(
              bottom: -96,
              left: -96,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 메인 컨텐츠
            Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메인 카피
                  Text(
                    '이지스테이에서만 경험할 수 있는 자동 운영 시스템',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '임대인은 방에 직접 가지 않아도 되는 단기임대를 경험해보세요',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.blue50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // CTA 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/host/room-registration');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            '방 등록하기',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // 혜택 체크리스트
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildBenefitBadge('무료 등록'),
                      _buildBenefitBadge('안전한 결제'),
                      _buildBenefitBadge('자동 관리'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 혜택 뱃지 위젯
  Widget _buildBenefitBadge(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.white),
        SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.blue100),
        ),
      ],
    );
  }

  // ==================== 빠른 메뉴 (모바일 2열, 태블릿/데스크톱 5열) ====================
  Widget _buildManagementGrid() {
    return ContentContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 모바일: 2열, 태블릿/데스크톱: 5열
          final crossAxisCount = constraints.maxWidth > 768 ? 5 : 2;

          return Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.radiusMd,
              boxShadow: AppShadows.cardDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('빠른 메뉴', style: AppTextStyles.headingSmall),
                SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.0,
                  children: [
                    _buildQuickMenuButton(
                      icon: Icons.home_work_outlined,
                      label: '방 관리',
                      onTap: () => context.go('/host/room-management'),
                    ),
                    _buildQuickMenuButton(
                      icon: Icons.chat_bubble_outline,
                      label: '채팅',
                      onTap: () => context.go('/chat-list'),
                    ),
                    _buildQuickMenuButton(
                      icon: Icons.settings_outlined,
                      label: '자동메시지',
                      onTap: () => context.go('/host/chat/auto-message'),
                    ),
                    _buildQuickMenuButton(
                      icon: Icons.description_outlined,
                      label: '계약관리',
                      onTap: () => context.go('/host/contracts'),
                    ),
                    _buildQuickMenuButton(
                      icon: Icons.account_balance_wallet_outlined,
                      label: '정산',
                      onTap: () => context.go('/host/settlement'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 빠른 메뉴 버튼 위젯
  Widget _buildQuickMenuButton({
    required IconData icon,
    required String label,
    int? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMd,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              // 메인 컨텐츠
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: AppColors.blue600,
                    ), // Primary → Blue600
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 뱃지
              if (badge != null && badge > 0)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error500,
                      borderRadius: AppRadius.radiusXs,
                    ),
                    child: Text(
                      '$badge',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
