import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/app_inputs.dart';
import '../shared/widgets/app_buttons.dart';
import '../shared/widgets/property_card.dart';
import '../features/web/web_layout.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_sidebar_widget.dart';

/// 게스트 모드 홈 화면 - 새 디자인 시스템 적용
class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  // 필터 상태
  RangeValues _priceRange = const RangeValues(0, 1000000);
  String? _selectedPropertyType;

  // 더미 데이터 (이미지 없이 플레이스홀더 사용)
  final List<Map<String, dynamic>> _mockProperties = [
    {
      'imageUrl': '', // 외부 이미지 제거 (네트워크 요청 없음)
      'title': '강남역 도보 5분 신축 원룸',
      'location': '서울시 강남구 역삼동',
      'rating': 4.8,
      'reviewCount': 128,
      'price': '₩330,000',
      'period': '주',
      'badges': ['신규', '할인'],
    },
    {
      'imageUrl': '', // 외부 이미지 제거
      'title': '홍대입구역 인근 깔끔한 투룸',
      'location': '서울시 마포구 서교동',
      'rating': 4.5,
      'reviewCount': 85,
      'price': '₩450,000',
      'period': '주',
      'badges': ['프리미엄'],
    },
    {
      'imageUrl': '', // 외부 이미지 제거
      'title': '판교 테크노밸리 오피스텔',
      'location': '경기도 성남시 분당구',
      'rating': 4.9,
      'reviewCount': 203,
      'price': '₩520,000',
      'period': '주',
      'badges': ['인증', '신규'],
    },
    {
      'imageUrl': '', // 외부 이미지 제거
      'title': '잠실역 초역세권 아파트',
      'location': '서울시 송파구 잠실동',
      'rating': 4.7,
      'reviewCount': 156,
      'price': '₩580,000',
      'period': '주',
      'badges': [],
    },
    {
      'imageUrl': '', // 외부 이미지 제거
      'title': '선릉역 도보 3분 오피스텔',
      'location': '서울시 강남구 선릉로',
      'rating': 4.6,
      'reviewCount': 92,
      'price': '₩380,000',
      'period': '주',
      'badges': ['할인'],
    },
    {
      'imageUrl': '', // 외부 이미지 제거
      'title': '신촌 대학가 원룸',
      'location': '서울시 서대문구 신촌동',
      'rating': 4.3,
      'reviewCount': 67,
      'price': '₩280,000',
      'period': '주',
      'badges': [],
    },
  ];

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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 검색 바
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: AppSearchBar(
                hintText: '지역, 역 이름으로 검색',
                onSearch: (query) => _handleSearch(query),
                onFilterTap: () => setState(() => _showFilters = !_showFilters),
              ),
            ),
          ),

          // 지도로 검색 버튼
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: _buildMapSearchButton(),
            ),
          ),

          // 필터 (열림 상태일 때만)
          if (_showFilters)
            SliverToBoxAdapter(
              child: _buildFiltersSection(),
            ),

          // 매물 리스트 (1열)
          SliverPadding(
            padding: AppSpacing.paddingMd,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final property = _mockProperties[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: PropertyCard(
                      imageUrl: property['imageUrl'],
                      title: property['title'],
                      location: property['location'],
                      rating: property['rating'],
                      reviewCount: property['reviewCount'],
                      price: property['price'],
                      period: property['period'],
                      badges: List<String>.from(property['badges']),
                      onTap: () => context.go('/map'),
                    ),
                  );
                },
                childCount: _mockProperties.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 태블릿 레이아웃 ====================
  Widget _buildTabletLayout(AuthService authService) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildDesktopAppBar(authService),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 검색 바
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: AppSearchBar(
                hintText: '지역, 역 이름으로 검색',
                onSearch: (query) => _handleSearch(query),
                onFilterTap: () => setState(() => _showFilters = !_showFilters),
              ),
            ),
          ),

          // 지도로 검색 버튼
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: _buildMapSearchButton(),
            ),
          ),

          // 필터
          if (_showFilters)
            SliverToBoxAdapter(
              child: _buildFiltersSection(),
            ),

          // 매물 그리드 (2열)
          SliverPadding(
            padding: AppSpacing.paddingLg,
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final property = _mockProperties[index];
                  return HoverEffect(
                    child: PropertyCard(
                      imageUrl: property['imageUrl'],
                      title: property['title'],
                      location: property['location'],
                      rating: property['rating'],
                      reviewCount: property['reviewCount'],
                      price: property['price'],
                      period: property['period'],
                      badges: List<String>.from(property['badges']),
                      onTap: () => context.go('/map'),
                    ),
                  );
                },
                childCount: _mockProperties.length,
              ),
            ),
          ),
        ],
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
                Icon(Icons.home, color: AppColors.primary600, size: 32),
                SizedBox(width: AppSpacing.sm),
                Text('EZStay', style: AppTextStyles.headingLarge),
              ],
            ),
            actions: _buildDesktopActions(authService),
          ),

          // 메인 컨텐츠
          Expanded(
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // 검색 바
                    SliverToBoxAdapter(
                      child: WebContainer(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: AppSearchBar(
                            hintText: '지역, 역 이름으로 검색',
                            onSearch: (query) => _handleSearch(query),
                            onFilterTap: () => setState(() => _showFilters = !_showFilters),
                          ),
                        ),
                      ),
                    ),

                    // 지도로 검색 버튼
                    SliverToBoxAdapter(
                      child: WebContainer(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _buildMapSearchButton(),
                        ),
                      ),
                    ),

                    // 메인 컨텐츠 (사이드바 + 매물 그리드)
                    SliverToBoxAdapter(
                      child: WebContainer(
                        child: SidebarLayout(
                          showSidebar: _showFilters,
                          sidebar: _buildFilterSidebar(),
                          content: _buildPropertyGrid(3),
                        ),
                      ),
                    ),
                  ],
                ),

                // 스크롤 탑 버튼
                ScrollToTopButton(scrollController: _scrollController),
               // 채팅 사이드바 (오버레이)
                ChatSidebarWidget(),
              ],
            ),
          ),

          // 푸터
          _buildFooter(),
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
        SizedBox(width: AppSpacing.md),
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
      AppTextButton(
        text: '즐겨찾기',
        icon: Icons.favorite_outline,
        onPressed: () => _showComingSoonDialog(context),
      ),
      SizedBox(width: AppSpacing.sm),
      AppTextButton(
        text: '채팅',
        icon: Icons.chat_bubble_outline,
        onPressed: () { final chatProvider = Provider.of<ChatProvider>(context, listen: false); chatProvider.openChatList(); },
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
      SizedBox(width: AppSpacing.md),
    ];
  }

  // ==================== 지도로 검색 버튼 ====================
  Widget _buildMapSearchButton() {
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
          onTap: () => context.go('/map'),
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
                    Icons.map_outlined,
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
                        '지도로 숙소 검색하기',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.neutral0,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '지도에서 원하는 위치의 숙소를 찾아보세요',
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

  // ==================== 필터 섹션 ====================
  Widget _buildFiltersSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('필터', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.md),

          // 가격 범위
          Text('가격 범위', style: AppTextStyles.labelMedium),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000000,
            divisions: 20,
            activeColor: AppColors.primary500,
            labels: RangeLabels(
              '₩${(_priceRange.start / 1000).toStringAsFixed(0)}K',
              '₩${(_priceRange.end / 1000).toStringAsFixed(0)}K',
            ),
            onChanged: (RangeValues values) {
              setState(() => _priceRange = values);
            },
          ),

          SizedBox(height: AppSpacing.md),

          // 필터 적용 버튼
          AppPrimaryButton(
            text: '필터 적용',
            onPressed: () => _applyFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar() {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('필터', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.lg),

          // 가격 범위
          Text('가격 범위', style: AppTextStyles.labelMedium),
          SizedBox(height: AppSpacing.sm),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000000,
            divisions: 20,
            activeColor: AppColors.primary500,
            labels: RangeLabels(
              '₩${(_priceRange.start / 1000).toStringAsFixed(0)}K',
              '₩${(_priceRange.end / 1000).toStringAsFixed(0)}K',
            ),
            onChanged: (RangeValues values) {
              setState(() => _priceRange = values);
            },
          ),

          SizedBox(height: AppSpacing.lg),

          // 매물 유형
          Text('매물 유형', style: AppTextStyles.labelMedium),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ['원룸', '투룸', '오피스텔', '아파트'].map((type) {
              final isSelected = _selectedPropertyType == type;
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: AppColors.primary100,
                checkmarkColor: AppColors.primary700,
                onSelected: (selected) {
                  setState(() {
                    _selectedPropertyType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: AppSpacing.xl),

          // 필터 적용
          AppPrimaryButton(
            text: '필터 적용',
            onPressed: () => _applyFilters(),
          ),
        ],
      ),
    );
  }

  // ==================== 매물 그리드 ====================
  Widget _buildPropertyGrid(int columns) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: _mockProperties.length,
      itemBuilder: (context, index) {
        final property = _mockProperties[index];
        return HoverEffect(
          child: PropertyCard(
            imageUrl: property['imageUrl'],
            title: property['title'],
            location: property['location'],
            rating: property['rating'],
            reviewCount: property['reviewCount'],
            price: property['price'],
            period: property['period'],
            badges: List<String>.from(property['badges']),
            onTap: () => context.go('/map'),
          ),
        );
      },
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
  void _handleSearch(String query) {
    debugPrint('검색: $query');
    // TODO: 실제 검색 로직 구현
  }

  void _applyFilters() {
    debugPrint('필터 적용: $_priceRange, $_selectedPropertyType');
    // TODO: 필터 적용 로직
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
              leading: Icon(Icons.chat_bubble_outline, color: AppColors.primary600),
              title: Text('채팅', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat-list');
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
                  context.go('/host'); // 호스트 홈으로 이동 (올바른 경로)
                }
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
