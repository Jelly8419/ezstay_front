import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/refund_policy.dart';
import 'api_client.dart';

/// 환불 정책 서비스
class RefundPolicyService {
  final ApiClient _apiClient;
  static List<RefundPolicy>? _cachedPolicies; // 메모리 캐싱

  RefundPolicyService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// 환불 정책 목록 조회 (캐싱 적용)
  Future<List<RefundPolicy>> getRefundPolicies() async {
    // 캐시가 있으면 반환
    if (_cachedPolicies != null && _cachedPolicies!.isNotEmpty) {
      return _cachedPolicies!;
    }

    try {

      final response = await _apiClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/refund-policies'),
      );

      if (response == null) {
        throw Exception('API 응답이 없습니다.');
      }


      if (response.statusCode != 200) {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }

      // JSON 파싱
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      // API 응답 구조: { "success": true, "message": "...", "data": [...] }
      if (jsonData['success'] == true && jsonData['data'] != null) {
        final policiesData = jsonData['data'] as List<dynamic>;
        _cachedPolicies = policiesData
            .map((json) => RefundPolicy.fromJson(json as Map<String, dynamic>))
            .toList();

        return _cachedPolicies!;
      }

      throw Exception('환불 정책 데이터를 불러올 수 없습니다.');
    } catch (e, stackTrace) {
      AppLogger.e('❌ [REFUND_POLICY] Error fetching policies: $e');
      AppLogger.e('❌ [REFUND_POLICY] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 특정 타입의 환불 정책 조회
  ///
  /// [policyType]은 한글("약하게", "보통", "엄격하게") 또는
  /// 영문("flexible", "moderate", "strict") 모두 지원
  Future<RefundPolicy?> getRefundPolicyByType(String policyType) async {
    try {
      final policies = await getRefundPolicies();

      // 한글 타입으로 먼저 검색
      RefundPolicy? policy = policies.firstWhere(
        (p) => p.policyType == policyType,
        orElse: () {
          // 영문 타입으로 변환해서 재검색
          final koreanType = RefundPolicy.toKoreanType(policyType);
          return policies.firstWhere(
            (p) => p.policyType == koreanType,
            orElse: () => throw Exception('환불 정책을 찾을 수 없습니다: $policyType'),
          );
        },
      );

      return policy;
    } catch (e) {
      AppLogger.e('❌ [REFUND_POLICY] Error finding policy by type: $e');
      rethrow;
    }
  }

  /// 캐시 초기화 (필요 시)
  void clearCache() {
    _cachedPolicies = null;
  }

  /// 캐시 상태 확인
  bool get isCached => _cachedPolicies != null && _cachedPolicies!.isNotEmpty;
}
