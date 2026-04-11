import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

/// 렌탈 주문 서비스 (옵션 상품 추가/변경/취소)
class RentalOrderService {
  RentalOrderService();

  // ========== 1. 렌탈 주문 목록 조회 ==========

  /// 계약의 렌탈 주문 목록 조회
  ///
  /// GET /api/contracts/:contractId/rental-orders
  Future<RentalOrderSummaryResponse> getRentalOrders(int contractId) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/rental-orders',
    );

    final response = await http
        .get(url, headers: _buildHeaders(token))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true && responseData['data'] != null) {
        return RentalOrderSummaryResponse.fromJson(responseData['data']);
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('렌탈 주문 목록을 불러오는데 실패했습니다.');
  }

  // ========== 2. 이용 가능한 렌탈 아이템 조회 ==========

  /// 계약에서 추가 가능한 렌탈 아이템 목록 조회
  ///
  /// GET /api/contracts/:contractId/available-rental-items
  Future<AvailableRentalItemsResult> getAvailableRentalItems(
    int contractId,
  ) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/available-rental-items',
    );

    final response = await http
        .get(url, headers: _buildHeaders(token))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        final List<dynamic> rawItems;
        bool hasPendingDelivery = false;
        if (data is List) {
          rawItems = data;
        } else if (data is Map) {
          hasPendingDelivery = data['hasPendingDelivery'] == true;
          rawItems = (data['items'] as List<dynamic>?) ?? [];
        } else {
          throw Exception('예상하지 못한 응답 형식입니다.');
        }
        return AvailableRentalItemsResult(
          items: rawItems.map((e) => AvailableRentalItem.fromJson(e)).toList(),
          hasPendingDelivery: hasPendingDelivery,
        );
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('이용 가능한 렌탈 아이템을 불러오는데 실패했습니다.');
  }

  // ========== 3. 승인대기 상태 렌탈 아이템 업데이트 (장바구니) ==========

  /// 승인대기 상태에서 렌탈 아이템 업데이트 (결제 없이 JSON만 업데이트)
  ///
  /// PATCH /api/contracts/:contractId/rental-items
  Future<void> updatePendingRentalItems({
    required int contractId,
    required List<RentalOrderItem> items,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/rental-items',
    );

    final body = {
      'rentalItems': items.map((e) => e.toJson()).toList(),
    };

    final response = await http
        .patch(
          url,
          headers: _buildHeaders(token),
          body: json.encode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true) {
        return;
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('렌탈 아이템 업데이트에 실패했습니다.');
  }

  // ========== 4. 추가 렌탈 주문 생성 ==========

  /// 추가 렌탈 주문 생성 (승인 후 상태에서만 사용)
  ///
  /// POST /api/contracts/:contractId/rental-orders
  Future<RentalOrderResponse> createRentalOrder({
    required int contractId,
    required List<RentalOrderItem> items,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/rental-orders',
    );

    final body = {
      'items': items.map((e) => e.toJson()).toList(),
    };

    final response = await http
        .post(
          url,
          headers: _buildHeaders(token),
          body: json.encode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true && responseData['data'] != null) {
        return RentalOrderResponse.fromJson(responseData['data']);
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('렌탈 주문 생성에 실패했습니다.');
  }

  // ========== 5. 결제 정보 조회 ==========

  /// 렌탈 주문 결제 정보 조회 (PayTag 연동)
  ///
  /// GET /api/rental-orders/:rentalOrderId/payment-info
  Future<Map<String, dynamic>> getPaymentInfo(int rentalOrderId) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/rental-orders/$rentalOrderId/payment-info',
    );

    final response = await http
        .get(url, headers: _buildHeaders(token))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true && responseData['data'] != null) {
        return responseData['data'] as Map<String, dynamic>;
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('결제 정보를 불러오는데 실패했습니다.');
  }

  // ========== 6. 결제 승인 ==========

  /// 렌탈 주문 결제 승인
  ///
  /// POST /api/rental-orders/:rentalOrderId/confirm-payment
  Future<Map<String, dynamic>> confirmPayment({
    required int rentalOrderId,
    required String recvPayparam,
    required String orderId,
    required int amount,
    String? payType,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/rental-orders/$rentalOrderId/confirm-payment',
    );

    final body = {
      'recvPayparam': recvPayparam,
      'orderId': orderId,
      'amount': amount,
      if (payType != null) 'payType': payType,
    };

    final response = await http
        .post(
          url,
          headers: _buildHeaders(token),
          body: json.encode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true) {
        return responseData['data'] ?? {};
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('결제 승인에 실패했습니다.');
  }

  // ========== 7. 결제취소 (아이템 단위 즉시환불) ==========

  /// 배송전 아이템을 선택해 즉시 PG 환불 처리
  ///
  /// POST /api/contracts/:contractId/rental-items/cancel
  /// [items] 취소할 아이템 목록. cancelQuantity 가 item.quantity 미만이면 부분 취소.
  Future<RentalItemCancelResponse> cancelRentalItems({
    required int contractId,
    required List<RentalItemCancelRequest> items,
    String reason = '',
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/rental-items/cancel',
    );

    final body = {
      'items': items.map((e) => e.toJson()).toList(),
      if (reason.isNotEmpty) 'reason': reason,
    };

    final response = await http
        .post(url, headers: _buildHeaders(token), body: json.encode(body))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true && responseData['data'] != null) {
        return RentalItemCancelResponse.fromJson(responseData['data']);
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('결제 취소에 실패했습니다.');
  }

  // ========== 8. 반품 신청 ==========

  /// 배송중/배송완료 아이템을 선택해 반품 신청 접수
  /// [items] 반품 아이템 목록. returnQuantity 가 item.quantity 미만이면 부분 반품.
  ///
  /// POST /api/contracts/:contractId/rental-items/return-request
  Future<void> returnRequestRentalItems({
    required int contractId,
    required List<RentalItemReturnRequest> items,
    required String reason,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/rental-items/return-request',
    );

    final body = {
      'items': items.map((e) => e.toJson()).toList(),
      'reason': reason,
    };

    final response = await http
        .post(url, headers: _buildHeaders(token), body: json.encode(body))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true) return;
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('반품 신청에 실패했습니다.');
  }

  // ========== 9. 반품 환불 예상 금액 조회 ==========

  /// 반품 신청 전 예상 환불 금액 미리보기
  /// 수거비 면제 여부를 서버에서 계산해 반환
  ///
  /// GET /api/contracts/:contractId/rental-items/return-preview?itemIds=12,13
  Future<ReturnPreviewResponse> getReturnPreview({
    required int contractId,
    required List<int> itemIds,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/contracts/$contractId/rental-items/return-preview'
      '?itemIds=${itemIds.join(',')}',
    );

    final response = await http
        .get(url, headers: _buildHeaders(token))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true && responseData['data'] != null) {
        return ReturnPreviewResponse.fromJson(responseData['data']);
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('환불 예상 금액 조회에 실패했습니다.');
  }

  // ========== 10. 미결제 주문 취소 ==========

  /// 미결제 렌탈 주문 취소
  ///
  /// DELETE /api/rental-orders/:rentalOrderId
  Future<void> cancelPendingOrder(int rentalOrderId) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/rental-orders/$rentalOrderId',
    );

    final response = await http
        .delete(url, headers: _buildHeaders(token))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    _handleErrorResponse(response);
    throw Exception('주문 취소에 실패했습니다.');
  }

  // ========== 8. 주문 취소 (환불) ==========

  /// 렌탈 주문 전체 취소 (환불)
  ///
  /// POST /api/rental-orders/:rentalOrderId/cancel
  /// - 임대중 이전: 즉시 취소 (refundStatus: "COMPLETED")
  /// - 임대중: 취소 요청 (status: "CANCEL_REQUESTED")
  Future<Map<String, dynamic>> cancelOrder({
    required int rentalOrderId,
    String reason = '',
  }) async {
    final token = await _getToken();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/rental-orders/$rentalOrderId/cancel',
    );

    final body = reason.isNotEmpty ? {'reason': reason} : <String, dynamic>{};

    final response = await http
        .post(
          url,
          headers: _buildHeaders(token),
          body: json.encode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['success'] == true) {
        return responseData['data'] ?? {};
      }
      throw Exception('예상하지 못한 응답 형식입니다.');
    }
    _handleErrorResponse(response);
    throw Exception('주문 취소에 실패했습니다.');
  }

  // ========== 헬퍼 메서드 ==========

  /// 토큰 가져오기
  Future<String> _getToken() async {
    var token = await TokenService.getValidAccessToken(autoRefresh: true);
    if (token == null && !ApiConfig.isProduction) {
      AppLogger.w('⚠️ [RENTAL_ORDER] 토큰 갱신 실패, skipExpiryCheck로 재시도');
      token = await TokenService.getAccessToken(skipExpiryCheck: true);
    }

    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  /// 헤더 생성
  Map<String, String> _buildHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// 렌탈 아이템 에러 코드 → 사용자 친화적 메시지
  static const _rentalErrorMessages = <int, String>{
    4421: '취소 가능 기간이 지났습니다. (입주 후 7일 초과)',
    4424: '이미 반품 신청된 상품입니다.',
    4425: '배송이 시작된 상품은 결제 취소가 불가합니다.\n반품 신청을 이용해 주세요.',
    4460: '존재하지 않는 상품입니다. 새로고침 후 다시 시도해 주세요.',
    4461: '다른 계약의 상품이 포함되어 있습니다.',
    4462: '이미 취소/환불된 상품이 포함되어 있습니다.',
    4463: '환불 불가 상태의 주문입니다.',
    4470: '배송 전 상품은 반품 신청 대신 결제 취소를 이용해 주세요.',
    4471: '반품 신청은 주문별로 각각 진행해 주세요.\n(여러 주문을 한 번에 신청할 수 없습니다)',
  };

  /// 에러 응답 처리
  void _handleErrorResponse(http.Response response) {
    try {
      final error = json.decode(utf8.decode(response.bodyBytes));
      final serverMessage = error['message'] ?? '알 수 없는 오류가 발생했습니다.';
      final errorCode = error['code'] as int?;

      // 렌탈 아이템 전용 에러 코드 우선 매핑
      if (errorCode != null && _rentalErrorMessages.containsKey(errorCode)) {
        throw Exception(_rentalErrorMessages[errorCode]);
      }

      switch (response.statusCode) {
        case 400:
          throw Exception(serverMessage);
        case 401:
          throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
        case 403:
          throw Exception('권한이 없습니다.');
        case 404:
          throw Exception('요청한 리소스를 찾을 수 없습니다.');
        case 409:
          throw Exception(serverMessage);
        default:
          throw Exception(serverMessage);
      }
    } on FormatException {
      throw Exception('서버 응답을 처리할 수 없습니다.');
    }
  }
}

