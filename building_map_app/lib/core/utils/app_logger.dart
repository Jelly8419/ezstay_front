import 'package:flutter/foundation.dart';

/// 앱 전역 로거 유틸리티.
///
/// - Debug 빌드: 콘솔 출력
/// - Release 빌드: 출력 없음 (컴파일러가 kDebugMode 블록 제거)
///
/// 사용법:
///   AppLogger.d('일반 로그');
///   AppLogger.w('경고 로그');
///   AppLogger.e('에러 로그', error: e, stackTrace: st);
class AppLogger {
  AppLogger._();

  /// Debug — 일반 정보 로그
  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Warning — 주의가 필요한 상황
  static void w(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Error — 에러/예외 상황
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint(message);
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  StackTrace: $stackTrace');
    }
  }
}
