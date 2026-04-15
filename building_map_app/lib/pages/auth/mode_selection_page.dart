import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/responsive_page_layout.dart';

/// 사용자 모드 선택 페이지
class ModeSelectionPage extends StatelessWidget {
  final Function(UserMode) onModeSelected;

  const ModeSelectionPage({super.key, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인 & 회원가입'),
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isLoggedIn) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _handleLogout(context, authService);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'user_info',
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 8),
                          Text(authService.currentUser?.displayName ?? '사용자'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text('로그아웃'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ResponsivePageLayout(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Enkostay 로고
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF87CEEB), // 블루스카이 색상
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EZStay',
                        style: AppTextStyles.headingMedium.copyWith(color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 안내 텍스트
            Text(
              '사용자 선택',
              style: AppTextStyles.headingMedium.copyWith(color: const Color(0xFF2C3E50)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 집 올리기와 집 내기 카드들을 가로로 배치
            Row(
              children: [
                // 집 찾기
                Expanded(
                  child: _buildModeCard(
                    context: context,
                    title: '집을 찾고 있어요',
                    description1: '1. 빠르게 계약이 가능합니다',
                    description1Detail: '계약요청 > 승인 > 결제 3단계\n절차만으로 계약할 수 있습니다.',
                    description2: '2. 안전하게 계약할 수 있습니다',
                    description2Detail: 'EZStay에서 모든 계약의 안전한 입주\n여부를 확인합니다',
                    buttonText: '집 둘러보기',
                    color: const Color(0xFF87CEEB),
                    onTap: () => onModeSelected(UserMode.guest),
                  ),
                ),

                const SizedBox(width: 16),

                // 집 내놓기
                Expanded(
                  child: _buildModeCard(
                    context: context,
                    title: '집을 내놓고 싶어요',
                    description1: '1.빠르게 공실을 줄여 보세요',
                    description1Detail: '등록 즉시 계약이 가능합니다.\n공실 고민에서 벗어나세요.',
                    description2: '2.쉽게 임대관리 하세요',
                    description2Detail: '복잡하고 번거로운 절차 없이도 바로\n계약할 수 있습니다.',
                    buttonText: '집 내놓기',
                    color: const Color(0xFF87CEEB),
                    onTap: () => onModeSelected(UserMode.host),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            InkWell(
              onTap: () {
                // 가격 포맷 표시로 이동하거나 게스트 모드로 기본 설정
                onModeSelected(UserMode.guest);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '가격으로 올리고 + 가격 책정 포맷쇼',
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 나중에 선택하기
            TextButton(
              onPressed: () {
                // 기본값으로 게스트 모드 선택
                onModeSelected(UserMode.guest);
              },
              child: Text(
                '나중에 선택할게요',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description1,
    required String description1Detail,
    required String description2,
    required String description2Detail,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.textPrimary, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.home, size: 24, color: color),
              ),
              const SizedBox(height: 16),

              // 제목
              Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(color: const Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 16),

              // 설명 1
              Text(
                description1,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),

              // 설명 1 상세
              Text(
                description1Detail,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),

              // 설명 2
              Text(
                description2,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),

              // 설명 2 상세
              Text(
                description2Detail,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // 선택 버튼
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
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

  void _handleLogout(BuildContext context, AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF87CEEB),
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('로그아웃되었습니다'),
            backgroundColor: const Color(0xFF87CEEB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        // 로그아웃 후 이전 페이지로 돌아가기
        Navigator.of(context).pop();
      }
    }
  }
}
