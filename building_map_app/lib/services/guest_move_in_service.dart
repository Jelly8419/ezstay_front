import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../core/utils/app_logger.dart';
import '../models/guest_move_in/guest_move_in.dart';
import 'token_service.dart';

/// 입주 준비 서비스 — 임차인(게스트) API 클라이언트 (10개 엔드포인트)
///
/// 베이스 경로: `/api/guest/move-in`
/// 응답 래퍼: `{ success, data, code, message, details? }` (responseHelper.js 표준)
///
/// 인증:
/// - `getInvite(token)` 만 optionalAuth (비로그인 OK)
/// - 그 외 모든 엔드포인트는 게스트 JWT 필수
///
/// 에러 시 [GuestMoveInException] throw.
class GuestMoveInService {
  static const String _basePath = '/api/guest/move-in';
  static const String _logTag = '[GUEST_MOVE_IN]';

  // ============================================================
  // 공통 헬퍼
  // ============================================================

  Future<Map<String, String>> _headers({
    bool jsonBody = true,
    bool requireAuth = true,
  }) async {
    final token =
        requireAuth ? await TokenService.getValidAccessToken() : null;
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// optionalAuth 헤더 — 토큰이 있으면 첨부, 없으면 비로그인
  Future<Map<String, String>> _optionalAuthHeaders({bool jsonBody = false}) async {
    final token = await TokenService.getValidAccessToken();
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  dynamic _extractData(http.Response response, {bool expectData = true}) {
    final statusCode = response.statusCode;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GuestMoveInException(
        errorCode: GuestMoveInErrorCode.unknown,
        message: '서버 응답을 해석할 수 없습니다.',
        httpStatus: statusCode,
        details: response.body,
      );
    }

    if (statusCode >= 200 && statusCode < 300 && body['success'] == true) {
      if (!expectData) return null;
      return body['data'];
    }

    AppLogger.e(
        '$_logTag ${response.request?.method} ${response.request?.url} → $statusCode');
    AppLogger.e('$_logTag body: ${response.body}');
    throw GuestMoveInException.fromResponse(
        httpStatus: statusCode, body: body);
  }

  Future<T> _call<T>(Future<T> Function() block) async {
    try {
      return await block();
    } on GuestMoveInException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('$_logTag network/parse error: $e');
      AppLogger.e('$_logTag stack: $st');
      throw GuestMoveInException.network(e);
    }
  }

  // ============================================================
  // 1. 비로그인 진입 / Bind
  // ============================================================

  /// GET /invite/:token — 비로그인 미리보기 (optionalAuth)
  Future<GuestMoveInInvitePreview> getInvite(String token) async {
    return _call(() async {
      final response = await http
          .get(_uri('/invite/$token'), headers: await _optionalAuthHeaders())
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestMoveInInvitePreview.fromJson(data);
    });
  }

