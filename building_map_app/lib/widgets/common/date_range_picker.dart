import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 날짜 범위 선택 위젯 (React UI 스타일 - 범위 선택)
/// 체크인/체크아웃 날짜를 동시에 선택하고 최소 계약 일수를 검증합니다.
class DateRangePicker extends StatefulWidget {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int minContractDays; // 최소 계약 일수 (예: 7일)
  final void Function(DateTime checkIn, DateTime checkOut) onDateSelected;
  final void Function(String)? onValidationError; // 검증 에러 콜백

  const DateRangePicker({
    super.key,
    this.checkInDate,
    this.checkOutDate,
    required this.minContractDays,
    required this.onDateSelected,
    this.onValidationError,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 범위 선택 버튼 (단일 버튼)
        InkWell(
          onTap: () => _showRangePicker(context),
          borderRadius: AppRadius.radiusMd,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              borderRadius: AppRadius.radiusMd,
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 20,
                  color: widget.checkInDate != null && widget.checkOutDate != null
                      ? AppColors.primary600
                      : AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '임대 기간 선택',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 최소 계약 일수 안내
        SizedBox(height: AppSpacing.sm),
        Text(
          '최소 ${widget.minContractDays}일 이상 선택해주세요',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _showRangePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DateRangePickerDialog(
        initialCheckIn: widget.checkInDate,
        initialCheckOut: widget.checkOutDate,
        minContractDays: widget.minContractDays,
        onDateRangeSelected: widget.onDateSelected,
        onValidationError: widget.onValidationError ?? (_) {}, // 콜백 전달 (없으면 빈 함수)
      ),
    );
  }
}

/// 날짜 범위 선택 다이얼로그 (React 스타일 범위 선택)
class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int minContractDays;
  final void Function(DateTime checkIn, DateTime checkOut) onDateRangeSelected;
  final void Function(String) onValidationError;

  const _DateRangePickerDialog({
    this.initialCheckIn,
    this.initialCheckOut,
    required this.minContractDays,
    required this.onDateRangeSelected,
    required this.onValidationError,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedMonth = widget.initialCheckIn ?? DateTime.now();
    _rangeStart = widget.initialCheckIn;
    _rangeEnd = widget.initialCheckOut;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
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
                Text('날짜 선택', style: AppTextStyles.headingMedium),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // 월 네비게이션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.neutral100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Text(
                  '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.neutral100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 요일 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['일', '월', '화', '수', '목', '금', '토'].asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final day = entry.value;
                  return SizedBox(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: index == 0
                            ? AppColors.error500
                            : index == 6
                            ? AppColors.primary600
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 8),

            // 날짜 그리드
            _buildDateGrid(),

            // 선택된 기간 표시
            if (_rangeStart != null && _rangeEnd != null) ...[
              const Divider(height: 32),
              Column(
                children: [
                  Text(
                    '임대 기간',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_rangeEnd!.difference(_rangeStart!).inDays}일',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.primary600,
                    ),
                  ),
                ],
              ),
            ],

            // 안내 메시지
            if (_rangeStart == null || _rangeEnd == null) ...[
              const Divider(height: 32),
              Text(
                '• 최소 ${widget.minContractDays}일부터 선택 가능합니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 초기화 및 확인 버튼
            if (_rangeStart != null && _rangeEnd != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _rangeStart = null;
                          _rangeEnd = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      child: Text(
                        '초기화',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDateRangeSelected(_rangeStart!, _rangeEnd!);
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
                      child: Text('선택 완료', style: AppTextStyles.buttonText),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 날짜 그리드 생성 (React 스타일)
  Widget _buildDateGrid() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일요일=0, 월요일=1, ...
    final daysInMonth = lastDayOfMonth.day;

    // 그리드에 표시할 날짜 목록 (앞뒤 빈칸 포함)
    final List<DateTime?> dateList = [];

    // 앞쪽 빈칸
    for (int i = 0; i < firstWeekday; i++) {
      dateList.add(null);
    }

    // 실제 날짜
    for (int day = 1; day <= daysInMonth; day++) {
      dateList.add(DateTime(_focusedMonth.year, _focusedMonth.month, day));
    }

    // 6주(42칸) 맞추기 위한 뒤쪽 빈칸
    while (dateList.length < 42) {
      dateList.add(null);
    }

    return Column(
      children: [
        // 날짜 그리드 (6주 x 7일)
        ...List.generate(6, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final index = weekIndex * 7 + dayIndex;
                final date = dateList[index];

                if (date == null) {
                  return const SizedBox(width: 36, height: 36);
                }

                return _buildDateCell(date);
              }),
            ),
          );
        }),
      ],
    );
  }

  /// 날짜 셀 생성
  Widget _buildDateCell(DateTime date) {
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

    // 선택 상태 확인
    final isStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isInRange =
        _rangeStart != null &&
        _rangeEnd != null &&
        date.isAfter(_rangeStart!) &&
        date.isBefore(_rangeEnd!);

    // 색상 결정
    Color? backgroundColor;
    Color? textColor;
    FontWeight? fontWeight;

    if (isStart || isEnd) {
      backgroundColor = AppColors.primary600;
      textColor = AppColors.textOnPrimary;
      fontWeight = FontWeight.w600;
    } else if (isInRange) {
      backgroundColor = AppColors.primary50;
      textColor = AppColors.primary600;
      fontWeight = FontWeight.normal;
    } else if (isToday) {
      backgroundColor = AppColors.primary50.withOpacity(0.5);
      textColor = AppColors.primary600;
      fontWeight = FontWeight.w600;
    } else if (isPast) {
      textColor = AppColors.textDisabled;
      fontWeight = FontWeight.normal;
    } else {
      textColor = AppColors.textPrimary;
      fontWeight = FontWeight.normal;
    }

    return InkWell(
      onTap: isPast ? null : () => _onDateSelected(date),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${date.day}',
          style: AppTextStyles.caption.copyWith(
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// 날짜 선택 핸들러 (React 로직)
  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      // 1. 시작일만 선택된 상태 → 종료일 선택
      if (_rangeStart != null && _rangeEnd == null) {
        // 같은 날짜 선택 시 무시
        if (_isSameDay(selectedDate, _rangeStart!)) {
          return;
        }

        // 날짜 순서 자동 정렬 (빠른 날짜를 체크인, 느린 날짜를 체크아웃으로)
        final DateTime earlierDate;
        final DateTime laterDate;

        if (selectedDate.isBefore(_rangeStart!)) {
          earlierDate = _normalizeDate(selectedDate);
          laterDate = _normalizeDate(_rangeStart!);
        } else {
          earlierDate = _normalizeDate(_rangeStart!);
          laterDate = _normalizeDate(selectedDate);
        }

        // 최소 기간 체크
        final duration = laterDate.difference(earlierDate).inDays;
        if (duration < widget.minContractDays) {
          // 에러 메시지를 위젯에 전달 (버튼 아래 표시)
          widget.onValidationError(
            '최소 ${widget.minContractDays}일 이상 선택해주세요. (현재: $duration일)',
          );
          return; // 다이얼로그는 열린 상태 유지
        }

        // 체크인/체크아웃 날짜 설정 (자동 정렬됨)
        _rangeStart = earlierDate;
        _rangeEnd = laterDate;
      }
      // 2. 범위가 이미 선택된 상태 → 초기화 후 새 시작일 설정
      else if (_rangeStart != null && _rangeEnd != null) {
        _rangeStart = _normalizeDate(selectedDate);
        _rangeEnd = null;
      }
      // 3. 아무것도 선택되지 않은 상태 → 시작일 설정
      else {
        _rangeStart = _normalizeDate(selectedDate);
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
}
