import 'guest_move_in_enums.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// 주문 라인 (옵션별 항목)
class GuestMoveInOrderItem {
  final int itemId;
  final int optionId;
  final String? name;
  final int quantity;
  final int pricePerItem;
  final int totalPrice;
  final OrderItemStatus status;

  /// 라인별 반품 요청 중(미승인 PENDING) 수량 — 부분 반품 남은수량 가드용.
  /// 백엔드 미include 시 0.
  final int pendingReturnQuantity;

  const GuestMoveInOrderItem({
    required this.itemId,
    required this.optionId,
    this.name,
    required this.quantity,
    required this.pricePerItem,
    required this.totalPrice,
    required this.status,
    this.pendingReturnQuantity = 0,
  });

  /// 아직 반품 요청 가능한 잔여 수량 (전체 - 진행 중 반품요청 수량)
  int get returnableQuantity {
    final r = quantity - pendingReturnQuantity;
    return r < 0 ? 0 : r;
  }

  factory GuestMoveInOrderItem.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestMoveInOrderItem(
      itemId: (json['itemId'] as num? ?? 0).toInt(),
      optionId: (json['optionId'] as num? ?? 0).toInt(),
      name: json['name']?.toString(),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      pricePerItem: (json['pricePerItem'] as num? ?? 0).toInt(),
      totalPrice: (json['totalPrice'] as num? ?? 0).toInt(),
      status: OrderItemStatus.fromCode(json['status']?.toString()),
      pendingReturnQuantity:
          (json['pendingReturnQuantity'] as num? ?? 0).toInt(),
    );
  }
}

/// 진행 중(PENDING) 반품요청 요약 — 주문 상세 응답 동봉
class GuestRefundRequestSummary {
  final int id;
  final String status; // PENDING
  final int itemTotalAmount;
  final String? returnReason;

  /// 반품 대상 라인·수량 스냅샷 (itemId → quantity)
  final Map<int, int> targetItems;
  final String? createdAt;

  const GuestRefundRequestSummary({
    required this.id,
    required this.status,
    required this.itemTotalAmount,
    this.returnReason,
    required this.targetItems,
    this.createdAt,
  });

  factory GuestRefundRequestSummary.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final tiRaw = (json['targetItems'] as List?) ?? const [];
    final ti = <int, int>{};
    for (final e in tiRaw) {
      final m = _asMap(e);
      final id = (m['itemId'] as num?)?.toInt();
      final qty = (m['quantity'] as num?)?.toInt();
      if (id != null && qty != null) ti[id] = qty;
    }
    return GuestRefundRequestSummary(
      id: (json['id'] as num? ?? 0).toInt(),
      status: json['status']?.toString() ?? '',
      itemTotalAmount: (json['itemTotalAmount'] as num? ?? 0).toInt(),
      returnReason: json['returnReason']?.toString(),
      targetItems: ti,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// 주문 (INITIAL / ADDITIONAL)
class GuestMoveInOrder {
  final int orderDbId;           // DB PK (정수) — 환불/반품 API path 인자
  final String orderId;          // "270701-G0001" (표시용 주문번호)
  final OrderType orderType;
  final GuestOrderStatus status;
  final DeliveryStatus deliveryStatus;
  final int totalAmount;
  final int paidAmount;
  final int refundedAmount;
  final String? paidAt;
  final String? deliveredAt;
  final String? createdAt;
  final List<GuestMoveInOrderItem> items;

  /// 진행 중(PENDING) 반품요청 목록 — 백엔드 미include 시 빈 배열
  final List<GuestRefundRequestSummary> refundRequests;

  /// 결제 취소 가능 여부 — 서버 정책 평가 결과(`evaluateGuestCancel`)를
  /// 그대로 노출. 프론트는 deliveryStatus·시점을 직접 검사하지 말고
  /// 이 플래그만 보고 탭/버튼 노출을 결정.
  final bool canCancel;

  /// 반품 요청 가능 여부 — 서버 정책 평가 결과(`evaluateGuestReturn`).
  final bool canReturn;

  const GuestMoveInOrder({
    required this.orderDbId,
    required this.orderId,
    required this.orderType,
    required this.status,
    required this.deliveryStatus,
    required this.totalAmount,
    required this.paidAmount,
    required this.refundedAmount,
    this.paidAt,
    this.deliveredAt,
    this.createdAt,
    required this.items,
    this.refundRequests = const [],
    this.canCancel = false,
    this.canReturn = false,
  });

  factory GuestMoveInOrder.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final itemsRaw = (json['items'] as List?) ?? const [];
    final rrRaw = (json['refundRequests'] as List?) ?? const [];
    return GuestMoveInOrder(
      orderDbId: (json['orderDbId'] as num? ?? 0).toInt(),
      orderId: json['orderId']?.toString() ?? '',
      orderType: OrderType.fromCode(json['orderType']?.toString()),
      status: GuestOrderStatus.fromCode(json['status']?.toString()),
      deliveryStatus:
          DeliveryStatus.fromCode(json['deliveryStatus']?.toString()),
      totalAmount: (json['totalAmount'] as num? ?? 0).toInt(),
      paidAmount: (json['paidAmount'] as num? ?? 0).toInt(),
      refundedAmount: (json['refundedAmount'] as num? ?? 0).toInt(),
      paidAt: json['paidAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      items: itemsRaw.map(GuestMoveInOrderItem.fromJson).toList(),
      refundRequests:
          rrRaw.map(GuestRefundRequestSummary.fromJson).toList(),
      canCancel: (json['canCancel'] as bool?) ?? false,
      canReturn: (json['canReturn'] as bool?) ?? false,
    );
  }

  bool get isCancellable => status == GuestOrderStatus.pending;

  /// 진행 중 반품요청이 하나라도 있는지
  bool get hasPendingReturn => refundRequests.isNotEmpty;

  /// 반품 가능한(잔여 수량 1 이상) ACTIVE 라인이 하나라도 있는지
  bool get hasReturnableItem => items.any((i) =>
      i.status == OrderItemStatus.active && i.returnableQuantity > 0);
}
