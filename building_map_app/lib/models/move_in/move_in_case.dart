import 'move_in_enums.dart';
import 'move_in_room.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// 청소 환불 견적 — 서버 정책 평가 결과 (단일 진실 원천: evaluateCleaningRefund).
///
/// 케이스 상세 응답의 `cleaningRefund` 와 `GET .../cleaning/refund/quote`
/// 응답이 동일 구조. 프론트는 정책 수치(차감액·D-2·1시간 등)를 직접
/// 알 필요 없이 이 객체의 산정값만 표시.
class CleaningRefundQuote {
  /// 현재 시점에 환불 가능 여부
  final bool canRefund;

  /// 환불될 금액 (차감 적용 후)
  final int refundAmount;

  /// 차감액 (D-1~당일 구간 10,000원, 그 외 0)
  final int deduction;

  /// canRefund=false 일 때 사용자에게 보여줄 거부 사유
  final String? reason;

  const CleaningRefundQuote({
    required this.canRefund,
    required this.refundAmount,
    required this.deduction,
    this.reason,
  });

  static const CleaningRefundQuote unavailable = CleaningRefundQuote(
    canRefund: false,
    refundAmount: 0,
    deduction: 0,
  );

  factory CleaningRefundQuote.fromJson(dynamic raw) {
    if (raw is! Map) return unavailable;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    return CleaningRefundQuote(
      canRefund: (json['canRefund'] as bool?) ?? false,
      refundAmount: (json['refundAmount'] as num? ?? 0).toInt(),
      deduction: (json['deduction'] as num? ?? 0).toInt(),
      reason: json['reason']?.toString(),
    );
  }
}

/// 임차인 결제 요청 발송 요약 정보 (케이스 내장)
class MoveInPaymentRequestSummary {
  final PaymentRequestStatus status;
  final String? sentAt;
  final String? lastResentAt;
  final int resendCount;
  final String? expiresAt;

  const MoveInPaymentRequestSummary({
    required this.status,
    this.sentAt,
    this.lastResentAt,
    required this.resendCount,
    this.expiresAt,
  });

  factory MoveInPaymentRequestSummary.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return MoveInPaymentRequestSummary(
      status: PaymentRequestStatus.fromCode(json['status']?.toString()),
      sentAt: json['sentAt']?.toString(),
      lastResentAt: json['lastResentAt']?.toString(),
      resendCount: (json['resendCount'] ?? 0).toInt(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}

/// 입주 준비 등록 (외부 계약 1건 = 케이스 1건)
///
/// 동일 방이라도 계약 기간/임차인이 다르면 별도 케이스로 관리.
/// `roomSnapshot`은 케이스 생성 시점의 방 정보로 락인 — 이후 방 정보 수정해도 반영 X (PRD 12.5).
class MoveInCase {
  final int id;
  final int moveInRoomId;
  final String checkInDate;        // 'YYYY-MM-DD'
  final String checkOutDate;
  final String guestName;
  final String guestPhone;
  final int? guestUserId;
  final String? requestMemo;

  final CleaningStatus cleaningStatus;
  final int? cleaningFee;

  /// 청소 희망 일자 'YYYY-MM-DD' (백엔드 컬럼: `cleaning_date`)
  final String? cleaningDate;

  /// 청소 희망 시작 시각 'HH:mm:ss' (DB TIME 컬럼은 SS까지 반환)
  final String? cleaningTime;

  final String? cleaningPaidAt;

  /// 청소 환불 견적 — 서버 정책 평가 결과.
  /// cleaningStatus=PAID 일 때만 의미 있는 값. 그 외엔 canRefund=false.
  final CleaningRefundQuote cleaningRefund;

  /// 결제 마감 시각 (KST) — 백엔드가 입주일 기준 계산하여 응답에 포함
  final String? cleaningPaymentDeadline;
  final String? optionPaymentDeadline;

  final MoveInRoom roomSnapshot;
  final MoveInPaymentRequestSummary? paymentRequest;

  final String createdAt;
  final String updatedAt;

  const MoveInCase({
    required this.id,
    required this.moveInRoomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestName,
    required this.guestPhone,
    this.guestUserId,
    this.requestMemo,
    required this.cleaningStatus,
    this.cleaningFee,
    this.cleaningDate,
    this.cleaningTime,
    this.cleaningPaidAt,
    this.cleaningRefund = CleaningRefundQuote.unavailable,
    this.cleaningPaymentDeadline,
    this.optionPaymentDeadline,
    required this.roomSnapshot,
    this.paymentRequest,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoveInCase.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return MoveInCase(
      id: (json['id'] ?? 0).toInt(),
      moveInRoomId: (json['moveInRoomId'] ?? 0).toInt(),
      checkInDate: (json['checkInDate'] ?? '').toString(),
      checkOutDate: (json['checkOutDate'] ?? '').toString(),
      guestName: (json['guestName'] ?? '').toString(),
      guestPhone: (json['guestPhone'] ?? '').toString(),
      guestUserId: (json['guestUserId'] as num?)?.toInt(),
      requestMemo: json['requestMemo']?.toString(),
      cleaningStatus: CleaningStatus.fromCode(json['cleaningStatus']?.toString()),
      cleaningFee: (json['cleaningFee'] as num?)?.toInt(),
      cleaningDate: json['cleaningDate']?.toString(),
      cleaningTime: json['cleaningTime']?.toString(),
      cleaningPaidAt: json['cleaningPaidAt']?.toString(),
      cleaningRefund: CleaningRefundQuote.fromJson(json['cleaningRefund']),
      cleaningPaymentDeadline: json['cleaningPaymentDeadline']?.toString(),
      optionPaymentDeadline: json['optionPaymentDeadline']?.toString(),
      roomSnapshot: MoveInRoom.fromJson(json['roomSnapshot']),
      paymentRequest: json['paymentRequest'] == null
          ? null
          : MoveInPaymentRequestSummary.fromJson(json['paymentRequest']),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  /// 청소 결제 가능 여부 (PRD 7.1)
  bool get canPayCleaning =>
      cleaningStatus == CleaningStatus.paymentPending &&
      roomSnapshot.cleaningSuppliesAvailable;

  /// 임차인 결제 요청을 한 번이라도 보냈는지
  bool get isPaymentRequestSent =>
      paymentRequest?.status == PaymentRequestStatus.sent;
}
