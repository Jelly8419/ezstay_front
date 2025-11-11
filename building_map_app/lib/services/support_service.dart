import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/notice.dart';
import '../models/faq.dart';
import '../models/inquiry.dart';
import '../services/token_service.dart';

/// 고객센터 서비스
class SupportService {
  final String baseUrl = ApiConfig.baseUrl;

  // ========== 공지사항 API ==========

  /// 공지사항 목록 조회
  Future<NoticeListResponse> getNotices({
    int page = 1,
    int limit = 10,
    bool? isImportant,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (isImportant != null) 'isImportant': isImportant.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/support/notices')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return NoticeListResponse.fromJson(jsonResponse);
      } else {
        throw HttpException(
          'Failed to load notices: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('공지사항 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('공지사항 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 공지사항 상세 조회
  Future<Notice> getNoticeDetail(int noticeId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/support/notices/$noticeId');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return Notice.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 404) {
        throw Exception('공지사항을 찾을 수 없습니다.');
      } else {
        throw HttpException(
          'Failed to load notice detail: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('공지사항 상세 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('공지사항 상세 조회 중 오류가 발생했습니다: $e');
    }
  }

  // ========== FAQ API ==========

  /// FAQ 카테고리 목록 조회
  Future<List<FAQCategory>> getFAQCategories({
    String userType = 'all',
  }) async {
    try {
      final queryParams = {'userType': userType};

      final uri = Uri.parse('$baseUrl/api/support/faq/categories')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final data = jsonResponse['data'] as List;
        return data
            .map((item) => FAQCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException(
          'Failed to load FAQ categories: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('FAQ 카테고리 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('FAQ 카테고리 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// FAQ 목록 조회
  Future<FAQListResponse> getFAQs({
    int? categoryId,
    String userType = 'all',
    String? searchKeyword,
  }) async {
    try {
      final queryParams = {
        'userType': userType,
        if (categoryId != null) 'categoryId': categoryId.toString(),
        if (searchKeyword != null && searchKeyword.isNotEmpty)
          'searchKeyword': searchKeyword,
      };

      final uri = Uri.parse('$baseUrl/api/support/faqs')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return FAQListResponse.fromJson(jsonResponse);
      } else {
        throw HttpException('Failed to load FAQs: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('FAQ 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('FAQ 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// FAQ 상세 조회
  Future<FAQ> getFAQDetail(int faqId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/support/faqs/$faqId');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return FAQ.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 404) {
        throw Exception('FAQ를 찾을 수 없습니다.');
      } else {
        throw HttpException(
          'Failed to load FAQ detail: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('FAQ 상세 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('FAQ 상세 조회 중 오류가 발생했습니다: $e');
    }
  }

  // ========== 문의하기 API (인증 필요) ==========

  /// 문의 등록
  Future<Inquiry> createInquiry({
    required InquiryCategoryType categoryType,
    required String title,
    required String content,
  }) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('$baseUrl/api/support/inquiries');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'categoryType': categoryType.name,
              'title': title,
              'content': content,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return Inquiry.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw HttpException(
          'Failed to create inquiry: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('문의 등록 실패: ${e.message}');
    } catch (e) {
      throw Exception('문의 등록 중 오류가 발생했습니다: $e');
    }
  }

  /// 내 문의 목록 조회
  Future<InquiryListResponse> getMyInquiries({
    int page = 1,
    int limit = 10,
    InquiryStatus? status,
  }) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status.name,
      };

      final uri = Uri.parse('$baseUrl/api/support/inquiries')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return InquiryListResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw HttpException(
          'Failed to load inquiries: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('문의 목록 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('문의 목록 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 문의 상세 조회
  Future<Inquiry> getInquiryDetail(int inquiryId) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('$baseUrl/api/support/inquiries/$inquiryId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return Inquiry.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        throw Exception('본인의 문의만 조회할 수 있습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('문의를 찾을 수 없습니다.');
      } else {
        throw HttpException(
          'Failed to load inquiry detail: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException catch (e) {
      throw Exception('문의 상세 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('문의 상세 조회 중 오류가 발생했습니다: $e');
    }
  }
}
