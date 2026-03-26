import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/room.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/room_management_card.dart';
import '../../utils/responsive_util.dart';
import '../../services/room_management_service.dart';
import '../../widgets/common/app_footer.dart';

/// 방 관리 페이지
///
/// 호스트가 등록한 방 목록을 상태별로 관리하고,
/// 수정/게시·중단/복제/삭제/일정관리 액션을 수행할 수 있는 페이지
class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({super.key});

  @override
  State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  // 서비스
  final RoomManagementService _roomService = RoomManagementService();

  // 검색어
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  // 선택된 상태 필터
  String _selectedStatus = 'all';

  // 방 목록 데이터
  List<Room> _rooms = [];
  bool _isLoading = false;

  // 상태 필터 드롭다운
  bool _isStatusDropdownOpen = false;
  final LayerLink _statusDropdownLayerLink = LayerLink();
  OverlayEntry? _statusDropdownOverlayEntry;
  final GlobalKey _statusDropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });

      // 검색어 디바운싱 (500ms 후 API 호출)
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _loadRooms();
      });
    });

    // 초기 데이터 로드
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _removeStatusDropdownOverlay();
    super.dispose();
  }

  /// 방 목록 로드
  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // API 호출 시 선택된 상태 필터 적용
      String? statusFilter;
      bool? isActiveFilter;

      if (_selectedStatus == 'draft') {
        statusFilter = 'draft';
      } else if (_selectedStatus == 'pending_review') {
        statusFilter = 'pending_review';
      } else if (_selectedStatus == 'approved') {
        statusFilter = 'approved';
      } else if (_selectedStatus == 'published_active') {
        statusFilter = 'published';
        isActiveFilter = true;
      } else if (_selectedStatus == 'published_inactive') {
        statusFilter = 'published';
        isActiveFilter = false;
      } else if (_selectedStatus == 'rejected') {
        statusFilter = 'rejected';
      } else if (_selectedStatus == 'hidden_by_admin') {
        statusFilter = 'hidden_by_admin';
      }

      final data = await _roomService.getRooms(
        status: statusFilter,
        isActive: isActiveFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      debugPrint('🔵 [ROOM_MANAGEMENT] API 응답 data: ${data != null ? "있음" : "null"}');

      if (data != null) {
        final rooms = _roomService.parseRooms(data);
        debugPrint('✅ [ROOM_MANAGEMENT] 로드된 방 개수: ${rooms.length}');

        if (rooms.isNotEmpty) {
          debugPrint('📋 [ROOM_MANAGEMENT] 첫 번째 방 정보:');
          debugPrint('  - 이름: ${rooms.first.roomName}');
          debugPrint('  - status: ${rooms.first.status}');
          debugPrint('  - isActive: ${rooms.first.isActive}');
        }

        setState(() {
          _rooms = rooms;
        });

        debugPrint('🔍 [ROOM_MANAGEMENT] 필터링 조건: $_selectedStatus');
        debugPrint('✅ [ROOM_MANAGEMENT] 필터링된 방 개수: ${_filteredRooms.length}');

        if (_filteredRooms.isEmpty && rooms.isNotEmpty) {
          debugPrint('⚠️ [ROOM_MANAGEMENT] 필터링으로 모든 방이 제외됨!');
        }
      } else {
        debugPrint('❌ [ROOM_MANAGEMENT] API 응답 data가 null입니다');
      }
    } catch (e) {
      debugPrint('❌ [RoomManagementPage] 방 목록 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return ColoredBox(
      color: AppColors.background,  // bg-gray-50
      child: Column(
        children: [
          // Header Section (sticky top-0)
          _buildStickyHeader(context, isMobile),

          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRooms.isEmpty
                    ? _buildEmptyState()
                    : _buildRoomList(),
          ),
        ],
      ),
    );
  }

  /// Sticky Header 섹션 (React: sticky top-0 z-50)
  Widget _buildStickyHeader(BuildContext context, bool isMobile) {
    final isDesktop = ResponsiveUtil.isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,  // bg-white
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),  // border-b border-gray-200
        ),
      ),
      child: MaxWidthContainer(
        maxWidth: 1024,  // max-w-5xl (React와 동일)
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,  // px-4 lg:px-8
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 (데스크톱만 표시, React: hidden lg:block)
              if (isDesktop) ...[
                const SizedBox(height: 12),  // py-3 lg:py-4
                Text(
                  '방 관리',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,  // text-gray-900
                  ),
                ),
                const SizedBox(height: 16),  // py-4
              ],

              // 검색 바 (모바일: pt-3, 데스크톱: pt-0)
              SizedBox(height: isDesktop ? 0 : 12),  // pt-3 lg:pt-0
              CustomTextField(
                controller: _searchController,
                label: '',
                hint: '방 이름이나 주소로 검색',
                prefixIcon: const Icon(Icons.search),
              ),
              const SizedBox(height: 12),  // pb-3 lg:pb-4

              // 필터 드롭다운 + 등록 버튼
              Row(
                children: [
                  // 상태 필터 드롭다운
                  Expanded(
                    child: _buildStatusDropdown(),
                  ),
                  const SizedBox(width: 12),  // gap-3

                  // 방 등록 버튼
                  if (isDesktop)
                    CustomButton(
                      text: '방 등록하기',  // ✅ + 기호 제거
                      onPressed: _onRegisterRoom,
                      backgroundColor: AppColors.primary500,  // bg-blue-600
                      foregroundColor: AppColors.textOnPrimary,
                      icon: const Icon(Icons.add, size: 20),  // Plus 아이콘 추가
                    ),
                  if (!isDesktop)
                    // 모바일: "등록" 텍스트 + 아이콘
                    CustomButton(
                      text: '등록',  // ✅ React: lg:hidden "등록"
                      onPressed: _onRegisterRoom,
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.textOnPrimary,
                      icon: const Icon(Icons.add, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 16),  // pb-4
            ],
          ),
        ),
      ),
    );
  }

  /// 상태 필터 드롭다운 토글
  void _toggleStatusDropdown() {
    if (_isStatusDropdownOpen) {
      _removeStatusDropdownOverlay();
    } else {
      _showStatusDropdownOverlay();
    }
  }

  /// 상태 필터 드롭다운 오버레이 표시
  void _showStatusDropdownOverlay() {
    _statusDropdownOverlayEntry = _createStatusDropdownOverlayEntry();
    Overlay.of(context).insert(_statusDropdownOverlayEntry!);
    setState(() => _isStatusDropdownOpen = true);
  }

  /// 상태 필터 드롭다운 오버레이 제거
  void _removeStatusDropdownOverlay() {
    _statusDropdownOverlayEntry?.remove();
    _statusDropdownOverlayEntry = null;
    if (mounted) {
      setState(() => _isStatusDropdownOpen = false);
    }
  }

  /// 상태 필터 드롭다운 오버레이 생성
  OverlayEntry _createStatusDropdownOverlayEntry() {
    final RenderBox? renderBox = _statusDropdownKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(0, 48);
    final statusCounts = _getStatusCounts();

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 배경 오버레이 (클릭 시 닫힘)
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeStatusDropdownOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

          // 드롭다운 메뉴 (React: w-48 = 192px)
          Positioned(
            width: 192, // React: w-48
            child: CompositedTransformFollower(
              link: _statusDropdownLayerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8), // 버튼 아래 8px
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusMenuItem(
                        label: '전체',
                        count: statusCounts['all'] ?? 0,
                        value: 'all',
                      ),
                      _buildStatusMenuItem(
                        label: '등록중',
                        count: statusCounts['draft'] ?? 0,
                        value: 'draft',
                      ),
                      _buildStatusMenuItem(
                        label: '심사중',
                        count: statusCounts['pending_review'] ?? 0,
                        value: 'pending_review',
                      ),
                      _buildStatusMenuItem(
                        label: '승인됨',
                        count: statusCounts['approved'] ?? 0,
                        value: 'approved',
                      ),
                      _buildStatusMenuItem(
                        label: '게시중',
                        count: statusCounts['published_active'] ?? 0,
                        value: 'published_active',
                      ),
                      _buildStatusMenuItem(
                        label: '게시중단',
                        count: statusCounts['published_inactive'] ?? 0,
                        value: 'published_inactive',
                      ),
                      _buildStatusMenuItem(
                        label: '등록 반려',
                        count: statusCounts['rejected'] ?? 0,
                        value: 'rejected',
                      ),
                      _buildStatusMenuItem(
                        label: '관리자 숨김',
                        count: statusCounts['hidden_by_admin'] ?? 0,
                        value: 'hidden_by_admin',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 필터 메뉴 아이템
  /// React: px-4 py-3, text-sm font-medium (14px, 500)
  Widget _buildStatusMenuItem({
    required String label,
    required int count,
    required String value,
  }) {
    final isSelected = _selectedStatus == value;

    return InkWell(
      onTap: () {
        _removeStatusDropdownOverlay();
        setState(() {
          _selectedStatus = value;
        });
        _loadRooms();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // React: px-4
          vertical: 12,   // React: py-3
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neutral50 : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // React: text-sm
                fontWeight: FontWeight.w500, // font-medium
                color: AppColors.textPrimary,
              ),
            ),
            // 카운트 배지 (React: bg-gray-100 rounded-full px-2 py-0.5)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,  // px-2
                vertical: 2,    // py-0.5
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(9999), // rounded-full
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상태 필터 드롭다운 버튼
  /// React UI: px-4 py-2 = 16px 8px, 내용 크기에 맞춰 자동 조절
  Widget _buildStatusDropdown() {
    final statusCounts = _getStatusCounts();

    // 현재 선택된 상태의 라벨
    String selectedLabel;
    int selectedCount;

    switch (_selectedStatus) {
      case 'draft':
        selectedLabel = '등록중';
        selectedCount = statusCounts['draft'] ?? 0;
        break;
      case 'pending_review':
        selectedLabel = '심사중';
        selectedCount = statusCounts['pending_review'] ?? 0;
        break;
      case 'approved':
        selectedLabel = '승인됨';
        selectedCount = statusCounts['approved'] ?? 0;
        break;
      case 'published_active':
        selectedLabel = '게시중';
        selectedCount = statusCounts['published_active'] ?? 0;
        break;
      case 'published_inactive':
        selectedLabel = '게시중단';
        selectedCount = statusCounts['published_inactive'] ?? 0;
        break;
      case 'rejected':
        selectedLabel = '등록 반려';
        selectedCount = statusCounts['rejected'] ?? 0;
        break;
      case 'hidden_by_admin':
        selectedLabel = '관리자 숨김';
        selectedCount = statusCounts['hidden_by_admin'] ?? 0;
        break;
      default:
        selectedLabel = '전체';
        selectedCount = statusCounts['all'] ?? 0;
    }

    return CompositedTransformTarget(
      key: _statusDropdownKey,
      link: _statusDropdownLayerLink,
      child: InkWell(
        onTap: _toggleStatusDropdown,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16, // React: px-4
            vertical: 8,    // React: py-2
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600, // font-semibold
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($selectedCount)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isStatusDropdownOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20, // React: w-5 h-5
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상태별 카운트 계산
  Map<String, int> _getStatusCounts() {
    final counts = <String, int>{
      'all': _rooms.length,
      'draft': 0,
      'pending_review': 0,
      'approved': 0,
      'published_active': 0,
      'published_inactive': 0,
      'rejected': 0,
      'hidden_by_admin': 0,
    };

    for (final room in _rooms) {
      if (room.status == 'draft') {
        counts['draft'] = (counts['draft'] ?? 0) + 1;
      } else if (room.status == 'pending_review') {
        counts['pending_review'] = (counts['pending_review'] ?? 0) + 1;
      } else if (room.status == 'approved') {
        counts['approved'] = (counts['approved'] ?? 0) + 1;
      } else if (room.status == 'published' && room.isActive) {
        counts['published_active'] = (counts['published_active'] ?? 0) + 1;
      } else if (room.status == 'published' && !room.isActive) {
        counts['published_inactive'] = (counts['published_inactive'] ?? 0) + 1;
      } else if (room.status == 'rejected') {
        counts['rejected'] = (counts['rejected'] ?? 0) + 1;
      } else if (room.status == 'hidden_by_admin') {
        counts['hidden_by_admin'] = (counts['hidden_by_admin'] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// 필터링된 방 목록
  List<Room> get _filteredRooms {
    return _rooms.where((room) {
      // 검색어 필터 (클라이언트 측 추가 필터링)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!room.roomName.toLowerCase().contains(query) &&
            !room.address.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 상태 필터 (클라이언트 측 추가 필터링)
      if (_selectedStatus == 'all') return true;
      if (_selectedStatus == 'draft') return room.status == 'draft';
      if (_selectedStatus == 'pending_review') return room.status == 'pending_review';
      if (_selectedStatus == 'approved') return room.status == 'approved';
      if (_selectedStatus == 'published_active') {
        return room.status == 'published' && room.isActive;
      }
      if (_selectedStatus == 'published_inactive') {
        return room.status == 'published' && !room.isActive;
      }
      if (_selectedStatus == 'rejected') return room.status == 'rejected';
      if (_selectedStatus == 'hidden_by_admin') return room.status == 'hidden_by_admin';

      return true;
    }).toList();
  }

  /// 방 목록 (스크롤 가능)
  /// React UI: max-w-5xl mx-auto px-4 lg:px-8 py-4 lg:py-6
  Widget _buildRoomList() {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32, // ✅ React: px-4 lg:px-8
            vertical: isMobile ? 16 : 24,   // ✅ React: py-4 lg:py-6
          ),
          child: Column(
            children: [
              for (int i = 0; i < _filteredRooms.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1024, // ✅ React: max-w-5xl = 1024px
                    ),
                    child: RoomManagementCard(
                      room: _filteredRooms[i],
                      onTap: () => _onRoomTap(_filteredRooms[i]),
                      onEdit: () => _onEditRoom(_filteredRooms[i]),
                      onSchedule: () => _onScheduleRoom(_filteredRooms[i]),
                      onTogglePublish: () => _onTogglePublish(_filteredRooms[i]),
                      onDuplicate: () => _onDuplicateRoom(_filteredRooms[i]),
                      onDelete: () => _onDeleteRoom(_filteredRooms[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const AppFooter(),
      ],
    );
  }

  /// Empty State (등록된 방이 없을 때)
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description,  // ✅ React: <FileText size={64} /> → description icon
                  size: 64,
                  color: AppColors.neutral400,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _searchQuery.isNotEmpty || _selectedStatus != 'all'
                      ? '검색 결과가 없습니다'
                      : '등록된 방이 없습니다',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _searchQuery.isNotEmpty || _selectedStatus != 'all'
                      ? '다른 검색어나 필터를 시도해보세요'
                      : '새로운 방을 등록하고 게스트를 맞이해보세요',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_searchQuery.isEmpty && _selectedStatus == 'all')
                  CustomButton(
                    text: '첫 번째 방 등록하기',  // ✅ React: "첫 번째 방 등록하기" (no + prefix)
                    onPressed: _onRegisterRoom,
                    backgroundColor: AppColors.primary500,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  // ========== 액션 핸들러 ==========

  void _onRegisterRoom() {
    context.go('/host/room-registration');
  }

  void _onRoomTap(Room room) {
    context.go('/guest/room/detail/${room.id}');
  }

  void _onEditRoom(Room room) async {
    // 승인된 방 수정 시 재심사 안내
    if (room.needsReReviewOnEdit) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning500, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('수정 시 재심사 안내'),
              ),
            ],
          ),
          content: const Text(
            '현재 승인된 방입니다.\n\n'
            '기본 정보(주소, 방 유형 등)는 수정할 수 없으며, '
            '요금·할인·소개·규칙·입퇴실 시간·사진·EZ서비스만 변경 가능합니다.\n\n'
            '일부 항목 변경 시 재심사가 필요할 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('수정하기'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    context.go('/host/room-registration/${room.id}');
  }

  void _onScheduleRoom(Room room) {
    // 일정관리 페이지로 이동
    context.pushNamed('room-schedule', pathParameters: {'roomId': room.id.toString()});
  }

  Future<void> _onTogglePublish(Room room) async {
    final newStatus = !room.isActive;
    final statusText = newStatus ? '게시' : '비공개';

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$statusText 전환'),
        content: Text('이 방을 $statusText로 전환하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(statusText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // API 호출
    final success = await _roomService.togglePublishStatus(room.id, newStatus);

    if (!mounted) return;

    if (success) {
      // 성공 시 목록 새로고침
      await _loadRooms();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$statusText 전환 완료'),
            content: Text('${room.roomName}을(를) $statusText로 전환했습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$statusText 전환 실패'),
          content: Text('${room.roomName} $statusText 전환에 실패했습니다.\n다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onDuplicateRoom(Room room) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방 복제'),
        content: Text('${room.roomName}을(를) 복제하시겠습니까?\n\n사진, 편의시설, 부가서비스, 방 소개가 모두 복사됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // API 호출
    final newRoomName = await _roomService.duplicateRoom(room.id);

    if (!mounted) return;

    if (newRoomName != null) {
      // 성공 시 목록 새로고침
      await _loadRooms();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('복제 완료'),
            content: Text('\'$newRoomName\'이(가) 생성되었습니다.\n수정 후 등록해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } else {
      // 실패 시 에러 알림
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('복제 실패'),
          content: Text('${room.roomName} 복제에 실패했습니다.\n다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onDeleteRoom(Room room) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방 삭제'),
        content: Text('${room.roomName}을(를) 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error500,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // API 호출
    final success = await _roomService.deleteRoom(room.id);

    if (success && mounted) {
      // 성공 시 목록 새로고침
      _loadRooms();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${room.roomName}을(를) 삭제했습니다.'),
          backgroundColor: AppColors.success500,
        ),
      );
    }
  }
}
