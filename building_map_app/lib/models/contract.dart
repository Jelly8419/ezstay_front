import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'promotion.dart';

/// 계약 상태 (백엔드 CONTRACT_STATUS 매핑)
enum ContractStatus {
  pendingApproval('PENDING_APPROVAL', '승인 대기'),
  approved('APPROVED', '결제 대기'),
  rejected('REJECTED', '승인 거절'),
  paymentCompleted('PAYMENT_COMPLETED', '결제 완료'),
  inProgress('IN_PROGRESS', '임대 중'),
  completed('COMPLETED', '계약 종료'),
  cancelledByGuest('CANCELLED_BY_GUEST', '계약 취소'),
  cancelledByHost('CANCELLED_BY_HOST', '계약 취소'),
  cancelledByAdminWithRefund('CANCELLED_BY_ADMIN_WITH_REFUND', '계약 취소'),
  cancelledByAdminNoRefund('CANCELLED_BY_ADMIN_NO_REFUND', '계약 취소'),
  refunded('REFUNDED', '계약 취소'),
  approvalExpired('APPROVAL_EXPIRED', '계약 취소'),
  paymentExpired('PAYMENT_EXPIRED', '계약 취소'),
  cancelRequested('CANCEL_REQUESTED', '취소 요청');

  final String value;
  final String label;

  const ContractStatus(this.value, this.label);

  static ContractStatus fromString(String value) {
    return ContractStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () {
        return ContractStatus.pendingApproval;
      },
    );
  }
}

/// 퇴실 상태
enum CheckoutStatus {
  notStarted('NOT_STARTED', '퇴실 전'),
  guestCompleted('GUEST_COMPLETED', '임차인 퇴실 완료'),
  hostConfirmed('HOST_CONFIRMED', '임대인 확인 완료'),
  hostPending('HOST_PENDING', '임대인 확인 보류'),
  agreementSubmitted('AGREEMENT_SUBMITTED', '합의 내용 제출'),
  holdRequested('HOLD_REQUESTED', '보증금 반환 보류 신청중'),
  holdRejected('HOLD_REJECTED', '보류 신청 반려'),
  autoReturned('AUTO_RETURNED', '보증금 전액 반환');

  final String value;
  final String label;

  const CheckoutStatus(this.value, this.label);

  static CheckoutStatus? fromString(String? value) {
    if (value == null) return null;
    return CheckoutStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () {
        return CheckoutStatus.notStarted;
      },
    );
  }
}

/// 보증금 프로세스 상태
///
/// 정책 7.4:
/// - HELD: 결제 완료 후 계약 진행 중 (보관중)
/// - RETURN_PENDING: 계약 종료 후, 퇴실 확인 전 (반환대기)
/// - RETURNED: 보증금 환불 실행 완료 (반환완료)
/// - RETURN_HOLD: 호스트 보류 신청 → 관리자 승인 후 합의 대기 (반환보류)
/// - DEDUCTION_CONFIRMED: 합의에 따라 차감 금액 확정 (차감확정)
/// - RETURN_CONFIRMED: 반환 금액 확정, 환불 실행 대상 (반환확정)
enum DepositStatus {
  held('HELD', '보관중'),
  returnPending('RETURN_PENDING', '반환대기'),
  returned('RETURNED', '반환완료'),
  returnHold('RETURN_HOLD', '반환보류'),
  deductionConfirmed('DEDUCTION_CONFIRMED', '차감확정'),
  returnConfirmed('RETURN_CONFIRMED', '반환확정');

  final String value;
  final String label;

  const DepositStatus(this.value, this.label);

