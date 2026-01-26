import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/notice.dart';
import '../models/faq.dart';
import '../models/inquiry.dart';
import '../models/pagination.dart';
import 'api_client.dart';
import 'token_service.dart';

/// 고객센터 관련 API 서비스
class SupportService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // 공지사항 (Notice) API
  // ============================================================

  /// 공지사항 목록 조회
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 개수 (기본값: 10)
  /// [search] 제목/내용 검색어
  Future<({List<Notice> items, Pagination pagination})?> getNotices({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(ApiConfig.noticesUrl).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getNotices 실패: ${json['message']}');
        return null;
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return (items: <Notice>[], pagination: Pagination.empty());
      }

      // API 응답: data.notices (백엔드 명세)
      final itemsList = (data['notices'] ?? data['items']) as List?;
      final items = itemsList != null
          ? itemsList
              .map((e) => Notice.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Notice>[];

      final paginationData = data['pagination'] as Map<String, dynamic>?;
      final pagination = paginationData != null
          ? Pagination.fromJson(paginationData)
          : Pagination.empty();

      return (items: items, pagination: pagination);
    } catch (e) {
      debugPrint('❌ [SupportService] getNotices 에러: $e');
      return null;
    }
  }

  /// 공지사항 상세 조회
  Future<Notice?> getNoticeDetail(int noticeId) async {
    try {
      final uri = Uri.parse(ApiConfig.noticeDetailUrl(noticeId));
      final response = await _apiClient.get(uri);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getNoticeDetail 실패: ${json['message']}');
        return null;
      }

      return Notice.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [SupportService] getNoticeDetail 에러: $e');
      return null;
    }
  }

  // ============================================================
  // FAQ API
  // ============================================================

  /// FAQ 카테고리 목록 조회
  /// [userType] 사용자 타입 필터 ('all', 'host', 'guest')
  Future<List<FAQCategory>?> getFAQCategories({String? userType}) async {
    try {
      final queryParams = <String, String>{};
      if (userType != null && userType.isNotEmpty) {
        queryParams['userType'] = userType;
      }

      final uri = Uri.parse(ApiConfig.faqCategoriesUrl)
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await _apiClient.get(uri);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getFAQCategories 실패: ${json['message']}');
        return null;
      }

      final data = json['data'] as List;
      return data
          .map((e) => FAQCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [SupportService] getFAQCategories 에러: $e');
      return null;
    }
  }

  /// FAQ 목록 조회
  /// [categoryId] 카테고리 ID 필터
  /// [search] 질문/답변 검색어
  /// [userType] 사용자 타입 필터
  Future<List<FAQ>?> getFAQs({
    int? categoryId,
    String? search,
    String? userType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (userType != null && userType.isNotEmpty) {
        queryParams['userType'] = userType;
      }

      final uri = Uri.parse(ApiConfig.faqsUrl)
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await _apiClient.get(uri);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getFAQs 실패: ${json['message']}');
        return null;
      }

      final data = json['data'] as List;
      return data
          .map((e) => FAQ.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [SupportService] getFAQs 에러: $e');
      return null;
    }
  }

  /// FAQ 상세 조회 (조회수 증가)
  Future<FAQ?> getFAQDetail(int faqId) async {
    try {
      final uri = Uri.parse(ApiConfig.faqDetailUrl(faqId));
      final response = await _apiClient.get(uri);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getFAQDetail 실패: ${json['message']}');
        return null;
      }

      return FAQ.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [SupportService] getFAQDetail 에러: $e');
      return null;
    }
  }

  // ============================================================
  // 문의하기 (Inquiry) API - 인증 필요
  // ============================================================

  /// 인증 헤더 생성
  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await TokenService.getAccessToken();
    if (token == null) {
      debugPrint('❌ [SupportService] Access Token이 없습니다');
      return null;
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 내 문의 목록 조회
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 개수 (기본값: 10)
  /// [status] 문의 상태 필터 ('pending', 'answered', 'closed')
  /// [categoryType] 카테고리 타입 필터
  /// [userType] 사용자 타입 필터 ('host', 'guest')
  Future<({List<Inquiry> items, Pagination pagination})?> getMyInquiries({
    int page = 1,
    int limit = 10,
    String? status,
    String? categoryType,
    String? userType,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (categoryType != null && categoryType.isNotEmpty) {
        queryParams['categoryType'] = categoryType;
      }
      if (userType != null && userType.isNotEmpty) {
        queryParams['userType'] = userType;
      }

      final uri = Uri.parse(ApiConfig.inquiriesUrl).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri, headers: headers);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getMyInquiries 실패: ${json['message']}');
        return null;
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return (items: <Inquiry>[], pagination: Pagination.empty());
      }

      // API 응답: data.inquiries (백엔드 명세)
      final itemsList = (data['inquiries'] ?? data['items']) as List?;
      final items = itemsList != null
          ? itemsList
              .map((e) => Inquiry.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Inquiry>[];

      final paginationData = data['pagination'] as Map<String, dynamic>?;
      final pagination = paginationData != null
          ? Pagination.fromJson(paginationData)
          : Pagination.empty();

      return (items: items, pagination: pagination);
    } catch (e) {
      debugPrint('❌ [SupportService] getMyInquiries 에러: $e');
      return null;
    }
  }

  /// 내 문의 상세 조회
  Future<Inquiry?> getInquiryDetail(int inquiryId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;

      final uri = Uri.parse(ApiConfig.inquiryDetailUrl(inquiryId));
      final response = await _apiClient.get(uri, headers: headers);

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] getInquiryDetail 실패: ${json['message']}');
        return null;
      }

      return Inquiry.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [SupportService] getInquiryDetail 에러: $e');
      return null;
    }
  }

  /// 문의 등록
  Future<Inquiry?> createInquiry(CreateInquiryRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;

      final uri = Uri.parse(ApiConfig.inquiriesUrl);
      final response = await _apiClient.post(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] createInquiry 실패: ${json['message']}');
        return null;
      }

      return Inquiry.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [SupportService] createInquiry 에러: $e');
      return null;
    }
  }

  /// 문의 수정
  /// 답변 전(status = 'pending')에만 수정 가능
  Future<Inquiry?> updateInquiry(int inquiryId, UpdateInquiryRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;

      final uri = Uri.parse(ApiConfig.inquiryDetailUrl(inquiryId));
      final response = await _apiClient.patch(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response == null) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        debugPrint('❌ [SupportService] updateInquiry 실패: ${json['message']}');
        return null;
      }

      return Inquiry.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [SupportService] updateInquiry 에러: $e');
      return null;
    }
  }

  /// 문의 삭제
  /// 답변 전(status = 'pending')에만 삭제 가능
  Future<bool> deleteInquiry(int inquiryId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return false;

      final uri = Uri.parse(ApiConfig.inquiryDetailUrl(inquiryId));
      final response = await _apiClient.delete(uri, headers: headers);

      if (response == null) return false;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint('❌ [SupportService] deleteInquiry 에러: $e');
      return false;
    }
  }
}
