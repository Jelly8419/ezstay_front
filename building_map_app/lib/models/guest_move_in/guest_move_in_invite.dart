import 'guest_move_in_enums.dart';
import 'guest_move_in_option.dart';
import 'guest_move_in_room.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// 결제 권한 상태 — `paymentEligibility` 필드
class PaymentEligibility {
  final bool loggedIn;
  final bool phoneMatched;
  final bool canPay;

  const PaymentEligibility({
    required this.loggedIn,
    required this.phoneMatched,
    required this.canPay,
  });

  factory PaymentEligibility.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return PaymentEligibility(
      loggedIn: (json['loggedIn'] as bool?) ?? false,
      phoneMatched: (json['phoneMatched'] as bool?) ?? false,
      canPay: (json['canPay'] as bool?) ?? false,
    );
  }
}

/// `GET /invite/:token` 응답 — 비로그인 미리보기 + 옵션 카탈로그
class GuestMoveInInvitePreview {
  final int requestId;
  final GuestMoveInStatus status;
  final GuestMoveInRoom room;
  final String checkInDate;       // KST ISO
  final String checkOutDate;      // KST ISO
  final String paymentDeadline;   // KST ISO (D-5)
  final bool authRequired;
  final List<GuestMoveInOption> options;
  final PaymentEligibility paymentEligibility;

  const GuestMoveInInvitePreview({
    required this.requestId,
    required this.status,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.paymentDeadline,
    required this.authRequired,
    required this.options,
    required this.paymentEligibility,
  });

  factory GuestMoveInInvitePreview.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final optionsRaw = (json['options'] as List?) ?? const [];
    return GuestMoveInInvitePreview(
      requestId: (json['requestId'] as num).toInt(),
      status: GuestMoveInStatus.fromCode(json['status']?.toString()),
      room: GuestMoveInRoom.fromJson(json['room']),
      checkInDate: json['checkInDate']?.toString() ?? '',
      checkOutDate: json['checkOutDate']?.toString() ?? '',
      paymentDeadline: json['paymentDeadline']?.toString() ?? '',
      authRequired: (json['authRequired'] as bool?) ?? true,
      options: optionsRaw.map(GuestMoveInOption.fromJson).toList(),
      paymentEligibility:
          PaymentEligibility.fromJson(json['paymentEligibility']),
    );
  }
}

/// `POST /invite/:token/bind` 응답
class BindResult {
  final int requestId;
  final bool bound;
  final int additionalBoundCount;

  const BindResult({
    required this.requestId,
    required this.bound,
    required this.additionalBoundCount,
  });

  factory BindResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return BindResult(
      requestId: (json['requestId'] as num).toInt(),
      bound: (json['bound'] as bool?) ?? false,
      additionalBoundCount:
          (json['additionalBoundCount'] as num? ?? 0).toInt(),
    );
  }
}
