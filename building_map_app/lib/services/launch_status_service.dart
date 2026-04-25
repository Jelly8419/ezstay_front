import 'dart:convert';
import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 정식 런칭 여부를 백엔드에서 조회하여 전역 상태로 보관.
///
/// - GET /api/system/launch-status (인증 불필요)
/// - 1시간 메모리 캐시 후 stale 처리, 다음 read에서 재조회
/// - 네트워크/파싱 실패 시 isPrelaunch=true (검색 차단 유지) 폴백
class LaunchStatusService extends ChangeNotifier {
  static const Duration _staleAfter = Duration(hours: 1);

  bool _isPrelaunch = true;
  DateTime? _launchedAt;
  DateTime? _fetchedAt;
  Future<void>? _inflight;

  bool get isPrelaunch => _isPrelaunch;
  DateTime? get launchedAt => _launchedAt;

  bool get _isStale {
    final fetched = _fetchedAt;
    if (fetched == null) return true;
    return DateTime.now().difference(fetched) > _staleAfter;
  }

  /// 캐시가 신선하면 noop, 아니면 백엔드 재조회.
  /// 동시 호출은 단일 in-flight Future로 합쳐서 중복 요청 방지.
  Future<void> ensureLoaded() {
    if (!_isStale) return Future.value();
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  Future<void> refresh() {
    _fetchedAt = null;
    return ensureLoaded();
  }

  Future<void> _fetch() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/system/launch-status'),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        AppLogger.w('⚠️ [LAUNCH_STATUS] HTTP ${response.statusCode} → 폴백 유지');
        _markFetched();
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        AppLogger.w('⚠️ [LAUNCH_STATUS] data 없음 → 폴백 유지');
        _markFetched();
        return;
      }

      final next = data['isPrelaunch'] as bool? ?? true;
      final launchedAtStr = data['launchedAt'] as String?;
      final nextLaunchedAt =
          launchedAtStr != null ? DateTime.tryParse(launchedAtStr) : null;

      final changed = next != _isPrelaunch || nextLaunchedAt != _launchedAt;
      _isPrelaunch = next;
      _launchedAt = nextLaunchedAt;
      _markFetched();
      if (changed) notifyListeners();
    } catch (e) {
      AppLogger.e('❌ [LAUNCH_STATUS] 조회 실패: $e (isPrelaunch=true 폴백 유지)');
      _markFetched();
    }
  }

  void _markFetched() {
    _fetchedAt = DateTime.now();
  }
}
