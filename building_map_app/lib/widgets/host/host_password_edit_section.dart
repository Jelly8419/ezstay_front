import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/password_validator.dart';
import '../common/custom_text_field.dart';

/// 비밀번호 변경 섹션
///
/// 표시/편집 모드를 외부 상태로 제어합니다.
/// 이메일 계정 전용 — 소셜 로그인 사용자는 표시하지 않습니다.
class HostPasswordEditSection extends StatelessWidget {
  const HostPasswordEditSection({
    super.key,
    required this.isEditing,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onStartEdit,
    required this.onCancel,
    required this.onSave,
    required this.onFieldChanged,
  });

  final bool isEditing;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onStartEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isEditing ? _buildEditForm() : _buildDisplay(),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '비밀번호',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '••••••••',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onStartEdit,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary500,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '변경',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final canSubmit = currentPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: currentPasswordController,
          hint: '현재 비밀번호',
          obscureText: true,
          onChanged: (_) => onFieldChanged(),
        ),
        SizedBox(height: AppSpacing.sm),
        CustomTextField(
          controller: newPasswordController,
          hint: '새 비밀번호',
          obscureText: true,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            PasswordValidator.policyDescription,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        CustomTextField(
          controller: confirmPasswordController,
          hint: '새 비밀번호 확인',
          obscureText: true,
          onChanged: (_) => onFieldChanged(),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border, width: 2),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  '취소',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: canSubmit ? onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  disabledBackgroundColor: AppColors.gray300,
                  foregroundColor: AppColors.neutral0,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  '변경',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
