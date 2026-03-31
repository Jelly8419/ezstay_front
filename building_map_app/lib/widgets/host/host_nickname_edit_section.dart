import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/custom_text_field.dart';

/// 닉네임 변경 섹션
///
/// 표시/편집 모드를 외부 상태로 제어합니다.
class HostNicknameEditSection extends StatelessWidget {
  const HostNicknameEditSection({
    super.key,
    required this.isEditing,
    required this.currentNickname,
    required this.nicknameController,
    required this.onStartEdit,
    required this.onCancel,
    required this.onSave,
    required this.onFieldChanged,
  });

  final bool isEditing;
  final String? currentNickname;
  final TextEditingController nicknameController;
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
      child: isEditing ? _buildEditForm() : _buildDisplay(),
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
                '닉네임',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentNickname ?? '미설정',
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
    final canSubmit = nicknameController.text.trim().length >= 2 &&
        nicknameController.text.trim().length <= 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '닉네임',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        CustomTextField(
          controller: nicknameController,
          hint: '닉네임을 입력해주세요',
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '2~20자 입력 가능',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
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