  static DepositStatus? fromString(String? value) {
    if (value == null) return null;
    return DepositStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () {
        return DepositStatus.held;
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

/// 결제 수단 (PayTag PG 코드 기준)
enum PaymentMethod {
  // 주요 신용카드
  bc('BC', '비씨카드'),
  kb('KB', '국민카드'),
  sin('SIN', '신한카드'),
  ss('SS', '삼성카드'),
  hd('HD', '현대카드'),
  lt('LT', '롯데카드'),
  wr('WR', '우리카드'),
  hn('HN', '하나카드'),
  ka('KA', '카카오뱅크'),
  nh('NH', '농협카드'),
  sh('SH', '수협카드'),

  // 간편결제
  kakaoPay('KAKAO', '카카오페이'),
  naverPay('NAVER', '네이버페이'),
  payco('PAYCO', '페이코')
  // TODO: 오픈 후 가상계좌 추가 예정
  // virtualAccount('VBANK', '가상계좌'),
  ;

  final String value;
  final String label;

  const PaymentMethod(this.value, this.label);

  /// 신용카드 여부 (할부 가능)
  bool get isCreditCard => !isEasyPay;

  /// 간편결제 여부 (할부 불가)
  bool get isEasyPay => this == kakaoPay || this == naverPay || this == payco;

  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.bc,
    );
  }
}

/// 호스트 정산 상세 정보 (API hostSettlement 객체)
class HostSettlement {
  final int rentalFee;
  final int maintenanceFee;
  final int cleaningFee;
  final int discountAmount;
  final int hostPlatformFee;
  final int hostEarnings;

  const HostSettlement({
    required this.rentalFee,
    required this.maintenanceFee,
    required this.cleaningFee,
    required this.discountAmount,
    required this.hostPlatformFee,
    required this.hostEarnings,
  });

  factory HostSettlement.fromJson(Map<String, dynamic> json) {
    return HostSettlement(
      rentalFee: json['rentalFee'] as int? ?? 0,
      maintenanceFee: json['maintenanceFee'] as int? ?? 0,
      cleaningFee: json['cleaningFee'] as int? ?? 0,
      discountAmount: json['discountAmount'] as int? ?? 0,
      hostPlatformFee: json['hostPlatformFee'] as int? ?? 0,
      hostEarnings: json['hostEarnings'] as int? ?? 0,
    );
  }
}

/// 계약 목록 아이템 (간단한 정보)
class ContractListItem {
  final int id;
  final String? contractNumber; // 계약번호 (승인 시 생성)
  final ContractStatus status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int totalDays;
  final int finalTotalAmount;
  final String? guestMessage; // 호스트용
  final String? rejectionReason; // 거절 사유
  final List<RentalItem>? rentalItems; // 옵션 상품
  final RecommendedItemsInfo? recommendedItems; // 호스트 권장 상품 (APPROVED 상태에서 제공)

  // 금액 상세 정보 (호스트용 - 선택적)
  final int? rentalFee; // 임대료
  final int? maintenanceFee; // 관리비
  final int? cleaningFee; // 청소비
  final int? rentalItemsFee; // 렌탈 아이템 비용
  final int? platformFee; // 플랫폼 수수료 (할인 후, DB 저장값)
  final int? platformFeeOriginal; // 원본 수수료 (platformFee + ACTIVE benefits 합)
  final int? platformFeeDiscount; // 수수료 할인액 (ACTIVE benefits 합)
  final List<AppliedPromotion> appliedPromotions; // 적용된 프로모션 (ACTIVE만)
  final int? discountAmount; // 할인 금액
  final DiscountType? discountType; // 할인 유형
  final String? discountCode; // 할인 쿠폰 코드
  final int? subtotal; // 소계 (할인 전)
  final int? totalUsageFee; // 실이용 금액 (할인 후)
  final int? deposit; // 보증금
  final HostSettlement? hostSettlement; // 호스트 정산 상세 (API 제공)
  final bool? isEzCleaning; // EZ청소 서비스 여부

