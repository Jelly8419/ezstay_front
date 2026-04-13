import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 영수증 편집 폼 위젯
///
/// 영수증 종류 선택, 번호/사업자 정보 입력, 저장/취소/삭제 버튼을 포함합니다.
/// 모든 상태는 외부에서 주입되며, 변경은 콜백으로 위임합니다.
class HostReceiptEditForm extends StatelessWidget {
  const HostReceiptEditForm({
    super.key,
    required this.receiptType,
    required this.receiptNumberInputType,
    required this.receiptNumberController,
    required this.receiptBusinessNameController,
    required this.receiptRepNameController,
    required this.receiptEmailController,
    required this.receiptFieldErrors,
    required this.savedReceipt,
    required this.onReceiptTypeChanged,
    required this.onNumberInputTypeChanged,
    required this.onCancel,
    required this.onSave,
    required this.onDelete,
    required this.onFieldChanged,
  });

  // 현재 상태 (읽기)
  final String receiptType;
  final String receiptNumberInputType;
  final TextEditingController receiptNumberController;
  final TextEditingController receiptBusinessNameController;
  final TextEditingController receiptRepNameController;
  final TextEditingController receiptEmailController;
  final Map<String, String?> receiptFieldErrors;
  final Map<String, dynamic>? savedReceipt;

  // 콜백 (상태 변경 위임)
  final void Function(String) onReceiptTypeChanged;
  final void Function(String) onNumberInputTypeChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final canSubmit = receiptType.isNotEmpty &&
        receiptNumberController.text.isNotEmpty &&
        (receiptType != 'tax_invoice' ||
            (receiptBusinessNameController.text.isNotEmpty &&
                receiptRepNameController.text.isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 영수증 종류
        Text(
          '영수증 종류',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutral700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        DropdownButtonFormField<String>(
          initialValue: receiptType.isEmpty ? null : receiptType,
          hint: Text(
            '선택하세요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'personal',
              child: Text('개인소득공제용 현금영수증'),
            ),
            DropdownMenuItem(
              value: 'business',
              child: Text('사업자증빙용 현금영수증'),
            ),
            DropdownMenuItem(
              value: 'tax_invoice',
              child: Text('전자세금계산서'),
            ),
          ],
          onChanged: (value) => onReceiptTypeChanged(value ?? ''),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: AppColors.primary500,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),

        // 개인소득공제용
        if (receiptType == 'personal') ...[
          SizedBox(height: AppSpacing.md),
          Text(
            '번호 종류',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral700,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildRadioOption(
                label: '휴대폰 번호',
                value: 'phone',
                groupValue: receiptNumberInputType,
                onChanged: onNumberInputTypeChanged,
              ),
              SizedBox(width: AppSpacing.md),
              _buildRadioOption(
                label: '현금영수증 카드 번호',
                value: 'card',
                groupValue: receiptNumberInputType,
                onChanged: onNumberInputTypeChanged,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _buildReceiptInputField(
            label: receiptNumberInputType == 'phone'
                ? '휴대폰 번호'
                : '현금영수증 카드 번호',
            placeholder: receiptNumberInputType == 'phone'
                ? "'-' 없이 숫자만 입력해주세요 (예: 01012345678)"
                : "'-' 없이 숫자만 입력해주세요",
            controller: receiptNumberController,
            keyboardType: TextInputType.number,
            errorText: receiptFieldErrors['number'],
            onFieldChanged: onFieldChanged,
          ),
        ],

        // 사업자증빙용
        if (receiptType == 'business') ...[
          SizedBox(height: AppSpacing.md),
          Text(
            '번호 종류',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral700,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildRadioOption(
                label: '휴대폰 번호',
                value: 'phone',
                groupValue: receiptNumberInputType,
                onChanged: onNumberInputTypeChanged,
              ),
              SizedBox(width: AppSpacing.md),
              _buildRadioOption(
                label: '사업자 등록번호',
                value: 'bizno',
                groupValue: receiptNumberInputType,
                onChanged: onNumberInputTypeChanged,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _buildReceiptInputField(
            label: receiptNumberInputType == 'phone'
                ? '휴대폰 번호'
                : '사업자 등록번호',
            placeholder: receiptNumberInputType == 'phone'
                ? "'-' 없이 숫자만 입력해주세요 (예: 01012345678)"
                : "'-' 없이 숫자만 입력해주세요 (10자리)",
            controller: receiptNumberController,
            keyboardType: TextInputType.number,
            errorText: receiptFieldErrors['number'],
            onFieldChanged: onFieldChanged,
          ),
        ],

        // 전자세금계산서
        if (receiptType == 'tax_invoice') ...[
          SizedBox(height: AppSpacing.md),
          _buildReceiptInputField(
            label: '사업자 등록번호',
            placeholder: "'-' 없이 숫자만 입력해주세요 (10자리)",
            controller: receiptNumberController,
            keyboardType: TextInputType.number,
            errorText: receiptFieldErrors['number'],
            onFieldChanged: onFieldChanged,
          ),
          SizedBox(height: AppSpacing.md),
          _buildReceiptInputField(
            label: '사업자명',
            placeholder: '사업자명을 입력해 주세요.',
            controller: receiptBusinessNameController,
            errorText: receiptFieldErrors['businessName'],
            onFieldChanged: onFieldChanged,
          ),
          SizedBox(height: AppSpacing.md),
          _buildReceiptInputField(
            label: '대표자 이름',
            placeholder: '대표자 이름을 입력해 주세요',
            controller: receiptRepNameController,
            errorText: receiptFieldErrors['repName'],
            onFieldChanged: onFieldChanged,
          ),
          SizedBox(height: AppSpacing.md),
          _buildReceiptInputField(
            label: '이메일 주소 (선택)',
            placeholder: '이메일 주소를 입력해 주세요',
            controller: receiptEmailController,
            keyboardType: TextInputType.emailAddress,
            errorText: receiptFieldErrors['email'],
            onFieldChanged: onFieldChanged,
          ),
        ],

        SizedBox(height: AppSpacing.md),

        // 버튼 영역
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        side: BorderSide(color: AppColors.gray300, width: 2),
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
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
                        backgroundColor: AppColors.primary600,
                        disabledBackgroundColor: AppColors.gray300,
                        foregroundColor: AppColors.neutral0,
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        '저장',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 삭제 버튼 (기존 설정이 있을 때만 표시)
              if (savedReceipt != null) ...[
                SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error500,
                      side: BorderSide(color: AppColors.error500, width: 2),
                      padding:
                          EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      '영수증 설정 삭제',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildRadioOption({
  required String label,
  required String value,
  required String groupValue,
  required void Function(String) onChanged,
}) {
  final isSelected = value == groupValue;

  return GestureDetector(
    onTap: () => onChanged(value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary600 : AppColors.gray300,
              width: 2,
            ),
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary600,
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray900,
          ),
        ),
      ],
    ),
  );
}

Widget _buildReceiptInputField({
  required String label,
  required String placeholder,
  required TextEditingController controller,
  TextInputType keyboardType = TextInputType.text,
  String? errorText,
  VoidCallback? onFieldChanged,
}) {
  final hasError = errorText != null && errorText.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.neutral700,
        ),
      ),
      SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => onFieldChanged?.call(),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          errorText: hasError ? errorText : null,
          errorStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.error500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: AppColors.gray300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: hasError ? AppColors.error500 : AppColors.gray300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: hasError ? AppColors.error500 : AppColors.primary500,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: AppColors.error500),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: AppColors.error500, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    ],
  );
}
