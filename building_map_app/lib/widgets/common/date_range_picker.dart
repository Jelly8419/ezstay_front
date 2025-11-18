import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';

/// 날짜 범위 선택 위젯 (React UI 스타일)
/// 체크인/체크아웃 날짜를 선택하고 최소 계약 일수를 검증합니다.
class DateRangePicker extends StatelessWidget {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int minContractDays; // 최소 계약 일수 (예: 7일)
  final Function(DateTime checkIn, DateTime checkOut) onDateSelected;
  final String? errorMessage;

  const DateRangePicker({
    super.key,
    this.checkInDate,
    this.checkOutDate,
    required this.minContractDays,
    required this.onDateSelected,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveUtil.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 선택 버튼들 (체크인/체크아웃)
        isMobile
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context),

        // 에러 메시지 표시
        if (errorMessage != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmallError,
          ),
        ],

        // 최소 계약 일수 안내
        SizedBox(height: AppSpacing.sm),
        Text(
          '최소 $minContractDays일 이상 선택해주세요',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            context: context,
            label: '체크인',
            date: checkInDate,
            icon: Icons.calendar_today,
            onTap: () => _showDatePicker(context, isCheckIn: true),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildDateButton(
            context: context,
            label: '체크아웃',
            date: checkOutDate,
            icon: Icons.event,
            onTap: () => _showDatePicker(context, isCheckIn: false),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildDateButton(
          context: context,
          label: '체크인',
          date: checkInDate,
          icon: Icons.calendar_today,
          onTap: () => _showDatePicker(context, isCheckIn: true),
        ),
        SizedBox(height: AppSpacing.md),
        _buildDateButton(
          context: context,
          label: '체크아웃',
          date: checkOutDate,
          icon: Icons.event,
          onTap: () => _showDatePicker(context, isCheckIn: false),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: errorMessage != null ? AppColors.error500 : AppColors.border,
            width: 1,
          ),
          borderRadius: AppRadius.radiusMd,
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: date != null ? AppColors.primary600 : AppColors.textSecondary,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    date != null
                        ? _formatDate(date)
                        : '날짜 선택',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _showDatePicker(BuildContext context, {required bool isCheckIn}) {
    showDialog(
      context: context,
      builder: (context) => _DatePickerDialog(
        initialDate: isCheckIn ? checkInDate : checkOutDate,
        minDate: DateTime.now(),
        maxDate: DateTime.now().add(const Duration(days: 365)),
        onDateSelected: (selectedDate) {
          if (isCheckIn) {
            // 체크인 날짜 선택 시
            if (checkOutDate != null) {
              // 체크아웃이 이미 선택된 경우, 체크인이 체크아웃보다 늦으면 체크아웃 초기화
              if (selectedDate.isAfter(checkOutDate!) ||
                  selectedDate.isAtSameMomentAs(checkOutDate!)) {
                // 체크아웃을 체크인 + 최소 계약 일수로 설정
                final newCheckOut = selectedDate.add(Duration(days: minContractDays));
                onDateSelected(selectedDate, newCheckOut);
              } else {
                onDateSelected(selectedDate, checkOutDate!);
              }
            } else {
              // 체크아웃이 없으면 최소 계약 일수만큼 자동 설정
              final newCheckOut = selectedDate.add(Duration(days: minContractDays));
              onDateSelected(selectedDate, newCheckOut);
            }
          } else {
            // 체크아웃 날짜 선택 시
            if (checkInDate != null) {
              final days = selectedDate.difference(checkInDate!).inDays;
              if (days < minContractDays) {
                // 최소 계약 일수 미만이면 에러 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('최소 $minContractDays일 이상 선택해주세요. (현재: $days일)'),
                    backgroundColor: AppColors.error500,
                  ),
                );
                return;
              }
              onDateSelected(checkInDate!, selectedDate);
            } else {
              // 체크인이 없으면 체크아웃을 먼저 선택할 수 없음
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('먼저 체크인 날짜를 선택해주세요.'),
                  backgroundColor: AppColors.warning500,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

/// 날짜 선택 다이얼로그 (TableCalendar 사용)
class _DatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final Function(DateTime) onDateSelected;

  const _DatePickerDialog({
    this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '날짜 선택',
                  style: AppTextStyles.headingMedium,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // 캘린더
            TableCalendar(
              firstDay: widget.minDate,
              lastDay: widget.maxDate,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isBefore(widget.minDate) ||
                    selectedDay.isAfter(widget.maxDate)) {
                  return;
                }

                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary600,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary100,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              locale: 'ko_KR',
            ),

            SizedBox(height: AppSpacing.lg),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDateSelected(_selectedDay);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
                child: Text(
                  '선택 완료',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
