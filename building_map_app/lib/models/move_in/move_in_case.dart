import 'move_in_enums.dart';
import 'move_in_room.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
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
  final String? cleaningRequestedDate;  // [Q2] 청소 희망일 (이미지 ②번 폼)
  final String? cleaningPaidAt;

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
    this.cleaningRequestedDate,
    this.cleaningPaidAt,
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
      cleaningRequestedDate: json['cleaningRequestedDate']?.toString(),
      cleaningPaidAt: json['cleaningPaidAt']?.toString(),
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
