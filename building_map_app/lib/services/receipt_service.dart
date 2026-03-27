import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'token_service.dart';

/// 영수증 발급 설정 서비스 (호스트 전용)
/// Backend API: /api/host/receipt
class ReceiptService {
  final ApiClient _apiClient = ApiClient();

  /// 영수증 설정 조회
  /// GET /api/host/receipt
  ///
  /// 반환:
  /// - Map<String, dynamic>: 영수증 설정 정보
  /// - null: 미등록 (data: null)
  ///
  /// 예외:
  /// - Exception: 서버 에러 또는 네트워크 에러
  Future<Map<String, dynamic>?> getReceipt() async {
    try {

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/receipt');
      final response = await _apiClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response == null) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // data가 null이면 미등록 상태
          if (data['data'] == null) {
            return null;
          }
          final receiptData = data['data'] as Map<String, dynamic>;
          return receiptData;
        } else {
          AppLogger.w('⚠️ [ReceiptService] 응답 형식 오류: $data');
          throw Exception('영수증 정보를 불러올 수 없습니다.');
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? '영수증 정보 조회 실패';
        AppLogger.e('❌ [ReceiptService] 에러: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('❌ [ReceiptService] 예외 발생: $e');
      rethrow;
    }
  }

  /// 영수증 설정 저장/수정
  /// PUT /api/host/receipt
  ///
  /// Request body:
  /// - type: "personal" | "business" | "tax_invoice"
  /// - number: 번호 (서버에서 숫자만 추출)
  /// - businessName: 사업자명 (tax_invoice일 때 필수)
  /// - repName: 대표자 이름 (tax_invoice일 때 필수)
  /// - email: 이메일 (tax_invoice일 때 선택)
  ///
  /// 반환: Map<String, dynamic> 저장된 영수증 설정 정보
  Future<Map<String, dynamic>> saveReceipt({
    required String type,
    required String number,
    String? businessName,
    String? repName,
    String? email,
  }) async {
    try {

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/receipt');
      final body = <String, dynamic>{
        'type': type,
        'number': number,
      };

      if (type == 'tax_invoice') {
        body['businessName'] = businessName;
        body['repName'] = repName;
        if (email != null && email.isNotEmpty) {
          body['email'] = email;
        }
      }


      final response = await _apiClient.put(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response == null) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final receiptData = data['data'] as Map<String, dynamic>;
          return receiptData;
        } else {
          AppLogger.w('⚠️ [ReceiptService] 응답 형식 오류: $data');
          throw Exception('영수증 정보를 저장할 수 없습니다.');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? '영수증 정보 저장 실패';
        AppLogger.e('❌ [ReceiptService] 에러: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('❌ [ReceiptService] 예외 발생: $e');
      rethrow;
    }
  }

  /// 영수증 설정 삭제
  /// DELETE /api/host/receipt
  ///
  /// 반환: void (성공 시)
  Future<void> deleteReceipt() async {
    try {

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/receipt');
      final response = await _apiClient.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response == null) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception(data['message'] ?? '영수증 설정 삭제 실패');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? '영수증 설정 삭제 실패';
        AppLogger.e('❌ [ReceiptService] 에러: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('❌ [ReceiptService] 예외 발생: $e');
      rethrow;
    }
  }
}
