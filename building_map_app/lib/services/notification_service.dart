import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/notification_item.dart';
import 'api_client.dart';
import 'token_service.dart';

/// 알림 서비스
/// 알림 목록 조회 및 읽음 처리를 담당합니다.
class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// 알림 목록 조회
  /// GET /api/notifications?userMode={userMode}&page={page}&limit={limit}
  Future<NotificationListResponse> getNotifications({
    required String userMode,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await TokenService.getValidAccessToken();
      if (token == null) {
        debugPrint('❌ [NotificationService] 토큰 없음');
        return const NotificationListResponse(
          notifications: [],
          pagination: NotificationPagination(),
        );
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/notifications?userMode=$userMode&page=$page&limit=$limit',
      );
      final response = await _apiClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        showErrorDialog: false,
      );

      if (response == null) {
        debugPrint('❌ [NotificationService] 응답 없음');
        return const NotificationListResponse(
          notifications: [],
          pagination: NotificationPagination(),
        );
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final result = NotificationListResponse.fromJson(jsonData);

        debugPrint('✅ [NotificationService] 알림 ${result.notifications.length}개 조회');
        return result;
      }

      debugPrint('❌ [NotificationService] 조회 실패: ${response.statusCode}');
      return const NotificationListResponse(
        notifications: [],
        pagination: NotificationPagination(),
      );
    } catch (e) {
      debugPrint('❌ [NotificationService] 에러: $e');
      return const NotificationListResponse(
        notifications: [],
        pagination: NotificationPagination(),
      );
    }
  }

  /// 모든 알림 읽음 처리
  /// PATCH /api/notifications/mark-all-read?userMode={userMode}
  Future<bool> markAllAsRead({String? userMode}) async {
    try {
      final token = await TokenService.getValidAccessToken();
      if (token == null) {
        debugPrint('❌ [NotificationService] 토큰 없음');
        return false;
      }

      String urlStr = '${ApiConfig.baseUrl}/api/notifications/mark-all-read';
      if (userMode != null) {
        urlStr += '?userMode=$userMode';
      }

      final url = Uri.parse(urlStr);
      final response = await _apiClient.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        showErrorDialog: false,
      );

      if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ [NotificationService] 전체 읽음 처리 완료');
        return true;
      }

      debugPrint('❌ [NotificationService] 읽음 처리 실패: ${response?.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ [NotificationService] 읽음 처리 에러: $e');
      return false;
    }
  }

  /// 읽지 않은 알림 개수 조회
  /// GET /api/notifications/unread-count?userMode={userMode}
  Future<UnreadCountResponse> getUnreadCount({String? userMode}) async {
    try {
      final token = await TokenService.getValidAccessToken();
      if (token == null) {
        return const UnreadCountResponse(singleModeCount: 0);
      }

      String urlStr = '${ApiConfig.baseUrl}/api/notifications/unread-count';
      if (userMode != null) {
        urlStr += '?userMode=$userMode';
      }

      final url = Uri.parse(urlStr);
      final response = await _apiClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        showErrorDialog: false,
      );

      if (response != null && response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return UnreadCountResponse.fromJson(jsonData);
      }

      return const UnreadCountResponse(singleModeCount: 0);
    } catch (e) {
      debugPrint('❌ [NotificationService] 미읽음 개수 조회 에러: $e');
      return const UnreadCountResponse(singleModeCount: 0);
    }
  }
}
