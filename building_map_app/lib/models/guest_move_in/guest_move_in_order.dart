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

  const GuestMoveInOrderItem({
    required this.itemId,
    required this.optionId,
    this.name,
    required this.quantity,
    required this.pricePerItem,
    required this.totalPrice,
    required this.status,
  });

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
  });

  factory GuestMoveInOrder.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final itemsRaw = (json['items'] as List?) ?? const [];
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
    );
  }

  bool get isCancellable => status == GuestOrderStatus.pending;
}
