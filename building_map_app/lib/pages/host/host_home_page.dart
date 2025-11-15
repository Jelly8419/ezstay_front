import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/room_service.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../features/web/web_layout.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_sidebar_widget.dart';
import '../../widgets/common/app_gnb.dart';

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
  Map<String, dynamic>? _inProgressRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Firebase 초기화 후 Analytics 사용
    _analytics = AnalyticsService();
    // 🔥 호스트 홈 화면 진입 이벤트 기록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logHomeViewHost();
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
    debugPrint('🏠 [HOST] 등록 중인 방 확인 시작');

    final rooms = await _roomService.getInProgressRooms();
    debugPrint('🏠 [HOST] getInProgressRooms 결과: $rooms');

    if (rooms != null) {
      debugPrint('🏠 [HOST] 반환된 방 개수: ${rooms.length}');

      if (rooms.isNotEmpty) {
        debugPrint('🏠 [HOST] 첫 번째 방 데이터: ${rooms[0]}');

        final roomId = rooms[0]['id'] ?? rooms[0]['roomId'];
        debugPrint('🏠 [HOST] roomId 추출: $roomId');

        final roomDetail = await _roomService.getRoom(roomId);
        debugPrint('🏠 [HOST] getRoom 결과: $roomDetail');

        if (mounted) {
          setState(() {
            if (roomDetail != null) {
              _inProgressRoom = {...roomDetail, 'id': roomId};
            } else {
              _inProgressRoom = roomDetail;
            }
            _isLoading = false;
          });
          debugPrint(
            '🏠 [HOST] setState 완료 - _inProgressRoom에 id 추가: ${_inProgressRoom?['id']}',
          );
        }
      } else {
        debugPrint('🏠 [HOST] 등록 중인 방이 없음');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint('🏠 [HOST] getInProgressRooms가 null 반환');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    debugPrint('🏠 [HOST] 배너 표시 여부: ${_inProgressRoom != null}');
  }

  /// 진행 중인 단계에 따라 페이지 이동
  void _continueRegistration() {
    if (_inProgressRoom == null) return;

    final roomId = _inProgressRoom!['id'] ?? _inProgressRoom!['roomId'];
    final progress = _inProgressRoom!['registrationProgress'];

    debugPrint('🚀 [HOST] 등록 계속하기 클릭');
    debugPrint('🚀 [HOST] roomId: $roomId');
    debugPrint('🚀 [HOST] progress: $progress');

    if (progress == null) {
      debugPrint('🚀 [HOST] progress 없음 -> /host/room-registration');
      context.go('/host/room-registration/$roomId');
      return;
    }

    final currentStep = progress['currentStep'] as String?;
    final steps = progress['steps'] as Map<String, dynamic>?;

    debugPrint('🚀 [HOST] currentStep: $currentStep');
    debugPrint('🚀 [HOST] steps: $steps');

    if (steps != null) {
      if (steps['basicInfo'] == false) {
        debugPrint('🚀 [HOST] basicInfo 미완료 -> /host/room-registration');
        context.go('/host/room-registration/$roomId');
      } else if (steps['pricing'] == false) {
        debugPrint('🚀 [HOST] pricing 미완료 -> /host/pricing');
        context.go('/host/pricing/$roomId');
      } else if (steps['photosAndAmenities'] == false) {
        debugPrint('🚀 [HOST] photosAndAmenities 미완료 -> /host/amenities');
        context.go('/host/amenities/$roomId');
      } else if (steps['freeServices'] == false) {
        debugPrint('🚀 [HOST] freeServices 미완료 -> /host/free-services');
        context.go('/host/free-services/$roomId');
      } else if (steps['description'] == false) {
        debugPrint('🚀 [HOST] description 미완료 -> /host/room-description');
        context.go('/host/room-description/$roomId');
      } else {
        debugPrint('🚀 [HOST] 모든 단계 완료 -> /host/room-registration');
        context.go('/host/room-registration/$roomId');
      }
    } else {
      debugPrint('🚀 [HOST] steps 없음, currentStep으로 판단: $currentStep');
      switch (currentStep) {
        case 'pricing':
          context.go('/host/pricing/$roomId');
          break;
        case 'photosAndAmenities':
          context.go('/host/amenities/$roomId');
          break;
        case 'freeServices':
          context.go('/host/free-services/$roomId');
          break;
        case 'description':
          context.go('/host/room-description/$roomId');
          break;
        default:
          context.go('/host/room-registration/$roomId');
      }
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 히어로 섹션
            _buildHeroSection(isMobile: true),

            Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.lg),

                  // 등록 중인 방 배너
                  if (_inProgressRoom != null) ...[
                    _buildInProgressRoomBanner(),
                    SizedBox(height: AppSpacing.lg),
                  ],

                  // 숙소 등록하기 버튼
                  _buildRegisterPropertyButton(),
                  SizedBox(height: AppSpacing.xl),

                  // 관리 섹션
                  Text('호스트 관리', style: AppTextStyles.headingMedium),
                  SizedBox(height: AppSpacing.md),
                  _buildManagementGrid(),
                  SizedBox(height: AppSpacing.xl),

                  // 통계 섹션
                  _buildStatsCard(),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 히어로 섹션
            _buildHeroSection(isMobile: false),

            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xl),

                  if (_inProgressRoom != null) ...[
                    _buildInProgressRoomBanner(),
                    SizedBox(height: AppSpacing.xl),
                  ],

                  _buildRegisterPropertyButton(),
                  SizedBox(height: AppSpacing.xxl),

                  Text('호스트 관리', style: AppTextStyles.headingLarge),
                  SizedBox(height: AppSpacing.lg),
                  _buildManagementGrid(),
                  SizedBox(height: AppSpacing.xxl),

                  _buildStatsCard(),
                  SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
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

                      WebContainer(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeSection(authService),
                              SizedBox(height: AppSpacing.xl),

                              if (_inProgressRoom != null) ...[
                                _buildInProgressRoomBanner(),
                                SizedBox(height: AppSpacing.xl),
                              ],

                              _buildRegisterPropertyButton(),
                              SizedBox(height: AppSpacing.xxxl),

                              Text('호스트 관리', style: AppTextStyles.displaySmall),
                              SizedBox(height: AppSpacing.lg),
                              _buildManagementGrid(),
                              SizedBox(height: AppSpacing.xxxl),

                              _buildStatsCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 스크롤 탑 버튼
                ScrollToTopButton(scrollController: _scrollController),
                // 채팅 사이드바 (오버레이)
                ChatSidebarWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 환영 섹션 ====================
  Widget _buildWelcomeSection(AuthService authService) {
    final user = authService.currentUser;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.shadowMd,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.success50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 32, color: AppColors.success600),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, ${user?.name ?? '호스트'}님!',
                  style: AppTextStyles.headingMedium,
                ),
                SizedBox(height: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success100,
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Text(
                    '호스트 모드',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 등록 중인 방 배너 ====================
  Widget _buildInProgressRoomBanner() {
    final progress = _inProgressRoom!['registrationProgress'];
    final completionRate = progress?['completionRate'] ?? 0;
    final roomName = _inProgressRoom!['roomName'] ?? '등록 중인 방';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning500, AppColors.secondary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.warning500.withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _continueRegistration,
          borderRadius: AppRadius.radiusLg,
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: AppColors.neutral0,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '등록 중인 방이 있네요!',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.neutral0,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '마저 입력하고 게스트에게 방을 보여주세요.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral0.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.neutral0,
                      size: 20,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  roomName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral0,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '진행률',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.neutral0,
                          ),
                        ),
                        Text(
                          '$completionRate%',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: AppRadius.radiusXs,
                      child: LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
            AppColors.blue600, // Blue-600
            AppColors.blue700, // Blue-700
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
            // 헤드라인 (흰색)
            Text(
              '호스트님의 단기임대를\n이지스테이가 함께합니다',
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

            SizedBox(height: AppSpacing.md),

            // 서브 타이틀 (Blue-50)
            Text(
              '안전한 계약부터 정산까지, 모든 것을 한 곳에서',
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

            SizedBox(height: AppSpacing.xl * 2),

            // 매물 등록하기 버튼
            SizedBox(
              width: isMobile ? double.infinity : 280,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/host/room-registration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.blue600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '매물 등록하기',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.blue600,
                        fontWeight: FontWeight.bold,
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
    );
  }

  // ==================== 숙소 등록 버튼 ====================
  Widget _buildRegisterPropertyButton() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue600, AppColors.blue700], // Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/host/room-registration'),
          borderRadius: AppRadius.radiusLg,
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(
                    Icons.add_home,
                    size: 40,
                    color: AppColors.neutral0,
                  ),
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '숙소 등록하기',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.neutral0,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '새로운 숙소를 등록하세요',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral0.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.neutral0,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Quick Actions (빠른 작업) ====================
  Widget _buildManagementGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.2,
      children: [
        _buildQuickActionCard(
          icon: Icons.location_on_outlined,
          title: '방 관리',
          backgroundColor: AppColors.blue100,
          iconColor: AppColors.blue600,
          onTap: () => _showComingSoonDialog(context),
        ),
        _buildQuickActionCard(
          icon: Icons.check_circle_outline,
          title: '계약 관리',
          backgroundColor: AppColors.success100,
          iconColor: AppColors.success600,
          onTap: () => context.go('/host/contracts'),
        ),
        _buildQuickActionCard(
          icon: Icons.all_inbox_outlined,
          title: '자동메시지',
          backgroundColor: const Color(0xFFF3E8FF), // Purple-100
          iconColor: const Color(0xFF9333EA), // Purple-600
          onTap: () => _showComingSoonDialog(context),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardDefault,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusLg,
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 통계 카드 ====================
  Widget _buildStatsCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 달 요약', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: '등록된 숙소',
                  value: '0',
                  icon: Icons.home,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildStatItem(
                  title: '예약 건수',
                  value: '0',
                  icon: Icons.book,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildStatItem(
                  title: '총 수익',
                  value: '₩0',
                  icon: Icons.payments,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.success600),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: AppTextStyles.bodySmallSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== 이벤트 핸들러 ====================
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('준비 중', style: AppTextStyles.headingSmall),
          content: Text(
            '해당 기능은 준비 중입니다.\n곧 만나보실 수 있어요!',
            style: AppTextStyles.bodyMedium,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          actions: [
            AppPrimaryButton(
              text: '확인',
              onPressed: () => Navigator.pop(context),
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }
}
