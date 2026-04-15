import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../host/host_receipt_edit_form.dart';

/// 부가서비스 영수증 서브섹션 (게스트용)
///
/// 표시 모드(현재 설정 + 변경 버튼)와 편집 모드(HostReceiptEditForm)를
/// 외부 상태로 제어합니다.
class GuestReceiptDisplaySection extends StatelessWidget {
  const GuestReceiptDisplaySection({
    super.key,
    required this.isEditing,
    required this.savedReceipt,
    required this.receiptTypeName,
    required this.onStartEdit,
    // 편집 모드 props (isEditing == true 일 때만 사용)
    required this.receiptType,
    required this.receiptNumberInputType,
    required this.receiptNumberController,
    required this.receiptBusinessNameController,
    required this.receiptRepNameController,
    required this.receiptEmailController,
    required this.receiptFieldErrors,
    required this.onReceiptTypeChanged,
    required this.onNumberInputTypeChanged,
    required this.onCancel,
    required this.onSave,
    required this.onDelete,
    required this.onFieldChanged,
  });

  final bool isEditing;
  final Map<String, dynamic>? savedReceipt;
  final String receiptTypeName;
  final VoidCallback onStartEdit;

  // 편집 모드용
  final String receiptType;
  final String receiptNumberInputType;
  final TextEditingController receiptNumberController;
  final TextEditingController receiptBusinessNameController;
  final TextEditingController receiptRepNameController;
  final TextEditingController receiptEmailController;
  final Map<String, String?> receiptFieldErrors;
  final void Function(String) onReceiptTypeChanged;
  final void Function(String) onNumberInputTypeChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '부가서비스 영수증',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        if (!isEditing) ...[
          _buildDisplayMode(),
        ] else ...[
          HostReceiptEditForm(
            receiptType: receiptType,
            receiptNumberInputType: receiptNumberInputType,
            receiptNumberController: receiptNumberController,
            receiptBusinessNameController: receiptBusinessNameController,
            receiptRepNameController: receiptRepNameController,
            receiptEmailController: receiptEmailController,
            receiptFieldErrors: receiptFieldErrors,
            savedReceipt: savedReceipt,
            onReceiptTypeChanged: onReceiptTypeChanged,
            onNumberInputTypeChanged: onNumberInputTypeChanged,
            onCancel: onCancel,
            onSave: onSave,
            onDelete: onDelete,
            onFieldChanged: onFieldChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildDisplayMode() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.neutral400,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  savedReceipt != null
                      ? '신청 - $receiptTypeName (${savedReceipt!['receiptNumber']})'
                      : '신청 안함',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onStartEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary500,
              side: BorderSide(color: AppColors.primary600, width: 2),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              '변경',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
