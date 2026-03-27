import 'package:building_map_app/core/utils/app_logger.dart';
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
        AppLogger.e('❌ [NotificationService] 토큰 없음');
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
        AppLogger.e('❌ [NotificationService] 응답 없음');
        return const NotificationListResponse(
          notifications: [],
          pagination: NotificationPagination(),
        );
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final result = NotificationListResponse.fromJson(jsonData);

        return result;
      }

      AppLogger.e('❌ [NotificationService] 조회 실패: ${response.statusCode}');
      return const NotificationListResponse(
        notifications: [],
        pagination: NotificationPagination(),
      );
    } catch (e) {
      AppLogger.e('❌ [NotificationService] 에러: $e');
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
        AppLogger.e('❌ [NotificationService] 토큰 없음');
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
        return true;
      }

      AppLogger.e('❌ [NotificationService] 읽음 처리 실패: ${response?.statusCode}');
      return false;
    } catch (e) {
      AppLogger.e('❌ [NotificationService] 읽음 처리 에러: $e');
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
      AppLogger.e('❌ [NotificationService] 미읽음 개수 조회 에러: $e');
      return const UnreadCountResponse(singleModeCount: 0);
    }
  }

  /// GNB 배지 상태 조회 (알림 미확인 수 + 채팅 미확인 여부 통합)
  /// GET /api/gnb/badge-status?userMode={userMode}
  Future<GnbBadgeStatusResponse> getGnbBadgeStatus({String? userMode}) async {
    try {
      final token = await TokenService.getValidAccessToken();
      if (token == null) return GnbBadgeStatusResponse.empty;

      final url = Uri.parse(ApiConfig.gnbBadgeStatusUrl(userMode: userMode));
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
        return GnbBadgeStatusResponse.fromJson(jsonData, userMode: userMode);
      }

      return GnbBadgeStatusResponse.empty;
    } catch (e) {
      AppLogger.e('❌ [NotificationService] GNB 배지 상태 조회 에러: $e');
      return GnbBadgeStatusResponse.empty;
    }
  }
}
