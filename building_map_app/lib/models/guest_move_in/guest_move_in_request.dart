import 'guest_move_in_enums.dart';
import 'guest_move_in_option.dart';
import 'guest_move_in_order.dart';
import 'guest_move_in_room.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// `GET /requests` 목록 아이템
class GuestMoveInRequestListItem {
  final int requestId;
  final GuestMoveInStatus status;
  final GuestMoveInRoom room;
  final String checkInDate;
  final String checkOutDate;
  final String paymentDeadline;
  final bool authRequired;
  final bool canPay;

  const GuestMoveInRequestListItem({
    required this.requestId,
    required this.status,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.paymentDeadline,
    required this.authRequired,
    required this.canPay,
  });

  factory GuestMoveInRequestListItem.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestMoveInRequestListItem(
      requestId: (json['requestId'] as num).toInt(),
      status: GuestMoveInStatus.fromCode(json['status']?.toString()),
      room: GuestMoveInRoom.fromJson(json['room']),
      checkInDate: json['checkInDate']?.toString() ?? '',
      checkOutDate: json['checkOutDate']?.toString() ?? '',
      paymentDeadline: json['paymentDeadline']?.toString() ?? '',
      authRequired: (json['authRequired'] as bool?) ?? false,
      canPay: (json['canPay'] as bool?) ?? false,
    );
  }
}

/// 페이지네이션 메타
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return Pagination(
      page: (json['page'] as num? ?? 1).toInt(),
      limit: (json['limit'] as num? ?? 20).toInt(),
      total: (json['total'] as num? ?? 0).toInt(),
      totalPages: (json['totalPages'] as num? ?? 0).toInt(),
    );
  }
}

/// `GET /requests` 응답 래퍼
class GuestMoveInRequestList {
  final List<GuestMoveInRequestListItem> items;
  final Pagination pagination;

  const GuestMoveInRequestList({
    required this.items,
    required this.pagination,
  });

  factory GuestMoveInRequestList.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final itemsRaw = (json['items'] as List?) ?? const [];
    return GuestMoveInRequestList(
      items: itemsRaw.map(GuestMoveInRequestListItem.fromJson).toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

/// `GET /requests/:caseId` 상세 응답
class GuestMoveInRequestDetail {
  final int requestId;
  final GuestMoveInStatus status;
  final GuestMoveInRoom room;
  final String checkInDate;
  final String checkOutDate;
  final String paymentDeadline;
  final bool authRequired;
  final bool canPay;
  final List<GuestMoveInOption> options;
  final List<GuestMoveInOrder> orders;

  const GuestMoveInRequestDetail({
    required this.requestId,
    required this.status,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.paymentDeadline,
    required this.authRequired,
    required this.canPay,
    required this.options,
    required this.orders,
  });

  factory GuestMoveInRequestDetail.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final optionsRaw = (json['options'] as List?) ?? const [];
    final ordersRaw = (json['orders'] as List?) ?? const [];
    return GuestMoveInRequestDetail(
      requestId: (json['requestId'] as num).toInt(),
      status: GuestMoveInStatus.fromCode(json['status']?.toString()),
      room: GuestMoveInRoom.fromJson(json['room']),
      checkInDate: json['checkInDate']?.toString() ?? '',
      checkOutDate: json['checkOutDate']?.toString() ?? '',
      paymentDeadline: json['paymentDeadline']?.toString() ?? '',
      authRequired: (json['authRequired'] as bool?) ?? false,
      canPay: (json['canPay'] as bool?) ?? false,
      options: optionsRaw.map(GuestMoveInOption.fromJson).toList(),
      orders: ordersRaw.map(GuestMoveInOrder.fromJson).toList(),
    );
  }

  /// INITIAL 결제가 PAID/PARTIAL_REFUND 상태인지 (추가 결제 가드)
  bool get hasPaidInitial => orders.any(
        (o) =>
            o.orderType == OrderType.initial &&
            (o.status == GuestOrderStatus.paid ||
                o.status == GuestOrderStatus.partialRefund),
      );
}

/// `GET /requests/:caseId/options` 결제 컨텍스트 (가벼운 응답)
class GuestMoveInOptionsResponse {
  final int caseId;
  final String checkInDate;
  final String checkOutDate;
  final String paymentDeadline;
  final bool canPay;
  final List<GuestMoveInOption> options;

  const GuestMoveInOptionsResponse({
    required this.caseId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.paymentDeadline,
    required this.canPay,
    required this.options,
  });

  factory GuestMoveInOptionsResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final optionsRaw = (json['options'] as List?) ?? const [];
    return GuestMoveInOptionsResponse(
      caseId: (json['caseId'] as num).toInt(),
      checkInDate: json['checkInDate']?.toString() ?? '',
      checkOutDate: json['checkOutDate']?.toString() ?? '',
      paymentDeadline: json['paymentDeadline']?.toString() ?? '',
      canPay: (json['canPay'] as bool?) ?? false,
      options: optionsRaw.map(GuestMoveInOption.fromJson).toList(),
    );
  }
}
