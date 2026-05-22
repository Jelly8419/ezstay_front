import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/move_in/move_in.dart';
import '../../../services/move_in_service.dart';
import '../../../widgets/common/custom_toast.dart';
import 'widgets/move_in_create_existing_tab.dart';
import 'widgets/move_in_create_simple_tab.dart';

/// 새 입주 준비 등록 (호스트) — 이미지 ② 화면
///
/// 두 개 탭:
/// 1. 등록된 방에서 선택 — 기존 간편 방 + 계약 정보 + 청소 서비스
/// 2. 새 주소로 간편 등록 — 방 정보만 등록
///
/// 탭 2에서 방을 등록하면 → 자동으로 탭 1로 전환 + 신규 방을 선택 상태로.
class MoveInCreatePage extends StatefulWidget {
  /// 초기 활성 탭 — 'existing' (기본) 또는 'new'
  final String? initialTab;

  /// 알림 딥링크에서 전달된 강조 대상 방 id — ExistingTab 에서 자동 스크롤 + 자동 선택 + 펄스
  final int? highlightRoomId;

  const MoveInCreatePage({super.key, this.initialTab, this.highlightRoomId});

  @override
  State<MoveInCreatePage> createState() => _MoveInCreatePageState();
}

class _MoveInCreatePageState extends State<MoveInCreatePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final MoveInService _service = MoveInService();

  List<MoveInRoom> _rooms = const [];
  bool _isLoadingRooms = false;
  int? _selectedRoomIdForExistingTab;

  @override
  void initState() {
    super.initState();
    // highlightRoomId 가 오면 'existing' 탭이 강제로 열려야 한다 — 'new' 명시 시에만 1번 탭
    final initialIndex = (widget.initialTab == 'new' && widget.highlightRoomId == null) ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    // 딥링크로 들어온 경우 해당 방을 우선 자동 선택
    _selectedRoomIdForExistingTab = widget.highlightRoomId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await _service.getMoveInRooms();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } on MoveInException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  /// 탭 2에서 방 등록 성공 시 호출 — 탭 1로 전환 + 신규 방 선택
  void _onSimpleRoomCreated(MoveInRoom room) {
    setState(() {
      _rooms = [room, ..._rooms];
      _selectedRoomIdForExistingTab = room.id;
    });
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    // 등록 페이지는 TabBarView 안에 자체 스크롤뷰를 가지므로
    // ResponsivePageLayout(scrollable=true)을 쓰지 않고 직접 max-width 제약만 적용.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '입주 준비 서비스로 돌아가기',
                    onPressed: () => context.go('/host/move-in'),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('새 입주 준비 등록', style: AppTextStyles.headingLarge),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '등록된 방에서 선택'),
                Tab(text: '새 주소로 간편 등록'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MoveInCreateExistingTab(
                    rooms: _rooms,
                    isLoadingRooms: _isLoadingRooms,
                    initialSelectedRoomId: _selectedRoomIdForExistingTab,
                    highlightRoomId: widget.highlightRoomId,
                    onRoomsChanged: _loadRooms,
                  ),
                  MoveInCreateSimpleTab(onCreated: _onSimpleRoomCreated),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
