import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../core/utils/app_logger.dart';
import '../models/move_in/move_in.dart';
import 'token_service.dart';

/// 입주 준비 서비스 — 임대인 API 클라이언트 (17개 엔드포인트)
///
/// 베이스 경로: `/api/host/move-in`
/// 응답 래퍼: `{ success, data, code, message, details? }` (responseHelper.js 표준)
///
/// 에러 시 [MoveInException] throw — 호출부는 try/catch로 받아
/// `errorCode`별로 분기 (409 CONFLICT 모달 등) 가능.
class MoveInService {
  static const String _basePath = '/api/host/move-in';
  static const String _logTag = '[MOVE_IN]';

  // ============================================================
  // 공통 헬퍼
  // ============================================================

  Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final token = await TokenService.getValidAccessToken();
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath$path');
    return query == null || query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  /// 응답 본문에서 `data` 추출 — 실패 시 [MoveInException] throw
  ///
  /// `expectData=false`면 `{ success: true }` 형태(204 / DELETE 응답)도 정상 처리.
  dynamic _extractData(http.Response response, {bool expectData = true}) {
    final statusCode = response.statusCode;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw MoveInException(
        errorCode: MoveInErrorCode.unknown,
        message: '서버 응답을 해석할 수 없습니다.',
        httpStatus: statusCode,
        details: response.body,
      );
    }

    if (statusCode >= 200 && statusCode < 300 && body['success'] == true) {
      if (!expectData) return null;
      return body['data'];
    }

