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

/// 퇴실 상태
enum CheckoutStatus {
  notStarted('NOT_STARTED', '퇴실 전'),
  guestCompleted('GUEST_COMPLETED', '게스트 퇴실 완료'),
  hostConfirmed('HOST_CONFIRMED', '호스트 확인 완료'),
  hostPending('HOST_PENDING', '호스트 확인 보류');

  final String value;
  final String label;

  const CheckoutStatus(this.value, this.label);

  static CheckoutStatus? fromString(String? value) {
    if (value == null) return null;
    return CheckoutStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () {
        debugPrint('⚠️ [CHECKOUT_STATUS] Unknown status: $value, defaulting to notStarted');
        return CheckoutStatus.notStarted;
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
  virtualAccount('VIRTUAL_ACCOUNT', '가상계좌'),
  easyPay('EASY_PAY', '간편결제'),
  mobilePayment('MOBILE_PAYMENT', '휴대폰 결제');

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
  final String? contractNumber; // 계약번호 (승인 시 생성)
  final ContractStatus status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int totalDays;
  final int finalTotalAmount;
  final String? guestMessage; // 호스트용
  final String? rejectionReason; // 거절 사유
  final List<RentalItem>? rentalItems; // 옵션 상품

  // 금액 상세 정보 (호스트용 - 선택적)
  final int? rentalFee; // 임대료
  final int? maintenanceFee; // 관리비
  final int? cleaningFee; // 청소비
  final int? rentalItemsFee; // 렌탈 아이템 비용
  final int? platformFee; // 플랫폼 수수료
  final int? discountAmount; // 할인 금액
  final DiscountType? discountType; // 할인 유형
  final String? discountCode; // 할인 쿠폰 코드
  final int? subtotal; // 소계 (할인 전)
  final int? totalUsageFee; // 실이용 금액 (할인 후)
  final int? deposit; // 보증금
  final int? hostEarnings; // 호스트 실수령액 (NEW)
  final bool? isEzCleaning; // EZ청소 서비스 여부

  // 퇴실 정보
  final CheckoutStatus? checkoutStatus; // 퇴실 상태
  final String? roomCheckoutTime; // 퇴실 시간

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
  String get partnerDisplayName => (partnerNickname?.isNotEmpty == true) ? partnerNickname! : partnerName;

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
    this.rentalFee,
    this.maintenanceFee,
    this.cleaningFee,
    this.rentalItemsFee,
    this.platformFee,
    this.discountAmount,
    this.discountType,
    this.discountCode,
    this.subtotal,
    this.totalUsageFee,
    this.deposit,
    this.hostEarnings,
    this.isEzCleaning,
    this.checkoutStatus,
    this.roomCheckoutTime,
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
    final room = json['room'];
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
      // 금액 상세 정보 (호스트용 - 선택적)
      rentalFee: json['rentalFee'] as int?,
      maintenanceFee: json['maintenanceFee'] as int?,
      cleaningFee: json['cleaningFee'] as int?,
      rentalItemsFee: json['rentalItemsFee'] as int?,
      platformFee: json['platformFee'] as int?,
      discountAmount: json['discountAmount'] as int?,
      discountType: json['discountType'] != null
        ? DiscountType.fromString(json['discountType'] as String)
        : null,
      discountCode: json['discountCode'] as String?,
      subtotal: json['subtotal'] as int?,
      totalUsageFee: json['totalUsageFee'] as int?,
      deposit: json['deposit'] as int?,
      hostEarnings: json['hostEarnings'] as int?,
      isEzCleaning: json['isEzCleaning'] as bool?,
      // 퇴실 정보
      checkoutStatus: CheckoutStatus.fromString(json['checkoutStatus'] as String?),
      roomCheckoutTime: json['roomCheckoutTime'] as String?,
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
      partnerNickname: partner['nickname'],
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
      rentalItems: _parseRentalItems(json['rentalItems']),
      paymentMethod: json['paymentMethod'] != null ? PaymentMethod.fromString(json['paymentMethod'] as String) : null,
      installmentMonths: json['installmentMonths'] as int? ?? 0,
      guestMessage: json['guestMessage'] as String?,
      hostMessage: json['hostMessage'] as String?,
      specialRequests: json['specialRequests'] as Map<String, dynamic>?,
      termsAgreed: (json['termsAgreed'] as Map<String, dynamic>?) ?? {},
      pricingSnapshot: json['pricingSnapshot'] as Map<String, dynamic>?,
      status: ContractStatus.fromString(json['status'] as String),
      checkoutStatus: CheckoutStatus.fromString(json['checkoutStatus'] as String?),
      roomCheckoutTime: json['roomCheckoutTime'] as String?,
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
      deliveryStatus: DeliveryStatus.fromString(json['deliveryStatus'] ?? 'pending'),
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
          debugPrint('⚠️ [PARSE_ERROR] List item is not a Map: ${item.runtimeType} = $item');
        }
      }
      return items.isEmpty ? null : items;
    }

    // Map 형식인 경우
    if (rentalItemsJson is Map<String, dynamic>) {
      final items = <RentalItem>[];

      // ✅ 새로운 API 형식: { items: [...], totalPaid, totalRefunded, netAmount }
      if (rentalItemsJson.containsKey('items') && rentalItemsJson['items'] is List) {
        final itemsList = rentalItemsJson['items'] as List;
        debugPrint('✅ [PARSE_RENTAL_ITEMS] Found ${itemsList.length} items in new API format');

        for (final item in itemsList) {
          if (item is Map<String, dynamic>) {
            items.add(RentalItem.fromJson(item));
          } else {
            debugPrint('⚠️ [PARSE_ERROR] Item in items array is not a Map: ${item.runtimeType}');
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
            debugPrint('⚠️ [PARSE_NONSTANDARD] Detected ${itemType}Id = $value');
          }
          // {itemType}Quantity 형식 (예: beddingSetQuantity: 1)
          else if (key.endsWith('Quantity')) {
            final itemType = key.substring(0, key.length - 8); // 'Quantity' 제거
            itemMap[itemType] ??= {};
            itemMap[itemType]!['quantity'] = value;
            debugPrint('⚠️ [PARSE_NONSTANDARD] Detected ${itemType}Quantity = $value');
          }
          // 기타 int 값 (key를 id로 사용)
          else {
            debugPrint('⚠️ [PARSE_WARNING] Simplified format: $key = $value');
            items.add(RentalItem(
              id: key,
              name: '', // API에서 채워질 예정
              price: 0, // API에서 채워질 예정
              quantity: value,
              deliveryStatus: DeliveryStatus.pending,
            ));
          }
        }
        // totalPaid, totalRefunded, netAmount 등 메타데이터는 무시
        else if (key == 'totalPaid' || key == 'totalRefunded' || key == 'netAmount') {
          debugPrint('ℹ️ [PARSE_RENTAL_ITEMS] Skipping metadata field: $key = $value');
        }
        else {
          debugPrint('⚠️ [PARSE_ERROR] Map value is unexpected type: ${value.runtimeType} = $value');
        }
      }

      // itemMap에서 RentalItem 생성 (비표준 형식 처리)
      for (final entry in itemMap.entries) {
        final itemType = entry.key;
        final itemData = entry.value;

        if (itemData['id'] != null) {
          items.add(RentalItem(
            id: itemData['id'] as String,
            name: '', // API에서 채워질 예정
            price: 0, // API에서 채워질 예정
            quantity: itemData['quantity'] as int? ?? 1, // 기본값 1
            deliveryStatus: DeliveryStatus.pending,
          ));
          debugPrint('✅ [PARSE_NONSTANDARD] Created RentalItem: id=${itemData['id']}, quantity=${itemData['quantity'] ?? 1}, type=$itemType');
        }
      }

      return items.isEmpty ? null : items;
    }

    // 예상치 못한 형식
    debugPrint('⚠️ [PARSE_ERROR] Unexpected rentalItems format: ${rentalItemsJson.runtimeType}');
    debugPrint('⚠️ [PARSE_ERROR] Content: $rentalItemsJson');
    return null;
  } catch (e, stackTrace) {
    debugPrint('⚠️ [PARSE_ERROR] Failed to parse rentalItems: $e');
    debugPrint('⚠️ [PARSE_ERROR] Stack trace: $stackTrace');
    return null;
  }
}
