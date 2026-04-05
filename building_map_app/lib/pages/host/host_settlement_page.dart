import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../../core/theme/app_colors.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/settlement/filter_bottom_sheet.dart';
import '../../widgets/settlement/settlement_date_picker.dart';

/// 호스트 정산 페이지
/// React HostSettlement.tsx와 동일한 UI
class HostSettlementPage extends StatefulWidget {
  const HostSettlementPage({super.key});

  @override
  State<HostSettlementPage> createState() => _HostSettlementPageState();
}

class _HostSettlementPageState extends State<HostSettlementPage> {
  final SettlementService _settlementService = SettlementService();

  // 탭 상태
  String _activeTab = 'pending'; // 'pending' | 'completed'

  // 필터 상태
  int? _selectedRoomId;

  // 날짜 필터 상태 (정산 완료 탭만)
  late String _startDate;
  late String _endDate;

  // PC 페이지네이션 상태
  int _currentPage = 1;
  static const int _itemsPerPage = 20;

  // 모바일 무한스크롤 상태
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // API 데이터
  List<Settlement> _settlements = [];
  List<SettlementRoom> _rooms = [];
  SettlementSummary? _summary;
  SettlementPagination? _pagination;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDefaultDates();
    _scrollController.addListener(_onScroll);
    _loadSettlements();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initDefaultDates() {
    final today = DateTime.now();
    final lastMonth = DateTime(today.year, today.month - 1, 1);

    _endDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    _startDate =
        '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}-${lastMonth.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSettlements({bool loadMore = false}) async {

    if (_isLoading) {
      AppLogger.w('⚠️ [SETTLEMENT PAGE] 이미 로딩 중, 스킵');
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });


