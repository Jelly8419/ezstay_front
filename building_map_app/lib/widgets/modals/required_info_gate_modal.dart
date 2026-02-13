import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 필수 정보 입력 게이트 모달 (Phase 4)
///
/// 정책: 계약 요청 시 이름/전화번호 미입력이면 모달로 유도
/// 에러코드 4010: missingFields 배열로 누락 필드 전달
class RequiredInfoGateModal extends StatefulWidget {
  final List<String> missingFields;

  const RequiredInfoGateModal({
    super.key,
    required this.missingFields,
  });

  /// 모달 표시 헬퍼
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required List<String> missingFields,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RequiredInfoGateModal(
        missingFields: missingFields,
      ),
    );
  }

  @override
  State<RequiredInfoGateModal> createState() => _RequiredInfoGateModalState();
}

class _RequiredInfoGateModalState extends State<RequiredInfoGateModal> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _bankController = TextEditingController();

  bool get _needsPhone => widget.missingFields.contains('phoneNumber');
  bool get _needsName => widget.missingFields.contains('name');
  bool get _needsBank => widget.missingFields.contains('bankAccount');
  bool get _needsVerification =>
      widget.missingFields.contains('verification');

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'phoneNumber':
        return '전화번호';
      case 'name':
        return '이름';
      case 'bankAccount':
        return '정산 계좌';
      case 'verification':
        return '본인 인증';
      default:
        return field;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary500, size: 24),
          const SizedBox(width: 8),
          const Text('필수 정보 입력'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '계약을 진행하려면 다음 정보가 필요합니다.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 16),

              if (_needsName) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름 *',
                    hintText: '실명을 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '이름을 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
              ],

              if (_needsPhone) ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '전화번호 *',
                    hintText: '010-0000-0000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '전화번호를 입력해주세요';
                    if (v.replaceAll('-', '').length < 10) {
                      return '올바른 전화번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (_needsBank) ...[
                TextFormField(
                  controller: _bankController,
                  decoration: const InputDecoration(
                    labelText: '정산 계좌 *',
                    hintText: '은행명 계좌번호',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '계좌 정보를 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
              ],

              if (_needsVerification)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '본인 인증이 필요합니다. 마이페이지에서 인증을 완료해주세요.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: TextStyle(color: AppColors.gray600),
          ),
        ),
        if (!_needsVerification)
          ElevatedButton(
            onPressed: _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final result = <String, String>{};
    if (_needsName) result['name'] = _nameController.text.trim();
    if (_needsPhone) result['phoneNumber'] = _phoneController.text.trim();
    if (_needsBank) result['bankAccount'] = _bankController.text.trim();

    Navigator.pop(context, result);
  }
}
