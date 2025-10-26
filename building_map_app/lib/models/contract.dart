import 'package:flutter/foundation.dart';

/// 계약 상태
enum ContractStatus {
  pendingApproval('PENDING_APPROVAL', '승인 대기'),
  approvalExpired('APPROVAL_EXPIRED', '미승인 만료'),
  approved('APPROVED', '승인됨'),
  paymentExpired('PAYMENT_EXPIRED', '미결제 만료'),
  rejected('REJECTED', '거절됨'),
  paymentCompleted('PAYMENT_COMPLETED', '결제 완료'),
  inProgress('IN_PROGRESS', '계약 진행중'),
  completed('COMPLETED', '계약 완료'),
  cancelledByGuest('CANCELLED_BY_GUEST', '게스트 취소'),
  cancelledByHost('CANCELLED_BY_HOST', '호스트 취소'),
  refunded('REFUNDED', '환불 완료');

  final String value;
  final String label;

  const ContractStatus(this.value, this.label);

  static ContractStatus fromString(String value) {
    return ContractStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () {
        debugPrint('⚠️ [CONTRACT_STATUS] Unknown status: $value, defaulting to pendingApproval');
        return ContractStatus.pendingApproval;
      },
    );
  }
}

/// 할인 유형
enum DiscountType {
  none('NONE', '할인 없음'),
  longTermDiscount('LONG_TERM_DISCOUNT', '장기 할인'),
  quickMoveIn('QUICK_MOVE_IN', '빠른 입주 할인'),
  coupon('COUPON', '쿠폰 할인'),
  promotional('PROMOTIONAL', '프로모션 할인');

  final String value;
  final String label;

  const DiscountType(this.value, this.label);

  static DiscountType? fromString(String? value) {
    if (value == null) return null;
    return DiscountType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DiscountType.none,
    );
  }
}

/// 결제 수단
enum PaymentMethod {
  creditCard('CREDIT_CARD', '신용카드'),
  bankTransfer('BANK_TRANSFER', '계좌이체'),
  simplePay('SIMPLE_PAY', '간편결제');

  final String value;
  final String label;

  const PaymentMethod(this.value, this.label);

  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.creditCard,
    );
  }
}

/// 계약 목록 아이템 (간단한 정보)
class ContractListItem {
  final int id;
  final ContractStatus status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int totalDays;
  final int finalTotalAmount;
  final String? guestMessage; // 호스트용

  // 방 정보
  final int roomId;
  final String roomName;
  final String roomAddress;
  final double roomArea;
  final String buildingType;
  final String? roomThumbnail;

  // 상대방 정보
  final int partnerId; // 게스트용이면 hostId, 호스트용이면 guestId
  final String partnerName;
  final String partnerPhone;
  final String? partnerEmail; // 호스트용에만 포함

  final DateTime createdAt;

  ContractListItem({
    required this.id,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalDays,
    required this.finalTotalAmount,
    this.guestMessage,
    required this.roomId,
    required this.roomName,
    required this.roomAddress,
    required this.roomArea,
    required this.buildingType,
    this.roomThumbnail,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhone,
    this.partnerEmail,
    required this.createdAt,
  });