    try {
      final response = await _settlementService.getSettlements(
        tab: _activeTab,
        roomId: _activeTab == 'completed' ? _selectedRoomId : null,
        startDate: _activeTab == 'completed' ? _startDate : null,
        endDate: _activeTab == 'completed' ? _endDate : null,
        page: loadMore ? _currentPage + 1 : 1,
        limit: _itemsPerPage,
      );


      if (response != null) {
        setState(() {
          if (loadMore) {
            _settlements.addAll(response.settlements);
            _currentPage++;
          } else {
            _settlements = response.settlements;
            _currentPage = 1;
          }
          _summary = response.summary;
          _pagination = response.pagination;
          _rooms = response.rooms;
        });
      } else {
        AppLogger.e('❌ [SETTLEMENT PAGE] response가 null');
        setState(() {
          _error = '정산 내역을 불러오는데 실패했습니다.';
        });
      }
    } catch (e) {
      AppLogger.e('❌ [SETTLEMENT PAGE] Exception: $e');
      setState(() {
        _error = '정산 내역을 불러오는데 실패했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1024) return; // PC에서는 무한스크롤 비활성화

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore) {
      final hasMore = _pagination != null &&
          _currentPage < _pagination!.totalPages;
      if (hasMore) {
        _loadSettlements(loadMore: true);
      }
    }
  }

  String get _selectedRoomName {
    if (_selectedRoomId == null) return '전체 보기';
    final room = _rooms.firstWhere(
      (r) => r.roomId == _selectedRoomId,
      orElse: () => SettlementRoom(roomId: 0, roomTitle: '전체 보기'),
    );
    return room.roomTitle;
  }

  int get _totalAmount {
    return _summary?.totalSettlementAmount ?? 0;
  }

  int get _totalCount {
    return _summary?.totalCount ?? _settlements.length;
  }

  void _handleStartDateChange(String newStartDate) {
    if (newStartDate.compareTo(_endDate) > 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth < 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('시작일은 종료일보다 미래일 수 없습니다.'),
            backgroundColor: AppColors.error500,
          ),
        );
      } else {
        _showAlertDialog('시작일은 종료일보다 미래일 수 없습니다.');
      }
      return;
    }
    setState(() {
      _startDate = newStartDate;
    });
    _loadSettlements();
  }

  void _handleEndDateChange(String newEndDate) {
    if (newEndDate.compareTo(_startDate) < 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth < 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('종료일은 시작일보다 과거일 수 없습니다.'),
            backgroundColor: AppColors.error500,
          ),
        );
      } else {
        _showAlertDialog('종료일은 시작일보다 과거일 수 없습니다.');
      }
      return;
    }
    setState(() {
      _endDate = newEndDate;
    });
    _loadSettlements();
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _handleDownloadExcel() {
    final url = _settlementService.getExportUrl(
      tab: _activeTab,
      roomId: _selectedRoomId,
      startDate: _activeTab == 'completed' ? _startDate : null,
      endDate: _activeTab == 'completed' ? _endDate : null,
    );

    // 웹에서 새 탭으로 다운로드 URL 열기
    html.window.open(url, '_blank');
  }

  void _onTabChange(String tab) {
    setState(() {
      _activeTab = tab;
      _selectedRoomId = null;
    });
    _loadSettlements();
  }

  void _onRoomFilterChange(String roomIdStr) {
    setState(() {
      if (roomIdStr == 'all') {
        _selectedRoomId = null;
      } else {
        _selectedRoomId = int.tryParse(roomIdStr);
      }
    });
    _loadSettlements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const AppGNB(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    // PC 페이지네이션
    final totalPages = _pagination?.totalPages ?? 1;

    if (_isLoading && _settlements.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.blue500),
      );
    }

    if (_error != null && _settlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: AppColors.error500),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettlements,
              child: Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 탭
                _buildTabs(),
                SizedBox(height: 16),
                // 필터 & 총액
                _buildFilterSection(),
                SizedBox(height: 16),
                // 정산 테이블
                if (_settlements.isEmpty)
                  _buildEmptyState()
                else
                  _buildSettlementTable(_settlements, isDesktop),
                // PC 페이지네이션
                if (isDesktop && _settlements.isNotEmpty)
                  _buildPagination(totalPages),
                // 모바일 무한스크롤 로딩 인디케이터
                if (_isLoadingMore)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final pendingCount = _summary?.pendingCount ?? 0;
    final completedCount = _summary?.completedCount ?? 0;

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildTabButton(
                  'pending', '정산 예정 ($pendingCount)')),
          Expanded(
              child: _buildTabButton(
                  'completed', '정산 완료 ($completedCount)')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isActive = _activeTab == tab;

    return GestureDetector(
      onTap: () => _onTabChange(tab),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blue500 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 필터 버튼들
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 방 필터 버튼
              _buildRoomFilterButton(isDesktop),
              // 날짜 필터 (정산 완료 탭만)
              if (_activeTab == 'completed') ...[
                SettlementDatePicker(
                  label: '시작일',
                  selectedDate: _startDate,
                  onDateChange: _handleStartDateChange,
                ),
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral400,
                  ),
                ),
                SettlementDatePicker(
                  label: '종료일',
                  selectedDate: _endDate,
                  onDateChange: _handleEndDateChange,
                ),
              ],
              // 엑셀 다운로드 버튼
              _buildExcelDownloadButton(),
            ],
          ),
          SizedBox(height: 16),
          // 총 정산 금액
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '총',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${_totalCount}건',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.blue600,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${_formatNumber(_totalAmount)}원',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFilterButton(bool isDesktop) {
    // SettlementRoom을 filter_bottom_sheet에서 사용하는 형식으로 변환
    final roomsForBottomSheet = _rooms
        .map((r) => SettlementRoom(roomId: r.roomId, roomTitle: r.roomTitle))
        .toList();

    return InkWell(
      onTap: () {
        showSettlementFilterBottomSheet(
          context: context,
          rooms: roomsForBottomSheet,
          selectedRoomId: _selectedRoomId?.toString() ?? 'all',
          onSelectRoom: _onRoomFilterChange,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedRoomName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelDownloadButton() {
    return InkWell(
      onTap: _handleDownloadExcel,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_outlined,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              '엑셀 내려받기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '정산 내역이 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral400,
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementTable(List<Settlement> settlements, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 테이블 헤더 (PC only)
          if (isDesktop) _buildTableHeader(),
          // 테이블 바디
          ...settlements.asMap().entries.map((entry) {
            final index = entry.key;
            final settlement = entry.value;
            return Column(
              children: [
                if (index > 0 || isDesktop)
                  Divider(height: 1, color: AppColors.gray200),
                _buildSettlementRow(settlement, isDesktop),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              _activeTab == 'pending' ? '정산 예정일' : '정산일',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '방 이름',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '계약자',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '입주일',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '총 정산 금액',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '상세보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementRow(Settlement settlement, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopRow(settlement);
    } else {
      return _buildMobileRow(settlement);
    }
  }

  Widget _buildDesktopRow(Settlement settlement) {
    // ISO 8601 날짜를 YYYY-MM-DD로 변환
    final checkInDate = _formatIsoDate(settlement.checkInDate);

    return InkWell(
      onTap: () => context.push('/host/settlement/${settlement.contractId}'),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                settlement.settlementDate,
                style: TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      settlement.roomTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue600,
                      ),
                    ),
                  ),
                  if (settlement.hasEzCleaningService) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EZ청소',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.blue600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                settlement.guestName,
                style: TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Text(
                    checkInDate,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (settlement.hasRefund) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '계약취소',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${_formatNumber(settlement.settlementAmount)}원',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 100,
              child: Center(
                child: TextButton(
                  onPressed: () =>
                      context.push('/host/settlement/${settlement.contractId}'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.neutral100,
                    foregroundColor: AppColors.neutral700,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    '상세보기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRow(Settlement settlement) {
    final checkInDate = _formatIsoDate(settlement.checkInDate);

    return InkWell(
      onTap: () => context.push('/host/settlement/${settlement.contractId}'),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Stack(
          children: [
            // 오른쪽 상단 화살표 아이콘
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.neutral400,
              ),
            ),
            // 내용
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileRowItem(
                  label: _activeTab == 'pending' ? '정산 예정일:' : '정산일:',
                  value: settlement.settlementDate,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        '방 이름:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            settlement.roomTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blue600,
                            ),
                          ),
                          if (settlement.hasEzCleaningService) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EZ청소',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blue600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildMobileRowItem(
                  label: '계약자:',
                  value: settlement.guestName,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        '입주일:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                    Text(
                      checkInDate,
                      style: TextStyle(fontSize: 14),
                    ),
                    if (settlement.hasRefund) ...[
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '계약취소',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),
                _buildMobileRowItem(
                  label: '총 정산 금액:',
                  value: '${_formatNumber(settlement.settlementAmount)}원',
                  valueFontWeight: FontWeight.w700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRowItem({
    required String label,
    required String value,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.neutral500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: valueFontWeight,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    if (totalPages == 0) totalPages = 1;

    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 버튼
          _buildPaginationButton(
            label: '이전',
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadSettlements();
                  }
                : null,
          ),
          SizedBox(width: 8),
          // 페이지 번호들
          ..._buildPageNumbers(totalPages),
          SizedBox(width: 8),
          // 다음 버튼
          _buildPaginationButton(
            label: '다음',
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadSettlements();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    final widgets = <Widget>[];

    for (int page = 1; page <= totalPages; page++) {
      if (page == 1 ||
          page == totalPages ||
          (page >= _currentPage - 1 && page <= _currentPage + 1)) {
        widgets.add(
          _buildPageNumberButton(page),
        );
      } else if (page == _currentPage - 2 || page == _currentPage + 2) {
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '...',
              style: TextStyle(color: AppColors.neutral400),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildPageNumberButton(int page) {
    final isActive = _currentPage == page;

    return GestureDetector(
      onTap: () {
        setState(() => _currentPage = page);
        _loadSettlements();
      },
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blue500 : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: AppColors.gray200),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : AppColors.neutral700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: onPressed != null
            ? AppColors.textPrimary
            : AppColors.neutral400,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  /// ISO 8601 날짜 문자열을 YYYY-MM-DD 형식으로 변환
  String _formatIsoDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
