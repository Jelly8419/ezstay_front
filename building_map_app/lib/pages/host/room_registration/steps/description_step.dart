import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/form_section.dart';

/// Step 5: 방 소개 및 안내 (리액트 DescriptionStep 복제)
class DescriptionStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final List<String>? validationErrors;

  const DescriptionStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    this.validationErrors,
  });

  @override
  State<DescriptionStep> createState() => _DescriptionStepState();
}

class _DescriptionStepState extends State<DescriptionStep> {
  // TextEditingController를 멤버 변수로 선언 (포커스 유지를 위해)
  late final TextEditingController _maxGuestsController;
  late final TextEditingController _propertyDescriptionController;

  // 입주 시간 옵션
  static const List<String> _checkInTimes = [
    '14:00',
    '15:00',
    '16:00',
    '17:00'
  ];

  // 퇴실 시간 옵션
  static const List<String> _checkOutTimes = [
    '08:00',
    '09:00',
    '10:00',
    '11:00'
  ];

  String get _maxGuests => widget.formData['maxGuests']?.toString() ?? '';
  String get _checkInTime =>
      widget.formData['checkInTime']?.toString() ?? '14:00';
  String get _checkOutTime =>
      widget.formData['checkOutTime']?.toString() ?? '11:00';
  String get _propertyDescription =>
      widget.formData['propertyDescription']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    _maxGuestsController = TextEditingController(text: _maxGuests);
    _propertyDescriptionController = TextEditingController(text: _propertyDescription);
  }

  @override
  void didUpdateWidget(DescriptionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // formData가 외부에서 변경된 경우에만 컨트롤러 텍스트 업데이트
    if (oldWidget.formData['maxGuests'] != widget.formData['maxGuests']) {
      final newMaxGuests = _maxGuests;
      if (_maxGuestsController.text != newMaxGuests) {
        _maxGuestsController.text = newMaxGuests;
      }
    }
    if (oldWidget.formData['propertyDescription'] != widget.formData['propertyDescription']) {
      final newDescription = _propertyDescription;
      if (_propertyDescriptionController.text != newDescription) {
        _propertyDescriptionController.text = newDescription;
      }
    }
  }

  @override
  void dispose() {
    // 컨트롤러 정리
    _maxGuestsController.dispose();
    _propertyDescriptionController.dispose();
    super.dispose();
  }

  void _updateFormData(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(widget.formData);
    updated[key] = value;
    widget.onFormDataChange(updated);
  }

  bool _hasError(String field) {
    if (widget.validationErrors == null) return false;
    const errorMessages = {
      'maxGuests': '최대 인원을 입력해주세요',
      'propertyDescription': '방 소개를 입력해주세요',
      'propertyDescriptionLength': '방 소개를 최소 10글자 이상 입력해주세요',
    };

    if (field == 'propertyDescription') {
      return widget.validationErrors!
              .contains(errorMessages['propertyDescription']) ||
          widget.validationErrors!
              .contains(errorMessages['propertyDescriptionLength']);
    }

    return widget.validationErrors!.contains(errorMessages[field]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 최대 인원
          FormSection(
            icon: Icons.person,
            title: '최대 인원',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _maxGuestsController,
                  onChanged: (value) => _updateFormData('maxGuests', value),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 2',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    filled: true,
                    fillColor: _hasError('maxGuests')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('maxGuests')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('maxGuests')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('maxGuests')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '* 이 방에서 머물 수 있는 최대 인원을 입력해주세요',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_hasError('maxGuests'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '최대 인원을 입력해주세요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 입주 및 퇴실 시간
          FormSection(
            icon: Icons.access_time,
            title: '입주 및 퇴실 시간',
            child: Row(
              children: [
                // 입주 시간
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '입주 시간',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _checkInTimes.contains(_checkInTime)
                            ? _checkInTime
                            : '14:00',
                        items: _checkInTimes
                            .map((time) => DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _updateFormData('checkInTime', value);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primary600, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 퇴실 시간
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '퇴실 시간',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _checkOutTimes.contains(_checkOutTime)
                            ? _checkOutTime
                            : '11:00',
                        items: _checkOutTimes
                            .map((time) => DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _updateFormData('checkOutTime', value);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primary600, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 방 소개
          FormSection(
            icon: Icons.description,
            title: '방 소개',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _propertyDescriptionController,
                  onChanged: (value) =>
                      _updateFormData('propertyDescription', value),
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText:
                        '방에 대한 자세한 설명을 입력해주세요. 교통편, 주변 편의시설, 방의 특징 등을 자유롭게 작성해주세요.(최소 10글자 이상)',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    filled: true,
                    fillColor: _hasError('propertyDescription')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('propertyDescription')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('propertyDescription')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('propertyDescription')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '* 임차인이 방을 선택하는 데 도움이 되는 정보를 상세히 작성해주세요',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_hasError('propertyDescription') &&
                    widget.validationErrors!.contains('방 소개를 입력해주세요'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '방 소개를 입력해주세요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error600,
                      ),
                    ),
                  ),
                if (_hasError('propertyDescription') &&
                    widget.validationErrors!.contains('방 소개를 최소 10글자 이상 입력해주세요'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '방 소개를 최소 10글자 이상 입력해주세요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 안내 사항
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              border: Border.all(color: AppColors.primary100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 등록 전 확인사항',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary900,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoItem('모든 정보가 정확하게 입력되었는지 확인해주세요'),
                const SizedBox(height: 8),
                _buildInfoItem('등록 후 관리자 심사가 진행됩니다 (보통 1-2일 소요)'),
                const SizedBox(height: 8),
                _buildInfoItem('심사 승인 후 매물이 공개됩니다'),
                const SizedBox(height: 8),
                _buildInfoItem('등록 중인 내용은 자동으로 저장됩니다'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary800,
            height: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary800,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
