import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';

/// 날짜 범위 선택 위젯 (React UI 스타일 - 범위 선택)
/// 체크인/체크아웃 날짜를 동시에 선택하고 최소/최대 계약 일수를 검증합니다.
///
/// 기능:
/// - 최소/최대 계약 기간 검증
/// - 단일 날짜 토글 (같은 날짜 재클릭 시 선택 해제)
/// - 최소 계약기간 시각화 (시작일 선택 시 최소 범위 표시)
/// - 커스터마이징 가능한 placeholder, helper 텍스트
class DateRangePicker extends StatefulWidget {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int minContractDays; // 최소 계약 일수 (예: 7일)
  final int? maxContractDays; // 최대 계약 일수 (예: 90일) - Optional
  final void Function(DateTime checkIn, DateTime checkOut) onDateSelected;
  final void Function()? onDateCleared; // 날짜 선택 해제 콜백 - Optional
  final void Function(String)? onValidationError; // 검증 에러 콜백
  final String placeholderText; // 기본값: '임대 기간 선택'
  final bool showHelperText; // 헬퍼 텍스트 표시 여부 (기본값: true)
  final String? customHelperText; // 커스텀 헬퍼 텍스트 (null이면 기본 메시지)
  final List<UnavailablePeriod> unavailablePeriods; // 임대 불가능 기간 목록

  const DateRangePicker({
    super.key,
    this.checkInDate,
    this.checkOutDate,
    required this.minContractDays,
    this.maxContractDays,
    required this.onDateSelected,
    this.onDateCleared,
    this.onValidationError,
    this.placeholderText = '임대 기간 선택',
    this.showHelperText = true,
    this.customHelperText,
    this.unavailablePeriods = const [],
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  /// 날짜 범위 포맷팅 (React UI 스타일)
  String _formatDateRange() {
    if (widget.checkInDate == null) return widget.placeholderText;

    final startDate = widget.checkInDate!;
    if (widget.checkOutDate == null) {
      return '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')} - 종료일 선택';
    }

    final endDate = widget.checkOutDate!;
    return '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')} - ${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
  }

  /// 헬퍼 텍스트 생성
  String _getHelperText() {
    if (widget.customHelperText != null) {
      return widget.customHelperText!;
    }
    if (widget.maxContractDays != null) {
      return '최소 ${widget.minContractDays}일 ~ 최대 ${widget.maxContractDays}일';
    }
    return '최소 ${widget.minContractDays}일 이상 선택해주세요';
  }

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
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: AppRadius.radiusMd,
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 20,
                  color:
                      widget.checkInDate != null && widget.checkOutDate != null
                      ? AppColors.primary600
                      : AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _formatDateRange(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.checkInDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          widget.checkInDate != null &&
                              widget.checkOutDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 헬퍼 텍스트
        if (widget.showHelperText) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            _getHelperText(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  void _showRangePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DateRangePickerDialog(
        initialCheckIn: widget.checkInDate,
        initialCheckOut: widget.checkOutDate,
        minContractDays: widget.minContractDays,
        maxContractDays: widget.maxContractDays,
        onDateRangeSelected: widget.onDateSelected,
        onDateCleared: widget.onDateCleared,
        onValidationError: widget.onValidationError ?? (_) {},
        unavailablePeriods: widget.unavailablePeriods,
      ),
    );
  }
}