  // 퇴실 정보
  final CheckoutStatus? checkoutStatus; // 퇴실 상태
  final String? checkoutStatusLabel; // 퇴실 상태 라벨 (서버 제공)
  final String? roomCheckoutTime; // 퇴실 시간
  final bool? checkoutRequested; // 퇴실 요청 여부
  final bool? hostCheckedOut; // 호스트 퇴실 확인 여부
  final DepositStatus? depositStatus; // 보증금 프로세스 상태 (정책 7.4)
  final String?
  agreementDeadline; // 합의 데드라인 ISO8601 (정책 7.9.1: 관리자 승인 시점 + 10일)
  final bool? cancellationRequested; // 취소 요청 여부 (1회 제한)
  final String?
  depositAgreementStatus; // 합의 상태 (null | REQUESTED | APPROVED | REJECTED | SUBMITTED | ACCEPTED | AUTO_RETURNED)
  final String? holdRejectedReason; // 보류 신청 반려 사유 (checkoutStatus == HOLD_REJECTED일 때)

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
  final String? partnerNickname;
  final String partnerPhone;
  final String? partnerEmail; // 호스트용에만 포함

  final DateTime createdAt;

  /// 상대방 표시명 (닉네임 우선, 없으면 이름)
  String get partnerDisplayName =>
      (partnerNickname?.isNotEmpty == true) ? partnerNickname! : partnerName;

  ContractListItem({
    required this.id,
    this.contractNumber,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalDays,
    required this.finalTotalAmount,
    this.guestMessage,
    this.rejectionReason,
    this.rentalItems,
    this.recommendedItems,
    this.rentalFee,
    this.maintenanceFee,
    this.cleaningFee,
    this.rentalItemsFee,
    this.platformFee,
    this.platformFeeOriginal,
    this.platformFeeDiscount,
    this.appliedPromotions = const [],
    this.discountAmount,
    this.discountType,
    this.discountCode,
    this.subtotal,
    this.totalUsageFee,
    this.deposit,
    this.hostSettlement,
    this.isEzCleaning,
    this.checkoutStatus,
    this.checkoutStatusLabel,
    this.roomCheckoutTime,
    this.checkoutRequested,
    this.hostCheckedOut,
    this.depositStatus,
    this.agreementDeadline,
    this.cancellationRequested,
    this.depositAgreementStatus,
    this.holdRejectedReason,
    required this.roomId,
    required this.roomName,
    required this.roomAddress,
    required this.roomArea,
    required this.buildingType,
    this.roomThumbnail,
    required this.partnerId,
    required this.partnerName,
    this.partnerNickname,
    required this.partnerPhone,
    this.partnerEmail,
    required this.createdAt,
  });

