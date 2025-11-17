import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../config/api_config.dart';

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
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    debugPrint('🏠 [HOST] 등록 중인 방 개수: ${_inProgressRooms.length}');
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(Icons.edit_outlined, size: 20, color: AppColors.blue600),
        SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
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

                  // 🔥 등록 중인 방 배너 (여러개 표시)
                  ...[
                    _buildInProgressRoomsSection(),
                    SizedBox(height: AppSpacing.xl),
                  ],

                  // 빠른 메뉴는 _buildManagementGrid 내부에 제목 포함
                  _buildManagementGrid(),
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

                  // 등록 중인 방 (여러 개)
                  ...[
                    _buildInProgressRoomsSection(),
                    SizedBox(height: AppSpacing.xl),
                  ],

                  _buildManagementGrid(),
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
                              // 등록 중인 방 (여러 개)
                              ...[
                                _buildInProgressRoomsSection(),
                                SizedBox(height: AppSpacing.xl),
                              ],

                              _buildManagementGrid(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 스크롤 탑 버튼
                ScrollToTopButton(scrollController: _scrollController),
                // 채팅 사이드바
                ChatSidebarWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 등록 중인 방들 섹선====================
  Widget _buildInProgressRoomsSection() {
    if (_inProgressRooms.isEmpty) return SizedBox.shrink();

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 1200),
        padding: EdgeInsets.all(24),
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
                SizedBox(width: 8),
                Text(
                  '등록 중인 방 (${_inProgressRooms.length})',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // --- 방 카드 리스트 ---
            Column(
              children: _inProgressRooms.map((room) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildInProgressRoomBanner(room), // 카드만 출력
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

    debugPrint('🖼️ [HOST] photos 데이터: $photos');

    if (photos != null && photos.isNotEmpty) {
      final firstPhoto = photos.first;
      debugPrint('🖼️ [HOST] firstPhoto 타입: ${firstPhoto.runtimeType}, 값: $firstPhoto');

      if (firstPhoto is String) {
        // 문자열인 경우 (URL 직접)
        photoUrl = firstPhoto;
      } else if (firstPhoto is Map) {
        // 객체인 경우 (url 또는 photoUrl 필드 추출)
        photoUrl = (firstPhoto['url'] ?? firstPhoto['photoUrl'] ?? '') as String;
      }

      // 상대 경로를 절대 URL로 변환
      if (photoUrl.isNotEmpty && photoUrl.startsWith('/')) {
        photoUrl = '${ApiConfig.baseUrl}$photoUrl';
      }

      debugPrint('🖼️ [HOST] 추출된 photoUrl: $photoUrl');
    }

    final hasPhoto = photoUrl.isNotEmpty;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 1200),
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusMd,
          boxShadow: AppShadows.cardDefault,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 여기서 섹션 헤더는 제거됨

            // Property Card
            Container(
              padding: EdgeInsets.all(20),
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
                                    debugPrint('🖼️ [HOST] 이미지 로딩 실패: $url');
                                    debugPrint('🖼️ [HOST] 에러: $error');
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
                                          SizedBox(height: 4),
                                          Text(
                                            '이미지 없음',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
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
                            SizedBox(height: 4),
                            Text(
                              address,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('이어서 등록하기'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CTA 배너 ====================
  Widget _buildHeroSection({required bool isMobile}) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 1200), // 최대 너비 제한
        margin: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '호스트는 방에 직접 가지 않아도 되는 단기임대를 경험해보세요',
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
                        // localStorage 초기화 (비즈니스 로직 유지)
                        context.go('/host/room-registration');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.blue600,
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

  // ==================== 빠른 메뉴 (리액트 스타일 - 모바일 2열, 데스크톱 4열) ====================
  Widget _buildManagementGrid() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 1200), // 최대 너비 제한
        margin: EdgeInsets.all(AppSpacing.lg), // 상하좌우 모두 동일 마진
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 모바일: 2열, 태블릿/데스크톱: 4열
            final crossAxisCount = constraints.maxWidth > 768 ? 4 : 2;

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
                    childAspectRatio: 2.0, // 세로 높이를 절반으로 줄임 (가로:세로 = 2:1)
                    children: [
                      _buildQuickMenuButton(
                        icon: Icons.chat_bubble_outline,
                        label: '채팅',
                        onTap: () => _showComingSoonDialog(context),
                      ),
                      _buildQuickMenuButton(
                        icon: Icons.settings_outlined,
                        label: '자동메시지',
                        onTap: () => _showComingSoonDialog(context),
                      ),
                      _buildQuickMenuButton(
                        icon: Icons.description_outlined,
                        label: '계약관리',
                        onTap: () => context.go('/host/contracts'),
                      ),
                      _buildQuickMenuButton(
                        icon: Icons.account_balance_wallet_outlined,
                        label: '정산',
                        onTap: () => _showComingSoonDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
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
