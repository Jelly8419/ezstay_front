import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/search_filters.dart';
import '../utils/responsive_util.dart';
import '../services/map_interaction_coordinator.dart';
import 'kakao_map_web.dart';
import '../core/theme/app_text_styles.dart';

/// 검색 필터 바 위젯 (React MapSearch.tsx 기반)
/// React 코드에 맞춰 3개 필터만 사용: 임대 기간, 건물 유형, 임대료
/// Portal 방식 드롭다운으로 버튼 아래에 위치
class SearchFilterBar extends StatefulWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;
  final KakaoMapWebController? mapController;

  const SearchFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.mapController,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late SearchFilters _currentFilters;

  // 드롭다운 상태 관리
  OverlayEntry? _overlayEntry;
  final GlobalKey _dateRangeButtonKey = GlobalKey();
  final GlobalKey _buildingTypeButtonKey = GlobalKey();
  final GlobalKey _rentRangeButtonKey = GlobalKey();

  // 날짜 선택 상태
  DateTime _focusedMonth = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // 건물 유형 선택 (다중 선택)
  Set<String> _selectedBuildingTypes = {};

  // 임대료 범위
  double _rentMin = 0;
  double _rentMax = 160;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
    _initializeFromFilters();
  }

  @override
  void didUpdateWidget(SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters != oldWidget.filters) {
      _currentFilters = widget.filters;
      _initializeFromFilters();
    }
  }

  void _initializeFromFilters() {
    // 날짜 범위
    _rangeStart = _currentFilters.dateRange?.startDate;
    _rangeEnd = _currentFilters.dateRange?.endDate;

    // 건물 유형 (다중 선택)
    _selectedBuildingTypes = Set.from(_currentFilters.buildingTypes);

    // 임대료
    _rentMin = _currentFilters.priceRange.minPrice.toDouble();
    _rentMax = _currentFilters.priceRange.maxPrice?.toDouble() ?? 160;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;

      // 🎯 Coordinator: 필터 닫기 → idle 모드 복귀 (지도 드래그 자동 허용)
      final coordinator = Provider.of<MapInteractionCoordinator>(
        context,
        listen: false,
      );
      coordinator.exitMode();
    } catch (e) {
      debugPrint('⚠️ Overlay 제거 중 에러: $e');
      _overlayEntry = null;

      // 🎯 Coordinator: 에러 시에도 idle 모드 복귀
      final coordinator = Provider.of<MapInteractionCoordinator>(
        context,
        listen: false,
      );
      coordinator.exitMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 임대 기간 필터
                  isMobile
                      ? _buildMobileFilterChip(
                          key: _dateRangeButtonKey,
                          icon: Icons.calendar_today,
                          label: _formatDateRangeMobile(),
                          isActive: _currentFilters.dateRange != null,
                          onTap: () => _showDateRangeDropdown(),
                        )
                      : _buildDesktopFilterButton(
                          key: _dateRangeButtonKey,
                          label: '임대 기간',
                          value: _formatDateRangeDesktop(),
                          isActive: _currentFilters.dateRange != null,
                          onTap: () => _showDateRangeDropdown(),
                        ),
                  SizedBox(width: isMobile ? 8 : 12),

                  // 건물 유형 필터
                  isMobile
                      ? _buildMobileFilterChip(
                          key: _buildingTypeButtonKey,
                          label: _formatBuildingTypeMobile(),
                          isActive: _selectedBuildingTypes.isNotEmpty,
                          onTap: () => _showBuildingTypeDropdown(),
                        )
                      : _buildDesktopFilterButton(
                          key: _buildingTypeButtonKey,
                          label: '건물 유형',
                          value: _formatBuildingTypeDesktop(),
                          isActive: _selectedBuildingTypes.isNotEmpty,
                          onTap: () => _showBuildingTypeDropdown(),
                        ),
                  SizedBox(width: isMobile ? 8 : 12),

                  // 임대료 필터
                  isMobile
                      ? _buildMobileFilterChip(
                          key: _rentRangeButtonKey,
                          label: _formatRentRangeMobile(),
                          isActive: !_currentFilters.priceRange.isDefault,
                          onTap: () => _showRentRangeDropdown(),
                        )
                      : _buildDesktopFilterButton(
                          key: _rentRangeButtonKey,
                          label: '임대료',
                          value: _formatRentRangeDesktop(),
                          isActive: !_currentFilters.priceRange.isDefault,
                          onTap: () => _showRentRangeDropdown(),
                        ),

                  // 데스크톱 필터 초기화 버튼 (임대료 필터 옆)
                  if (!isMobile && _currentFilters.hasActiveFilters) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _currentFilters = const SearchFilters();
                          _rangeStart = null;
                          _rangeEnd = null;
                          _selectedBuildingTypes.clear();
                          _rentMin = 0;
                          _rentMax = 160;
                        });
                        widget.onFiltersChanged(_currentFilters);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '전체 초기화',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 모바일 필터 초기화 버튼 (우측 고정)
          if (isMobile && _currentFilters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _currentFilters = const SearchFilters();
                  _rangeStart = null;
                  _rangeEnd = null;
                  _selectedBuildingTypes.clear();
                  _rentMin = 0;
                  _rentMax = 160;
                });
                widget.onFiltersChanged(_currentFilters);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.refresh, size: 20, color: Colors.grey[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 데스크톱 필터 버튼 (React: rounded-lg, px-4 py-2)
  Widget _buildDesktopFilterButton({
    required GlobalKey key,
    required String label,
    required String value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final bool showOnlyValue = value != '전체';

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF3B82F6) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showOnlyValue)
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.black87),
              )
            else ...[
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  /// 모바일 필터 칩 (React: rounded-full, px-3 py-1.5, text-sm)
  Widget _buildMobileFilterChip({
    required GlobalKey key,
    IconData? icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDDEAFD) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? const Color(0xFF3B82F6) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? const Color(0xFF3B82F6) : Colors.black87,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF3B82F6) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 포맷팅 메서드 ==========

  String _formatDateRangeMobile() {
    if (_rangeStart == null || _rangeEnd == null) {
      return '임대 기간';
    }
    final start = '${_rangeStart!.month}/${_rangeStart!.day}';
    final end = '${_rangeEnd!.month}/${_rangeEnd!.day}';
    return '$start - $end';
  }

  String _formatDateRangeDesktop() {
    if (_rangeStart == null || _rangeEnd == null) {
      return '전체';
    }
    final start = '${_rangeStart!.month}/${_rangeStart!.day}';
    final end = '${_rangeEnd!.month}/${_rangeEnd!.day}';
    return '$start - $end';
  }

  String _formatBuildingTypeMobile() {
    if (_selectedBuildingTypes.isEmpty) return '건물 유형';
    if (_selectedBuildingTypes.length == 1) return _selectedBuildingTypes.first;
    return '건물 유형 ${_selectedBuildingTypes.length}개';
  }

  String _formatBuildingTypeDesktop() {
    if (_selectedBuildingTypes.isEmpty) return '전체';
    // 다중 선택 시 모든 유형을 쉼표로 구분하여 표시 (예: '원룸, 오피스텔')
    return _selectedBuildingTypes.join(', ');
  }

  String _formatRentRangeMobile() {
    if (_rentMin == 0 && _rentMax == 160) {
      return '임대료';
    }
    if (_rentMax == 160) {
      return '${_rentMin.toInt()}만원~';
    }
    return '${_rentMin.toInt()}~${_rentMax.toInt()}만원';
  }

  String _formatRentRangeDesktop() {
    if (_rentMin == 0 && _rentMax == 160) {
      return '전체';
    }
    if (_rentMax == 160) {
      return '${_rentMin.toInt()}만원 이상';
    }
    return '${_rentMin.toInt()}~${_rentMax.toInt()}만원';
  }

  // ========== Portal 방식 드롭다운 메서드 ==========

  void _showDateRangeDropdown() {
    _removeOverlay();

    final renderBox =
        _dateRangeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return FocusScope(
            canRequestFocus: false,
            child: Stack(
              children: [
                // 배경 클릭 시 닫기 (모든 제스처 차단)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _removeOverlay,
                    onPanDown: (_) {}, // 드래그 시작 차단
                    onPanUpdate: (_) {}, // 드래그 중 차단
                    onPanEnd: (_) {}, // 드래그 끝 차단
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      onPointerDown: (_) {}, // 포인터 이벤트 완전 차단
                      onPointerMove: (_) {},
                      onPointerUp: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
                // 드롭다운 (React: rounded-xl, shadow-xl, min-w-[320px])
                Positioned(
                  top: offset.dy + size.height + 4,
                  left: offset.dx,
                  child: GestureDetector(
                    onPanDown: (_) {}, // 드래그 이벤트 흡수
                    onPanUpdate: (_) {},
                    onPanEnd: (_) {},
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      onPointerDown: (_) {},
                      onPointerMove: (_) {},
                      onPointerUp: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: _buildCalendarDropdown(setOverlayState),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 🎯 Coordinator: 필터 열기 → 필터 모드 진입 (지도 드래그 자동 차단)
    final coordinator = Provider.of<MapInteractionCoordinator>(
      context,
      listen: false,
    );
    coordinator.enterMode(InteractionMode.filterOpen);
  }

  void _showBuildingTypeDropdown() {
    _removeOverlay();

    final renderBox =
        _buildingTypeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final types = ['전체', '오피스텔', '원룸', '빌라', '주택', '아파트', '고시원'];

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return FocusScope(
            canRequestFocus: false,
            child: Stack(
              children: [
                // 배경 클릭 시 닫기 (모든 제스처 차단)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _removeOverlay,
                    onPanDown: (_) {}, // 드래그 시작 차단
                    onPanUpdate: (_) {}, // 드래그 중 차단
                    onPanEnd: (_) {}, // 드래그 끝 차단
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      onPointerDown: (_) {}, // 포인터 이벤트 완전 차단
                      onPointerMove: (_) {},
                      onPointerUp: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
                // 드롭다운 (너비 1.5배 확장: 160px → 240px)
                Positioned(
                  top: offset.dy + size.height + 4,
                  left: offset.dx,
                  child: GestureDetector(
                    onPanDown: (_) {}, // 드래그 이벤트 흡수
                    onPanUpdate: (_) {},
                    onPanEnd: (_) {},
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      onPointerDown: (_) {},
                      onPointerMove: (_) {},
                      onPointerUp: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 헤더
                              Text(
                                '건물 유형',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 체크박스 리스트
                              ...types.asMap().entries.map((entry) {
                                final type = entry.value;
                                final isSelected = _selectedBuildingTypes
                                    .contains(type);

                                return InkWell(
                                  onTap: () {
                                    setOverlayState(() {
                                      if (type == '전체') {
                                        // '전체' 클릭 시 모든 선택 해제
                                        _selectedBuildingTypes.clear();
                                      } else {
                                        // 개별 항목 토글
                                        if (isSelected) {
                                          _selectedBuildingTypes.remove(type);
                                        } else {
                                          _selectedBuildingTypes.add(type);
                                        }
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        // 체크박스
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF3B82F6)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF3B82F6)
                                                  : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        // 라벨
                                        Expanded(
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? const Color(0xFF3B82F6)
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              // 적용 버튼
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentFilters = _currentFilters
                                          .copyWith(
                                            buildingTypes:
                                                _selectedBuildingTypes,
                                          );
                                    });
                                    widget.onFiltersChanged(_currentFilters);
                                    _removeOverlay();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '적용',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 🎯 Coordinator: 필터 열기 → 필터 모드 진입 (지도 드래그 자동 차단)
    final coordinator = Provider.of<MapInteractionCoordinator>(
      context,
      listen: false,
    );
    coordinator.enterMode(InteractionMode.filterOpen);
  }

  void _showRentRangeDropdown() {
    _removeOverlay();

    final renderBox =
        _rentRangeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveUtil.isMobile(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return FocusScope(
            canRequestFocus: false,
            child: Stack(
              children: [
                // 배경 클릭 시 닫기 (모든 제스처 차단)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _removeOverlay,
                    onPanDown: (_) {}, // 드래그 시작 차단
                    onPanUpdate: (_) {}, // 드래그 중 차단
                    onPanEnd: (_) {}, // 드래그 끝 차단
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      onPointerDown: (_) {}, // 포인터 이벤트 완전 차단
                      onPointerMove: (_) {},
                      onPointerUp: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
                // 드롭다운 (React: rounded-lg, shadow-lg, w-[90vw] lg:w-auto max-w-[360px])
                Positioned(
                  top: offset.dy + size.height + 4,
                  left: isMobile
                      ? (screenWidth - (screenWidth * 0.9)) / 2
                      : offset.dx,
                  child: GestureDetector(
                    onPanDown: (_) {}, // 드래그 이벤트 흡수
                    onPanUpdate: (_) {},
                    onPanEnd: (_) {},
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      onPointerDown: (_) {},
                      onPointerMove: (_) {},
                      onPointerUp: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: isMobile ? screenWidth * 0.9 : 360,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: _buildRentRangeDropdown(setOverlayState),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 🎯 Coordinator: 필터 열기 → 필터 모드 진입 (지도 드래그 자동 차단)
    final coordinator = Provider.of<MapInteractionCoordinator>(
      context,
      listen: false,
    );
    coordinator.enterMode(InteractionMode.filterOpen);
  }

  Widget _buildCalendarDropdown(StateSetter setOverlayState) {
    // 간단한 캘린더 UI (React 스타일)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 월 네비게이션
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setOverlayState(() {
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
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              '${_focusedMonth.year}년 ${_focusedMonth.month}월',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            IconButton(
              onPressed: () {
                setOverlayState(() {
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
                backgroundColor: Colors.grey[100],
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
          children: ['일', '월', '화', '수', '목', '금', '토'].asMap().entries.map((
            entry,
          ) {
            final index = entry.key;
            final day = entry.value;
            return SizedBox(
              width: 36,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: index == 0
                      ? Colors.red[600]
                      : index == 6
                      ? Colors.blue[600]
                      : Colors.grey[600],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // 날짜 그리드 (React 스타일 구현)
        _buildDateGrid(setOverlayState),

        // 선택된 기간 표시
        if (_rangeStart != null && _rangeEnd != null) ...[
          const Divider(height: 32),
          Column(
            children: [
              Text(
                '임대 기간',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_rangeEnd!.difference(_rangeStart!).inDays}일',
                style: AppTextStyles.labelLarge.copyWith(
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],

        // 안내 메시지
        if (_rangeStart == null || _rangeEnd == null) ...[
          const Divider(height: 32),
          Text(
            '• 최소 7일부터 선택 가능합니다\n• 최대 3개월(90일)까지 선택 가능합니다',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],

        // 초기화 버튼 (날짜가 선택되었을 때만 표시)
        if (_rangeStart != null || _rangeEnd != null) ...[
          const Divider(height: 32),
          Center(
            child: OutlinedButton(
              onPressed: () {
                setOverlayState(() {
                  _rangeStart = null;
                  _rangeEnd = null;
                });
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    clearDateRange: true,
                  );
                });
                widget.onFiltersChanged(_currentFilters);
                _removeOverlay();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '초기화',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 날짜 그리드 생성 (React 스타일)
  Widget _buildDateGrid(StateSetter setOverlayState) {
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

                return _buildDateCell(date, setOverlayState);
              }),
            ),
          );
        }),
      ],
    );
  }

  /// 날짜 셀 생성
  Widget _buildDateCell(DateTime date, StateSetter setOverlayState) {
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
      backgroundColor = const Color(0xFF3B82F6); // blue-600
      textColor = Colors.white;
      fontWeight = FontWeight.w600;
    } else if (isInRange) {
      backgroundColor = const Color(0xFFDDEAFD); // blue-50
      textColor = const Color(0xFF3B82F6);
      fontWeight = FontWeight.normal;
    } else if (isToday) {
      backgroundColor = const Color(0xFFDDEAFD).withValues(alpha: 0.5);
      textColor = const Color(0xFF3B82F6);
      fontWeight = FontWeight.w600;
    } else if (isPast) {
      textColor = Colors.grey[400];
      fontWeight = FontWeight.normal;
    } else {
      textColor = Colors.black87;
      fontWeight = FontWeight.normal;
    }

    return InkWell(
      onTap: isPast ? null : () => _onDateSelected(date, setOverlayState),
      borderRadius: BorderRadius.circular(18),
      canRequestFocus: false, // 포커스 시스템 비활성화로 레이아웃 에러 방지
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// 날짜 선택 핸들러 (React 로직 + UX 개선)
  void _onDateSelected(DateTime selectedDate, StateSetter setOverlayState) {
    setOverlayState(() {
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

        // 최소 기간 체크 (7일)
        final duration = laterDate.difference(earlierDate).inDays;
        if (duration < 7) {
          // 에러 표시 (2초 후 자동 제거)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이지스테이는 최소 7일부터 예약할 수 있어요'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // 최대 기간 체크 (90일)
        if (duration > 90) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이지스테이는 최대 90일까지 예약할 수 있어요'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // 체크인/체크아웃 날짜 설정 (자동 정렬됨)
        _rangeStart = earlierDate;
        _rangeEnd = laterDate;

        // 필터 업데이트 및 드롭다운 닫기
        setState(() {
          _currentFilters = _currentFilters.copyWith(
            dateRange: DateRange(startDate: _rangeStart!, endDate: _rangeEnd!),
          );
        });
        widget.onFiltersChanged(_currentFilters);
        _removeOverlay();
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

  Widget _buildRentRangeDropdown(StateSetter setOverlayState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 최소/최대 값 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '최소',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_rentMin.toInt()}만원',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '최대',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _rentMax == 160 ? '전체' : '${_rentMax.toInt()}만원',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 듀얼 슬라이더 (RangeSlider)
        RangeSlider(
          values: RangeValues(_rentMin, _rentMax),
          min: 0,
          max: 160,
          divisions: 16,
          labels: RangeLabels(
            '${_rentMin.toInt()}만원',
            _rentMax == 160 ? '전체' : '${_rentMax.toInt()}만원',
          ),
          activeColor: const Color(0xFF3B82F6),
          inactiveColor: Colors.grey[300],
          onChanged: (RangeValues values) {
            setOverlayState(() {
              _rentMin = values.start;
              _rentMax = values.end;
            });
          },
        ),

        const SizedBox(height: 16),

        // 버튼
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setOverlayState(() {
                    _rentMin = 0;
                    _rentMax = 160;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '초기화',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      priceRange: PriceRange(
                        minPrice: _rentMin.toInt(),
                        maxPrice: _rentMax == 160 ? null : _rentMax.toInt(),
                      ),
                    );
                  });
                  widget.onFiltersChanged(_currentFilters);
                  _removeOverlay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '적용',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
