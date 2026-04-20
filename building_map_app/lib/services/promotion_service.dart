import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:building_map_app/core/utils/app_logger.dart';
import '../config/api_config.dart';
import '../models/promotion_event.dart';
import 'token_service.dart';

/// 프로모션 이벤트 조회 서비스
///
/// 가이드: `C:/study/frontend_md_list/프로모션_이벤트_API_가이드.md`
class PromotionService {
  /// GET /api/promotions/active
  ///
  /// - 비로그인 가능 (토큰 없으면 Authorization 헤더 생략, `userStatus` 필드 없음)
  /// - 선착순 마감/만료 이벤트는 서버가 필터링 → 응답에 있으면 노출 OK
  /// - 네트워크/파싱 실패 시 null 반환 (silent fail)
  Future<List<PromotionEvent>?> getActivePromotions() async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      final accessToken =
          await TokenService.getValidAccessToken(autoRefresh: true);
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/promotions/active'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        AppLogger.w(
          '⚠️ [PROMOTION] 실패: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final events = data?['events'] as List<dynamic>?;
      if (events == null) return <PromotionEvent>[];

      return events
          .whereType<Map<String, dynamic>>()
          .map(PromotionEvent.fromJson)
          .toList(growable: false);
    } catch (e) {
      AppLogger.e('❌ [PROMOTION] 에러: $e');
      return null;
    }
  }
}