  /// POST /invite/:token/bind — 계정 연결 (auth 필수, idempotent)
  Future<BindResult> bindInvite(String token) async {
    return _call(() async {
      final response = await http
          .post(
            _uri('/invite/$token/bind'),
            headers: await _headers(),
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return BindResult.fromJson(data);
    });
  }

  // ============================================================
  // 2. 본인 요청 조회
  // ============================================================

  /// GET /requests — 내 요청 목록
  Future<GuestMoveInRequestList> getMyRequests({
    GuestMoveInStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    return _call(() async {
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status.code,
      };
      final response = await http
          .get(_uri('/requests', query),
              headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestMoveInRequestList.fromJson(data);
    });
  }

  /// GET /requests/:caseId — 상세 (옵션 + 본인 주문 통합)
  Future<GuestMoveInRequestDetail> getRequestDetail(int caseId) async {
    return _call(() async {
      final response = await http
          .get(_uri('/requests/$caseId'),
              headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestMoveInRequestDetail.fromJson(data);
    });
  }

  /// GET /requests/:caseId/options — 결제 컨텍스트 (가벼운 응답)
  Future<GuestMoveInOptionsResponse> getRequestOptions(int caseId) async {
    return _call(() async {
      final response = await http
          .get(_uri('/requests/$caseId/options'),
              headers: await _headers(jsonBody: false))
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestMoveInOptionsResponse.fromJson(data);
    });
  }

  // ============================================================
  // 3. INITIAL 결제
  // ============================================================

  /// POST /requests/:caseId/payment/init — INITIAL 주문 생성 + PG 페이로드
  Future<GuestPaymentInitResponse> initPayment(
    int caseId,
    List<GuestSelectedItem> items,
  ) async {
    return _call(() async {
      final body = jsonEncode({
        'items': items.map((e) => e.toJson()).toList(),
      });
      final response = await http
          .post(
            _uri('/requests/$caseId/payment/init'),
            headers: await _headers(),
            body: body,
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestPaymentInitResponse.fromJson(data);
    });
  }

  /// POST /requests/:caseId/payment/confirm — 결제 승인
  Future<GuestPaymentConfirmResponse> confirmPayment(
    int caseId, {
    required int paymentId,
    String? recvPayparam,
    String? payType,
    bool? simulateFailure,
  }) async {
    return _call(() async {
      final body = jsonEncode({
        'paymentId': paymentId,
        if (recvPayparam != null) 'recvPayparam': recvPayparam,
        if (payType != null) 'payType': payType,
        if (simulateFailure == true) 'simulateFailure': true,
      });
      final response = await http
          .post(
            _uri('/requests/$caseId/payment/confirm'),
            headers: await _headers(),
            body: body,
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestPaymentConfirmResponse.fromJson(data);
    });
  }

  // ============================================================
  // 4. ADDITIONAL 결제
  // ============================================================

  /// POST /requests/:caseId/additional/init — ADDITIONAL 주문 생성
  Future<GuestPaymentInitResponse> initAdditional(
    int caseId,
    List<GuestSelectedItem> items,
  ) async {
    return _call(() async {
      final body = jsonEncode({
        'items': items.map((e) => e.toJson()).toList(),
      });
      final response = await http
          .post(
            _uri('/requests/$caseId/additional/init'),
            headers: await _headers(),
            body: body,
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestPaymentInitResponse.fromJson(data);
    });
  }

  /// POST /requests/:caseId/additional/confirm — 추가 결제 승인
  Future<GuestPaymentConfirmResponse> confirmAdditional(
    int caseId, {
    required int paymentId,
    String? recvPayparam,
    String? payType,
    bool? simulateFailure,
  }) async {
    return _call(() async {
      final body = jsonEncode({
        'paymentId': paymentId,
        if (recvPayparam != null) 'recvPayparam': recvPayparam,
        if (payType != null) 'payType': payType,
        if (simulateFailure == true) 'simulateFailure': true,
      });
      final response = await http
          .post(
            _uri('/requests/$caseId/additional/confirm'),
            headers: await _headers(),
            body: body,
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestPaymentConfirmResponse.fromJson(data);
    });
  }

  // ============================================================
  // 5. 미결제 주문 취소
  // ============================================================

  /// DELETE /orders/:orderId — PENDING 주문 취소 (orderId는 DB id, 정수)
  Future<GuestOrderCancelResponse> cancelOrder(int orderDbId) async {
    return _call(() async {
      final response = await http
          .delete(
            _uri('/orders/$orderDbId'),
            headers: await _headers(jsonBody: false),
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestOrderCancelResponse.fromJson(data);
    });
  }

  // ============================================================
  // 5-1. 환불 / 반품 (결제 완료 주문)
  // ============================================================

  /// POST /orders/:orderDbId/cancel — 옵션 취소 (즉시 환불)
  ///
  /// 결제완료~D-5 전액 / D-5~입주일 배송 전만 / 입주 후 불가 (서버 최종 판정).
  Future<GuestOrderRefundResponse> cancelPaidOrder(
    int orderDbId, {
    String? reason,
  }) async {
    return _call(() async {
      final body = jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      final response = await http
          .post(
            _uri('/orders/$orderDbId/cancel'),
            headers: await _headers(),
            body: body,
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestOrderRefundResponse.fromJson(data);
    });
  }

  /// POST /orders/:orderDbId/return — 반품 요청 (관리자 승인 대상)
  ///
  /// 입주일~퇴실일 + deliveryStatus=DELIVERED 만. 케이스당 PENDING 반품 1건 제한.
  Future<GuestReturnRequestResponse> requestReturn(
    int orderDbId, {
    String? reason,
  }) async {
    return _call(() async {
      final body = jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      final response = await http
          .post(
            _uri('/orders/$orderDbId/return'),
            headers: await _headers(),
            body: body,
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestReturnRequestResponse.fromJson(data);
    });
  }

  // ============================================================
  // 6. 결제 결과 조회
  // ============================================================

  /// GET /payments/:paymentId — 결제 결과 통합 (결제 완료 화면용)
  Future<GuestPaymentResult> getPaymentResult(int paymentId) async {
    return _call(() async {
      final response = await http
          .get(
            _uri('/payments/$paymentId'),
            headers: await _headers(jsonBody: false),
          )
          .timeout(ApiConfig.timeout);
      final data = _extractData(response);
      return GuestPaymentResult.fromJson(data);
    });
  }
}