  factory ContractListItem.fromJson(Map<String, dynamic> json) {
    // 백엔드는 room과 guest(호스트용) 또는 host(게스트용) 정보를 포함
    final room = json['room'];
    final partner = json['guest'] ?? json['host']; // 호스트용은 guest, 게스트용은 host

    return ContractListItem(
      id: json['id'],
      status: ContractStatus.fromString(json['status']),
      checkInDate: DateTime.parse(json['checkInDate']),
      checkOutDate: DateTime.parse(json['checkOutDate']),
      totalDays: json['totalDays'],
      finalTotalAmount: json['finalTotalAmount'],
      guestMessage: json['guestMessage'],
      // 방 정보 - 백엔드 필드명: roomName, thumbnailUrl
      roomId: room['id'],
      roomName: room['roomName'] ?? room['name'],
      roomAddress: room['address'],
      roomArea: double.parse(room['area'].toString()),
      buildingType: room['buildingType'],
      roomThumbnail: room['thumbnailUrl'] ?? room['thumbnail'],
      // 상대방 정보 - 백엔드 필드명: phoneNumber
      partnerId: partner['id'],
      partnerName: partner['name'],
      partnerPhone: partner['phoneNumber'] ?? partner['phone'],
      partnerEmail: partner['email'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// 계약 상세 정보 (모든 정보)
class Contract {
  final int id;
  final int roomId;
  final int hostId;
  final int guestId;

  // 체크인/체크아웃 정보
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int totalDays;
  final int? totalWeeks;

  // 금액 정보
  final int rentalFee;
  final int maintenanceFee;
  final int cleaningFee;
  final int rentalItemsFee;
  final int platformFee;
  final int discountAmount;
  final DiscountType? discountType;
  final String? discountCode;
  final int subtotal;
  final int totalUsageFee;
  final int deposit;
  final int finalTotalAmount;

  // 렌탈 아이템 정보
  final Map<String, dynamic>? rentalItems;

  // 결제 정보
  final PaymentMethod? paymentMethod;
  final int installmentMonths;

  // 메시지 및 요청사항
  final String? guestMessage;
  final String? hostMessage;
  final Map<String, dynamic>? specialRequests;
  final Map<String, dynamic> termsAgreed;
  final Map<String, dynamic>? pricingSnapshot;

  // 계약 상태
  final ContractStatus status;

  // 계약 진행 시점
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? paidAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final DateTime? cancelledAt;

  final DateTime createdAt;
  final DateTime? updatedAt;

  // 관련 정보 (상세 조회시)
  final RoomInfo? room;
  final UserInfo? host;
  final UserInfo? guest;

  Contract({
    required this.id,
    required this.roomId,
    required this.hostId,
    required this.guestId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalDays,
    this.totalWeeks,
    required this.rentalFee,
    required this.maintenanceFee,
    required this.cleaningFee,
    required this.rentalItemsFee,
    required this.platformFee,
    required this.discountAmount,
    this.discountType,
    this.discountCode,
    required this.subtotal,
    required this.totalUsageFee,
    required this.deposit,
    required this.finalTotalAmount,
    this.rentalItems,
    this.paymentMethod,
    required this.installmentMonths,
    this.guestMessage,
    this.hostMessage,
    this.specialRequests,
    required this.termsAgreed,
    this.pricingSnapshot,
    required this.status,
    this.approvedAt,
    this.rejectedAt,
    this.paidAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
    this.room,
    this.host,
    this.guest,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    // hostId와 guestId는 직접 포함되거나, host.id / guest.id로 중첩될 수 있음
    final hostId = json['hostId'] as int? ??
                   (json['host'] != null ? json['host']['id'] as int? : null) ??
                   0;
    final guestId = json['guestId'] as int? ??
                    (json['guest'] != null ? json['guest']['id'] as int? : null) ??
                    0;
    final roomId = json['roomId'] as int? ??
                   (json['room'] != null ? json['room']['id'] as int? : null) ??
                   0;

    return Contract(
      id: json['id'] as int,
      roomId: roomId,
      hostId: hostId,
      guestId: guestId,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      totalDays: json['totalDays'] as int? ?? 0,
      totalWeeks: json['totalWeeks'] as int?,
      rentalFee: json['rentalFee'] as int? ?? 0,
      maintenanceFee: json['maintenanceFee'] as int? ?? 0,
      cleaningFee: json['cleaningFee'] as int? ?? 0,
      rentalItemsFee: json['rentalItemsFee'] as int? ?? 0,
      platformFee: json['platformFee'] as int? ?? 0,
      discountAmount: json['discountAmount'] as int? ?? 0,
      discountType: json['discountType'] != null ? DiscountType.fromString(json['discountType'] as String) : null,
      discountCode: json['discountCode'] as String?,
      subtotal: json['subtotal'] as int? ?? 0,
      totalUsageFee: json['totalUsageFee'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,
      finalTotalAmount: json['finalTotalAmount'] as int? ?? 0,
      rentalItems: json['rentalItems'] as Map<String, dynamic>?,
      paymentMethod: json['paymentMethod'] != null ? PaymentMethod.fromString(json['paymentMethod'] as String) : null,
      installmentMonths: json['installmentMonths'] as int? ?? 0,
      guestMessage: json['guestMessage'] as String?,
      hostMessage: json['hostMessage'] as String?,
      specialRequests: json['specialRequests'] as Map<String, dynamic>?,
      termsAgreed: (json['termsAgreed'] as Map<String, dynamic>?) ?? {},
      pricingSnapshot: json['pricingSnapshot'] as Map<String, dynamic>?,
      status: ContractStatus.fromString(json['status'] as String),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt'] as String) : null,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      checkedInAt: json['checkedInAt'] != null ? DateTime.parse(json['checkedInAt'] as String) : null,
      checkedOutAt: json['checkedOutAt'] != null ? DateTime.parse(json['checkedOutAt'] as String) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      room: json['room'] != null ? RoomInfo.fromJson(json['room'] as Map<String, dynamic>) : null,
      host: json['host'] != null ? UserInfo.fromJson(json['host'] as Map<String, dynamic>) : null,
      guest: json['guest'] != null ? UserInfo.fromJson(json['guest'] as Map<String, dynamic>) : null,
    );
  }
}

/// 방 정보 (계약에 포함된)
class RoomInfo {
  final int id;
  final String name;
  final String address;
  final double area;
  final String buildingType;
  final String? thumbnail;

  RoomInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.buildingType,
    this.thumbnail,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'] as int,
      name: json['roomName'] ?? json['name'] ?? '',
      address: json['address'] ?? '',
      area: double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      buildingType: json['buildingType'] ?? '',
      thumbnail: json['thumbnailUrl'] ?? json['thumbnail'],
    );
  }
}

/// 사용자 정보 (계약에 포함된)
class UserInfo {
  final int id;
  final String name;
  final String phone;
  final String? email;

  UserInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      name: json['name'] ?? '',
      phone: json['phoneNumber'] ?? json['phone'] ?? '',
      email: json['email'],
    );
  }
}