  factory ContractListItem.fromJson(Map<String, dynamic> json) {
    // 백엔드는 room과 guest(호스트용) 또는 host(게스트용) 정보를 포함
    // Breaking Change: roomSnapshot → snapshot, room fallback 유지
    final room = json['snapshot'] ?? json['room'];
    final partner = json['guest'] ?? json['host']; // 호스트용은 guest, 게스트용은 host

    return ContractListItem(
      id: json['id'],
      contractNumber: json['contractNumber'],
      status: ContractStatus.fromString(json['status']),
      checkInDate: DateTime.parse(json['checkInDate']),
      checkOutDate: DateTime.parse(json['checkOutDate']),
      totalDays: json['totalDays'],
      finalTotalAmount: json['finalTotalAmount'],
      guestMessage: json['guestMessage'],
      rejectionReason: json['rejectionReason'],
      rentalItems: _parseRentalItems(json['rentalItems']),
      recommendedItems: json['recommendedItems'] != null
          ? RecommendedItemsInfo.fromJson(json['recommendedItems'] as Map<String, dynamic>)
          : null,
      // 금액 상세 정보 (호스트용 - 선택적)
      rentalFee: json['rentalFee'] as int?,
      maintenanceFee: json['maintenanceFee'] as int?,
      cleaningFee: json['cleaningFee'] as int?,
      rentalItemsFee: json['rentalItemsFee'] as int?,
      platformFee: json['platformFee'] as int?,
      platformFeeOriginal: json['platformFeeOriginal'] as int?,
      platformFeeDiscount: json['platformFeeDiscount'] as int?,
      appliedPromotions: parsePromotionList<AppliedPromotion>(
        json['appliedPromotions'],
        AppliedPromotion.fromJson,
      ),
      discountAmount: json['discountAmount'] as int?,
      discountType: json['discountType'] != null
          ? DiscountType.fromString(json['discountType'] as String)
          : null,
      discountCode: json['discountCode'] as String?,
      subtotal: json['subtotal'] as int?,
      totalUsageFee: json['totalUsageFee'] as int?,
      deposit: json['deposit'] as int?,
      hostSettlement: json['hostSettlement'] != null
          ? HostSettlement.fromJson(json['hostSettlement'] as Map<String, dynamic>)
          : null,
      isEzCleaning: json['isEzCleaning'] as bool?,
      // 퇴실 정보
      checkoutStatus: CheckoutStatus.fromString(
        json['checkoutStatus'] as String?,
      ),
      checkoutStatusLabel: json['checkoutStatusLabel'] as String?,
      roomCheckoutTime: json['roomCheckoutTime'] as String?,
      checkoutRequested: json['checkoutRequested'] as bool?,
      hostCheckedOut: json['hostCheckedOut'] as bool?,
      depositStatus: DepositStatus.fromString(json['depositStatus'] as String?),
      agreementDeadline: json['agreementDeadline'] as String?,
      cancellationRequested: json['cancellationRequested'] as bool?,
      depositAgreementStatus: json['depositAgreementStatus'] as String?,
      holdRejectedReason: json['holdRejectedReason'] as String?,
      // 방 정보 - 백엔드 필드명: roomName, thumbnailUrl
      roomId: room?['id'] as int? ?? 0,
      roomName: room?['roomName'] ?? room?['name'] ?? '',
      roomAddress: room?['address'] ?? '',
      roomArea: double.parse((room?['area'] ?? 0).toString()),
      buildingType: room?['buildingType'] ?? '',
      roomThumbnail: room?['thumbnailUrl'] ?? room?['thumbnail'],
      // 상대방 정보 - 백엔드 필드명: phoneNumber
      partnerId: partner?['id'] as int? ?? 0,
      partnerName: partner?['name'] ?? '',
      partnerNickname: partner?['nickname'] as String?,
      partnerPhone: partner?['phoneNumber'] ?? partner?['phone'] ?? '',
      partnerEmail: partner?['email'] as String?,
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
  final int? platformFeeOriginal;
  final int? platformFeeDiscount;
  final List<AppliedPromotion> appliedPromotions;
  final int discountAmount;
  final DiscountType? discountType;
  final String? discountCode;
  final int subtotal;
  final int totalUsageFee;
  final int deposit;
  final int finalTotalAmount;

  // 렌탈 아이템 정보
  final List<RentalItem>? rentalItems;

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

  // 환불 정책 및 EZ서비스
  final String refundPolicy; // 'flexible' | 'moderate' | 'strict'
  final bool isEzCleaning; // EZ청소 서비스 여부

  // 퇴실 정보
  final CheckoutStatus? checkoutStatus;
  final String? roomCheckoutTime;

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
    this.platformFeeOriginal,
    this.platformFeeDiscount,
    this.appliedPromotions = const [],
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
    this.refundPolicy = 'moderate',
    this.isEzCleaning = false,
    this.checkoutStatus,
    this.roomCheckoutTime,
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
    final hostId =
        json['hostId'] as int? ??
        (json['host'] != null ? json['host']['id'] as int? : null) ??
        0;
    final guestId =
        json['guestId'] as int? ??
        (json['guest'] != null ? json['guest']['id'] as int? : null) ??
        0;
    final roomData = json['snapshot'] ?? json['room'];
    final roomId =
        json['roomId'] as int? ??
        (roomData != null ? roomData['id'] as int? : null) ??
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
      platformFeeOriginal: json['platformFeeOriginal'] as int?,
      platformFeeDiscount: json['platformFeeDiscount'] as int?,
      appliedPromotions: parsePromotionList<AppliedPromotion>(
        json['appliedPromotions'],
        AppliedPromotion.fromJson,
      ),
      discountAmount: json['discountAmount'] as int? ?? 0,
      discountType: json['discountType'] != null
          ? DiscountType.fromString(json['discountType'] as String)
          : null,
      discountCode: json['discountCode'] as String?,
      subtotal: json['subtotal'] as int? ?? 0,
      totalUsageFee: json['totalUsageFee'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,
      finalTotalAmount: json['finalTotalAmount'] as int? ?? 0,
      rentalItems: _parseRentalItems(json['rentalItems']),
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromString(json['paymentMethod'] as String)
          : null,
      installmentMonths: json['installmentMonths'] as int? ?? 0,
      guestMessage: json['guestMessage'] as String?,
      hostMessage: json['hostMessage'] as String?,
      specialRequests: json['specialRequests'] as Map<String, dynamic>?,
      termsAgreed: (json['termsAgreed'] as Map<String, dynamic>?) ?? {},
      pricingSnapshot: json['pricingSnapshot'] as Map<String, dynamic>?,
      status: ContractStatus.fromString(json['status'] as String),
      refundPolicy: json['refundPolicy'] as String? ?? 'moderate',
      isEzCleaning: json['isEzCleaning'] as bool? ?? false,
      checkoutStatus: CheckoutStatus.fromString(
        json['checkoutStatus'] as String?,
      ),
      roomCheckoutTime: json['roomCheckoutTime'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      checkedOutAt: json['checkedOutAt'] != null
          ? DateTime.parse(json['checkedOutAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      room: roomData != null
          ? RoomInfo.fromJson(roomData as Map<String, dynamic>)
          : null,
      host: json['host'] != null
          ? UserInfo.fromJson(json['host'] as Map<String, dynamic>)
          : null,
      guest: json['guest'] != null
          ? UserInfo.fromJson(json['guest'] as Map<String, dynamic>)
          : null,
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
  final String? nickname;
  final String phone;
  final String? email;

  UserInfo({
    required this.id,
    required this.name,
    this.nickname,
    required this.phone,
    this.email,
  });

  /// 표시용 이름 (닉네임 우선, 없으면 이름)
  String get displayName => (nickname?.isNotEmpty == true) ? nickname! : name;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      name: json['name'] ?? '',
      nickname: json['nickname'],
      phone: json['phoneNumber'] ?? json['phone'] ?? '',
      email: json['email'],
    );
  }
}

/// 배송 상태
enum DeliveryStatus {
  pending('PENDING', '배송 전'),
  inTransit('IN_TRANSIT', '배송중'),
  delivered('DELIVERED', '배송 완료');

  final String value;
  final String label;

  const DeliveryStatus(this.value, this.label);

  static DeliveryStatus fromString(String value) {
    return DeliveryStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DeliveryStatus.pending,
    );
  }
}

/// 렌탈 아이템 (옵션 상품)
class RentalItem {
  final String id;
  final String name;
  final String? description;
  final int price;
  final int quantity;
  final DeliveryStatus deliveryStatus;
  final int? rentalOrderId; // 렌탈 주문 ID (결제 후 취소 시 필요)

  RentalItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    required this.deliveryStatus,
    this.rentalOrderId,
  });

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    // API 응답에서 id 필드명이 다를 수 있음: id, itemId
    // /api/contracts/guest 응답: { "itemId": 3, "quantity": 1 }
    // /api/rental-items 응답: { "id": 3, "name": "...", "price": "..." }
    final id = json['id']?.toString() ?? json['itemId']?.toString() ?? '';

    // API 응답에서 price 필드명이 다를 수 있음: price, pricePerItem, totalPrice
    int price = 0;
    if (json['price'] != null) {
      price = _parsePrice(json['price']);
    } else if (json['pricePerItem'] != null) {
      price = _parsePrice(json['pricePerItem']);
    }

    return RentalItem(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      price: price,
      quantity: json['quantity'] as int? ?? 0,
      deliveryStatus: DeliveryStatus.fromString(
        json['deliveryStatus'] ?? 'pending',
      ),
      rentalOrderId: json['rentalOrderId'] as int?,
    );
  }

