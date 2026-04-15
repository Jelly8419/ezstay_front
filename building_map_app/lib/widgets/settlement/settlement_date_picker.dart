import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 정산 날짜 선택 위젯
/// React SettlementDatePicker.tsx와 동일한 UI
class SettlementDatePicker extends StatefulWidget {
  final String label; // "시작일" 또는 "종료일"
  final String selectedDate; // YYYY-MM-DD
  final ValueChanged<String> onDateChange;

  const SettlementDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateChange,
  });

  @override
  State<SettlementDatePicker> createState() => _SettlementDatePickerState();
}

class _SettlementDatePickerState extends State<SettlementDatePicker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate.isNotEmpty
        ? DateTime.parse(widget.selectedDate)
        : DateTime.now();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return widget.label;
    final date = DateTime.parse(dateStr);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _togglePicker() {
    if (_isOpen) {
      _removeOverlay();
      setState(() {});
    } else {
      _showPicker();
    }
  }

  void _showPicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;

    if (isMobile) {
      // 모바일: 바텀시트
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildBottomSheetCalendar(),
      );
    } else {
      // PC: 오버레이 팝업
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 배경 오버레이
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
                setState(() {});
              },
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          // 캘린더 팝업
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: _buildCalendarContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetCalendar() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: _buildCalendarContent(
            setModalState: setModalState,
            isBottomSheet: true,
          ),
        );
      },
    );
  }

  Widget _buildCalendarContent({
    StateSetter? setModalState,
    bool isBottomSheet = false,
  }) {
    final today = DateTime.now();
    final oneYearAgo = DateTime(today.year - 1, today.month, today.day);

    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingDayOfWeek = DateTime(year, month, 1).weekday % 7;

    return Container(
      padding: EdgeInsets.all(24), // p-6
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 월 네비게이션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final newMonth = DateTime(year, month - 1);
                  if (setModalState != null) {
                    setModalState(() => _currentMonth = newMonth);
                  } else {
                    setState(() => _currentMonth = newMonth);
                    _overlayEntry?.markNeedsBuild();
                  }
                },
                icon: Icon(Icons.chevron_left, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.all(8),
                ),
              ),
              Text(
                '${_currentMonth.year}년 ${_currentMonth.month}월',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              IconButton(
                onPressed: () {
                  final newMonth = DateTime(year, month + 1);
                  if (setModalState != null) {
                    setModalState(() => _currentMonth = newMonth);
                  } else {
                    setState(() => _currentMonth = newMonth);
                    _overlayEntry?.markNeedsBuild();
                  }
                },
                icon: Icon(Icons.chevron_right, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .asMap()
                .entries
                .map((entry) {
              final i = entry.key;
              final day = entry.value;
              Color textColor;
              if (i == 0) {
                textColor = Colors.red.shade600;
              } else if (i == 6) {
                textColor = AppColors.blue600;
              } else {
                textColor = AppColors.gray600;
              }
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 4),
          // 날짜 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startingDayOfWeek + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startingDayOfWeek) {
                return SizedBox();
              }

              final day = index - startingDayOfWeek + 1;
              final date = DateTime(year, month, day);
              final isPast = date.isBefore(oneYearAgo);
              final isFuture = date.isAfter(today);
              final isDisabled = isPast || isFuture;
              final isSelected = widget.selectedDate.isNotEmpty &&
                  date.year == DateTime.parse(widget.selectedDate).year &&
                  date.month == DateTime.parse(widget.selectedDate).month &&
                  date.day == DateTime.parse(widget.selectedDate).day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () {
                        final dateString =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        widget.onDateChange(dateString);
                        if (isBottomSheet) {
                          Navigator.pop(context);
                        } else {
                          _removeOverlay();
                          setState(() {});
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blue600
                        : isDisabled
                            ? AppColors.gray50
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected && !isDisabled
                        ? Border.all(color: AppColors.blue600, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: (isSelected || isToday
                              ? AppTextStyles.labelMedium
                              : AppTextStyles.bodyMedium)
                          .copyWith(
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? AppColors.gray300
                                : AppColors.gray900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          // 안내 메시지
          Container(
            padding: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Text(
              '최근 1년 이내 정산 내역만 조회 가능합니다',
              style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = widget.selectedDate.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _togglePicker,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasDate ? AppColors.blue500 : AppColors.gray200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.neutral400,
              ),
              SizedBox(width: 8),
              Text(
                _formatDate(widget.selectedDate),
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