// ========== 모델 클래스 ==========

/// 렌탈 주문 요약 응답
class RentalOrderSummaryResponse {
  final RentalOrderSummary summary;
  final List<RentalOrder> orders;

  RentalOrderSummaryResponse({
    required this.summary,
    required this.orders,
  });

  factory RentalOrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    // 1. summary.activeItems에서 description 맵 추출 (orderItemId -> description)
    final Map<int, String> descriptionMap = {};
    final summaryData = json['summary'];
    if (summaryData != null && summaryData['activeItems'] != null) {
      final activeItems = summaryData['activeItems'] as List<dynamic>;
      for (final item in activeItems) {
        final orderItemId = item['orderItemId'];
        final description = item['description'];
        if (orderItemId != null && description != null) {
          descriptionMap[orderItemId] = description;
        }
      }
    }

    // 2. orders 파싱 (description 맵 전달)
    final orders = (json['orders'] as List<dynamic>)
        .map((e) => RentalOrder.fromJson(e, descriptionMap: descriptionMap))
        .toList();

    return RentalOrderSummaryResponse(
      summary: RentalOrderSummary.fromJson(summaryData),
      orders: orders,
    );
  }
}

/// 렌탈 주문 요약
class RentalOrderSummary {
  final int totalPaid;
  final int totalRefunded;
  final int netAmount;
  final int activeItemsCount;

