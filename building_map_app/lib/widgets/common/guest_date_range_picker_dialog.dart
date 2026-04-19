import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 게스트용 날짜 범위 선택 다이얼로그.
///
/// 원래 `guest_home_page.dart`의 private 클래스(`_GuestDateRangePickerDialog`)
/// 를 공통 위젯으로 분리한 것. 홈 외에도 계약 시작·채팅 등에서 재사용 가능.
///
/// **정책 상수** (`minContractDays` 7, `maxContractDays` 90)는 서비스 정책
/// 기본값이지만 필요 시 override 가능하도록 파라미터화했다. 값을 바꿀 때는
/// 백엔드 정책(FeeConstants 등)과 일치 여부를 반드시 확인할 것.
///
/// 사용 예시:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => GuestDateRangePickerDialog(
///     initialCheckIn: _checkIn,
///     initialCheckOut: _checkOut,
///     onDateRangeSelected: (s, e) => setState(() { ... }),
///     onDateCleared: () => setState(() { ... }),
///   ),
/// );
/// ```
class GuestDateRangePickerDialog extends StatefulWidget {
  const GuestDateRangePickerDialog({
    super.key,
    this.initialCheckIn,
    this.initialCheckOut,
    required this.onDateRangeSelected,
    this.onDateCleared,
    this.minContractDays = 7,
    this.maxContractDays = 90,
  });

  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final void Function(DateTime checkIn, DateTime checkOut) onDateRangeSelected;
  final VoidCallback? onDateCleared;

  /// 최소 계약 일수 (기본 7일).
  final int minContractDays;

  /// 최대 계약 일수 (기본 90일).
  final int maxContractDays;

  @override
  State<GuestDateRangePickerDialog> createState() =>
      _GuestDateRangePickerDialogState();
}

class _GuestDateRangePickerDialogState
    extends State<GuestDateRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String? _errorMessage;

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
                Text('임대 기간 선택', style: AppTextStyles.headingMedium),
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
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .asMap()
                  .entries
                  .map(
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
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 날짜 그리드
            _buildDateGrid(),

            // 에러 메시지
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error50,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error500,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
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
                        '최소 ${widget.minContractDays}일 ~ 최대 ${widget.maxContractDays}일 선택 가능',
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
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.md),
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
      children: [
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

  Widget _buildDateCell(DateTime date) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

    final isStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isInRange = _rangeStart != null &&
        _rangeEnd != null &&
        date.isAfter(_rangeStart!) &&
        date.isBefore(_rangeEnd!);

    final isInMinRange = _isInMinContractRange(date);

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
    } else if (isInMinRange) {
      backgroundColor = AppColors.neutral100;
      textColor = AppColors.textDisabled;
      fontWeight = FontWeight.normal;
    } else if (isToday) {
      // ignore: deprecated_member_use_from_same_package
      backgroundColor = AppColors.primary50.withValues(alpha: 0.5);
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

  bool _isInMinContractRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd != null) return false;
    if (_isSameDay(date, _rangeStart!)) return false;

    final minEndDate =
        _rangeStart!.add(Duration(days: widget.minContractDays - 1));

    return date.isAfter(_rangeStart!) &&
        (date.isBefore(minEndDate) || _isSameDay(date, minEndDate));
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _errorMessage = null;

      if (_rangeStart != null &&
          _rangeEnd == null &&
          _isSameDay(selectedDate, _rangeStart!)) {
        _rangeStart = null;
        _rangeEnd = null;
        widget.onDateCleared?.call();
        return;
      }

      if (_rangeStart != null && _rangeEnd == null) {
        final DateTime earlierDate;
        final DateTime laterDate;

        if (selectedDate.isBefore(_rangeStart!)) {
          earlierDate = _normalizeDate(selectedDate);
          laterDate = _normalizeDate(_rangeStart!);
        } else {
          earlierDate = _normalizeDate(_rangeStart!);
          laterDate = _normalizeDate(selectedDate);
        }

        final duration = laterDate.difference(earlierDate).inDays;

        if (duration < widget.minContractDays) {
          _errorMessage = '최소 ${widget.minContractDays}일 이상 선택해주세요';
          return;
        }

        if (duration > widget.maxContractDays) {
          _errorMessage = '최대 ${widget.maxContractDays}일까지 선택 가능합니다';
          return;
        }

        _rangeStart = earlierDate;
        _rangeEnd = laterDate;
      } else if (_rangeStart != null && _rangeEnd != null) {
        _rangeStart = _normalizeDate(selectedDate);
        _rangeEnd = null;
      } else {
        _rangeStart = _normalizeDate(selectedDate);
        _rangeEnd = null;
      }
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