/// 날짜 범위 선택 다이얼로그 (React 스타일 범위 선택)
class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int minContractDays;
  final int? maxContractDays;
  final void Function(DateTime checkIn, DateTime checkOut) onDateRangeSelected;
  final void Function()? onDateCleared;
  final void Function(String) onValidationError;
  final List<UnavailablePeriod> unavailablePeriods;

  const _DateRangePickerDialog({
    this.initialCheckIn,
    this.initialCheckOut,
    required this.minContractDays,
    this.maxContractDays,
    required this.onDateRangeSelected,
    this.onDateCleared,
    required this.onValidationError,
    this.unavailablePeriods = const [],
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String? _unavailableMessage; // 비가용 날짜 클릭 시 안내 메시지

  @override
  void initState() {
    super.initState();
    _focusedMonth = widget.initialCheckIn ?? DateTime.now();
    _rangeStart = widget.initialCheckIn;
    _rangeEnd = widget.initialCheckOut;
  }

  /// 특정 날짜가 임대 불가능 기간에 해당하는지 확인
  bool _isUnavailableDate(DateTime date) {
    for (final period in widget.unavailablePeriods) {
      if (period.contains(date)) return true;
    }
    return false;
  }

  /// 선택한 범위 안에 임대 불가능 기간이 포함되는지 확인
  bool _rangeContainsUnavailable(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    for (final period in widget.unavailablePeriods) {
      final periodStart = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final periodEnd = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
      // 두 범위가 겹치는지 확인
      if (!periodEnd.isBefore(normalizedStart) && !periodStart.isAfter(normalizedEnd)) {
        return true;
      }
    }
    return false;
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
                  color: AppColors.textPrimary,
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

            // 비가용 날짜 클릭 시 안내 메시지
            if (_unavailableMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error50,
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(color: AppColors.error500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 16,
                      color: AppColors.error500,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _unavailableMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 선택된 기간 표시
            if (_rangeStart != null && _rangeEnd != null) ...[
              const Divider(height: 32),
              Column(
                children: [
                  Text(
                    '임대 기간',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
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

            // 안내 메시지 (시작일만 선택된 상태)
            if (_rangeStart != null && _rangeEnd == null) ...[
              const Divider(height: 32),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.primary600,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '최소 ${widget.minContractDays}일${widget.maxContractDays != null ? ' ~ 최대 ${widget.maxContractDays}일' : ''} 선택 가능',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 안내 메시지 (아무것도 선택 안됨)
            if (_rangeStart == null) ...[
              const Divider(height: 32),
              Text(
                '• 최소 ${widget.minContractDays}일부터 선택 가능합니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
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
    final isUnavailable = _isUnavailableDate(date);
    final isDisabled = isPast || isUnavailable;

    // 선택 상태 확인
    final isStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isInRange =
        _rangeStart != null &&
        _rangeEnd != null &&
        date.isAfter(_rangeStart!) &&
        date.isBefore(_rangeEnd!);

    // 최소 계약기간 범위 확인 (시작일만 선택된 상태)
    final isInMinRange = _isInMinContractRange(date);

    // 색상 결정
    Color? backgroundColor;
    Color? textColor;
    FontWeight? fontWeight;

    if (isUnavailable && !isPast) {
      // 임대 불가능 기간: 회색 배경 + 취소선 효과
      backgroundColor = AppColors.neutral200;
      textColor = AppColors.neutral400;
      fontWeight = FontWeight.normal;
    } else if (isStart || isEnd) {
      // 시작일/종료일: Primary 색상
      backgroundColor = AppColors.primary600;
      textColor = AppColors.textOnPrimary;
      fontWeight = FontWeight.w600;
    } else if (isInRange) {
      // 선택된 범위 내: 연한 Primary
      backgroundColor = AppColors.primary50;
      textColor = AppColors.primary600;
      fontWeight = FontWeight.normal;
    } else if (isInMinRange) {
      // 최소 계약기간 범위: 회색 (선택 불가 표시)
      backgroundColor = AppColors.neutral100;
      textColor = AppColors.textDisabled;
      fontWeight = FontWeight.normal;
    } else if (isToday) {
      // 오늘: 연한 Primary
      backgroundColor = AppColors.primary50.withValues(alpha: 0.5);
      textColor = AppColors.primary600;
      fontWeight = FontWeight.w600;
    } else if (isPast) {
      // 과거: 비활성화
      textColor = AppColors.textDisabled;
      fontWeight = FontWeight.normal;
    } else {
      // 기본
      textColor = AppColors.textPrimary;
      fontWeight = FontWeight.normal;
    }

    return InkWell(
      onTap: isDisabled
          ? (isUnavailable
              ? () {
                  setState(() {
                    _unavailableMessage = '해당 기간은 임대가 불가능합니다.';
                  });
                }
              : null)
          : () => _onDateSelected(date),
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
            decoration: isUnavailable && !isPast
                ? TextDecoration.lineThrough
                : null,
            decorationColor: AppColors.neutral400,
          ),
        ),
      ),
    );
  }

  /// 최소 계약기간 범위 내인지 확인 (시작일만 선택된 상태에서만 활성화)
  bool _isInMinContractRange(DateTime date) {
    // 시작일만 선택된 상태가 아니면 false
    if (_rangeStart == null || _rangeEnd != null) return false;

    // 시작일 자체는 범위에 포함하지 않음 (이미 isStart로 처리됨)
    if (_isSameDay(date, _rangeStart!)) return false;

    // 시작일 + 1 ~ 시작일 + (minContractDays - 1) 범위
    final minEndDate = _rangeStart!.add(Duration(days: widget.minContractDays - 1));

    return date.isAfter(_rangeStart!) &&
           (date.isBefore(minEndDate) || _isSameDay(date, minEndDate));
  }

  /// 날짜 선택 핸들러
  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      // 비가용 메시지 초기화
      _unavailableMessage = null;

      // 1. 시작일만 선택된 상태에서 같은 날짜 클릭 → 선택 해제 (토글)
      if (_rangeStart != null && _rangeEnd == null && _isSameDay(selectedDate, _rangeStart!)) {
        _rangeStart = null;
        _rangeEnd = null;
        // 선택 해제 콜백 호출
        widget.onDateCleared?.call();
        return;
      }

      // 2. 시작일만 선택된 상태 → 종료일 선택
      if (_rangeStart != null && _rangeEnd == null) {
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

        // 기간 계산
        final duration = laterDate.difference(earlierDate).inDays;

        // 최소 기간 체크
        if (duration < widget.minContractDays) {
          widget.onValidationError(
            '이 방의 최소 계약기간은 ${widget.minContractDays}일 입니다.',
          );
          return; // 다이얼로그는 열린 상태 유지
        }

        // 최대 기간 체크
        if (widget.maxContractDays != null && duration > widget.maxContractDays!) {
          widget.onValidationError(
            '최대 ${widget.maxContractDays}일까지 선택할 수 있습니다.',
          );
          return;
        }

        // 선택 범위 내에 임대 불가능 기간이 포함되는지 체크
        if (_rangeContainsUnavailable(earlierDate, laterDate)) {
          _unavailableMessage = '선택한 기간에 임대 불가능한 날짜가 포함되어 있습니다.';
          return;
        }

        // 체크인/체크아웃 날짜 설정 (자동 정렬됨)
        _rangeStart = earlierDate;
        _rangeEnd = laterDate;
      }
      // 3. 범위가 이미 선택된 상태 → 초기화 후 새 시작일 설정
      else if (_rangeStart != null && _rangeEnd != null) {
        _rangeStart = _normalizeDate(selectedDate);
        _rangeEnd = null;
      }
      // 4. 아무것도 선택되지 않은 상태 → 시작일 설정
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

// ============================================================
// SingleDatePicker — DateRangePicker와 동일 디자인의 단일 날짜 선택
// ============================================================

/// 단일 날짜 선택 위젯 ([DateRangePicker]와 동일한 디자인 토큰을 따른다).
///
/// 범위 전용 기능(최소/최대 계약일, unavailablePeriods)은 제외하고
/// 한 날짜만 선택해 [onDateSelected]로 반환한다.
class SingleDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onDateCleared;
  final String placeholderText;
  final String? helperText;
  final DateTime? minDate;
  final DateTime? maxDate;

  const SingleDatePicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.onDateCleared,
    this.placeholderText = '날짜 선택',
    this.helperText,
    this.minDate,
    this.maxDate,
  });

  String _formatLabel() {
    final d = selectedDate;
    if (d == null) return placeholderText;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPicker(context),
          borderRadius: AppRadius.radiusMd,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: AppRadius.radiusMd,
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: selectedDate != null
                      ? AppColors.primary600
                      : AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _formatLabel(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selectedDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            helperText!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SingleDatePickerDialog(
        initialDate: selectedDate,
        minDate: minDate,
        maxDate: maxDate,
        onDateSelected: (d) {
          onDateSelected(d);
        },
        onDateCleared: onDateCleared,
      ),
    );
  }
}

class _SingleDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onDateCleared;

  const _SingleDatePickerDialog({
    this.initialDate,
    this.minDate,
    this.maxDate,
    required this.onDateSelected,
    this.onDateCleared,
  });

  @override
  State<_SingleDatePickerDialog> createState() =>
      _SingleDatePickerDialogState();
}

class _SingleDatePickerDialogState extends State<_SingleDatePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _focusedMonth = widget.initialDate ?? DateTime.now();
    _selected = widget.initialDate;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isDisabled(DateTime date) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final min = widget.minDate ?? todayNorm;
    if (date.isBefore(_normalize(min))) return true;
    if (widget.maxDate != null && date.isAfter(_normalize(widget.maxDate!))) {
      return true;
    }
    return false;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('날짜 선택', style: AppTextStyles.headingMedium),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .asMap()
                  .entries
                  .map((entry) {
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
              }).toList(),
            ),
            const SizedBox(height: 8),
            _buildDateGrid(),
            const Divider(height: 32),
            Row(
              children: [
                if (_selected != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _selected = null);
                        widget.onDateCleared?.call();
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
                if (_selected != null) SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            widget.onDateSelected(_selected!);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor: AppColors.neutral200,
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
        ),
      ),
    );
  }

  Widget _buildDateGrid() {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final List<DateTime?> dateList = [];
    for (int i = 0; i < firstWeekday; i++) {
      dateList.add(null);
    }
    for (int day = 1; day <= daysInMonth; day++) {
      dateList.add(DateTime(_focusedMonth.year, _focusedMonth.month, day));
    }
    while (dateList.length < 42) {
      dateList.add(null);
    }

    return Column(
      children: List.generate(6, (weekIndex) {
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
    );
  }

  Widget _buildDateCell(DateTime date) {
    final today = DateTime.now();
    final isToday = _isSameDay(date, today);
    final isSelected = _selected != null && _isSameDay(date, _selected!);
    final isDisabled = _isDisabled(date);

    Color? backgroundColor;
    Color? textColor;
    FontWeight fontWeight = FontWeight.normal;

    if (isSelected) {
      backgroundColor = AppColors.primary600;
      textColor = AppColors.textOnPrimary;
      fontWeight = FontWeight.w600;
    } else if (isToday) {
      backgroundColor = AppColors.primary50.withValues(alpha: 0.5);
      textColor = AppColors.primary600;
      fontWeight = FontWeight.w600;
    } else if (isDisabled) {
      textColor = AppColors.textDisabled;
    } else {
      textColor = AppColors.textPrimary;
    }

    return InkWell(
      onTap: isDisabled
          ? null
          : () => setState(() => _selected = _normalize(date)),
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
}
