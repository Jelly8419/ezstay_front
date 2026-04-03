import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auto_message_template.dart';

/// 자동 메시지 폼 — 발송 시점 섹션
class AutoMessageTriggerSection extends StatelessWidget {
  final TriggerType triggerType;
  final int daysOffset;
  final String time;
  final List<String> timeOptions;
  final ValueChanged<TriggerType> onTriggerTypeChanged;
  final ValueChanged<int> onDaysOffsetChanged;
  final ValueChanged<String> onTimeChanged;

  const AutoMessageTriggerSection({
    super.key,
    required this.triggerType,
    required this.daysOffset,
    required this.time,
    required this.timeOptions,
    required this.onTriggerTypeChanged,
    required this.onDaysOffsetChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 20, color: AppColors.neutral600),
            const SizedBox(width: 8),
            Text('발송 시점',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral900)),
          ],
        ),
        const SizedBox(height: 12),

        _TriggerOption(
          label: '계약 확정(결제 완료) 즉시',
          type: TriggerType.contractConfirmed,
          selectedType: triggerType,
          onChanged: onTriggerTypeChanged,
        ),
        const SizedBox(height: 12),

        _TriggerOption(
          label: '입주일 기준',
          type: TriggerType.checkin,
          selectedType: triggerType,
          onChanged: onTriggerTypeChanged,
        ),
        if (triggerType == TriggerType.checkin) ...[
          const SizedBox(height: 12),
          _DaysAndTimeSelector(
            daysOffset: daysOffset,
            time: time,
            timeOptions: timeOptions,
            onDaysOffsetChanged: onDaysOffsetChanged,
            onTimeChanged: onTimeChanged,
          ),
        ],
        const SizedBox(height: 12),

        _TriggerOption(
          label: '퇴실일 기준',
          type: TriggerType.checkout,
          selectedType: triggerType,
          onChanged: onTriggerTypeChanged,
        ),
        if (triggerType == TriggerType.checkout) ...[
          const SizedBox(height: 12),
          _DaysAndTimeSelector(
            daysOffset: daysOffset,
            time: time,
            timeOptions: timeOptions,
            onDaysOffsetChanged: onDaysOffsetChanged,
            onTimeChanged: onTimeChanged,
          ),
        ],
      ],
    );
  }
}

class _TriggerOption extends StatelessWidget {
  final String label;
  final TriggerType type;
  final TriggerType selectedType;
  final ValueChanged<TriggerType> onChanged;

  const _TriggerOption({
    required this.label,
    required this.type,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedType == type;
    return InkWell(
      onTap: () => onChanged(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.blue500 : AppColors.gray200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
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
            const SizedBox(width: 12),
            Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.neutral900)),
          ],
        ),
      ),
    );
  }
}

class _DaysAndTimeSelector extends StatelessWidget {
  final int daysOffset;
  final String time;
  final List<String> timeOptions;
  final ValueChanged<int> onDaysOffsetChanged;
  final ValueChanged<String> onTimeChanged;

  const _DaysAndTimeSelector({
    required this.daysOffset,
    required this.time,
    required this.timeOptions,
    required this.onDaysOffsetChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('발송 일',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.neutral700)),
                const SizedBox(height: 8),
                _Dropdown<int>(
                  value: daysOffset,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('당일')),
                    DropdownMenuItem(value: 1, child: Text('1일 전')),
                    DropdownMenuItem(value: 2, child: Text('2일 전')),
                    DropdownMenuItem(value: 3, child: Text('3일 전')),
                    DropdownMenuItem(value: 4, child: Text('4일 전')),
                    DropdownMenuItem(value: 5, child: Text('5일 전')),
                  ],
                  onChanged: (v) => onDaysOffsetChanged(v!),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('발송 시각',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.neutral700)),
                const SizedBox(height: 8),
                _Dropdown<String>(
                  value: time,
                  items: timeOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => onTimeChanged(v!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral900),
        ),
      ),
    );
  }
}
