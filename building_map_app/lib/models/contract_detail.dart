import 'dart:convert';
import '../constants/fee_constants.dart';
import 'contract.dart';
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
  final String? hostNickname;
  final String? hostProfileImage;
  final String? hostPhoneNumber;
  final String guestName;
  final String? guestNickname;
  final String guestPhone;
  final String? guestMessage; // 게스트 메시지

  /// 호스트 표시명 (닉네임 우선, 없으면 이름)
  String get hostDisplayName => (hostNickname?.isNotEmpty == true) ? hostNickname! : hostName;

  /// 게스트 표시명 (닉네임 우선, 없으면 이름)
  String get guestDisplayName => (guestNickname?.isNotEmpty == true) ? guestNickname! : guestName;

  // 시간 정보 (계약 생명주기)
  final String? requestedAt;
  final String? approvedAt;
  final String createdAt;

  // 퇴실 확인 정보
  final String? guestCheckoutConfirmedAt;
  final String? hostCheckoutConfirmedAt;
  final DepositStatus? depositStatus;

  // 퇴실 상세 정보 (API v2)
  final String? checkoutStatus; // 퇴실 세부 상태 (NOT_STARTED, GUEST_COMPLETED, HOST_CONFIRMED, HOST_PENDING, AGREEMENT_SUBMITTED)
  final String? checkoutStatusLabel; // 퇴실 상태 라벨 (서버 제공)
  final int? depositDeduction; // 보증금 차감 금액
  final String? deductionReason; // 차감 사유
  final int? refundableDeposit; // 환급 가능 보증금
  final String? checkoutRequestedAt; // 퇴실 요청 시각
  final DepositAgreement? depositAgreement; // 보증금 합의 정보

  // 채팅 읽기 전용 정보
  final bool isReadOnly;
  final String? readOnlyReason;

  // 방 입실/퇴실 시간
  final String? roomCheckInTime;
  final String? roomCheckoutTime;

  // 취소 요청 여부 (IN_PROGRESS 상태에서 1회 제한)
  final bool cancellationRequested;

  // 호스트 정산 정보 (호스트용)
  final HostSettlement? hostSettlement;

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
    this.hostNickname,
    this.hostProfileImage,
    this.hostPhoneNumber,
    required this.guestName,
    this.guestNickname,
    required this.guestPhone,
    this.guestMessage,
    this.requestedAt,
    this.approvedAt,
    required this.createdAt,
    this.guestCheckoutConfirmedAt,
    this.hostCheckoutConfirmedAt,
    this.depositStatus,
    this.checkoutStatus,
    this.checkoutStatusLabel,
    this.depositDeduction,
    this.deductionReason,
    this.refundableDeposit,
    this.checkoutRequestedAt,
    this.depositAgreement,
    this.isReadOnly = false,
    this.readOnlyReason,
    this.roomCheckInTime,
    this.roomCheckoutTime,
    this.cancellationRequested = false,
    required this.isEzCleaning,
    this.hostSettlement,
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

    // rentalItems 파싱 (rentalOrders.activeItems 우선 사용)
    List<ContractRentalItem> parsedRentalItems = [];

    // 1. rentalOrders.activeItems 확인 (실제 활성 주문 아이템)
    final rentalOrdersData = json['rentalOrders'];
    if (rentalOrdersData is Map && rentalOrdersData['activeItems'] is List) {
      final activeItems = rentalOrdersData['activeItems'] as List;
      parsedRentalItems = activeItems.map((e) {
        final item = e as Map<String, dynamic>;
        // activeItems 필드명 → ContractRentalItem 필드명 매핑
        return ContractRentalItem.fromJson({
          'id': item['rentalItemId'],
          'name': item['name'],
          'description': item['description'],
          'price': item['pricePerItem'],
          'quantity': item['quantity'],
          'imageUrl': item['imageUrl'],
        });
      }).toList();
    } else {
      // 2. recommendedItems.items fallback
      final recommendedItemsData = json['recommendedItems'];
      if (recommendedItemsData is Map &&
          recommendedItemsData['items'] is List) {
        final itemsList = recommendedItemsData['items'] as List;
        parsedRentalItems = itemsList
            .map(
              (e) => ContractRentalItem.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } else {
        // 3. rentalItems 사용 (JSON 문자열 또는 List)
        final rentalItemsData = json['rentalItems'];
        List<dynamic>? itemsList;
        if (rentalItemsData is List) {
          itemsList = rentalItemsData;
        } else if (rentalItemsData is String && rentalItemsData.isNotEmpty) {
          try {
            final decoded = jsonDecode(rentalItemsData);
            if (decoded is List) itemsList = decoded;
          } catch (_) {}
        }
        if (itemsList != null) {
          parsedRentalItems = itemsList
              .map(
                (e) => ContractRentalItem.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
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
      deposit: json['deposit'] as int? ?? FeeConstants.depositAmount,
      rentalItemsFee: json['rentalItemsFee'] as int? ?? 0,
      platformFee: json['platformFee'] as int,
      finalTotalAmount: json['finalTotalAmount'] as int,
      // 상태 정보
      status: parseStringField(json['status'], 'PENDING'),
      paidAt: json['paidAt'] != null ? parseDateField(json['paidAt']) : null,
      // 환불 정책
      refundPolicy: parseStringField(json['refundPolicy'], 'moderate'),
      refundPolicyDetail: parseStringField(json['refundPolicyDetail'], ''),
      refundPolicySnapshot: _parseRefundPolicySnapshot(json['refundPolicySnapshot']),
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
      hostNickname: host?['nickname'] as String?,
      hostProfileImage: host?['profileImage'] != null
          ? parseStringField(host?['profileImage'])
          : null,
      hostPhoneNumber: host?['phoneNumber'] != null
          ? parseStringField(host?['phoneNumber'])
          : null,
      // 게스트 정보 (nested 구조, 안전 파싱)
      guestName: parseStringField(guest?['name'], ''),
      guestNickname: guest?['nickname'] as String?,
      guestPhone: parseStringField(guest?['phoneNumber'], ''),
      guestMessage: json['guestMessage'] as String?,
      // 시간 정보
      requestedAt: json['requestedAt'] != null ? parseDateField(json['requestedAt']) : null,
      approvedAt: json['approvedAt'] != null ? parseDateField(json['approvedAt']) : null,
      createdAt: parseDateField(json['createdAt'] ?? json['requestedAt'] ?? ''),
      // 퇴실 확인 정보
      guestCheckoutConfirmedAt: json['guestCheckoutConfirmedAt'] != null
          ? parseDateField(json['guestCheckoutConfirmedAt'])
          : null,
      hostCheckoutConfirmedAt: json['hostCheckoutConfirmedAt'] != null
          ? parseDateField(json['hostCheckoutConfirmedAt'])
          : null,
      depositStatus: DepositStatus.fromString(json['depositStatus'] as String?),
      // 퇴실 상세 정보 (API v2)
      checkoutStatus: json['checkoutStatus'] as String?,
      checkoutStatusLabel: json['checkoutStatusLabel'] as String?,
      depositDeduction: json['depositDeduction'] as int?,
      deductionReason: json['deductionReason'] as String?,
      refundableDeposit: json['refundableDeposit'] as int?,
      checkoutRequestedAt: json['checkoutRequestedAt'] != null
          ? parseDateField(json['checkoutRequestedAt'])
          : null,
      depositAgreement: json['depositAgreement'] != null
          ? DepositAgreement.fromJson(json['depositAgreement'] as Map<String, dynamic>)
          : null,
      // 채팅 읽기 전용
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      readOnlyReason: json['readOnlyReason'] as String?,
      // 방 입실/퇴실 시간
      roomCheckInTime: room?['checkInTime'] as String? ?? json['roomCheckInTime'] as String?,
      roomCheckoutTime: room?['checkoutTime'] as String? ?? json['roomCheckoutTime'] as String?,
      // 취소 요청 여부
      cancellationRequested: json['cancellationRequested'] as bool? ?? false,
      // 호스트 정산 정보
      hostSettlement: json['hostSettlement'] != null
          ? HostSettlement.fromJson(json['hostSettlement'] as Map<String, dynamic>)
          : null,
      // 기타
      isEzCleaning: json['isEzCleaning'] as bool? ?? false,
    );
  }

  /// ContractDetail → Contract 변환 (RefundCalculationModal 등에서 사용)
  Contract toContract() {
    return Contract(
      id: id,
      roomId: roomId,
      hostId: 0, // ContractDetail에는 hostId가 없음
      guestId: 0, // ContractDetail에는 guestId가 없음
      checkInDate: DateTime.tryParse(checkInDate) ?? DateTime.now(),
      checkOutDate: DateTime.tryParse(checkOutDate) ?? DateTime.now(),
      totalDays: totalDays,
      rentalFee: rentalFee,
      maintenanceFee: maintenanceFee,
      cleaningFee: cleaningFee,
      rentalItemsFee: rentalItemsFee,
      platformFee: platformFee,
      discountAmount: 0,
      subtotal: finalTotalAmount,
      totalUsageFee: finalTotalAmount,
      deposit: deposit,
      finalTotalAmount: finalTotalAmount,
      rentalItems: rentalItems
          .map((item) => RentalItem(
                id: item.id.toString(),
                name: item.name,
                description: item.description,
                price: item.price,
                quantity: item.quantity,
                deliveryStatus: DeliveryStatus.fromString(
                    item.deliveryStatus ?? 'PENDING'),
              ))
          .toList(),
      installmentMonths: 0,
      termsAgreed: const {},
      status: ContractStatus.fromString(status),
      refundPolicy: refundPolicy,
      isEzCleaning: isEzCleaning,
      paidAt: paidAt != null ? DateTime.tryParse(paidAt!) : null,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
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
      if (hostNickname != null) 'hostNickname': hostNickname,
      if (hostProfileImage != null) 'hostProfileImage': hostProfileImage,
      if (hostPhoneNumber != null) 'hostPhoneNumber': hostPhoneNumber,
      'guestName': guestName,
      if (guestNickname != null) 'guestNickname': guestNickname,
      'guestPhone': guestPhone,
      if (guestMessage != null) 'guestMessage': guestMessage,
      if (requestedAt != null) 'requestedAt': requestedAt,
      if (approvedAt != null) 'approvedAt': approvedAt,
      'createdAt': createdAt,
      if (guestCheckoutConfirmedAt != null) 'guestCheckoutConfirmedAt': guestCheckoutConfirmedAt,
      if (hostCheckoutConfirmedAt != null) 'hostCheckoutConfirmedAt': hostCheckoutConfirmedAt,
      if (depositStatus != null) 'depositStatus': depositStatus!.value,
      if (checkoutStatus != null) 'checkoutStatus': checkoutStatus,
      if (checkoutStatusLabel != null) 'checkoutStatusLabel': checkoutStatusLabel,
      if (depositDeduction != null) 'depositDeduction': depositDeduction,
      if (deductionReason != null) 'deductionReason': deductionReason,
      if (refundableDeposit != null) 'refundableDeposit': refundableDeposit,
      if (checkoutRequestedAt != null) 'checkoutRequestedAt': checkoutRequestedAt,
      if (depositAgreement != null) 'depositAgreement': depositAgreement!.toJson(),
      'isReadOnly': isReadOnly,
      if (readOnlyReason != null) 'readOnlyReason': readOnlyReason,
      if (roomCheckInTime != null) 'roomCheckInTime': roomCheckInTime,
      if (roomCheckoutTime != null) 'roomCheckoutTime': roomCheckoutTime,
      'cancellationRequested': cancellationRequested,
      'isEzCleaning': isEzCleaning,
    };
  }

  /// refundPolicySnapshot 파싱 (Map 또는 JSON String 모두 처리)
  static RefundPolicySnapshot? _parseRefundPolicySnapshot(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return RefundPolicySnapshot.fromJson(value);
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value) as Map<String, dynamic>;
        return RefundPolicySnapshot.fromJson(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// 보증금 합의 정보
class DepositAgreement {
  final int deductAmount; // 차감 금액
  final String agreementText; // 합의 내용
  final String? holdReason; // 보류 사유
  final String? status; // 합의 상태 (SUBMITTED, ACCEPTED 등)
  final String? statusLabel; // 상태 라벨 (서버 제공)
  final String? submittedAt; // 제출 시각
  final String? acceptedAt; // 게스트 동의 시각
  final int? refundableAmount; // 환급 가능 금액
  final int? deposit; // 보증금 총액
  final String? holdApprovedAt; // 관리자 보류 승인 시각 (정책 7.9.1: 합의 데드라인 기준)

  const DepositAgreement({
    required this.deductAmount,
    required this.agreementText,
    this.holdReason,
    this.status,
    this.statusLabel,
    this.submittedAt,
    this.acceptedAt,
    this.refundableAmount,
    this.deposit,
    this.holdApprovedAt,
  });

  /// 합의 데드라인 계산 (정책 7.9.1)
  ///
  /// 기준: 관리자 승인 시점 + (24h × 10) = 승인 시점 + 10일
  /// holdApprovedAt이 없으면 null 반환 (프론트에서 데드라인 표시 불가)
  DateTime? get agreementDeadline {
    if (holdApprovedAt == null) return null;
    final approvedAt = DateTime.tryParse(holdApprovedAt!);
    if (approvedAt == null) return null;
    return approvedAt.add(const Duration(days: 10));
  }

  factory DepositAgreement.fromJson(Map<String, dynamic> json) {
    return DepositAgreement(
      deductAmount: json['deductAmount'] as int? ?? 0,
      agreementText: json['agreementText'] as String? ?? '',
      holdReason: json['holdReason'] as String?,
      status: json['status'] as String?,
      statusLabel: json['statusLabel'] as String?,
      submittedAt: json['submittedAt'] as String?,
      acceptedAt: json['acceptedAt'] as String?,
      refundableAmount: json['refundableAmount'] as int?,
      deposit: json['deposit'] as int?,
      holdApprovedAt: json['holdApprovedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deductAmount': deductAmount,
      'agreementText': agreementText,
      if (holdReason != null) 'holdReason': holdReason,
      if (status != null) 'status': status,
      if (statusLabel != null) 'statusLabel': statusLabel,
      if (submittedAt != null) 'submittedAt': submittedAt,
      if (acceptedAt != null) 'acceptedAt': acceptedAt,
      if (refundableAmount != null) 'refundableAmount': refundableAmount,
      if (deposit != null) 'deposit': deposit,
      if (holdApprovedAt != null) 'holdApprovedAt': holdApprovedAt,
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
