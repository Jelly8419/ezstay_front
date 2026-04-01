import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/map_interaction_coordinator.dart';
import '../../utils/responsive_util.dart';
import 'mobile_property_card.dart';

/// 모바일/태블릿용 지도 전체화면 레이아웃
class MapOnlyLayout extends StatelessWidget {
  final Widget mapWidget;
  final List<Map<String, dynamic>> filteredRooms;
  final bool isLoading;
  final bool showMobileCardList;
  final int currentMobileCardIndex;
  final int? currentZoomLevel;
  final PageController mobileCardController;

  /// 매물 개수 뱃지 탭 콜백 (모바일 카드 토글)
  final VoidCallback onBadgeTap;

  /// PageView 페이지 변경 콜백
  final void Function(int index) onPageChanged;

  /// 지도 상태 저장 콜백 (roomId)
  final void Function(int roomId) onSaveMapState;

  /// 지도 마커 선택 해제 콜백
  final VoidCallback onDeselectMarker;

  const MapOnlyLayout({
    super.key,
    required this.mapWidget,
    required this.filteredRooms,
    required this.isLoading,
    required this.showMobileCardList,
    required this.currentMobileCardIndex,
    required this.currentZoomLevel,
    required this.mobileCardController,
    required this.onBadgeTap,
    required this.onPageChanged,
    required this.onSaveMapState,
    required this.onDeselectMarker,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        mapWidget,

        // 필터링 결과가 없을 때 안내 메시지
        if (!isLoading && filteredRooms.isEmpty)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  '일치하는 조건의 매물이 없습니다',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // 매물 개수 뱃지 (모바일: 하단 중앙, 데스크톱: 좌측 상단)
        if (filteredRooms.isNotEmpty &&
            (!ResponsiveUtil.isMobile(context) || !showMobileCardList))
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: ResponsiveUtil.isMobile(context) ? null : 16,
            bottom: ResponsiveUtil.isMobile(context) ? 80 : null,
            left: ResponsiveUtil.isMobile(context) ? 0 : 16,
            right: ResponsiveUtil.isMobile(context) ? 0 : null,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: ResponsiveUtil.isMobile(context)
                    ? () {
                        // 🎯 Coordinator: 마커 선택 모드 진입 + 300ms 이벤트 잠금
                        final coordinator =
                            Provider.of<MapInteractionCoordinator>(
                              context,
                              listen: false,
                            );
                        coordinator.enterMode(
                          InteractionMode.markerSelecting,
                          lockDuration: const Duration(milliseconds: 300),
                        );
                        onDeselectMarker();
                        onBadgeTap();
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '매물 ${filteredRooms.length}개',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (ResponsiveUtil.isMobile(context)) ...[
                        const SizedBox(width: 8),
                        Icon(
                          showMobileCardList
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20,
                          color: const Color(0xFF1F2937),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 하단 슬라이드 카드 (모바일 전용)
        if (ResponsiveUtil.isMobile(context) && filteredRooms.isNotEmpty)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: showMobileCardList ? 80 : -320,
            left: 0,
            right: 0,
            height: 320,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: showMobileCardList ? 1.0 : 0.0,
              child: Listener(
                onPointerDown: (_) {
                  final coordinator = Provider.of<MapInteractionCoordinator>(
                    context,
                    listen: false,
                  );
                  coordinator.enterMode(InteractionMode.cardSwiping);
                },
                onPointerUp: (_) {
                  final coordinator = Provider.of<MapInteractionCoordinator>(
                    context,
                    listen: false,
                  );
                  coordinator.exitMode();
                },
                onPointerCancel: (_) {
                  final coordinator = Provider.of<MapInteractionCoordinator>(
                    context,
                    listen: false,
                  );
                  coordinator.exitMode();
                },
                behavior: HitTestBehavior.opaque,
                child: PageView.builder(
                  controller: mobileCardController,
                  itemCount: filteredRooms.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    final roomData = filteredRooms[index];
                    return MobilePropertyCard(
                      roomData: roomData,
                      onSaveMapState: onSaveMapState,
                    );
                  },
                ),
              ),
            ),
          ),

        // 결과 없음 메시지
        if (filteredRooms.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                currentZoomLevel != null && currentZoomLevel! >= 6
                    ? '지도를 확대해서 방을 찾아주세요.'
                    : '현재 위치에 조건이 일치하는 방이 없습니다.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}
