import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';

/// 계약 불가 기간 모델
class BlockedPeriod {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  BlockedPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.reason,
  });
}

/// 계약 정보 모델
class Contract {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String guestName;
  final String? guestNickname;

  Contract({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.guestName,
    this.guestNickname,
  });

  /// 표시용 게스트 이름 (닉네임 우선, 없으면 이름)
  String get guestDisplayName =>
      (guestNickname?.isNotEmpty == true) ? guestNickname! : guestName;
}

/// 날짜 상태 열거형
enum DateStatus {
  past, // 과거 날짜
  contracted, // 계약된 날짜
  blocked, // 계약 불가 날짜
  available, // 예약 가능 날짜
}

/// 선택 모드 열거형
enum SelectionMode {
  block, // 불가 기간 설정
  unblock, // 가능 기간 설정
}

/// 방 일정 관리 페이지
class RoomSchedulePage extends StatefulWidget {
  final String roomId;

  const RoomSchedulePage({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomSchedulePage> createState() => _RoomSchedulePageState();
}

class _RoomSchedulePageState extends State<RoomSchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();

  // 방 정보
  String propertyName = '';
  String propertyAddress = '';

  // 계약 목록
  List<Contract> contracts = [];

  // 계약 불가 기간 목록
  List<BlockedPeriod> blockedPeriods = [];

  // 로딩 상태
  bool _isLoading = false;

  // 선택 모드
  SelectionMode? selectionMode;

  // 선택된 날짜
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // 오늘 날짜
  late DateTime today;

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    today = DateTime(today.year, today.month, today.day); // 시간 제거

    // Firebase Analytics 로깅 (비즈니스 로직 유지)
    // TODO: Firebase Analytics 추가 시 활성화
    // _logPageView();

    // 일정 데이터 로드
    _loadScheduleData();
  }

