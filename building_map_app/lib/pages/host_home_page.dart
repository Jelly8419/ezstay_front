import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../models/user.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/app_buttons.dart';
import '../features/web/web_layout.dart';

/// 호스트 모드 홈 화면 - 새 디자인 시스템 적용
class HostHomePage extends StatefulWidget {
  const HostHomePage({super.key});

  @override
  State<HostHomePage> createState() => _HostHomePageState();
}

class _HostHomePageState extends State<HostHomePage> {
  final _roomService = RoomService();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _inProgressRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
          debugPrint('🏠 [HOST] setState 완료 - _inProgressRoom에 id 추가: ${_inProgressRoom?['id']}');
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
      appBar: _buildMobileAppBar(authService),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.md),
            _buildWelcomeSection(authService),
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
    );
  }

  // ==================== 태블릿 레이아웃 ====================
  Widget _buildTabletLayout(AuthService authService) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildDesktopAppBar(authService),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.lg),
            _buildWelcomeSection(authService),
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
              children: [
                Icon(Icons.home_work, color: AppColors.success600, size: 32),
                SizedBox(width: AppSpacing.sm),
                Text('EZStay 호스트', style: AppTextStyles.headingLarge),
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
                  child: WebContainer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
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
      title: Text('EZStay 호스트', style: AppTextStyles.headingMedium),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.person, color: AppColors.success600),
          onPressed: () => _showUserMenu(context, authService),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(AuthService authService) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.home_work, color: AppColors.success600),
          SizedBox(width: AppSpacing.sm),
          Text('EZStay 호스트', style: AppTextStyles.headingMedium),
        ],
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      actions: _buildDesktopActions(authService),
    );
  }

  List<Widget> _buildDesktopActions(AuthService authService) {
    return [
      AppTextButton(
        text: '계약 관리',
        icon: Icons.description_outlined,
        onPressed: () => context.go('/host/contracts'),
      ),
      SizedBox(width: AppSpacing.sm),
      AppTextButton(
        text: '내 숙소',
        icon: Icons.home_work_outlined,
        onPressed: () => _showComingSoonDialog(context),
      ),
      SizedBox(width: AppSpacing.sm),
      AppTextButton(
        text: '채팅',
        icon: Icons.chat_bubble_outline,
        onPressed: () => context.push('/chat-list'),
      ),
      SizedBox(width: AppSpacing.sm),
      PopupMenuButton<String>(
        icon: Icon(Icons.account_circle, color: AppColors.success600),
        onSelected: (value) {
          if (value == 'logout') {
            _handleLogout(context, authService);
          } else if (value == 'switch_to_guest') {
            _switchToGuestMode(context, authService);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'switch_to_guest',
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.primary600),
                SizedBox(width: AppSpacing.sm),
                Text('게스트 모드로 전환', style: AppTextStyles.bodyMedium),
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
      SizedBox(width: AppSpacing.md),
    ];
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
            child: Icon(
              Icons.person,
              size: 32,
              color: AppColors.success600,
            ),
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
            color: AppColors.warning500.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.3),
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
                              color: AppColors.neutral0.withOpacity(0.9),
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
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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

  // ==================== 숙소 등록 버튼 ====================
  Widget _buildRegisterPropertyButton() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary500, AppColors.primary700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
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
                          color: AppColors.neutral0.withOpacity(0.9),
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

  // ==================== 관리 그리드 ====================
  Widget _buildManagementGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.1,
      children: [
        _buildManagementCard(
          icon: Icons.home_work_outlined,
          title: '내 숙소',
          subtitle: '등록된 숙소 관리',
          color: AppColors.primary600,
          onTap: () => _showComingSoonDialog(context),
        ),
        _buildManagementCard(
          icon: Icons.description_outlined,
          title: '계약 관리',
          subtitle: '계약 요청 확인',
          color: AppColors.secondary600,
          onTap: () => context.go('/host/contracts'),
        ),
        _buildManagementCard(
          icon: Icons.attach_money_outlined,
          title: '수익 관리',
          subtitle: '매출 및 정산',
          color: AppColors.success600,
          onTap: () => _showComingSoonDialog(context),
        ),
        _buildManagementCard(
          icon: Icons.reviews_outlined,
          title: '리뷰 관리',
          subtitle: '게스트 리뷰',
          color: AppColors.warning600,
          onTap: () => _showComingSoonDialog(context),
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMd,
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmallSecondary,
                  textAlign: TextAlign.center,
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
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  title: '예약 건수',
                  value: '0',
                  icon: Icons.book,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
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
        Icon(
          icon,
          size: 20,
          color: AppColors.success600,
        ),
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
                context.go('/host/contracts');
              },
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline, color: AppColors.primary600),
              title: Text('채팅', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat-list');
              },
            ),
            ListTile(
              leading: Icon(Icons.search, color: AppColors.primary600),
              title: Text('게스트 모드로 전환', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _switchToGuestMode(context, authService);
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

  void _switchToGuestMode(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('게스트 모드로 전환', style: AppTextStyles.headingSmall),
          content: Text(
            '게스트 모드로 전환하시겠습니까?\n숙소 검색 및 예약 기능을 사용할 수 있습니다.',
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
              onPressed: () {
                authService.switchUserMode(UserMode.guest);
                Navigator.pop(context);
              },
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }

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