    AppLogger.e('$_logTag ${response.request?.method} ${response.request?.url} → $statusCode');
    AppLogger.e('$_logTag body: ${response.body}');
    throw MoveInException.fromResponse(httpStatus: statusCode, body: body);
  }

  /// HTTP 호출 + 일관된 예외 변환 래퍼
  Future<T> _call<T>(Future<T> Function() block) async {
    try {
      return await block();
    } on MoveInException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('$_logTag network/parse error: $e');
      AppLogger.e('$_logTag stack: $st');
      throw MoveInException.network(e);
    }
  }

  // ============================================================
  // 1. 간편 방 (Rooms) — 5개
  // ============================================================

  /// GET /rooms — 간편 방 목록 조회
  Future<List<MoveInRoom>> getMoveInRooms() async {
    return _call(() async {
      final response = await http
          .get(_uri('/rooms'), headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      final list = (data is List)
          ? data
          : (data is Map && data['rooms'] is List ? data['rooms'] as List : <dynamic>[]);
      return list.map(MoveInRoom.fromJson).toList();
    });
  }

  /// POST /rooms — 간편 방 등록 (탭 2 — 새 주소로 간편 등록)
  Future<MoveInRoom> createMoveInRoom(MoveInRoomRequest request) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/rooms'),
            headers: await _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeout);
      return MoveInRoom.fromJson(_extractData(response));
    });
  }

  /// GET /rooms/:roomId — 방 정보 단건 조회 (수정 모달 진입)
  Future<MoveInRoom> getMoveInRoom(int roomId) async {
    return _call(() async {
      final response = await http
          .get(_uri('/rooms/$roomId'), headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      return MoveInRoom.fromJson(_extractData(response));
    });
  }

  /// PATCH /rooms/:roomId — 방 정보 수정
  ///
  /// 주의: PRD 12.5 — 수정해도 기존 케이스의 `roomSnapshot`에는 반영되지 않음.
  Future<MoveInRoom> updateMoveInRoom(int roomId, MoveInRoomRequest request) async {
    return _call(() async {
      final response = await http
          .patch(
            _uri('/rooms/$roomId'),
            headers: await _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeout);
      return MoveInRoom.fromJson(_extractData(response));
    });
  }

  /// DELETE /rooms/:roomId — 방 삭제
  ///
  /// 연결된 케이스가 있으면 4230 ROOM_HAS_CONTRACTS throw.
  Future<void> deleteMoveInRoom(int roomId) async {
    return _call(() async {
      final response = await http
          .delete(_uri('/rooms/$roomId'), headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      _extractData(response, expectData: false);
    });
  }

  // ============================================================
  // 2. 케이스 (Cases) — 4개
  // ============================================================

  /// GET /cases — 입주 준비 등록 목록 (홈 화면)
  Future<MoveInCaseListResponse> getMoveInCases({
    int page = 1,
    int limit = 20,
    PaymentRequestStatus? requestStatus,
    CleaningStatus? cleaningStatus,
    String? search,
  }) async {
    return _call(() async {
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (requestStatus != null) query['requestStatus'] = requestStatus.code;
      if (cleaningStatus != null) query['cleaningStatus'] = cleaningStatus.code;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await http
          .get(_uri('/cases', query), headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      return MoveInCaseListResponse.fromJson(_extractData(response));
    });
  }

  /// POST /cases — 입주 준비 등록 생성
  ///
  /// 청소 신청은 별도 호출 ([requestCleaning]) — Q5 결정에 따라
  /// 호출부에서 2단계로 처리하고, 청소 신청 실패 시 토스트 + 상세로 이동.
  Future<MoveInCaseCreateResponse> createMoveInCase(
    MoveInCaseCreateRequest request,
  ) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/cases'),
            headers: await _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeout);
      return MoveInCaseCreateResponse.fromJson(_extractData(response));
    });
  }

  /// GET /cases/:caseId — 케이스 상세
  Future<MoveInCase> getMoveInCase(int caseId) async {
    return _call(() async {
      final response = await http
          .get(_uri('/cases/$caseId'), headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      return MoveInCase.fromJson(_extractData(response));
    });
  }

  /// PATCH /cases/:caseId — 케이스 정보 수정
  ///
  /// `guestPhone` 변경 시 백엔드가 토큰 자동 재발급 + paymentRequest.status를 NOT_SENT로 초기화.
  Future<MoveInCase> updateMoveInCase(
    int caseId,
    MoveInCaseUpdateRequest request,
  ) async {
    return _call(() async {
      final response = await http
          .patch(
            _uri('/cases/$caseId'),
            headers: await _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeout);
      return MoveInCase.fromJson(_extractData(response));
    });
  }

  // ============================================================
  // 3. 청소 (Cleaning) — 5개
  // ============================================================

  /// POST /cases/:caseId/cleaning/quote — 청소비 견적 미리보기
  Future<CleaningQuoteResponse> getCleaningQuote(int caseId) async {
    return _call(() async {
      final response = await http
          .post(_uri('/cases/$caseId/cleaning/quote'), headers: await _headers())
          .timeout(ApiConfig.timeout);
      return CleaningQuoteResponse.fromJson(_extractData(response));
    });
  }

  /// POST /cases/:caseId/cleaning/request — 청소 신청 (cleaningFee 락인)
  ///
  /// [body.cleaningRequestedDate] (Q2) — 이미지 ② 폼의 청소 희망일.
  Future<MoveInCase> requestCleaning(int caseId, {CleaningRequestBody? body}) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/cases/$caseId/cleaning/request'),
            headers: await _headers(),
            body: jsonEncode(body?.toJson() ?? <String, dynamic>{}),
          )
          .timeout(ApiConfig.timeout);
      return MoveInCase.fromJson(_extractData(response));
    });
  }

  /// DELETE /cases/:caseId/cleaning/request — 청소 신청 취소
  ///
  /// PAYMENT_PENDING 상태에서만 가능. PAID는 취소 불가.
  /// 백엔드는 부분 응답({caseId, cleaningStatus})만 반환 — provider 에서 별도 재조회 필요.
  Future<MoveInCase> cancelCleaningRequest(int caseId) async {
    return _call(() async {
      final response = await http
          .delete(
            _uri('/cases/$caseId/cleaning/request'),
            headers: await _headers(jsonBody: false),
          )
          .timeout(ApiConfig.timeout);
      return MoveInCase.fromJson(_extractData(response));
    });
  }

  /// POST /cases/:caseId/cleaning/payment/init — PG 결제 시작
  Future<CleaningPaymentInitResponse> initCleaningPayment(int caseId) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/cases/$caseId/cleaning/payment/init'),
            headers: await _headers(),
          )
          .timeout(ApiConfig.timeout);
      return CleaningPaymentInitResponse.fromJson(_extractData(response));
    });
  }

  /// POST /cases/:caseId/cleaning/payment/confirm — PG 콜백 후 서버 승인
  Future<CleaningPaymentConfirmResponse> confirmCleaningPayment(
    int caseId,
    CleaningPaymentConfirmRequest request,
  ) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/cases/$caseId/cleaning/payment/confirm'),
            headers: await _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeout);
      return CleaningPaymentConfirmResponse.fromJson(_extractData(response));
    });
  }

  // ============================================================
  // 4. 임차인 결제 요청 (Payment Request) — 3개
  // ============================================================

  /// POST /cases/:caseId/payment-request/send — 결제 요청 보내기
  ///
  /// 이미 발송된 케이스에는 400 에러. UI에서 `paymentRequest.status === NOT_SENT`일 때만 호출.
  Future<PaymentRequestSendResponse> sendPaymentRequest(int caseId) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/cases/$caseId/payment-request/send'),
            headers: await _headers(),
          )
          .timeout(ApiConfig.timeout);
      return PaymentRequestSendResponse.fromJson(_extractData(response));
    });
  }

  /// POST /cases/:caseId/payment-request/resend — 다시 보내기 (resendCount++)
  Future<PaymentRequestSendResponse> resendPaymentRequest(int caseId) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/cases/$caseId/payment-request/resend'),
            headers: await _headers(),
          )
          .timeout(ApiConfig.timeout);
      return PaymentRequestSendResponse.fromJson(_extractData(response));
    });
  }

  /// GET /cases/:caseId/payment-request/link — 임차인 결제 링크 조회 (클립보드 복사용)
  Future<PaymentRequestSendResponse> getPaymentRequestLink(int caseId) async {
    return _call(() async {
      final response = await http
          .get(
            _uri('/cases/$caseId/payment-request/link'),
            headers: await _headers(jsonBody: false),
          )
          .timeout(ApiConfig.timeout);
      return PaymentRequestSendResponse.fromJson(_extractData(response));
    });
  }
}
