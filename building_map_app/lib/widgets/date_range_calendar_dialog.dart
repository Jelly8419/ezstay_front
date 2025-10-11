import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/search_filters.dart';
import '../constants/app_constants.dart';

/// 임대 일정 선택 캘린더 다이얼로그
///
/// 요구사항:
/// - 첫 번째 클릭: 시작일 설정
/// - 두 번째 클릭: 종료일 설정 (시작일보다 이후 날짜만)
/// - 세 번째 클릭: 초기화 후 새로운 시작일로 설정
/// - 최소 임대 기간: 7일
/// - 최대 임대 기간: 90일
class DateRangeCalendarDialog extends StatefulWidget {
  final DateRange? initialDateRange;
  final Function(DateRange) onDateRangeSelected;

  const DateRangeCalendarDialog({
    super.key,
    this.initialDateRange,
    required this.onDateRangeSelected,
  });

  @override
  State<DateRangeCalendarDialog> createState() => _DateRangeCalendarDialogState();
}

class _DateRangeCalendarDialogState extends State<DateRangeCalendarDialog> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateRange != null) {
      _rangeStart = widget.initialDateRange!.startDate;
      _rangeEnd = widget.initialDateRange!.endDate;
      _focusedDay = _rangeStart!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '임대 일정 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 설명 텍스트
            Text(
              '최소 7일, 최대 90일까지 선택 가능합니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // 선택된 날짜 표시
            if (_rangeStart != null || _rangeEnd != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _rangeStart != null
                          ? _formatDate(_rangeStart!)
                          : '시작일 선택',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _rangeEnd != null
                          ? _formatDate(_rangeEnd!)
                          : '종료일 선택',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (_rangeStart != null && _rangeEnd != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${_rangeEnd!.difference(_rangeStart!).inDays}일)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 캘린더
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              locale: 'ko_KR',
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                // 오늘 날짜 스타일
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),

                // 선택된 날짜 스타일
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),

                // 범위 시작/종료 스타일
                rangeStartDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),

                // 범위 내 날짜 스타일
                rangeHighlightColor: AppColors.primary.withValues(alpha: 0.2),
                withinRangeDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),

                // 과거 날짜 비활성화
                disabledTextStyle: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              enabledDayPredicate: (day) {
                // 오늘 이후 날짜만 선택 가능
                return day.isAfter(DateTime.now().subtract(const Duration(days: 1)));
              },
            ),

            // 에러 메시지
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 버튼 영역
            Row(
              children: [
                // 초기화 버튼
                if (_rangeStart != null || _rangeEnd != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _rangeStart = null;
                        _rangeEnd = null;
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('초기화'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),

                // 취소 버튼
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),

                // 적용 버튼
                ElevatedButton(
                  onPressed: _rangeStart != null && _rangeEnd != null
                      ? () {
                          final dateRange = DateRange(
                            startDate: _rangeStart!,
                            endDate: _rangeEnd!,
                          );
                          widget.onDateRangeSelected(dateRange);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('적용'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _errorMessage = null;
      _focusedDay = focusedDay;

      // 1. 범위가 완성되지 않은 경우 (시작일만 설정되어 있음)
      if (_rangeStart != null && _rangeEnd == null) {
        // 선택한 날짜가 시작일보다 이전이면, 시작일을 재설정
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeStart = _normalizeDate(selectedDay);
          _rangeEnd = null;
          return;
        }

        // 선택한 날짜가 시작일과 같으면 무시
        if (_isSameDay(selectedDay, _rangeStart!)) {
          return;
        }

        // 최소 기간 체크 (7일)
        final duration = selectedDay.difference(_rangeStart!).inDays;
        if (duration < 7) {
          _showToastMessage('이지스테이는 최소 7일부터 예약할 수 있어요');
          return;
        }

        // 최대 기간 체크 (90일)
        if (duration > 90) {
          _showToastMessage('이지스테이는 최대 90일까지 예약할 수 있어요');
          return;
        }

        // 종료일 설정
        _rangeEnd = _normalizeDate(selectedDay);
      }
      // 2. 범위가 이미 완성된 경우 (시작일과 종료일 모두 설정됨) - 초기화 후 새 시작일 설정
      else if (_rangeStart != null && _rangeEnd != null) {
        _rangeStart = _normalizeDate(selectedDay);
        _rangeEnd = null;
      }
      // 3. 아무것도 설정되지 않은 경우 - 시작일 설정
      else {
        _rangeStart = _normalizeDate(selectedDay);
        _rangeEnd = null;
      }
    });
  }

  /// 날짜를 00:00:00으로 정규화
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 두 날짜가 같은 날인지 확인
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 날짜 포맷팅 (예: 2025.10.15)
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 토스트 메시지 표시
  void _showToastMessage(String message) {
    setState(() {
      _errorMessage = message;
    });

    // 3초 후 에러 메시지 제거
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }
}
