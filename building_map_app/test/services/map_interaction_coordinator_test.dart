import 'package:flutter_test/flutter_test.dart';
import 'package:building_map_app/services/map_interaction_coordinator.dart';

void main() {
  group('MapInteractionCoordinator', () {
    late MapInteractionCoordinator coordinator;

    setUp(() {
      coordinator = MapInteractionCoordinator();
    });

    tearDown(() {
      coordinator.dispose();
    });

    group('Mode Management', () {
      test('초기 모드는 idle이어야 함', () {
        expect(coordinator.currentMode, InteractionMode.idle);
      });

      test('enterMode로 모드 전환이 가능해야 함', () {
        coordinator.enterMode(InteractionMode.listScrolling);
        expect(coordinator.currentMode, InteractionMode.listScrolling);

        coordinator.enterMode(InteractionMode.cardSwiping);
        expect(coordinator.currentMode, InteractionMode.cardSwiping);
      });

      test('exitMode로 idle 모드로 복귀해야 함', () {
        coordinator.enterMode(InteractionMode.filterOpen);
        expect(coordinator.currentMode, InteractionMode.filterOpen);

        coordinator.exitMode();
        expect(coordinator.currentMode, InteractionMode.idle);
      });

      test('모드 전환 시 리스너에게 알림이 가야 함', () {
        var notificationCount = 0;
        coordinator.addListener(() {
          notificationCount++;
        });

        coordinator.enterMode(InteractionMode.markerSelecting);
        expect(notificationCount, 1);

        coordinator.exitMode();
        expect(notificationCount, 2);
      });
    });

    group('Event Locking', () {
      test('lockDuration 없이 모드 전환 시 잠금되지 않아야 함', () {
        coordinator.enterMode(InteractionMode.listScrolling);
        expect(coordinator.isEventLocked, false);
      });

      test('lockDuration과 함께 모드 전환 시 잠금되어야 함', () async {
        coordinator.enterMode(
          InteractionMode.markerSelecting,
          lockDuration: const Duration(milliseconds: 100),
        );

        expect(coordinator.isEventLocked, true);
      });

      test('lockDuration 이후 자동으로 잠금 해제되어야 함', () async {
        coordinator.enterMode(
          InteractionMode.markerSelecting,
          lockDuration: const Duration(milliseconds: 100),
        );

        expect(coordinator.isEventLocked, true);

        // 150ms 대기 (100ms + 여유)
        await Future.delayed(const Duration(milliseconds: 150));

        expect(coordinator.isEventLocked, false);
      });

      test('잠금 해제 시 리스너에게 알림이 가야 함', () async {
        var notificationCount = 0;
        coordinator.addListener(() {
          notificationCount++;
        });

        coordinator.enterMode(
          InteractionMode.markerSelecting,
          lockDuration: const Duration(milliseconds: 100),
        );

        expect(notificationCount, 1); // enterMode 알림

        await Future.delayed(const Duration(milliseconds: 150));

        expect(notificationCount, 2); // 잠금 해제 알림
      });
    });

    group('Event Permission Checking', () {
      test('idle 모드에서는 기본 이벤트들을 허용해야 함', () {
        coordinator.enterMode(InteractionMode.idle);

        expect(coordinator.canProcessEvent(EventType.markerClick), true);
        expect(coordinator.canProcessEvent(EventType.badgeClick), true);
        expect(coordinator.canProcessEvent(EventType.mapDrag), true);
        expect(coordinator.canProcessEvent(EventType.clusterClick), true);
      });

      test('idle 모드에서는 특정 이벤트들을 차단해야 함', () {
        coordinator.enterMode(InteractionMode.idle);

        expect(coordinator.canProcessEvent(EventType.listScroll), false);
        expect(coordinator.canProcessEvent(EventType.pageViewDrag), false);
        expect(coordinator.canProcessEvent(EventType.filterInteraction), false);
      });

      test('listScrolling 모드에서는 listScroll만 허용해야 함', () {
        coordinator.enterMode(InteractionMode.listScrolling);

        expect(coordinator.canProcessEvent(EventType.listScroll), true);
        expect(coordinator.canProcessEvent(EventType.markerClick), false);
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);
      });

      test('cardSwiping 모드에서는 pageViewDrag만 허용해야 함', () {
        coordinator.enterMode(InteractionMode.cardSwiping);

        expect(coordinator.canProcessEvent(EventType.pageViewDrag), true);
        expect(coordinator.canProcessEvent(EventType.markerClick), false);
        expect(coordinator.canProcessEvent(EventType.listScroll), false);
      });

      test('filterOpen 모드에서는 filterInteraction만 허용해야 함', () {
        coordinator.enterMode(InteractionMode.filterOpen);

        expect(coordinator.canProcessEvent(EventType.filterInteraction), true);
        expect(coordinator.canProcessEvent(EventType.markerClick), false);
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);
      });

      test('markerSelecting 모드에서는 마커 관련 이벤트만 허용해야 함', () {
        coordinator.enterMode(InteractionMode.markerSelecting);

        expect(coordinator.canProcessEvent(EventType.markerClick), true);
        expect(coordinator.canProcessEvent(EventType.clusterClick), true);
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);
        expect(coordinator.canProcessEvent(EventType.listScroll), false);
      });

      test('이벤트 잠금 중에는 모든 이벤트를 차단해야 함', () {
        coordinator.enterMode(
          InteractionMode.idle,
          lockDuration: const Duration(milliseconds: 100),
        );

        // idle 모드에서 보통은 허용되는 이벤트들도 차단
        expect(coordinator.canProcessEvent(EventType.markerClick), false);
        expect(coordinator.canProcessEvent(EventType.badgeClick), false);
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);
      });

      test('이벤트 잠금 해제 후에는 모드에 따라 이벤트를 허용해야 함', () async {
        coordinator.enterMode(
          InteractionMode.idle,
          lockDuration: const Duration(milliseconds: 100),
        );

        // 잠금 중
        expect(coordinator.canProcessEvent(EventType.markerClick), false);

        // 잠금 해제 대기
        await Future.delayed(const Duration(milliseconds: 150));

        // 잠금 해제 후
        expect(coordinator.canProcessEvent(EventType.markerClick), true);
      });
    });

    group('Integration Scenarios', () {
      test('뱃지 클릭 → 마커 선택 시나리오', () async {
        // 1. 초기 상태: idle 모드
        expect(coordinator.currentMode, InteractionMode.idle);
        expect(coordinator.canProcessEvent(EventType.badgeClick), true);

        // 2. 뱃지 클릭 → markerSelecting 모드 진입 (300ms 잠금)
        coordinator.enterMode(
          InteractionMode.markerSelecting,
          lockDuration: const Duration(milliseconds: 300),
        );

        // 3. 300ms 동안 마커 클릭 차단
        expect(coordinator.canProcessEvent(EventType.markerClick), false);
        expect(coordinator.isEventLocked, true);

        // 4. 350ms 후 마커 클릭 가능
        await Future.delayed(const Duration(milliseconds: 350));
        expect(coordinator.canProcessEvent(EventType.markerClick), true);
        expect(coordinator.isEventLocked, false);
      });

      test('리스트 스크롤 중 지도 드래그 차단 시나리오', () {
        // 1. 리스트 스크롤 시작
        coordinator.enterMode(InteractionMode.listScrolling);

        // 2. 지도 드래그 차단
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);

        // 3. 리스트 스크롤 종료
        coordinator.exitMode();

        // 4. 지도 드래그 다시 허용
        expect(coordinator.canProcessEvent(EventType.mapDrag), true);
      });

      test('필터 열기 → 지도 드래그 차단 시나리오', () {
        // 1. 필터 드롭다운 열기
        coordinator.enterMode(InteractionMode.filterOpen);

        // 2. 지도 드래그 및 마커 클릭 차단
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);
        expect(coordinator.canProcessEvent(EventType.markerClick), false);

        // 3. 필터 인터랙션만 허용
        expect(coordinator.canProcessEvent(EventType.filterInteraction), true);

        // 4. 필터 닫기
        coordinator.exitMode();

        // 5. 모든 기본 이벤트 다시 허용
        expect(coordinator.canProcessEvent(EventType.mapDrag), true);
        expect(coordinator.canProcessEvent(EventType.markerClick), true);
      });

      test('카드 슬라이드 중 다른 인터랙션 차단 시나리오', () {
        // 1. PageView 드래그 시작
        coordinator.enterMode(InteractionMode.cardSwiping);

        // 2. PageView 드래그만 허용
        expect(coordinator.canProcessEvent(EventType.pageViewDrag), true);

        // 3. 다른 모든 이벤트 차단
        expect(coordinator.canProcessEvent(EventType.mapDrag), false);
        expect(coordinator.canProcessEvent(EventType.markerClick), false);
        expect(coordinator.canProcessEvent(EventType.listScroll), false);

        // 4. 슬라이드 종료
        coordinator.exitMode();

        // 5. 기본 이벤트 다시 허용
        expect(coordinator.canProcessEvent(EventType.mapDrag), true);
        expect(coordinator.canProcessEvent(EventType.markerClick), true);
      });
    });

    group('Edge Cases', () {
      test('동일한 모드로 여러 번 전환해도 문제없어야 함', () {
        coordinator.enterMode(InteractionMode.listScrolling);
        coordinator.enterMode(InteractionMode.listScrolling);
        coordinator.enterMode(InteractionMode.listScrolling);

        expect(coordinator.currentMode, InteractionMode.listScrolling);
      });

      test('잠금 중 모드 전환 시 기존 잠금이 취소되어야 함', () async {
        // 1. 첫 번째 모드 (500ms 잠금)
        coordinator.enterMode(
          InteractionMode.markerSelecting,
          lockDuration: const Duration(milliseconds: 500),
        );
        expect(coordinator.isEventLocked, true);

        // 2. 100ms 후 두 번째 모드 (100ms 잠금)
        await Future.delayed(const Duration(milliseconds: 100));
        coordinator.enterMode(
          InteractionMode.listScrolling,
          lockDuration: const Duration(milliseconds: 100),
        );

        // 3. 150ms 후 (첫 번째 잠금은 무시되고 두 번째 잠금만 적용)
        await Future.delayed(const Duration(milliseconds: 150));
        expect(coordinator.isEventLocked, false);
      });

      test('dispose 후에는 타이머가 정리되어야 함', () async {
        // 이 테스트만 별도의 coordinator 인스턴스 사용
        final testCoordinator = MapInteractionCoordinator();

        // listener를 먼저 추가
        var notificationCount = 0;
        testCoordinator.addListener(() {
          notificationCount++;
        });

        // 타이머 설정
        testCoordinator.enterMode(
          InteractionMode.markerSelecting,
          lockDuration: const Duration(milliseconds: 100),
        );

        // 초기 알림 (enterMode 호출)
        expect(notificationCount, 1);

        // dispose 호출 → 타이머가 취소되어야 함
        testCoordinator.dispose();

        // 150ms 대기 (원래는 100ms 후에 잠금 해제 알림이 가야 하지만)
        await Future.delayed(const Duration(milliseconds: 150));

        // dispose로 타이머가 취소되었으므로 추가 알림이 없어야 함
        expect(notificationCount, 1); // enterMode 알림만 있고, 잠금 해제 알림은 없음
      });
    });
  });
}
