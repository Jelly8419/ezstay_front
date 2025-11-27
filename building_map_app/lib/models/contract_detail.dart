import 'payment_history.dart';

/// 계약 상세 정보 모델 (상세 페이지용)
class ContractDetail {
  // 기본 정보
  final int id;
  final String? orderId; // 계약 주문번호 (결제 시스템에서 발급)
  final int roomId;
  final String roomName;
  final String roomPhoto;
  final String address;
  final String detailAddress;
  final String floor;

  // 날짜 정보
  final String checkInDate;
  final String checkOutDate;
  final int totalDays;

  // 금액 정보
  final int rentalFee; // 임대료
  final int maintenanceFee; // 관리비
  final int cleaningFee; // 청소비
  final int deposit; // 보증금
  final int rentalItemsFee; // 옵션 상품 총액
  final int platformFee; // 플랫폼 수수료
  final int finalTotalAmount; // 최종 총액

  // 상태 정보
  final String status;
  final String? paidAt;

  // 환불 정책
  final String refundPolicy; // 'flexible' | 'moderate' | 'strict'
  final String refundPolicyDetail;
  final RefundPolicySnapshot? refundPolicySnapshot; // 환불 정책 스냅샷

  // 렌탈 아이템
  final List<ContractRentalItem> rentalItems;

  // 결제 내역
  final List<PaymentHistory> paymentHistory;

  // 당사자 정보
  final String hostName;
  final String? hostProfileImage;
  final String? hostPhoneNumber;
  final String guestName;
  final String guestPhone;
  final String? guestMessage; // 게스트 메시지

  // 기타
  final bool isEzCleaning;

  const ContractDetail({
    required this.id,
    this.orderId,
    required this.roomId,
    required this.roomName,
    required this.roomPhoto,
    required this.address,
    required this.detailAddress,
    required this.floor,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalDays,
    required this.rentalFee,
    required this.maintenanceFee,
    required this.cleaningFee,
    required this.deposit,
    required this.rentalItemsFee,
    required this.platformFee,
    required this.finalTotalAmount,
    required this.status,
    this.paidAt,
    required this.refundPolicy,
    required this.refundPolicyDetail,
    this.refundPolicySnapshot,
    required this.rentalItems,
    required this.paymentHistory,
    required this.hostName,
    this.hostProfileImage,
    this.hostPhoneNumber,
    required this.guestName,
    required this.guestPhone,
    this.guestMessage,
    required this.isEzCleaning,
  });

  factory ContractDetail.fromJson(Map<String, dynamic> json) {
    // String 필드 안전 파싱 헬퍼 함수 (맨 위로 이동)
    String parseStringField(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map) {
        // Map인 경우 첫 번째 값을 시도
        return value.values.firstOrNull?.toString() ?? defaultValue;
      }
      return value.toString();
    }

