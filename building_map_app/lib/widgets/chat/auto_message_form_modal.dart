import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auto_message_template.dart';
import 'auto_message_trigger_section.dart';
import 'auto_message_property_selector.dart';

/// 자동 메시지 추가/수정 모달
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
    _contentController.text = text.replaceRange(start, end, variable);
    _contentController.selection =
        TextSelection.collapsed(offset: start + variable.length);
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
        const SnackBar(content: Text('제목, 메시지 내용을 모두 입력해주세요.')),
      );
      return;
    }

    final template = AutoMessageTemplate(
      id: widget.editingTemplate?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      trigger: MessageTrigger(
        type: _triggerType,
        daysOffset:
            _triggerType != TriggerType.contractConfirmed ? _daysOffset : null,
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
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isEditing),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleInput(),
                  const SizedBox(height: 24),
                  _buildContentInput(),
                  const SizedBox(height: 24),

                  AutoMessageTriggerSection(
                    triggerType: _triggerType,
                    daysOffset: _daysOffset,
                    time: _time,
                    timeOptions: _timeOptions,
                    onTriggerTypeChanged: (v) =>
                        setState(() => _triggerType = v),
                    onDaysOffsetChanged: (v) =>
                        setState(() => _daysOffset = v),
                    onTimeChanged: (v) => setState(() => _time = v),
                  ),
                  const SizedBox(height: 24),

                  AutoMessagePropertySelector(
                    properties: widget.properties,
                    selectedProperties: _selectedProperties,
                    onToggleProperty: _toggleProperty,
                    onToggleAll: _toggleAllProperties,
                  ),
                  const SizedBox(height: 24),

                  _buildActiveStatusSection(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isEditing ? '자동메시지 수정' : '자동메시지 추가',
              style: AppTextStyles.headingSmall),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.close, size: 20, color: AppColors.neutral900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('제목',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral900)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: _inputDecoration('예: 입주 안내'),
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('메시지 내용',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral900)),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          maxLines: 8,
          decoration: _inputDecoration('임차인에게 전달할 메시지를 입력하세요...'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _VariableButton(
              label: '{공동현관비밀번호}',
              onTap: () => _insertVariable('{공동현관비밀번호}'),
            ),
            const SizedBox(width: 8),
            _VariableButton(
              label: '{방비밀번호}',
              onTap: () => _insertVariable('{방비밀번호}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '버튼을 클릭하여 입력된 텍스트는 임차인에게 전송 시, 해당 방 정보에 저장된 내용으로 보여집니다. (예 : {방 비밀번호} > *1234)',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
        ),
      ],
    );
  }

  Widget _buildActiveStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('활성화 상태',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.neutral900)),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeTrackColor: AppColors.blue600,
            inactiveTrackColor: AppColors.gray200,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('취소',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.neutral700)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: _handleSave,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('저장',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.neutral0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }
}

class _VariableButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _VariableButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blue50,
          border: Border.all(color: AppColors.blue100),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.blue700,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}