  /// 일정 데이터 로드
  Future<void> _loadScheduleData() async {
    setState(() => _isLoading = true);

    try {
      final roomId = int.parse(widget.roomId);
      final scheduleData = await _scheduleService.getSchedule(roomId: roomId);

      // 방 정보
      final roomInfo = scheduleData['roomInfo'];
      propertyName = roomInfo['propertyName'] ?? '';
      propertyAddress = roomInfo['propertyAddress'] ?? '';

      // 계약 목록
      final contractsData = scheduleData['contracts'] as List;
      contracts = contractsData.map((data) {
        return Contract(
          id: data['id'].toString(),
          startDate: DateTime.parse(data['startDate']),
          endDate: DateTime.parse(data['endDate']),
          guestName: data['guestName'] ?? '알 수 없음',
          guestNickname: data['guestNickname'],
        );
      }).toList();

      // 계약 불가 기간 목록
      final blockedPeriodsData = scheduleData['blockedPeriods'] as List;
      blockedPeriods = blockedPeriodsData.map((data) {
        return BlockedPeriod(
          id: data['id'].toString(),
          startDate: DateTime.parse(data['startDate']),
          endDate: DateTime.parse(data['endDate']),
          reason: data['reason'],
        );
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 조회 실패: $e'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  /// 12개월 생성
  List<Map<String, dynamic>> _generateMonths() {
    final List<Map<String, dynamic>> months = [];
    for (int i = 0; i < 12; i++) {
      final date = DateTime(today.year, today.month + i, 1);
      months.add({
        'year': date.year,
        'month': date.month,
        'monthName': '${date.year}년 ${date.month}월',
      });
    }
    return months;
  }

  /// 해당 월의 일수
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 해당 월의 첫 요일 (0=일요일)
  int _getFirstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday % 7;
  }

  /// 두 날짜가 같은지 확인
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 날짜가 범위 내에 있는지 확인
  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return d.compareTo(s) >= 0 && d.compareTo(e) <= 0;
  }

  /// 해당 날짜의 계약 정보 가져오기
  Contract? _getContractForDate(DateTime date) {
    for (final contract in contracts) {
      if (_isDateInRange(date, contract.startDate, contract.endDate)) {
        return contract;
      }
    }
    return null;
  }

  /// 계약 위치 정보 (시작일/종료일 여부)
  Map<String, bool>? _getContractPosition(DateTime date) {
    final contract = _getContractForDate(date);
    if (contract == null) return null;

    final isStart = _isSameDate(date, contract.startDate);
    final isEnd = _isSameDate(date, contract.endDate);
    final isOnlyDay = _isSameDate(contract.startDate, contract.endDate);

    return {
      'isStart': isStart,
      'isEnd': isEnd,
      'isOnlyDay': isOnlyDay,
    };
  }

  /// 날짜 상태 확인
  DateStatus _getDateStatus(DateTime date) {
    final compareDate = DateTime(date.year, date.month, date.day);
    final todayCompare = DateTime(today.year, today.month, today.day);

    // 과거 날짜
    if (compareDate.isBefore(todayCompare)) {
      return DateStatus.past;
    }

    // 계약된 날짜
    for (final contract in contracts) {
      if (_isDateInRange(date, contract.startDate, contract.endDate)) {
        return DateStatus.contracted;
      }
    }

    // 계약 불가 날짜
    for (final blocked in blockedPeriods) {
      if (_isDateInRange(date, blocked.startDate, blocked.endDate)) {
        return DateStatus.blocked;
      }
    }

    return DateStatus.available;
  }

  /// 날짜 클릭 처리
  void _handleDateClick(DateTime date) {
    final status = _getDateStatus(date);

    // 과거 날짜와 계약된 날짜는 선택 불가
    if (status == DateStatus.past || status == DateStatus.contracted) {
      return;
    }

    // 불가 기간 설정은 available 날짜만
    if (selectionMode == SelectionMode.block && status != DateStatus.available) {
      return;
    }

    // 가능 기간 설정은 blocked 날짜만
    if (selectionMode == SelectionMode.unblock && status != DateStatus.blocked) {
      return;
    }

    setState(() {
      if (selectedStartDate == null) {
        // 첫 번째 클릭: 시작일 설정
        selectedStartDate = date;
        selectedEndDate = null;
      } else if (selectedEndDate == null) {
        // 두 번째 클릭: 종료일 설정 (자동 정렬)
        if (date.isBefore(selectedStartDate!)) {
          selectedEndDate = selectedStartDate;
          selectedStartDate = date;
        } else {
          selectedEndDate = date;
        }
      } else {
        // 세 번째 클릭: 다시 시작일 설정
        selectedStartDate = date;
        selectedEndDate = null;
      }
    });
  }

  /// 선택된 날짜 목록 가져오기
  List<DateTime> _getSelectedDates() {
    if (selectedStartDate == null) return [];
    if (selectedEndDate == null) return [selectedStartDate!];

    final List<DateTime> dates = [];
    DateTime current = selectedStartDate!;
    while (current.isBefore(selectedEndDate!) || _isSameDate(current, selectedEndDate!)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// 불가 기간 설정 적용
  Future<void> _handleApplyBlock() async {
    final selectedDates = _getSelectedDates();

    if (selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜를 선택해주세요')),
      );
      return;
    }

    // 모든 선택된 날짜가 available인지 확인
    final allAvailable = selectedDates.every((date) => _getDateStatus(date) == DateStatus.available);
    if (!allAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약 가능한 날짜만 선택할 수 있습니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sortedDates = List<DateTime>.from(selectedDates)..sort();
      final roomId = int.parse(widget.roomId);

      // API 호출
      final result = await _scheduleService.createBlockedPeriod(
        roomId: roomId,
        startDate: sortedDates.first.toIso8601String().split('T')[0],
        endDate: sortedDates.last.toIso8601String().split('T')[0],
        reason: '호스트 설정',
      );

      // 성공 시 목록에 추가
      final newBlocked = BlockedPeriod(
        id: result['id'].toString(),
        startDate: DateTime.parse(result['startDate']),
        endDate: DateTime.parse(result['endDate']),
        reason: result['reason'],
      );

      setState(() {
        blockedPeriods.add(newBlocked);
        selectedStartDate = null;
        selectedEndDate = null;
        selectionMode = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계약 불가 기간이 설정되었습니다')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 실패: $e'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  /// 가능 기간 설정 적용
  Future<void> _handleApplyUnblock() async {
    final selectedDates = _getSelectedDates();

    if (selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜를 선택해주세요')),
      );
      return;
    }

    final sortedSelectedDates = List<DateTime>.from(selectedDates)..sort();
    final selectionStart = sortedSelectedDates.first;
    final selectionEnd = sortedSelectedDates.last;

    final List<BlockedPeriod> updatedBlocked = [];

    for (final blocked in blockedPeriods) {
      // 선택 범위와 차단 기간이 겹치는지 확인
      final hasOverlap = selectedDates.any((date) => _isDateInRange(date, blocked.startDate, blocked.endDate));

      if (!hasOverlap) {
        updatedBlocked.add(blocked);
      } else {
        // 겹치면 분할 처리
        final blockedStart = blocked.startDate;
        final blockedEnd = blocked.endDate;

        // 선택 범위 이전 부분
        final dayBeforeSelection = selectionStart.subtract(const Duration(days: 1));
        if (blockedStart.isBefore(selectionStart) && !dayBeforeSelection.isBefore(blockedStart)) {
          updatedBlocked.add(BlockedPeriod(
            id: '${blocked.id}_before',
            startDate: blockedStart,
            endDate: dayBeforeSelection,
            reason: blocked.reason,
          ));
        }

        // 선택 범위 이후 부분
        final dayAfterSelection = selectionEnd.add(const Duration(days: 1));
        if (blockedEnd.isAfter(selectionEnd) && !dayAfterSelection.isAfter(blockedEnd)) {
          updatedBlocked.add(BlockedPeriod(
            id: '${blocked.id}_after',
            startDate: dayAfterSelection,
            endDate: blockedEnd,
            reason: blocked.reason,
          ));
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final sortedSelectedDates = List<DateTime>.from(selectedDates)..sort();
      final roomId = int.parse(widget.roomId);

      // API 호출 - 백엔드에서 기간 분할 처리
      final result = await _scheduleService.unblockPeriod(
        roomId: roomId,
        startDate: sortedSelectedDates.first.toIso8601String().split('T')[0],
        endDate: sortedSelectedDates.last.toIso8601String().split('T')[0],
      );

      // 응답에서 생성된 기간 목록 가져오기
      final createdPeriods = (result['createdPeriods'] as List).map((data) {
        return BlockedPeriod(
          id: data['id'].toString(),
          startDate: DateTime.parse(data['startDate']),
          endDate: DateTime.parse(data['endDate']),
          reason: data['reason'],
        );
      }).toList();

      // 삭제된 기간 ID 목록
      final deletedIds = (result['deletedPeriods'] as List)
          .map((data) => data['id'].toString())
          .toSet();

      setState(() {
        // 삭제된 기간 제거
        blockedPeriods.removeWhere((period) => deletedIds.contains(period.id));
        // 새로 생성된 기간 추가
        blockedPeriods.addAll(createdPeriods);
        selectedStartDate = null;
        selectedEndDate = null;
        selectionMode = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계약 가능으로 전환되었습니다')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('해제 실패: $e'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  /// 선택 취소
  void _handleCancelSelection() {
    setState(() {
      selectedStartDate = null;
      selectedEndDate = null;
      selectionMode = null;
    });
  }

  /// 날짜가 선택되었는지 확인
  bool _isDateSelected(DateTime date) {
    if (selectedStartDate == null) return false;
    if (selectedEndDate == null) return _isSameDate(date, selectedStartDate!);

    return _isDateInRange(date, selectedStartDate!, selectedEndDate!);
  }

  /// 캘린더 렌더링
  List<Widget> _renderCalendar(int year, int month) {
    final daysInMonth = _getDaysInMonth(year, month);
    final firstDay = _getFirstDayOfMonth(year, month);
    final List<Widget> days = [];

    // 빈 칸 추가 (이전 달)
    for (int i = 0; i < firstDay; i++) {
      days.add(const SizedBox(
        width: double.infinity,
        child: AspectRatio(aspectRatio: 1),
      ));
    }

    // 날짜 추가
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final status = _getDateStatus(date);
      final isSelected = _isDateSelected(date);

      Color bgColor = Colors.white;
      Color textColor = AppColors.textPrimary;
      Color? borderColor;
      BorderRadius? borderRadius;

      // 선택 모드가 아닐 때는 클릭 불가
      bool canClick = selectionMode != null;

      if (status == DateStatus.past) {
        // 과거 날짜: 매우 연한 회색
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[400]!;
        canClick = false;
      } else if (status == DateStatus.contracted) {
        // 계약된 기간: 연결된 블록
        final position = _getContractPosition(date);
        if (position != null) {
          bgColor = Colors.blue[500]!;
          textColor = Colors.white;
          if (position['isOnlyDay'] == true) {
            borderRadius = BorderRadius.circular(100);
          } else if (position['isStart'] == true) {
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(100),
              bottomLeft: Radius.circular(100),
            );
          } else if (position['isEnd'] == true) {
            borderRadius = const BorderRadius.only(
              topRight: Radius.circular(100),
              bottomRight: Radius.circular(100),
            );
          } else {
            borderRadius = BorderRadius.circular(AppRadius.md);
          }
        } else {
          bgColor = Colors.blue[500]!;
          textColor = Colors.white;
        }
        canClick = false;
      } else if (status == DateStatus.blocked) {
        // 계약 불가: 진한 회색
        bgColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
        canClick = selectionMode == SelectionMode.unblock;
      } else if (status == DateStatus.available) {
        // 예약 가능: 흰색
        bgColor = Colors.white;
        textColor = AppColors.textPrimary;
        canClick = selectionMode == SelectionMode.block;
      }

      if (isSelected) {
        // 선택된 날짜: 모드에 따라 색상 구분
        if (selectionMode == SelectionMode.block) {
          bgColor = Colors.orange[500]!;
          textColor = Colors.white;
        } else if (selectionMode == SelectionMode.unblock) {
          bgColor = Colors.green[500]!;
          textColor = Colors.white;
        }
      }

      days.add(
        GestureDetector(
          onTap: canClick ? () => _handleDateClick(date) : null,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm), // ✅ 8px (React rounded-lg)
                border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // ✅ 14px (React text-sm font-semibold)
                ),
              ),
            ),
          ),
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // 권한 체크 (비즈니스 로직 유지)
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('권한 없음')),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    final months = _generateMonths();
    final isMobile = ResponsiveUtil.isMobile(context);
    final isTablet = ResponsiveUtil.isTablet(context);

    return Scaffold(
      appBar: const AppGNB(),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtil.getPadding(context),
                      vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile) ...[
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 20),
                            label: const Text('방 관리로 돌아가기'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      SizedBox(height: AppSpacing.md),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('일정 관리', style: AppTextStyles.headingMedium),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                propertyName,
                                style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                propertyAddress,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveUtil.getPadding(context)),
              child: Column(
                children: [
                  // 범례
                  Container(
                    padding: EdgeInsets.all(AppSpacing.lg), // ✅ 24px (React p-6)
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md), // ✅ 12px (React rounded-xl)
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            _buildLegendItem('예약 가능', Colors.white, hasBorder: true),
                            _buildLegendItem('계약됨', Colors.blue[500]!),
                            _buildLegendItem('계약 불가', Colors.grey[300]!),
                            if (selectionMode == SelectionMode.block)
                              _buildLegendItem('선택됨 (불가 설정)', Colors.orange[500]!),
                            if (selectionMode == SelectionMode.unblock)
                              _buildLegendItem('선택됨 (가능 설정)', Colors.green[500]!),
                          ],
                        ),
                        if (selectionMode != null) ...[
                          SizedBox(height: AppSpacing.md),
                          Container(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border.all(color: Colors.blue[200]!),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectionMode == SelectionMode.block
                                      ? '📌 계약 불가로 설정할 기간을 선택하세요 (시작일 클릭 → 종료일 클릭)'
                                      : '📌 계약 가능으로 전환할 기간을 선택하세요 (시작일 클릭 → 종료일 클릭)',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.blue[700]),
                                ),
                                if (selectedStartDate != null && selectedEndDate == null) ...[
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '✓ 시작일 선택됨: ${_formatDate(selectedStartDate!)} (종료일을 선택하세요)',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.orange[600]),
                                  ),
                                ],
                                if (selectedStartDate != null && selectedEndDate != null) ...[
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '✓ 선택 완료: ${_formatDate(selectedStartDate!)} ~ ${_formatDate(selectedEndDate!)}',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.orange[600]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // 12개월 캘린더 그리드
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (!isMobile && !isTablet) {
                        crossAxisCount = 4; // PC: 4열
                      } else if (isTablet) {
                        crossAxisCount = 2; // 태블릿: 2열
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.0, // ✅ 정사각형 셀 (React와 일치)
                          crossAxisSpacing: AppSpacing.lg, // ✅ 24px (React gap-6)
                          mainAxisSpacing: AppSpacing.lg, // ✅ 24px (React gap-6)
                        ),
                        itemCount: months.length,
                        itemBuilder: (context, index) {
                          final monthData = months[index];
                          final year = monthData['year'] as int;
                          final month = monthData['month'] as int;
                          final monthName = monthData['monthName'] as String;

                          return Container(
                            padding: EdgeInsets.all(AppSpacing.md), // ✅ 16px (React p-4)
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md), // ✅ 12px (React rounded-xl)
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  monthName,
                                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold), // ✅ 16px (React text-base)
                                ),
                                SizedBox(height: AppSpacing.sm), // ✅ 8px (React mb-2)

                                // 요일 헤더
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 7,
                                  childAspectRatio: 1.0, // ✅ 정사각형 (React와 일치)
                                  mainAxisSpacing: 4.0, // ✅ 4px (React gap-1)
                                  crossAxisSpacing: 4.0, // ✅ 4px (React gap-1)
                                  children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                                    return Center(
                                      child: Text(
                                        day,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14, // ✅ 14px (React text-sm)
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                SizedBox(height: AppSpacing.sm), // ✅ 8px

                                // 날짜 그리드
                                Expanded(
                                  child: GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 7,
                                    childAspectRatio: 1.0, // ✅ 정사각형 (React aspect-square)
                                    mainAxisSpacing: 4.0, // ✅ 4px (React gap-1)
                                    crossAxisSpacing: 4.0, // ✅ 4px (React gap-1)
                                    children: _renderCalendar(year, month),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // 계약 및 차단 기간 목록
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildContractsList(),
                            SizedBox(height: AppSpacing.lg),
                            _buildBlockedPeriodsList(),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildContractsList()),
                            SizedBox(width: AppSpacing.lg),
                            Expanded(child: _buildBlockedPeriodsList()),
                          ],
                        );
                      }
                    },
                  ),

                  // 하단 버튼 공간 확보
                  SizedBox(height: isMobile ? 128 : 96), // ✅ React pb-32 lg:pb-24 (128px/96px)
                ],
              ),
            ),
          ),
        ],
      ),

      // 하단 고정 바 (Positioned instead of bottomSheet)
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: ExcludeFocus(
          excluding: true,
          child: RepaintBoundary(
            child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtil.getPadding(context),
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                if (selectionMode == null) ...[
                  // 모드 선택 버튼
                  if (isMobile)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => setState(() => selectionMode = SelectionMode.block),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                              side: const BorderSide(color: AppColors.border, width: 2),
                            ),
                            child: const Text('불가 기간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => setState(() => selectionMode = SelectionMode.unblock),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                              side: const BorderSide(color: AppColors.border, width: 2),
                            ),
                            child: const Text('가능 기간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => selectionMode = SelectionMode.block),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            side: const BorderSide(color: AppColors.border, width: 2),
                          ),
                          child: const Text('불가 기간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () => setState(() => selectionMode = SelectionMode.unblock),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            side: const BorderSide(color: AppColors.border, width: 2),
                          ),
                          child: const Text('가능 기간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                ] else ...[
                  // 적용/취소 버튼
                  Column(
                    children: [
                      if (isMobile)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _handleCancelSelection,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  side: const BorderSide(color: AppColors.border, width: 2),
                                ),
                                child: const Text('취소', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedStartDate != null
                                    ? (selectionMode == SelectionMode.block ? _handleApplyBlock : _handleApplyUnblock)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  backgroundColor: AppColors.primary500,
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                                child: const Text('적용', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: _handleCancelSelection,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.md,
                                ),
                                side: const BorderSide(color: AppColors.border, width: 2),
                              ),
                              child: const Text('취소', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            ElevatedButton(
                              onPressed: selectedStartDate != null
                                  ? (selectionMode == SelectionMode.block ? _handleApplyBlock : _handleApplyUnblock)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.md,
                                ),
                                backgroundColor: AppColors.primary500,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: const Text('적용', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        selectionMode == SelectionMode.block
                            ? '📌 계약 불가로 설정할 기간을 선택하세요'
                            : '📌 계약 가능으로 전환할 기간을 선택하세요',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
        ),
      ), // ExcludeFocus 닫기
    ],
      ),
    );
  }

  /// 범례 아이템
  Widget _buildLegendItem(String label, Color color, {bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: hasBorder ? Border.all(color: Colors.grey[300]!, width: 2) : null,
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  /// 계약된 기간 목록
  Widget _buildContractsList() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg), // ✅ 24px (React p-6)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md), // ✅ 12px (React rounded-xl)
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('계약된 기간', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: AppSpacing.md),
          if (contracts.isEmpty)
            Text('계약된 기간이 없습니다', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))
          else
            ...contracts.map((contract) {
              return Container(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contract.guestDisplayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          '계약 번호: ${contract.id}',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.blue[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      '${_formatDate(contract.startDate)} ~ ${_formatDate(contract.endDate)}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.blue[600]),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// 계약 불가 기간 목록
  Widget _buildBlockedPeriodsList() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg), // ✅ 24px (React p-6)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md), // ✅ 12px (React rounded-xl)
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('계약 불가 기간', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: AppSpacing.md),
          if (blockedPeriods.isEmpty)
            Text('계약 불가 기간이 없습니다', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))
          else
            ...blockedPeriods.map((blocked) {
              return Container(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatDate(blocked.startDate)} ~ ${_formatDate(blocked.endDate)}',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          blockedPeriods.removeWhere((b) => b.id == blocked.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('차단 기간이 해제되었습니다')),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      ),
                      child: const Text('삭제', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
