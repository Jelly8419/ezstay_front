import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 이벤트 로깅 서비스
///
/// PRD에 명세된 4가지 주요 이벤트를 관리합니다:
/// - home_view_guest: 게스트 홈 화면 진입
/// - home_view_host: 호스트 홈 화면 진입
/// - home_select_period: 날짜 선택 완료
/// - home_go_map: 지도 검색 클릭
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  /// 게스트 홈 화면 진입 이벤트
  ///
  /// 게스트 모드로 홈 화면에 접속했을 때 호출됩니다.
  Future<void> logHomeViewGuest() async {
    try {
      await analytics.logEvent(
        name: 'home_view_guest',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [Analytics] home_view_guest 이벤트 기록');
    } catch (e) {
      debugPrint('❌ [Analytics] home_view_guest 이벤트 기록 실패: $e');
    }
  }

  /// 호스트 홈 화면 진입 이벤트
  ///
  /// 호스트 모드로 홈 화면에 접속했을 때 호출됩니다.
  Future<void> logHomeViewHost() async {
    try {
      await analytics.logEvent(
        name: 'home_view_host',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [Analytics] home_view_host 이벤트 기록');
    } catch (e) {
      debugPrint('❌ [Analytics] home_view_host 이벤트 기록 실패: $e');
    }
  }

  /// 날짜 선택 완료 이벤트
  ///
  /// 사용자가 체크인/체크아웃 날짜를 선택했을 때 호출됩니다.
  ///
  /// [checkInDate] 체크인 날짜
  /// [checkOutDate] 체크아웃 날짜
  /// [numberOfDays] 선택한 기간 (일 수)
  Future<void> logHomeSelectPeriod({
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      final numberOfDays = checkOutDate.difference(checkInDate).inDays;

      await analytics.logEvent(
        name: 'home_select_period',
        parameters: {
          'check_in_date': checkInDate.toIso8601String(),
          'check_out_date': checkOutDate.toIso8601String(),
          'number_of_days': numberOfDays,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [Analytics] home_select_period 이벤트 기록: ${numberOfDays}일');
    } catch (e) {
      debugPrint('❌ [Analytics] home_select_period 이벤트 기록 실패: $e');
    }
  }

  /// 지도 검색 클릭 이벤트
  ///
  /// 사용자가 "지도에서 검색" 버튼을 클릭했을 때 호출됩니다.
  ///
  /// [hasDateSelected] 날짜 선택 여부 (true: 날짜 선택 후 검색, false: 날짜 없이 검색)
  Future<void> logHomeGoMap({bool hasDateSelected = false}) async {
    try {
      await analytics.logEvent(
        name: 'home_go_map',
        parameters: {
          'has_date_selected': hasDateSelected,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [Analytics] home_go_map 이벤트 기록 (날짜 선택: $hasDateSelected)');
    } catch (e) {
      debugPrint('❌ [Analytics] home_go_map 이벤트 기록 실패: $e');
    }
  }

  /// 화면 조회 이벤트 (Firebase Analytics 기본)
  ///
  /// 특정 화면에 진입했을 때 자동으로 기록됩니다.
  ///
  /// [screenName] 화면 이름
  /// [screenClass] 화면 클래스명 (optional)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('📊 [Analytics] 화면 조회: $screenName');
    } catch (e) {
      debugPrint('❌ [Analytics] 화면 조회 기록 실패: $e');
    }
  }
}
