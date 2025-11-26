import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/contract.dart';
import 'token_service.dart';

/// 계약 요청 및 관리 서비스
class ContractService {
  ContractService();

  /// 계약 승인 요청
  Future<Map<String, dynamic>> requestContract({
    required int roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int totalDays,
    required int totalWeeks,
    required int rentalFee,
    required int maintenanceFee,
    required int cleaningFee,
    required int platformFee,
    required int discountAmount,
    required int subtotal,
    required int totalUsageFee,
    required int deposit,
    required int finalTotalAmount,
    int rentalItemsFee = 0,
    List<Map<String, dynamic>>? rentalItems,
    String? guestMessage,
    String? discountCode,
    String? discountType,
    String? paymentMethod,
    int? installmentMonths,
    required bool serviceTermsAgreed,
    required bool cancellationPolicyAgreed,
    required bool refundPolicyAgreed,
    bool? earlyCheckIn,
    bool? lateCheckOut,
    bool? petAccompanying,
    String? additionalNotes,
    required double dailyRentalFee,
    required double dailyMaintenanceFee,
    required double platformFeeRate,
    required double depositRate,
  }) async {
    // 유효한 토큰 가져오기 (자동 갱신 포함)
    final token = await TokenService.getValidAccessToken(autoRefresh: true);

    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final body = {
      // 필수 필드
      'roomId': roomId,
      'checkInDate': checkInDate.toIso8601String().split('T')[0],
      'checkOutDate': checkOutDate.toIso8601String().split('T')[0],
      'totalDays': totalDays,
      'totalWeeks': totalWeeks,

      // 금액 (백엔드에서 재검증)
      'rentalFee': rentalFee,
      'maintenanceFee': maintenanceFee,
      'cleaningFee': cleaningFee,
      'platformFee': platformFee,
      'discountAmount': discountAmount,
      'subtotal': subtotal,
      'totalUsageFee': totalUsageFee,
      'deposit': deposit,
      'finalTotalAmount': finalTotalAmount,

      // 렌탈 아이템 (EZStay 제공)
      if (rentalItemsFee > 0) 'rentalItemsFee': rentalItemsFee,
      if (rentalItems != null && rentalItems.isNotEmpty) 'rentalItems': rentalItems,

      // 메시지
      if (guestMessage != null && guestMessage.isNotEmpty) 'guestMessage': guestMessage,

      // 선택 필드
      if (discountCode != null && discountCode.isNotEmpty) 'discountCode': discountCode,
      if (discountType != null && discountType.isNotEmpty) 'discountType': discountType,
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
      if (installmentMonths != null) 'installmentMonths': installmentMonths,

      // 약관 동의 (필수)
      'termsAgreed': {
        'serviceTerms': serviceTermsAgreed,
        'cancellationPolicy': cancellationPolicyAgreed,
        'refundPolicy': refundPolicyAgreed,
      },

      // 특별 요청
      if (earlyCheckIn != null || lateCheckOut != null || petAccompanying != null || (additionalNotes != null && additionalNotes.isNotEmpty))
        'specialRequests': {
          if (earlyCheckIn != null) 'earlyCheckIn': earlyCheckIn,
          if (lateCheckOut != null) 'lateCheckOut': lateCheckOut,
          if (petAccompanying != null) 'petAccompanying': petAccompanying,
          if (additionalNotes != null && additionalNotes.isNotEmpty) 'additionalNotes': additionalNotes,
        },

      // 가격 스냅샷 (분쟁 대비)
      'pricingSnapshot': {
        'dailyRentalFee': dailyRentalFee,
        'dailyMaintenanceFee': dailyMaintenanceFee,
        'platformFeeRate': platformFeeRate,
        'depositRate': depositRate,
        'snapshotTimestamp': DateTime.now().toIso8601String(),
      },
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/contracts/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? '잘못된 요청입니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 409) {
        throw Exception('이미 예약된 기간입니다.');
      } else {
        throw Exception('계약 승인 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('서버 응답 시간이 초과되었습니다. 다시 시도해주세요.');
      }
      rethrow;
    }
  }

