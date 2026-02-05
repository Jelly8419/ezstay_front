import 'package:flutter/material.dart';
import '../models/room.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// 방 관리 액션 드롭다운 위젯 (React PropertyCard 완벽 복제)
///
/// React UI:
/// - 버튼: px-3 py-1.5, text-[15px], ChevronDown 아이콘
/// - 메뉴: w-40 (160px), py-1, 아이콘 없음, text-[15px]
/// - 삭제하기만 빨간색 (text-red-600)
class RoomActionDropdown extends StatefulWidget {
  final Room room;
  final VoidCallback? onEdit;
  final VoidCallback? onSchedule;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const RoomActionDropdown({
    super.key,
    required this.room,
    this.onEdit,
    this.onSchedule,
    this.onTogglePublish,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  State<RoomActionDropdown> createState() => _RoomActionDropdownState();
}

class _RoomActionDropdownState extends State<RoomActionDropdown> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  /// 오버레이 닫고 다음 프레임에서 콜백 실행
  void _closeAndRun(VoidCallback? callback) {
    _removeOverlay();
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) callback();
      });
    }
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
    entry?.dispose();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // 버튼 하단에서 화면 끝까지 남은 공간 (드롭다운 높이 ~200px 예상)
    final spaceBelow = screenHeight - buttonPosition.dy - size.height;
    final openUpward = spaceBelow < 220;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 배경 오버레이 (클릭 시 닫힘)
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

          // 드롭다운 메뉴 (React: w-40 = 160px)
          Positioned(
            width: 160, // React: w-40
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: openUpward ? Alignment.topRight : Alignment.bottomRight,
              followerAnchor: openUpward ? Alignment.bottomRight : Alignment.topRight,
              offset: openUpward ? const Offset(0, -8) : const Offset(0, 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8), // rounded-lg
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildMenuItems(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final items = <Widget>[];

    // 수정하기 (React: draft, rejected, approved일 때)
    if (widget.room.canEdit) {
      items.add(_buildMenuItem(
        label: '수정하기',
        onTap: () => _closeAndRun(widget.onEdit),
      ));
    }

    // 일정관리 (React: approved 또는 inactive일 때)
    if (widget.room.canSchedule) {
      items.add(_buildMenuItem(
        label: '일정관리',
        onTap: () => _closeAndRun(widget.onSchedule),
      ));
    }

    // 게시/비공개 (React: approved 또는 inactive일 때)
    if (widget.room.canTogglePublish) {
      items.add(_buildMenuItem(
        label: widget.room.isActive ? '비공개 하기' : '게시하기',
        onTap: () => _closeAndRun(widget.onTogglePublish),
      ));
    }

    // 복제하기 (React: draft가 아닐 때)
    if (widget.room.canDuplicate) {
      items.add(_buildMenuItem(
        label: '복제하기',
        onTap: () => _closeAndRun(widget.onDuplicate),
      ));
    }

    // 삭제하기 (React: 항상 표시, 빨간색)
    if (widget.room.canDelete) {
      items.add(_buildMenuItem(
        label: '삭제하기',
        isDestructive: true,
        onTap: () => _closeAndRun(widget.onDelete),
      ));
    }

    return items;
  }

  /// 메뉴 아이템 (React: px-4 py-2, text-[15px], 아이콘 없음)
  Widget _buildMenuItem({
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // React: px-4
          vertical: 8,    // React: py-2
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15, // React: text-[15px]
            fontWeight: FontWeight.w500, // font-medium
            color: isDestructive ? AppColors.error500 : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12, // React: px-3
            vertical: 6,    // React: py-1.5
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8), // rounded-lg
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '관리 및 설정',
                style: TextStyle(
                  fontSize: 15, // React: text-[15px]
                  fontWeight: FontWeight.w500, // font-medium
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6), // gap-1.5
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0, // 180도 회전
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 14, // React: w-3.5 h-3.5
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