  RentalOrderSummary({
    required this.totalPaid,
    required this.totalRefunded,
    required this.netAmount,
    required this.activeItemsCount,
  });

  factory RentalOrderSummary.fromJson(Map<String, dynamic> json) {
    return RentalOrderSummary(
      totalPaid: json['totalPaid'] ?? 0,
      totalRefunded: json['totalRefunded'] ?? 0,
      netAmount: json['netAmount'] ?? 0,
      activeItemsCount: json['activeItemsCount'] ?? 0,
    );
  }
}

/// 렌탈 주문
class RentalOrder {
  final int id;
  final String orderId;
  final String orderType; // INITIAL, ADDITIONAL
  final String status; // PENDING, PAID, CANCELLED, REFUNDED
  final int totalAmount;
  final String? deliveryStatus; // PENDING, IN_TRANSIT, DELIVERED
  final List<RentalOrderItemDetail> items;
  final DateTime? createdAt;

  RentalOrder({
    required this.id,
    required this.orderId,
    required this.orderType,
    required this.status,
    required this.totalAmount,
    this.deliveryStatus,
    required this.items,
    this.createdAt,
  });

  factory RentalOrder.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? descriptionMap,
  }) {
    return RentalOrder(
      id: json['id'],
      orderId: json['orderId'] ?? '',
      orderType: json['orderType'] ?? 'INITIAL',
      status: json['status'] ?? 'PENDING',
      totalAmount: json['totalAmount'] ?? 0,
      deliveryStatus: json['deliveryStatus'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RentalOrderItemDetail.fromJson(
                    e,
                    descriptionMap: descriptionMap,
                  ))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

/// 렌탈 주문 아이템 상세
class RentalOrderItemDetail {
  final int id;
  final int itemId;
  final String name;
  final String? description;
  final String? itemType;
  final int quantity;
  final int price;
  final int subtotal;
  final String status; // ACTIVE, CANCELLED, REFUNDED
  final String? deliveryStatus; // (item 레벨 - 현재 미사용, order 레벨에서 관리)

  RentalOrderItemDetail({
    required this.id,
    required this.itemId,
    required this.name,
    this.description,
    this.itemType,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.status,
    this.deliveryStatus,
  });

  factory RentalOrderItemDetail.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? descriptionMap,
  }) {
    final int itemId = json['id'] ?? 0;
    // description: 1) json에서 직접 가져오기 2) descriptionMap에서 orderItemId로 매핑
    String? description = json['description'];
    if (description == null && descriptionMap != null) {
      description = descriptionMap[itemId];
    }

    return RentalOrderItemDetail(
      id: itemId,
      // API 응답: rentalItemId 또는 itemId
      itemId: json['rentalItemId'] ?? json['itemId'] ?? 0,
      name: json['name'] ?? '',
      description: description,
      itemType: json['itemType'],
      quantity: json['quantity'] ?? 0,
      // API 응답: pricePerItem 또는 price
      price: _parsePrice(json['pricePerItem'] ?? json['price']),
      // API 응답: totalPrice 또는 subtotal
      subtotal: _parsePrice(json['totalPrice'] ?? json['subtotal']),
      status: json['status'] ?? 'ACTIVE',
      deliveryStatus: json['deliveryStatus'],
    );
  }

  static int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.toInt();
    if (price is String) {
      try {
        return double.parse(price).toInt();
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

/// 이용 가능한 렌탈 아이템 조회 결과
class AvailableRentalItemsResult {
  final List<AvailableRentalItem> items;
  final bool hasPendingDelivery;

  const AvailableRentalItemsResult({
    required this.items,
    required this.hasPendingDelivery,
  });
}

/// 이용 가능한 렌탈 아이템
class AvailableRentalItem {
  final int id;
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final int totalStock;

  AvailableRentalItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.totalStock,
  });

  factory AvailableRentalItem.fromJson(Map<String, dynamic> json) {
    final stock = json['totalStock'] ?? json['availableQuantity'] ?? 0;
    return AvailableRentalItem(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: _parsePrice(json['price']),
      imageUrl: json['imageUrl'],
      totalStock: stock is int ? stock : int.tryParse(stock.toString()) ?? 0,
    );
  }

  static int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.toInt();
    if (price is String) {
      try {
        return double.parse(price).toInt();
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

/// 렌탈 주문 아이템 (요청용)
class RentalOrderItem {
  final int itemId;
  final int quantity;

  RentalOrderItem({
    required this.itemId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
    };
  }
}

/// 렌탈 주문 생성 응답
class RentalOrderResponse {
  final int rentalOrderId;
  final String orderId;
  final String orderType;
  final int totalAmount;
  final String status;
  final DateTime? modifiableUntil;
  final List<RentalOrderItemDetail> items;
  final bool requiresPayment;
  final String? paymentUrl;

  RentalOrderResponse({
    required this.rentalOrderId,
    required this.orderId,
    required this.orderType,
    required this.totalAmount,
    required this.status,
    this.modifiableUntil,
    required this.items,
    this.requiresPayment = false,
    this.paymentUrl,
  });

  factory RentalOrderResponse.fromJson(Map<String, dynamic> json) {
    return RentalOrderResponse(
      rentalOrderId: json['rentalOrderId'],
      orderId: json['orderId'] ?? '',
      orderType: json['orderType'] ?? 'ADDITIONAL',
      totalAmount: json['totalAmount'] ?? 0,
      status: json['status'] ?? 'PENDING',
      modifiableUntil: json['modifiableUntil'] != null
          ? DateTime.parse(json['modifiableUntil'])
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RentalOrderItemDetail.fromJson(e))
              .toList() ??
          [],
      requiresPayment: json['requiresPayment'] ?? false,
      paymentUrl: json['paymentUrl'],
    );
  }
}

// ========== 결제취소 요청 모델 ==========

/// 취소 요청 아이템 단위 (수량 부분 취소 지원)
class RentalItemCancelRequest {
  final int id;
  final int cancelQuantity;

  const RentalItemCancelRequest({
    required this.id,
    required this.cancelQuantity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cancelQuantity': cancelQuantity,
      };
}

// ========== 반품 요청 모델 ==========

/// 반품 요청 아이템 단위 (수량 부분 반품 지원)
class RentalItemReturnRequest {
  final int id;
  final int returnQuantity;

  const RentalItemReturnRequest({
    required this.id,
    required this.returnQuantity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'returnQuantity': returnQuantity,
      };
}

// ========== 결제취소 응답 모델 ==========

class RentalItemCancelResponse {
  final List<CancelSucceededOrder> succeeded;
  final List<CancelFailedOrder> failed;
  final int totalRefunded;

  RentalItemCancelResponse({
    required this.succeeded,
    required this.failed,
    required this.totalRefunded,
  });

  bool get hasFailures => failed.isNotEmpty;

  factory RentalItemCancelResponse.fromJson(Map<String, dynamic> json) {
    return RentalItemCancelResponse(
      succeeded: (json['succeeded'] as List<dynamic>? ?? [])
          .map((e) => CancelSucceededOrder.fromJson(e))
          .toList(),
      failed: (json['failed'] as List<dynamic>? ?? [])
          .map((e) => CancelFailedOrder.fromJson(e))
          .toList(),
      totalRefunded: json['totalRefunded'] ?? 0,
    );
  }
}

class CancelSucceededOrder {
  final String orderId;
  final int refundAmount;

  CancelSucceededOrder({required this.orderId, required this.refundAmount});

  factory CancelSucceededOrder.fromJson(Map<String, dynamic> json) {
    return CancelSucceededOrder(
      orderId: json['orderId'] ?? '',
      refundAmount: json['refundAmount'] ?? 0,
    );
  }
}

class CancelFailedOrder {
  final String orderId;
  final String reason;

  CancelFailedOrder({required this.orderId, required this.reason});

  factory CancelFailedOrder.fromJson(Map<String, dynamic> json) {
    return CancelFailedOrder(
      orderId: json['orderId'] ?? '',
      reason: json['reason'] ?? '처리 중 오류가 발생했습니다.',
    );
  }
}

// ========== 반품 예상 금액 조회 응답 모델 ==========

class ReturnPreviewResponse {
  final List<ReturnOrderPreview> orderPreviews;
  final ReturnPreviewSummary summary;

  ReturnPreviewResponse({required this.orderPreviews, required this.summary});

  factory ReturnPreviewResponse.fromJson(Map<String, dynamic> json) {
    return ReturnPreviewResponse(
      orderPreviews: (json['orderPreviews'] as List<dynamic>? ?? [])
          .map((e) => ReturnOrderPreview.fromJson(e))
          .toList(),
      summary: ReturnPreviewSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class ReturnOrderPreview {
  final String orderId;
  final int rentalOrderId;
  final String deliveryStatus;
  final int itemTotalAmount;
  final int shippingDeduction;
  final int refundAmount;
  final String shippingDeductionReason;

  ReturnOrderPreview({
    required this.orderId,
    required this.rentalOrderId,
    required this.deliveryStatus,
    required this.itemTotalAmount,
    required this.shippingDeduction,
    required this.refundAmount,
    required this.shippingDeductionReason,
  });

  factory ReturnOrderPreview.fromJson(Map<String, dynamic> json) {
    return ReturnOrderPreview(
      orderId: json['orderId'] ?? '',
      rentalOrderId: json['rentalOrderId'] ?? 0,
      deliveryStatus: json['deliveryStatus'] ?? '',
      itemTotalAmount: json['itemTotalAmount'] ?? 0,
      shippingDeduction: json['shippingDeduction'] ?? 0,
      refundAmount: json['refundAmount'] ?? 0,
      shippingDeductionReason: json['shippingDeductionReason'] ?? '',
    );
  }
}

class ReturnPreviewSummary {
  final int totalItemAmount;
  final int totalShippingDeduction;
  final int totalRefundAmount;

  ReturnPreviewSummary({
    required this.totalItemAmount,
    required this.totalShippingDeduction,
    required this.totalRefundAmount,
  });

  factory ReturnPreviewSummary.fromJson(Map<String, dynamic> json) {
    return ReturnPreviewSummary(
      totalItemAmount: json['totalItemAmount'] ?? 0,
      totalShippingDeduction: json['totalShippingDeduction'] ?? 0,
      totalRefundAmount: json['totalRefundAmount'] ?? 0,
    );
  }
}