    // 날짜 필드 안전 파싱 헬퍼 함수
    String parseDateField(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        // DateTime 객체일 경우 ISO 8601 문자열로 변환
        return value.toString();
      }
      return value.toString();
    }

    // nested room 객체 파싱
    final room = json['room'] as Map<String, dynamic>?;
    final roomPhotos = room?['photos'] as List<dynamic>?;

    // 첫 번째 사진 안전하게 추출 (photo 객체에서 url 필드 추출)
    String firstPhoto = '';
    if (roomPhotos != null && roomPhotos.isNotEmpty) {
      final photo = roomPhotos[0];
      if (photo is Map<String, dynamic>) {
        firstPhoto = photo['url'] as String? ?? '';
      } else if (photo is String) {
        firstPhoto = photo;
      }
    }

    // nested host 객체 파싱
    final host = json['host'] as Map<String, dynamic>?;

    // nested guest 객체 파싱
    final guest = json['guest'] as Map<String, dynamic>?;

    // rentalItems 파싱 (recommendedItems.items 우선 사용)
    List<ContractRentalItem> parsedRentalItems = [];

    // 1. recommendedItems.items 확인 (완전한 정보 포함)
    final recommendedItemsData = json['recommendedItems'];
    if (recommendedItemsData is Map && recommendedItemsData['items'] is List) {
      final itemsList = recommendedItemsData['items'] as List;
      parsedRentalItems = itemsList
          .map((e) => ContractRentalItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // 2. rentalItems 사용 (간소화된 정보)
      final rentalItemsData = json['rentalItems'];
      if (rentalItemsData is List) {
        parsedRentalItems = rentalItemsData
            .map((e) => ContractRentalItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return ContractDetail(
      id: json['id'] as int,
      orderId: json['orderId'] as String?,
      // room 정보 (nested 구조)
      roomId: room?['id'] as int? ?? 0,
      roomName: parseStringField(room?['roomName'], ''),
      roomPhoto: firstPhoto,
      address: parseStringField(room?['address'], ''),
      detailAddress: parseStringField(room?['detailAddress'], ''),
      floor: parseStringField(room?['floor'], ''),
      // 날짜 정보 (안전 파싱)
      checkInDate: parseDateField(json['checkInDate']),
      checkOutDate: parseDateField(json['checkOutDate']),
      totalDays: json['totalDays'] as int,
      // 금액 정보
      rentalFee: json['rentalFee'] as int,
      maintenanceFee: json['maintenanceFee'] as int,
      cleaningFee: json['cleaningFee'] as int,
      deposit: json['deposit'] as int? ?? 300000,
      rentalItemsFee: json['rentalItemsFee'] as int? ?? 0,
      platformFee: json['platformFee'] as int,
      finalTotalAmount: json['finalTotalAmount'] as int,
      // 상태 정보
      status: parseStringField(json['status'], 'PENDING'),
      paidAt: json['paidAt'] != null ? parseDateField(json['paidAt']) : null,
      // 환불 정책
      refundPolicy: parseStringField(json['refundPolicy'], 'moderate'),
      refundPolicyDetail: parseStringField(json['refundPolicyDetail'], ''),
      refundPolicySnapshot: json['refundPolicySnapshot'] != null
          ? RefundPolicySnapshot.fromJson(
              json['refundPolicySnapshot'] as Map<String, dynamic>,
            )
          : null,
      // 렌탈 아이템 (파싱된 결과)
      rentalItems: parsedRentalItems,
      // 결제 내역
      paymentHistory:
          (json['paymentHistory'] as List<dynamic>?)
              ?.map((e) => PaymentHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      // 호스트 정보 (nested 구조, 안전 파싱)
      hostName: parseStringField(host?['name'], ''),
      hostProfileImage: host?['profileImage'] != null
          ? parseStringField(host?['profileImage'])
          : null,
      hostPhoneNumber: host?['phoneNumber'] != null
          ? parseStringField(host?['phoneNumber'])
          : null,
      // 게스트 정보 (nested 구조, 안전 파싱)
      guestName: parseStringField(guest?['name'], ''),
      guestPhone: parseStringField(guest?['phoneNumber'], ''),
      guestMessage: json['guestMessage'] as String?,
      // 기타
      isEzCleaning: json['isEzCleaning'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (orderId != null) 'orderId': orderId,
      'roomId': roomId,
      'roomName': roomName,
      'roomPhoto': roomPhoto,
      'address': address,
      'detailAddress': detailAddress,
      'floor': floor,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'totalDays': totalDays,
      'rentalFee': rentalFee,
      'maintenanceFee': maintenanceFee,
      'cleaningFee': cleaningFee,
      'deposit': deposit,
      'rentalItemsFee': rentalItemsFee,
      'platformFee': platformFee,
      'finalTotalAmount': finalTotalAmount,
      'status': status,
      if (paidAt != null) 'paidAt': paidAt,
      'refundPolicy': refundPolicy,
      'refundPolicyDetail': refundPolicyDetail,
      'rentalItems': rentalItems.map((e) => e.toJson()).toList(),
      'paymentHistory': paymentHistory.map((e) => e.toJson()).toList(),
      'hostName': hostName,
      if (hostProfileImage != null) 'hostProfileImage': hostProfileImage,
      if (hostPhoneNumber != null) 'hostPhoneNumber': hostPhoneNumber,
      'guestName': guestName,
      'guestPhone': guestPhone,
      if (guestMessage != null) 'guestMessage': guestMessage,
      'isEzCleaning': isEzCleaning,
    };
  }
}

/// 계약 상세의 렌탈 아이템 (배송 상태 포함)
class ContractRentalItem {
  final int id;
  final String name;
  final String? description;
  final int price;
  final int quantity;
  final String? imageUrl;
  final String? deliveryStatus; // 'PENDING' | 'IN_DELIVERY' | 'DELIVERED'

  const ContractRentalItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.deliveryStatus,
  });

  factory ContractRentalItem.fromJson(Map<String, dynamic> json) {
    // itemId 또는 id 필드 안전 파싱
    final int itemId = json['itemId'] as int? ?? json['id'] as int? ?? 0;

    // name 필드 안전 파싱
    final String itemName = json['name'] as String? ?? '';

    // price 필드 안전 파싱 (String 또는 int 처리)
    int itemPrice = 0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        itemPrice = int.tryParse(json['price']) ??
                   double.tryParse(json['price'])?.toInt() ?? 0;
      } else if (json['price'] is num) {
        itemPrice = (json['price'] as num).toInt();
      }
    }

    return ContractRentalItem(
      id: itemId,
      name: itemName,
      description: json['description'] as String?,
      price: itemPrice,
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['imageUrl'] as String?,
      deliveryStatus: json['deliveryStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (deliveryStatus != null) 'deliveryStatus': deliveryStatus,
    };
  }

  /// 아이템 총 금액
  int get totalPrice => price * quantity;
}

/// 환불 정책 스냅샷 (계약 시점의 환불 정책)
class RefundPolicySnapshot {
  final String policyType;
  final String displayName;
  final String? description;
  final List<RefundPolicyRule> rules;
  final RefundSpecialRules? specialRules;
  final String? capturedAt;

  const RefundPolicySnapshot({
    required this.policyType,
    required this.displayName,
    this.description,
    required this.rules,
    this.specialRules,
    this.capturedAt,
  });

  factory RefundPolicySnapshot.fromJson(Map<String, dynamic> json) {
    return RefundPolicySnapshot(
      policyType: json['policyType'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String?,
      rules:
          (json['rules'] as List<dynamic>?)
              ?.map((e) => RefundPolicyRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      specialRules: json['specialRules'] != null
          ? RefundSpecialRules.fromJson(
              json['specialRules'] as Map<String, dynamic>,
            )
          : null,
      capturedAt: json['capturedAt'] as String?,
    );
  }
}

/// 환불 정책 규칙
class RefundPolicyRule {
  final int? daysBeforeMin;
  final int? daysBeforeMax;
  final int refundRate;
  final bool isSameDayCancellation;
  final String description;

  const RefundPolicyRule({
    this.daysBeforeMin,
    this.daysBeforeMax,
    required this.refundRate,
    required this.isSameDayCancellation,
    required this.description,
  });

  factory RefundPolicyRule.fromJson(Map<String, dynamic> json) {
    return RefundPolicyRule(
      daysBeforeMin: json['daysBeforeMin'] as int?,
      daysBeforeMax: json['daysBeforeMax'] as int?,
      refundRate: json['refundRate'] as int? ?? 0,
      isSameDayCancellation: json['isSameDayCancellation'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }
}

/// 환불 특별 규칙
class RefundSpecialRules {
  final RefundAlwaysRefund? alwaysRefund;

  const RefundSpecialRules({this.alwaysRefund});

  factory RefundSpecialRules.fromJson(Map<String, dynamic> json) {
    return RefundSpecialRules(
      alwaysRefund: json['alwaysRefund'] != null
          ? RefundAlwaysRefund.fromJson(
              json['alwaysRefund'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// 항상 환불되는 항목
class RefundAlwaysRefund {
  final bool cleaningFee;
  final bool maintenanceFee;

  const RefundAlwaysRefund({
    required this.cleaningFee,
    required this.maintenanceFee,
  });

  factory RefundAlwaysRefund.fromJson(Map<String, dynamic> json) {
    return RefundAlwaysRefund(
      cleaningFee: json['cleaningFee'] as bool? ?? false,
      maintenanceFee: json['maintenanceFee'] as bool? ?? false,
    );
  }

  /// 표시용 텍스트 생성
  String get displayText {
    final items = <String>[];
    if (cleaningFee) items.add('청소비');
    if (maintenanceFee) items.add('관리비');
    if (items.isEmpty) return '';
    return '${items.join(', ')}는 전액 환불됩니다.';
  }
}
