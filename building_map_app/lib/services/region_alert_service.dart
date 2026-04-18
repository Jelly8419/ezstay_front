import 'dart:convert';
import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class RegionAlertResult {
  final bool alreadyRegistered;
  final DateTime alertedAt;

  const RegionAlertResult({
    required this.alreadyRegistered,
    required this.alertedAt,
  });

  factory RegionAlertResult.fromJson(Map<String, dynamic> json) {
    return RegionAlertResult(
      alreadyRegistered: json['alreadyRegistered'] as bool,
      alertedAt: DateTime.parse(json['alertedAt'] as String),
    );
  }
}

class RegionAlertService {
  /// POST /api/user/region-alert
  /// 201: 신규 신청, 200: 중복 신청(멱등)
  /// 토큰 없음 또는 네트워크 에러 시 null 반환
  Future<RegionAlertResult?> requestAlert() async {
    try {
      final accessToken =
          await TokenService.getValidAccessToken(autoRefresh: true);
      if (accessToken == null || accessToken.isEmpty) {
        AppLogger.w('⚠️ [REGION_ALERT] 토큰 없음');
        return null;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/user/region-alert'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        return RegionAlertResult.fromJson(data);
      } else {
        AppLogger.e('❌ [REGION_ALERT] 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [REGION_ALERT] 에러: $e');
      return null;
    }
  }
}