  /// 가격 파싱 헬퍼 (int, double, String 모두 처리)
  static int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return double.parse(value).toInt();
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'deliveryStatus': deliveryStatus.value,
      'rentalOrderId': rentalOrderId,
    };
  }

  /// 수량 변경된 복사본 생성
  RentalItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    int? quantity,
    DeliveryStatus? deliveryStatus,
    int? rentalOrderId,
  }) {
    return RentalItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      rentalOrderId: rentalOrderId ?? this.rentalOrderId,
    );
  }
}

/// 호스트가 권장한 옵션 상품 정보 (APPROVED 상태에서 제공)
class RecommendedItemsInfo {
  final List<RecommendedItem> items;
  final int recommendedBy;
  final DateTime recommendedAt;

  RecommendedItemsInfo({
    required this.items,
    required this.recommendedBy,
    required this.recommendedAt,
  });

  factory RecommendedItemsInfo.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List? ?? [])
        .map((e) => RecommendedItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecommendedItemsInfo(
      items: itemsList,
      recommendedBy: json['recommendedBy'] as int,
      recommendedAt: DateTime.parse(json['recommendedAt'] as String),
    );
  }
}

class RecommendedItem {
  final int itemId;
  final String name;
  final int price;

  RecommendedItem({
    required this.itemId,
    required this.name,
    required this.price,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    int price = 0;
    final raw = json['price'];
    if (raw is int) price = raw;
    else if (raw is double) price = raw.toInt();
    else if (raw is String) price = double.tryParse(raw)?.toInt() ?? 0;
    return RecommendedItem(
      itemId: json['itemId'] as int,
      name: json['name'] as String,
      price: price,
    );
  }
}

/// 사용 가능한 옵션 상품
class AvailableOption {
  final String id;
  final String name;
  final String description;
  final int price;
  final int maxQuantity;

