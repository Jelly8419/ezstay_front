import 'bed_info.dart';

/// 간편 방 정보 생성/수정 요청 (POST/PATCH /api/host/move-in/rooms[/:id])
///
/// PATCH 시 전체 필드를 보내거나 변경된 필드만 보내도 백엔드가 처리.
/// `beds`의 길이는 반드시 `bedCount`와 일치 (불일치 시 400 에러).
class MoveInRoomRequest {
  final String? roomName;
  final String address;
  final String detailAddress;
  final num areaPyeong;
  final int livingRoomCount;
  final int roomCount;
  final int bathroomCount;
  final int bedCount;
  final List<BedInfo> beds;
  final String? commonEntrancePassword;
  final String? doorLockPassword;
  final bool cleaningSuppliesAvailable;
  final String? cleaningSuppliesLocation;
  final String? memo;

  const MoveInRoomRequest({
    this.roomName,
    required this.address,
    required this.detailAddress,
    required this.areaPyeong,
    required this.livingRoomCount,
    required this.roomCount,
    required this.bathroomCount,
    required this.bedCount,
    required this.beds,
    this.commonEntrancePassword,
    this.doorLockPassword,
    required this.cleaningSuppliesAvailable,
    this.cleaningSuppliesLocation,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'address': address,
      'detailAddress': detailAddress,
      'areaPyeong': areaPyeong,
      'livingRoomCount': livingRoomCount,
      'roomCount': roomCount,
      'bathroomCount': bathroomCount,
      'bedCount': bedCount,
      'beds': beds.map((b) => b.toJson()).toList(),
      'cleaningSuppliesAvailable': cleaningSuppliesAvailable,
    };
    if (roomName != null) map['roomName'] = roomName;
    if (commonEntrancePassword != null) map['commonEntrancePassword'] = commonEntrancePassword;
    if (doorLockPassword != null) map['doorLockPassword'] = doorLockPassword;
    if (cleaningSuppliesLocation != null) map['cleaningSuppliesLocation'] = cleaningSuppliesLocation;
    if (memo != null) map['memo'] = memo;
    return map;
  }
}

/// 입주 준비 등록(케이스) 생성 요청 (POST /api/host/move-in/cases)
///
/// 청소 신청은 별도 호출 (POST /cases/:id/cleaning/request) 로 상태 전환만 수행.
/// 청소 희망 일자/시간은 케이스 생성 시점에 함께 저장 ([cleaningDate]+[cleaningTime]).
class MoveInCaseCreateRequest {
  final int moveInRoomId;
  final String checkInDate;
  final String checkOutDate;
  final String guestName;
  final String guestPhone;
  final String? requestMemo;

  /// 자동 발송 체크박스 (Q3-A — 기본 ON)
  final bool sendGuestPaymentRequest;

  /// 청소 희망 일자 'YYYY-MM-DD' — [cleaningTime]과 함께 전송하거나 함께 비워야 함.
  final String? cleaningDate;

  /// 청소 희망 시작 시각 'HH:mm' (30분 단위, 09:00~18:00).
  final String? cleaningTime;

  const MoveInCaseCreateRequest({
    required this.moveInRoomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestName,
    required this.guestPhone,
    this.requestMemo,
    this.sendGuestPaymentRequest = true,
    this.cleaningDate,
    this.cleaningTime,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'moveInRoomId': moveInRoomId,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'sendGuestPaymentRequest': sendGuestPaymentRequest,
    };
    if (requestMemo != null && requestMemo!.isNotEmpty) {
      map['requestMemo'] = requestMemo;
    }
    if (cleaningDate != null) map['cleaningDate'] = cleaningDate;
    if (cleaningTime != null) map['cleaningTime'] = cleaningTime;
    return map;
  }
}

/// 케이스 수정 요청 (PATCH /api/host/move-in/cases/:id)
///
/// 부분 수정 — null 필드는 직렬화에서 제외.
/// `guestPhone` 변경 시 백엔드가 토큰 재발급 + status를 NOT_SENT로 초기화.
class MoveInCaseUpdateRequest {
  final String? checkInDate;
  final String? checkOutDate;
  final String? guestName;
  final String? guestPhone;
  final String? requestMemo;
  final String? cleaningDate;
  final String? cleaningTime;

  const MoveInCaseUpdateRequest({
    this.checkInDate,
    this.checkOutDate,
    this.guestName,
    this.guestPhone,
    this.requestMemo,
    this.cleaningDate,
    this.cleaningTime,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (checkInDate != null) map['checkInDate'] = checkInDate;
    if (checkOutDate != null) map['checkOutDate'] = checkOutDate;
    if (guestName != null) map['guestName'] = guestName;
    if (guestPhone != null) map['guestPhone'] = guestPhone;
    if (requestMemo != null) map['requestMemo'] = requestMemo;
    if (cleaningDate != null) map['cleaningDate'] = cleaningDate;
    if (cleaningTime != null) map['cleaningTime'] = cleaningTime;
    return map;
  }

  bool get isEmpty => toJson().isEmpty;
}

/// 청소 결제 승인 요청 (POST /cleaning/payment/confirm)
class CleaningPaymentConfirmRequest {
  final int paymentId;
  final String? recvPayparam;
  final String? payType;
  final bool? simulateFailure; // Mock 모드 옵션

  const CleaningPaymentConfirmRequest({
    required this.paymentId,
    this.recvPayparam,
    this.payType,
    this.simulateFailure,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'paymentId': paymentId};
    if (recvPayparam != null) map['recvPayparam'] = recvPayparam;
    if (payType != null) map['payType'] = payType;
    if (simulateFailure != null) map['simulateFailure'] = simulateFailure;
    return map;
  }
}
