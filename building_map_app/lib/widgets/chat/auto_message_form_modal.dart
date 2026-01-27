import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auto_message_template.dart';

/// 자동 메시지 추가/수정 모달
/// React AutoMessageFormModal.tsx를 Flutter로 완전 복제
class AutoMessageFormModal extends StatefulWidget {
  final AutoMessageTemplate? editingTemplate;
  final List<PropertyInfo> properties;
  final Function(AutoMessageTemplate) onSave;

  const AutoMessageFormModal({
    super.key,
    this.editingTemplate,
    required this.properties,
    required this.onSave,
  });

  /// 모달 표시 헬퍼
  static Future<void> show({
    required BuildContext context,
    AutoMessageTemplate? editingTemplate,
    required List<PropertyInfo> properties,
    required Function(AutoMessageTemplate) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AutoMessageFormModal(
        editingTemplate: editingTemplate,
        properties: properties,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AutoMessageFormModal> createState() => _AutoMessageFormModalState();
}

class _AutoMessageFormModalState extends State<AutoMessageFormModal> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;

  TriggerType _triggerType = TriggerType.checkin;
  int _daysOffset = 1;
  String _time = '09:00';
  List<String> _selectedProperties = [];
  bool _isActive = true;

  // 시간 옵션 (08:00 ~ 22:00)
  final List<String> _timeOptions = List.generate(
    15,
    (index) => '${(index + 8).toString().padLeft(2, '0')}:00',
  );

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _contentFocusNode = FocusNode();

    if (widget.editingTemplate != null) {
      final template = widget.editingTemplate!;
      _titleController.text = template.title;
      _contentController.text = template.content;
      _triggerType = template.trigger.type;
      _daysOffset = template.trigger.daysOffset ?? 1;
      _time = template.trigger.time ?? '09:00';
      _selectedProperties = List.from(template.appliedProperties);
      _isActive = template.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _insertVariable(String variable) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, variable);
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: start + variable.length,
    );

    _contentFocusNode.requestFocus();
  }

  void _toggleProperty(String propertyId) {
    setState(() {
      if (_selectedProperties.contains(propertyId)) {
        _selectedProperties.remove(propertyId);
      } else {
        _selectedProperties.add(propertyId);
      }
    });
  }