  AvailableOption({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.maxQuantity,
  });

  /// 기본 옵션 목록
  static final List<AvailableOption> defaultOptions = [
    AvailableOption(
      id: '1',
      name: '침구류 대여',
      description: '침대 1set당 (이불+베개+침대커버)',
      price: 25000,
      maxQuantity: 4,
    ),
    AvailableOption(
      id: '2',
      name: '어메니티 키트',
      description: '샴푸(30mlx2개)·바디워시(30ml)·폼클렌징(50ml)·비누·빗·두루마리 휴지(1개)·물티슈(1팩)',
      price: 5000,
      maxQuantity: 4,
    ),
    AvailableOption(
      id: '3',
      name: '헤어드라이기 대여',
      description: '',
      price: 2000,
      maxQuantity: 4,
    ),
    AvailableOption(
      id: '4',
      name: '수건 세트',
      description: '대형 수건 2개, 소형 수건 2개',
      price: 10000,
      maxQuantity: 4,
    ),
  ];
}

/// 옵션 변경 추적
class OptionChange {
  final String itemId;
  final String itemName;
  final int originalQuantity;
  final int newQuantity;
  final int pricePerUnit;

  OptionChange({
    required this.itemId,
    required this.itemName,
    required this.originalQuantity,
    required this.newQuantity,
    required this.pricePerUnit,
  });

  /// 수량 차이
  int get quantityDiff => newQuantity - originalQuantity;