  /// 게스트용 - 내가 요청한 계약 목록 조회
  Future<List<ContractListItem>> getGuestContracts({
    String? status,
  }) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [CONTRACT] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [CONTRACT] 토큰 확보 성공 (${token.length}자)');
      }

      final queryParams = status != null ? '?status=$status' : '';
      final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/guest$queryParams');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_GUEST] 응답 데이터 구조: ${responseData.keys}');
        }

        // 백엔드 응답 구조: { success, message, data: { contracts: [...] } }
        final List<dynamic> contractsList;
        if (responseData['data'] != null && responseData['data']['contracts'] != null) {
          contractsList = responseData['data']['contracts'];
        } else if (responseData['contracts'] != null) {
          contractsList = responseData['contracts'];
        } else if (responseData is List) {
          contractsList = responseData;
        } else {
          throw Exception('예상하지 못한 응답 형식입니다.');
        }

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_GUEST] 계약 개수: ${contractsList.length}');
        }

        // 각 계약 파싱 시도 (하나 실패해도 나머지는 계속 처리)
        final parsedContracts = <ContractListItem>[];
        for (int i = 0; i < contractsList.length; i++) {
          try {
            final contract = ContractListItem.fromJson(contractsList[i]);
            parsedContracts.add(contract);
            if (!ApiConfig.isProduction) {
              debugPrint('✅ [CONTRACT_PARSE] 계약 #${i + 1} 파싱 성공: ID=${contract.id}, status=${contract.status}');
            }
          } catch (e, stackTrace) {
            debugPrint('❌ [CONTRACT_PARSE] 계약 #${i + 1} 파싱 실패: $e');
            debugPrint('📍 [CONTRACT_PARSE] JSON: ${contractsList[i]}');
            debugPrint('📍 [CONTRACT_PARSE] Stack trace: $stackTrace');
            // 파싱 실패한 계약은 건너뛰고 계속 진행
            continue;
          }
        }

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_GUEST] 최종 파싱된 계약 개수: ${parsedContracts.length}/${contractsList.length}');
        }

        return parsedContracts;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약 목록을 불러오는데 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }

  /// 호스트용 - 내게 들어온 계약 요청 목록 조회
  Future<List<ContractListItem>> getHostContracts({
    String? status,
  }) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [CONTRACT] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [CONTRACT] 토큰 확보 성공 (${token.length}자)');
      }

      final queryParams = status != null ? '?status=$status' : '';
      final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/host$queryParams');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_HOST] 응답 데이터 구조: ${responseData.keys}');
        }

        // 백엔드 응답 구조: { success, message, data: { contracts: [...] } }
        final List<dynamic> contractsList;
        if (responseData['data'] != null && responseData['data']['contracts'] != null) {
          contractsList = responseData['data']['contracts'];
        } else if (responseData['contracts'] != null) {
          contractsList = responseData['contracts'];
        } else if (responseData is List) {
          contractsList = responseData;
        } else {
          throw Exception('예상하지 못한 응답 형식입니다.');
        }

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_HOST] 계약 개수: ${contractsList.length}');
        }

        return contractsList.map((json) => ContractListItem.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약 목록을 불러오는데 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }

  /// 계약 상세 조회 (호스트/게스트 모두 사용 가능)
  Future<Contract> getContractDetail(int contractId) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [CONTRACT] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [CONTRACT] 토큰 확보 성공 (${token.length}자)');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_DETAIL] 응답 데이터 구조: ${responseData.keys}');
        }

        // 백엔드 응답 구조: { success, message, data: { contract: {...} } } 또는 { contract: {...} }
        final Map<String, dynamic> contractData;
        if (responseData['data'] != null && responseData['data']['contract'] != null) {
          contractData = Map<String, dynamic>.from(responseData['data']['contract']);
        } else if (responseData['data'] != null && responseData['data'] is Map) {
          contractData = Map<String, dynamic>.from(responseData['data']);
        } else if (responseData['contract'] != null) {
          contractData = Map<String, dynamic>.from(responseData['contract']);
        } else if (responseData is Map && responseData['id'] != null) {
          // 직접 contract 데이터인 경우
          contractData = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception('예상하지 못한 응답 형식입니다.');
        }

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [CONTRACT_DETAIL] 계약 ID: ${contractData['id']}');
        }

        return Contract.fromJson(contractData);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        throw Exception('해당 계약을 볼 수 있는 권한이 없습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('계약을 찾을 수 없습니다.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약 정보를 불러오는데 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }

  /// 계약 승인 (호스트만 가능)
  Future<Map<String, dynamic>> approveContract(int contractId) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [CONTRACT] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/approve');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['data'] ?? responseData;
      } else if (response.statusCode == 400) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약을 승인할 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        throw Exception('계약을 승인할 권한이 없습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('계약을 찾을 수 없습니다.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약 승인에 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }

  /// 계약 거절 (호스트만 가능)
  Future<Map<String, dynamic>> rejectContract(int contractId, String hostMessage) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [CONTRACT] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/reject');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'hostMessage': hostMessage,
        }),
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['data'] ?? responseData;
      } else if (response.statusCode == 400) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약을 거절할 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        throw Exception('계약을 거절할 권한이 없습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('계약을 찾을 수 없습니다.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약 거절에 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }

  /// 계약 철회 (게스트)
  Future<Map<String, dynamic>> withdrawContract(int contractId, String cancellationReason) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [CONTRACT] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/cancel');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cancellationReason': cancellationReason,
        }),
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['data'] ?? responseData;
      } else if (response.statusCode == 400) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약을 철회할 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        throw Exception('계약을 철회할 권한이 없습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('계약을 찾을 수 없습니다.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '계약 철회에 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }

  /// 계약 상태 필터 옵션 (게스트용)
  static List<ContractStatusFilter> getGuestStatusFilters() {
    return [
      ContractStatusFilter('전체', null),
      ContractStatusFilter('승인 대기', 'PENDING_APPROVAL'),
      ContractStatusFilter('승인됨', 'APPROVED'),
      ContractStatusFilter('결제 완료', 'PAYMENT_COMPLETED'),
      ContractStatusFilter('진행중', 'IN_PROGRESS'),
      ContractStatusFilter('완료', 'COMPLETED'),
      ContractStatusFilter('거절됨', 'REJECTED'),
      ContractStatusFilter('취소', 'CANCELLED_BY_GUEST'),
    ];
  }

  /// 계약 상태 필터 옵션 (호스트용)
  static List<ContractStatusFilter> getHostStatusFilters() {
    return [
      ContractStatusFilter('전체', null),
      ContractStatusFilter('승인 대기', 'PENDING_APPROVAL'),
      ContractStatusFilter('승인됨', 'APPROVED'),
      ContractStatusFilter('결제 완료', 'PAYMENT_COMPLETED'),
      ContractStatusFilter('진행중', 'IN_PROGRESS'),
      ContractStatusFilter('완료', 'COMPLETED'),
      ContractStatusFilter('거절됨', 'REJECTED'),
      ContractStatusFilter('취소', 'CANCELLED_BY_HOST'),
    ];
  }

  /// 렌탈 아이템 전체 목록 조회 (완전한 데이터)
  ///
  /// [itemType]: 필터할 아이템 타입 (선택) - hair_dryer, bedding_set, amenity_kit, towel_set, other
  /// [inStock]: 재고 있는 것만 조회 (기본값: true)
  ///
  /// 반환: 렌탈 아이템 목록 (id, itemType, itemTypeLabel, name, description, price, availableStock, imageUrl)
  Future<List<dynamic>?> getAllRentalItems({
    String? itemType,
    bool inStock = true,
  }) async {
    try {
      // 개발 환경에서는 skipExpiryCheck도 시도
      var token = await TokenService.getValidAccessToken(autoRefresh: true);
      if (token == null && !ApiConfig.isProduction) {
        debugPrint('⚠️ [RENTAL_ITEMS] 토큰 갱신 실패, skipExpiryCheck로 재시도');
        token = await TokenService.getAccessToken(skipExpiryCheck: true);
      }

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [RENTAL_ITEMS] 토큰 확보 성공 (${token.length}자)');
      }

      // 쿼리 파라미터 구성
      final queryParams = <String, String>{
        'inStock': inStock.toString(),
      };
      if (itemType != null && itemType.isNotEmpty) {
        queryParams['itemType'] = itemType;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/rental-items').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (!ApiConfig.isProduction) {
          debugPrint('📦 [RENTAL_ITEMS] 응답 데이터 구조: ${responseData.keys}');
        }

        // 백엔드 응답 구조: { success: true, data: [...], message: "..." }
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> itemsList = responseData['data'];

          if (!ApiConfig.isProduction) {
            debugPrint('📦 [RENTAL_ITEMS] 렌탈 아이템 개수: ${itemsList.length}');
          }

          return itemsList;
        } else {
          throw Exception('예상하지 못한 응답 형식입니다.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '렌탈 아이템 목록을 불러오는데 실패했습니다.');
      }
    } on SocketException {
      throw Exception('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw Exception('서버와 통신할 수 없습니다.');
    } on FormatException {
      throw Exception('잘못된 응답 형식입니다.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('요청 시간이 초과되었습니다.');
      }
      rethrow;
    }
  }
}

/// 계약 상태 필터
class ContractStatusFilter {
  final String label;
  final String? value;

  ContractStatusFilter(this.label, this.value);
}
