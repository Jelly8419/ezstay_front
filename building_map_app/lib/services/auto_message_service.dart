import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/auto_message_template.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../config/api_config.dart';

/// 자동 메시지 서비스 (호스트 전용)
/// 백엔드 API와 연동하여 자동 메시지 템플릿을 관리합니다.
class AutoMessageService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AutoMessageTemplate> _templates = [];
  List<PropertyInfo> _properties = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AutoMessageTemplate> get templates => _templates;
  List<PropertyInfo> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Authorization 헤더 생성
  Future<Map<String, String>> _getAuthHeaders() async {
    final accessToken =
        await TokenService.getValidAccessToken(autoRefresh: true);
    if (accessToken == null) {
      throw Exception('액세스 토큰이 없습니다. 먼저 로그인하세요.');
    }
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  // ============================================
  // 자동 메시지 템플릿 CRUD
  // ============================================

  /// 템플릿 목록 조회
  Future<List<AutoMessageTemplate>> getAutoMessages() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('📋 [AUTO_MSG] 자동 메시지 목록 조회 시작');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/auto-messages');
      final response = await _apiClient.get(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '자동 메시지 목록 조회 실패');
      }

      final List<dynamic> templatesJson = data['data']['templates'] ?? [];
      _templates =
          templatesJson.map((json) => AutoMessageTemplate.fromJson(json)).toList();

      debugPrint('✅ [AUTO_MSG] 자동 메시지 ${_templates.length}개 조회 완료');

      _isLoading = false;
      notifyListeners();
      return _templates;
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 자동 메시지 목록 조회 실패: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 템플릿 상세 조회
  Future<AutoMessageTemplate> getAutoMessageDetail(String id) async {
    try {
      debugPrint('📋 [AUTO_MSG] 자동 메시지 상세 조회: $id');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/auto-messages/$id');
      final response = await _apiClient.get(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '자동 메시지 조회 실패');
      }

      final template = AutoMessageTemplate.fromJson(data['data']['template']);
      debugPrint('✅ [AUTO_MSG] 자동 메시지 상세 조회 완료');
      return template;
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 자동 메시지 상세 조회 실패: $e');
      rethrow;
    }
  }

  /// 템플릿 생성
  Future<AutoMessageTemplate> createAutoMessage(AutoMessageTemplate template) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🆕 [AUTO_MSG] 자동 메시지 생성');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/auto-messages');
      final response = await _apiClient.post(
        url,
        headers: headers,
        body: jsonEncode(template.toJson()),
      );

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '자동 메시지 생성 실패');
      }

      final newTemplate = AutoMessageTemplate.fromJson(data['data']['template']);

      // 로컬 목록에 추가
      _templates = [..._templates, newTemplate];

      debugPrint('✅ [AUTO_MSG] 자동 메시지 생성 완료: ${newTemplate.id}');

      _isLoading = false;
      notifyListeners();
      return newTemplate;
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 자동 메시지 생성 실패: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 템플릿 수정
  Future<AutoMessageTemplate> updateAutoMessage(AutoMessageTemplate template) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('✏️ [AUTO_MSG] 자동 메시지 수정: ${template.id}');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/auto-messages/${template.id}');
      final response = await _apiClient.patch(
        url,
        headers: headers,
        body: jsonEncode(template.toJson()),
      );

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '자동 메시지 수정 실패');
      }

      final updatedTemplate = AutoMessageTemplate.fromJson(data['data']['template']);

      // 로컬 목록 업데이트
      _templates = _templates.map((t) {
        if (t.id == updatedTemplate.id) {
          return updatedTemplate;
        }
        return t;
      }).toList();

      debugPrint('✅ [AUTO_MSG] 자동 메시지 수정 완료');

      _isLoading = false;
      notifyListeners();
      return updatedTemplate;
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 자동 메시지 수정 실패: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 템플릿 삭제
  Future<void> deleteAutoMessage(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🗑️ [AUTO_MSG] 자동 메시지 삭제: $id');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/auto-messages/$id');
      final response = await _apiClient.delete(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '자동 메시지 삭제 실패');
      }

      // 로컬 목록에서 제거
      _templates = _templates.where((t) => t.id != id).toList();

      debugPrint('✅ [AUTO_MSG] 자동 메시지 삭제 완료');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 자동 메시지 삭제 실패: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 템플릿 활성화 토글
  Future<void> toggleAutoMessage(String id) async {
    try {
      debugPrint('🔄 [AUTO_MSG] 자동 메시지 토글: $id');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/auto-messages/$id/toggle');
      final response = await _apiClient.patch(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '자동 메시지 토글 실패');
      }

      // 로컬 목록 업데이트
      _templates = _templates.map((t) {
        if (t.id == id) {
          return t.copyWith(isActive: !t.isActive);
        }
        return t;
      }).toList();

      debugPrint('✅ [AUTO_MSG] 자동 메시지 토글 완료');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 자동 메시지 토글 실패: $e');
      rethrow;
    }
  }

  // ============================================
  // 방 목록 조회 (자동 메시지 적용 대상)
  // ============================================

  /// 호스트의 방 목록 조회
  Future<List<PropertyInfo>> getHostProperties() async {
    try {
      debugPrint('📋 [AUTO_MSG] 호스트 방 목록 조회');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms');
      final response = await _apiClient.get(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '방 목록 조회 실패');
      }

      final List<dynamic> roomsJson = data['data']['rooms'] ?? [];
      _properties = roomsJson.map((json) => PropertyInfo.fromJson(json)).toList();

      debugPrint('✅ [AUTO_MSG] 방 ${_properties.length}개 조회 완료');
      notifyListeners();
      return _properties;
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 방 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 특정 방의 자동 메시지 목록 조회
  Future<List<AutoMessageTemplate>> getAutoMessagesForRoom(String roomId) async {
    try {
      debugPrint('📋 [AUTO_MSG] 방별 자동 메시지 조회: $roomId');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/auto-messages');
      final response = await _apiClient.get(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '방별 자동 메시지 조회 실패');
      }

      final List<dynamic> templatesJson = data['data']['autoMessages'] ?? [];
      final templates =
          templatesJson.map((json) => AutoMessageTemplate.fromJson(json)).toList();

      debugPrint('✅ [AUTO_MSG] 방별 자동 메시지 ${templates.length}개 조회 완료');
      return templates;
    } catch (e) {
      debugPrint('❌ [AUTO_MSG] 방별 자동 메시지 조회 실패: $e');
      rethrow;
    }
  }

  /// 캐시 초기화
  void clearCache() {
    _templates = [];
    _properties = [];
    _error = null;
    notifyListeners();
  }
}
