import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// 지도 상호작용 모드
///
/// 현재 사용자가 어떤 인터랙션을 하고 있는지 나타냅니다.
/// 각 모드에서 허용되는 이벤트가 다릅니다.
enum InteractionMode {
  /// 대기 상태 - 모든 기본 이벤트 허용
  idle,

  /// 매물 리스트 스크롤 중 - 스크롤 이벤트만 허용
  listScrolling,

  /// 카드 슬라이드 중 (PageView) - PageView 드래그만 허용
  cardSwiping,

  /// 필터 드롭다운 열림 - 필터 인터랙션만 허용
  filterOpen,

  /// 마커 선택 중 - 마커 관련 이벤트만 허용
  markerSelecting,
}

/// 이벤트 타입
///
/// 시스템에서 발생할 수 있는 모든 이벤트 타입을 정의합니다.
enum EventType {
  /// 마커 클릭
  markerClick,

  /// 뱃지 클릭 (매물 개수 표시)
  badgeClick,

  /// 지도 드래그
  mapDrag,

  /// 리스트 스크롤
  listScroll,

  /// PageView 드래그 (카드 슬라이드)
  pageViewDrag,

  /// 필터 인터랙션
  filterInteraction,

  /// 클러스터 클릭
  clusterClick,
}

/// 지도 상호작용 조정자
///
/// 여러 UI 컴포넌트와 지도 간의 이벤트 충돌을 방지하기 위한
/// 중앙 조정 클래스입니다.
///
/// **주요 기능:**
/// - 현재 상호작용 모드 관리
/// - 이벤트 잠금 메커니즘 (일정 시간 동안 다른 이벤트 차단)
/// - 모드별 허용 이벤트 제어
///
/// **사용 예시:**
/// ```dart
/// final coordinator = Provider.of<MapInteractionCoordinator>(context);
///
/// // 뱃지 클릭 시
/// coordinator.enterMode(
///   InteractionMode.markerSelecting,
///   lockDuration: const Duration(milliseconds: 300),
/// );
///
/// // 마커 클릭 핸들러에서
/// if (!coordinator.canProcessEvent(EventType.markerClick)) {
///   return; // 차단됨
/// }
/// ```
class MapInteractionCoordinator extends ChangeNotifier {
  /// 현재 상호작용 모드
  InteractionMode _currentMode = InteractionMode.idle;

  /// 이벤트 잠금 여부
  bool _isEventLocked = false;

  /// 이벤트 잠금 타이머
  Timer? _lockTimer;

  /// 현재 모드 getter
  InteractionMode get currentMode => _currentMode;

  /// 이벤트 잠금 상태 getter
  bool get isEventLocked => _isEventLocked;

  /// 모드별 허용 이벤트 매핑
  ///
  /// 각 상호작용 모드에서 처리 가능한 이벤트 타입을 정의합니다.
  static const Map<InteractionMode, Set<EventType>> _allowedEvents = {
    InteractionMode.idle: {
      EventType.markerClick,
      EventType.badgeClick,
      EventType.mapDrag,
      EventType.clusterClick,
    },
    InteractionMode.listScrolling: {
      EventType.listScroll,
    },
    InteractionMode.cardSwiping: {
      EventType.pageViewDrag,
    },
    InteractionMode.filterOpen: {
      EventType.filterInteraction,
    },
    InteractionMode.markerSelecting: {
      EventType.markerClick,
      EventType.clusterClick,
    },
  };

  /// 모드 진입
  ///
  /// 새로운 상호작용 모드로 전환합니다.
  /// 선택적으로 이벤트 잠금 기간을 설정할 수 있습니다.
  ///
  /// **Parameters:**
  /// - [mode]: 전환할 모드
  /// - [lockDuration]: 선택적 잠금 기간 (다른 이벤트 차단)
  ///
  /// **예시:**
  /// ```dart
  /// // 300ms 동안 다른 이벤트 차단
  /// coordinator.enterMode(
  ///   InteractionMode.markerSelecting,
  ///   lockDuration: const Duration(milliseconds: 300),
  /// );
  /// ```
  void enterMode(InteractionMode mode, {Duration? lockDuration}) {
    _currentMode = mode;

    if (lockDuration != null) {
      _lockEvent(lockDuration);
    }

    notifyListeners();

    if (kDebugMode) {
    }
  }

  /// Idle 모드로 복귀
  ///
  /// 상호작용이 종료되어 대기 상태로 돌아갑니다.
  /// 이벤트 잠금은 자동으로 해제되지 않습니다.
  void exitMode() {
    _currentMode = InteractionMode.idle;
    notifyListeners();

    if (kDebugMode) {
    }
  }

  /// 이벤트 잠금
  ///
  /// 지정된 기간 동안 모든 이벤트를 차단합니다.
  /// 기존 잠금이 있으면 취소하고 새로 설정합니다.
  void _lockEvent(Duration duration) {
    _isEventLocked = true;
    _lockTimer?.cancel();

    _lockTimer = Timer(duration, () {
      _isEventLocked = false;
      notifyListeners();

      if (kDebugMode) {
      }
    });

    if (kDebugMode) {
    }
  }

  /// 이벤트 처리 가능 여부 확인
  ///
  /// 현재 모드와 이벤트 잠금 상태를 고려하여
  /// 특정 이벤트를 처리할 수 있는지 확인합니다.
  ///
  /// **Parameters:**
  /// - [eventType]: 확인할 이벤트 타입
  ///
  /// **Returns:**
  /// - `true`: 이벤트 처리 가능
  /// - `false`: 이벤트 차단됨
  ///
  /// **예시:**
  /// ```dart
  /// if (!coordinator.canProcessEvent(EventType.markerClick)) {
  ///   debugPrint('마커 클릭 차단됨');
  ///   return;
  /// }
  /// // 정상 처리
  /// ```
  bool canProcessEvent(EventType eventType) {
    // 이벤트 잠금 중이면 모든 이벤트 차단
    if (_isEventLocked) {
      if (kDebugMode) {
      }
      return false;
    }

    // 현재 모드에서 허용되는 이벤트인지 확인
    final allowed = _allowedEvents[_currentMode]?.contains(eventType) ?? false;

    if (!allowed && kDebugMode) {
    }

    return allowed;
  }

  /// 현재 상태 디버그 출력
  ///
  /// 개발 환경에서만 동작합니다.
  void debugPrintState() {
    if (kDebugMode) {
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}