  void _toggleAllProperties() {
    setState(() {
      if (_selectedProperties.length == widget.properties.length) {
        _selectedProperties.clear();
      } else {
        _selectedProperties = widget.properties.map((p) => p.id).toList();
      }
    });
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목, 메시지 내용을 모두 입력해주세요.'),
        ),
      );
      return;
    }

    final template = AutoMessageTemplate(
      id: widget.editingTemplate?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      trigger: MessageTrigger(
        type: _triggerType,
        daysOffset: _triggerType != TriggerType.contractConfirmed ? _daysOffset : null,
        time: _triggerType != TriggerType.contractConfirmed ? _time : null,
      ),
      appliedProperties: _selectedProperties,
      isActive: _isActive,
      createdAt: widget.editingTemplate?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(template);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingTemplate != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9, // max-h-[90vh]
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral0, // bg-white
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12), // rounded-xl
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (sticky top-0)
          _buildHeader(isEditing),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24, // px-6
                right: 24,
                top: 24, // py-6
                bottom: 24 + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title input
                  _buildTitleInput(),
                  const SizedBox(height: 24), // space-y-6

                  // Content input
                  _buildContentInput(),
                  const SizedBox(height: 24),

                  // Trigger Type
                  _buildTriggerSection(),
                  const SizedBox(height: 24),

                  // Applied Properties
                  _buildPropertiesSection(),
                  const SizedBox(height: 24),

                  // Active Status
                  _buildActiveStatusSection(),
                ],
              ),
            ),
          ),

          // Footer (sticky bottom-0)
          _buildFooter(),
        ],
      ),
    );
  }

  /// 헤더 (React: sticky top-0 bg-white border-b border-gray-200 px-6 py-4)
  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200), // border-b border-gray-200
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditing ? '자동메시지 수정' : '자동메시지 추가',
            style: AppTextStyles.headingSmall,
          ),
          // X button (React: p-2 hover:bg-gray-100 rounded-lg)
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8), // rounded-lg
            child: Container(
              padding: const EdgeInsets.all(8), // p-2
              child: const Icon(
                Icons.close,
                size: 20, // w-5 h-5
                color: AppColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 제목 입력 (React: space-y-2)
  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제목',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral900, // text-gray-900
          ),
        ),
        const SizedBox(height: 8), // space-y-2
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '예: 입주 안내',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral400,
            ),
            // React: w-full px-4 py-3 border border-gray-300 rounded-lg
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, // px-4
              vertical: 12, // py-3
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // rounded-lg
              borderSide: const BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blue500, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// 메시지 내용 입력
  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메시지 내용',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          maxLines: 8, // rows={8}
          decoration: InputDecoration(
            hintText: '게스트에게 전달할 메시지를 입력하세요...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blue500, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Variable buttons (React: flex gap-2)
        Row(
          children: [
            // {공동현관비밀번호} button
            _buildVariableButton('{공동현관비밀번호}'),
            const SizedBox(width: 8), // gap-2
            // {방비밀번호} button
            _buildVariableButton('{방비밀번호}'),
          ],
        ),
        const SizedBox(height: 8),

        // Help text (React: text-sm text-gray-500)
        Text(
          '변수 버튼을 클릭하면 커서 위치에 변수가 삽입됩니다. 해당 방의 실제 값으로 자동 대체됩니다.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral500, // text-gray-500
          ),
        ),
      ],
    );
  }

  /// 변수 삽입 버튼 (React: text-sm px-3 py-1.5 bg-blue-50 text-blue-700 font-semibold rounded)
  Widget _buildVariableButton(String variable) {
    return InkWell(
      onTap: () => _insertVariable(variable),
      borderRadius: BorderRadius.circular(4), // rounded
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, // px-3
          vertical: 6, // py-1.5
        ),
        decoration: BoxDecoration(
          color: AppColors.blue50, // bg-blue-50
          border: Border.all(color: AppColors.blue100), // border border-blue-200
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          variable,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.blue700, // text-blue-700
            fontWeight: FontWeight.w600, // font-semibold
          ),
        ),
      ),
    );
  }

  /// 발송 시점 섹션
  Widget _buildTriggerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon (React: flex items-center gap-2)
        Row(
          children: [
            Icon(
              Icons.access_time, // Clock icon
              size: 20, // w-5 h-5
              color: AppColors.neutral600, // text-gray-600
            ),
            const SizedBox(width: 8), // gap-2
            Text(
              '발송 시점',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // space-y-3

        // Radio options
        _buildTriggerOption(
          TriggerType.contractConfirmed,
          '계약 확정(결제 완료) 즉시',
        ),
        const SizedBox(height: 12),

        _buildTriggerOption(
          TriggerType.checkin,
          '입주일 기준',
        ),
        if (_triggerType == TriggerType.checkin) ...[
          const SizedBox(height: 12),
          _buildDaysAndTimeSelector(),
        ],
        const SizedBox(height: 12),

        _buildTriggerOption(
          TriggerType.checkout,
          '퇴실일 기준',
        ),
        if (_triggerType == TriggerType.checkout) ...[
          const SizedBox(height: 12),
          _buildDaysAndTimeSelector(),
        ],
      ],
    );
  }

  /// 트리거 옵션 라디오 (React: flex items-center gap-3 p-3 border-2 rounded-lg cursor-pointer)
  Widget _buildTriggerOption(TriggerType type, String label) {
    final isSelected = _triggerType == type;

    return InkWell(
      onTap: () => setState(() => _triggerType = type),
      borderRadius: BorderRadius.circular(8), // rounded-lg
      child: Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.blue500 : AppColors.gray200,
            width: 2, // border-2
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 16, // w-4
              height: 16, // h-4
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.blue500 : AppColors.neutral400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue500,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12), // gap-3
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 발송 일/시각 선택 (React: ml-7 grid grid-cols-2 gap-4)
  Widget _buildDaysAndTimeSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 28), // ml-7
      child: Row(
        children: [
          // Days offset dropdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '발송 일',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral700, // text-gray-700
                  ),
                ),
                const SizedBox(height: 8), // space-y-2
                _buildDropdown(
                  value: _daysOffset,
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('당일')),
                    const DropdownMenuItem(value: 1, child: Text('1일 전')),
                    const DropdownMenuItem(value: 2, child: Text('2일 전')),
                    const DropdownMenuItem(value: 3, child: Text('3일 전')),
                    const DropdownMenuItem(value: 4, child: Text('4일 전')),
                    const DropdownMenuItem(value: 5, child: Text('5일 전')),
                  ],
                  onChanged: (value) => setState(() => _daysOffset = value!),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // gap-4

          // Time dropdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '발송 시각',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _time,
                  items: _timeOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setState(() => _time = value!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 드롭다운 위젯 (React: w-full px-4 py-2 border border-gray-300 rounded-lg)
  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8), // rounded-lg
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral900,
          ),
        ),
      ),
    );
  }

  /// 사용할 방 섹션
  Widget _buildPropertiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon
        Row(
          children: [
            Icon(
              Icons.calendar_today, // Calendar icon
              size: 20,
              color: AppColors.neutral600,
            ),
            const SizedBox(width: 8),
            Text(
              '사용할 방',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Toggle all button (React: text-sm text-blue-600 hover:text-blue-700)
        InkWell(
          onTap: _toggleAllProperties,
          child: Text(
            _selectedProperties.length == widget.properties.length
                ? '전체 해제'
                : '전체 선택',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.blue600, // text-blue-600
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Property list (React: space-y-2 max-h-48 overflow-y-auto border border-gray-200 rounded-lg p-3)
        Container(
          constraints: const BoxConstraints(maxHeight: 192), // max-h-48
          padding: const EdgeInsets.all(12), // p-3
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(8), // rounded-lg
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.properties.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8), // space-y-2
            itemBuilder: (context, index) {
              final property = widget.properties[index];
              final isSelected = _selectedProperties.contains(property.id);

              // React: flex items-center gap-3 p-2 hover:bg-gray-50 rounded cursor-pointer
              return InkWell(
                onTap: () => _toggleProperty(property.id),
                borderRadius: BorderRadius.circular(4), // rounded
                child: Container(
                  padding: const EdgeInsets.all(8), // p-2
                  child: Row(
                    children: [
                      // Checkbox (React: w-4 h-4)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleProperty(property.id),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12), // gap-3
                      Expanded(
                        child: Text(
                          property.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral700, // text-gray-700
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Selected count (React: text-sm text-gray-500)
        Text(
          '선택된 방: ${_selectedProperties.length}개',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }

  /// 활성화 상태 섹션 (React: flex items-center justify-between p-4 bg-gray-50 rounded-lg)
  Widget _buildActiveStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: AppColors.gray50, // bg-gray-50
        borderRadius: BorderRadius.circular(8), // rounded-lg
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '활성화 상태',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral900, // text-gray-900
            ),
          ),
          // Toggle switch
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeTrackColor: AppColors.blue600, // peer-checked:bg-blue-600
            inactiveTrackColor: AppColors.gray200, // bg-gray-200
          ),
        ],
      ),
    );
  }

  /// 푸터 (React: sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3)
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          top: BorderSide(color: AppColors.gray200), // border-t border-gray-200
        ),
      ),
      child: Row(
        children: [
          // Cancel button (React: flex-1 py-3 bg-gray-100 text-gray-700 rounded-lg)
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8), // rounded-lg
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12), // py-3
                decoration: BoxDecoration(
                  color: AppColors.neutral100, // bg-gray-100
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '취소',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral700, // text-gray-700
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12), // gap-3

          // Save button (React: flex-1 py-3 bg-blue-600 text-white rounded-lg)
          Expanded(
            child: InkWell(
              onTap: _handleSave,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue600, // bg-blue-600
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '저장',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral0, // text-white
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
