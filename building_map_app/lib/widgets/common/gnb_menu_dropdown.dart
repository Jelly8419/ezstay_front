import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';

/// GNB 메뉴 드롭다운
/// 햄버거 메뉴 클릭 시 표시되는 드롭다운 메뉴입니다.
class GNBMenuDropdown extends StatelessWidget {
  final AuthService authService;
  final bool isHostMode;

  const GNBMenuDropdown({
    super.key,
    required this.authService,
    required this.isHostMode,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: AppColors.textPrimary, size: 28),
      offset: Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
      ),
      elevation: 8,
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        // 계약 관리
        _buildMenuItem(
          value: 'contracts',
          icon: Icons.description_outlined,
          label: '계약 관리',
        ),

        // 내 정보 관리
        _buildMenuItem(
          value: 'profile',
          icon: Icons.person_outline,
          label: '내 정보 관리',
        ),

        // 고객센터
        _buildMenuItem(
          value: 'support',
          icon: Icons.help_outline,
          label: '고객센터',
        ),

        const PopupMenuDivider(),

        // 로그아웃
        _buildMenuItem(
          value: 'logout',
          icon: Icons.logout,
          label: '로그아웃',
          iconColor: AppColors.error500,
          textColor: AppColors.error600,
        ),
      ],
    );
  }

  /// 메뉴 아이템 생성
  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 메뉴 선택 처리
  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'contracts':
        // 계약 관리 페이지로 이동
        final route = isHostMode ? '/host/contracts' : '/guest/contracts';
        context.go(route);
        break;

      case 'profile':
        // 내 정보 관리 페이지로 이동
        final route = isHostMode ? '/host/my-page' : '/guest/my-page';
        context.go(route);
        break;

      case 'support':
        // 고객센터 페이지로 이동
        context.go('/support');
        break;

      case 'logout':
        // 로그아웃 확인 다이얼로그
        _showLogoutDialog(context);
        break;
    }
  }

  /// 로그아웃 확인 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('로그아웃', style: AppTextStyles.headingSmall),
        content: Text(
          '정말 로그아웃하시겠습니까?',
          style: AppTextStyles.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authService.logout();
              // 로그아웃 후 홈으로 이동
              if (context.mounted) {
                context.go('/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error500,
              foregroundColor: AppColors.neutral0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSm,
              ),
            ),
            child: Text('로그아웃', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