  /// 가격 차이
  int get priceDiff => quantityDiff * pricePerUnit;
}

/// rentalItems JSON 파싱 헬퍼 (Map 또는 List 형식 모두 처리)
///
/// 백엔드 API 응답 형식:
/// ```json
/// "rentalItems": {
///   "totalPaid": 0,
///   "totalRefunded": 0,
///   "netAmount": 0,
///   "items": [
///     { "name": "헤어드라이기 대여", "quantity": 1, "pricePerItem": 10000, "totalPrice": 10000, "imageUrl": null }
///   ]
/// }
/// ```
List<RentalItem>? _parseRentalItems(dynamic rentalItemsJson) {
  if (rentalItemsJson == null) return null;

  try {
    // List 형식인 경우 (직접 아이템 배열)
    if (rentalItemsJson is List) {
      final items = <RentalItem>[];
      for (final item in rentalItemsJson) {
        if (item is Map<String, dynamic>) {
          items.add(RentalItem.fromJson(item));
        } else {
        }
      }
      return items.isEmpty ? null : items;
    }

    // Map 형식인 경우
    if (rentalItemsJson is Map<String, dynamic>) {
      final items = <RentalItem>[];

      // ✅ 새로운 API 형식: { items: [...], totalPaid, totalRefunded, netAmount }
      if (rentalItemsJson.containsKey('items') &&
          rentalItemsJson['items'] is List) {
        final itemsList = rentalItemsJson['items'] as List;

        for (final item in itemsList) {
          if (item is Map<String, dynamic>) {
            items.add(RentalItem.fromJson(item));
          } else {
          }
        }
        return items.isEmpty ? null : items;
      }

      // 이전 형식: Map의 values를 직접 순회
      final itemMap = <String, Map<String, dynamic>>{}; // 아이템별 데이터 임시 저장

      for (final entry in rentalItemsJson.entries) {
        final key = entry.key;
        final value = entry.value;

        // value가 Map인 경우 - 정상적인 RentalItem 객체
        if (value is Map<String, dynamic>) {
          items.add(RentalItem.fromJson(value));
        }
        // 비표준 형식: {itemType}Id: {id}, {itemType}Quantity: {quantity}
        else if (value is int) {
          // {itemType}Id 형식 (예: hairDryerId: 3)
          if (key.endsWith('Id')) {
            final itemType = key.substring(0, key.length - 2); // 'Id' 제거
            itemMap[itemType] ??= {};
            itemMap[itemType]!['id'] = value.toString();
          }
          // {itemType}Quantity 형식 (예: beddingSetQuantity: 1)
          else if (key.endsWith('Quantity')) {
            final itemType = key.substring(0, key.length - 8); // 'Quantity' 제거
            itemMap[itemType] ??= {};
            itemMap[itemType]!['quantity'] = value;
          }
          // 기타 int 값 (key를 id로 사용)
          else {
            AppLogger.w('⚠️ [PARSE_WARNING] Simplified format: $key = $value');
            items.add(
              RentalItem(
                id: key,
                name: '', // API에서 채워질 예정
                price: 0, // API에서 채워질 예정
                quantity: value,
                deliveryStatus: DeliveryStatus.pending,
              ),
            );
          }
        }
        // totalPaid, totalRefunded, netAmount 등 메타데이터는 무시
        else if (key == 'totalPaid' ||
            key == 'totalRefunded' ||
            key == 'netAmount') {
        } else {
        }
      }

      // itemMap에서 RentalItem 생성 (비표준 형식 처리)
      for (final entry in itemMap.entries) {
        final itemType = entry.key;
        final itemData = entry.value;

        if (itemData['id'] != null) {
          items.add(
            RentalItem(
              id: itemData['id'] as String,
              name: '', // API에서 채워질 예정
              price: 0, // API에서 채워질 예정
              quantity: itemData['quantity'] as int? ?? 1, // 기본값 1
              deliveryStatus: DeliveryStatus.pending,
            ),
          );
        }
      }

      return items.isEmpty ? null : items;
    }

    // String 형식인 경우 (JSON string으로 저장된 경우)
    if (rentalItemsJson is String) {
      try {
        final decoded = json.decode(rentalItemsJson);
        if (decoded is List) {
          return _parseRentalItems(decoded);
        }
      } catch (_) {
      }
      return null;
    }

    // 예상치 못한 형식
    AppLogger.w('⚠️ [PARSE_ERROR] Content: $rentalItemsJson');
    return null;
  } catch (e, stackTrace) {
    AppLogger.w('⚠️ [PARSE_ERROR] Failed to parse rentalItems: $e');
    AppLogger.w('⚠️ [PARSE_ERROR] Stack trace: $stackTrace');
    return null;
  }
}
