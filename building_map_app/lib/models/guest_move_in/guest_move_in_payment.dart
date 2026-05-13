import 'guest_move_in_enums.dart';
import 'guest_move_in_order.dart';
import 'guest_move_in_request.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// PG 페이로드 — Mock 모드 / 실 PayTag 모드 둘 다 처리
class PgPayload {
  final bool mock;
  final String? message;       // mock=true 일 때 안내
  final String? shopcode;
  final String? orderId;
  final int? amount;
  final String? productName;
  final String? buyerName;
  final String? customerPhone;

  const PgPayload({
    required this.mock,
    this.message,
    this.shopcode,
    this.orderId,
    this.amount,
    this.productName,
    this.buyerName,
    this.customerPhone,
  });

  factory PgPayload.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final mock = (json['mock'] as bool?) ?? false;
    return PgPayload(
      mock: mock,
      message: json['message']?.toString(),
      shopcode: json['shopcode']?.toString(),
      orderId: json['orderId']?.toString(),
      amount: (json['amount'] as num?)?.toInt(),
      productName: json['productName']?.toString(),
      buyerName: json['buyerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
    );
  }
}

/// `POST /payment/init` 또는 `/additional/init` 응답
class GuestPaymentInitResponse {
  final String orderId;          // "270701-G0001"
  final int orderDbId;
  final OrderType orderType;
  final int paymentId;
  final int amount;
  final int caseId;
  final PgPayload pgPayload;

  const GuestPaymentInitResponse({
    required this.orderId,
    required this.orderDbId,
    required this.orderType,
    required this.paymentId,
    required this.amount,
    required this.caseId,
    required this.pgPayload,
  });

  factory GuestPaymentInitResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestPaymentInitResponse(
      orderId: json['orderId']?.toString() ?? '',
      orderDbId: (json['orderDbId'] as num? ?? 0).toInt(),
      orderType: OrderType.fromCode(json['orderType']?.toString()),
      paymentId: (json['paymentId'] as num? ?? 0).toInt(),
      amount: (json['amount'] as num? ?? 0).toInt(),
      caseId: (json['caseId'] as num? ?? 0).toInt(),
      pgPayload: PgPayload.fromJson(json['pgPayload']),
    );
  }
}

/// `POST /payment/confirm` 또는 `/additional/confirm` 응답
class GuestPaymentConfirmResponse {
  final int paymentId;
  final String orderId;
  final int orderDbId;
  final int caseId;
  final GuestOrderStatus orderStatus;
  final String? paidAt;
  final String? pgTid;
  final bool mock;

  const GuestPaymentConfirmResponse({
    required this.paymentId,
    required this.orderId,
    required this.orderDbId,
    required this.caseId,
    required this.orderStatus,
    this.paidAt,
    this.pgTid,
    required this.mock,
  });

  factory GuestPaymentConfirmResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestPaymentConfirmResponse(
      paymentId: (json['paymentId'] as num? ?? 0).toInt(),
      orderId: json['orderId']?.toString() ?? '',
      orderDbId: (json['orderDbId'] as num? ?? 0).toInt(),
      caseId: (json['caseId'] as num? ?? 0).toInt(),
      orderStatus:
          GuestOrderStatus.fromCode(json['orderStatus']?.toString()),
      paidAt: json['paidAt']?.toString(),
      pgTid: json['pgTid']?.toString(),
      mock: (json['mock'] as bool?) ?? false,
    );
  }
}

/// 결제 메타 정보 (`payment` 객체)
class GuestPayment {
  final int paymentId;
  final String orderId;
  final int amount;
  final GuestOrderStatus status;
  final String? pgProvider;
  final String? pgMethod;
  final String? pgTid;
  final String? paidAt;
  final String? failedAt;
  final String? failureReason;

  const GuestPayment({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.status,
    this.pgProvider,
    this.pgMethod,
    this.pgTid,
    this.paidAt,
    this.failedAt,
    this.failureReason,
  });

  factory GuestPayment.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestPayment(
      paymentId: (json['paymentId'] as num? ?? 0).toInt(),
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num? ?? 0).toInt(),
      status: GuestOrderStatus.fromCode(json['status']?.toString()),
      pgProvider: json['pgProvider']?.toString(),
      pgMethod: json['pgMethod']?.toString(),
      pgTid: json['pgTid']?.toString(),
      paidAt: json['paidAt']?.toString(),
      failedAt: json['failedAt']?.toString(),
      failureReason: json['failureReason']?.toString(),
    );
  }
}

/// `GET /payments/:paymentId` 결제 결과 통합 응답
class GuestPaymentResult {
  final GuestPayment payment;
  final GuestMoveInOrder order;
  final GuestMoveInRequestListItem caseInfo;

  const GuestPaymentResult({
    required this.payment,
    required this.order,
    required this.caseInfo,
  });

  factory GuestPaymentResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestPaymentResult(
      payment: GuestPayment.fromJson(json['payment']),
      order: GuestMoveInOrder.fromJson(json['order']),
      caseInfo: GuestMoveInRequestListItem.fromJson(json['case']),
    );
  }
}

/// `DELETE /orders/:orderId` 응답
class GuestOrderCancelResponse {
  final int orderDbId;
  final String orderId;
  final GuestOrderStatus status;
  final String? cancelledAt;

  const GuestOrderCancelResponse({
    required this.orderDbId,
    required this.orderId,
    required this.status,
    this.cancelledAt,
  });

  factory GuestOrderCancelResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestOrderCancelResponse(
      orderDbId: (json['orderDbId'] as num? ?? 0).toInt(),
      orderId: json['orderId']?.toString() ?? '',
      status: GuestOrderStatus.fromCode(json['status']?.toString()),
      cancelledAt: json['cancelledAt']?.toString(),
    );
  }
}
