import 'room_photo.dart';
import 'room_amenity.dart';
import 'room_free_service.dart';
import 'rental_item.dart';

/// 방/숙소 정보 모델 (API 응답 기준)
class Room {
  // 기본 정보
  final int id;
  final String roomName;
  final String address;
  final double latitude;
  final double longitude;
  final String area; // 전용면적 (제곱미터)
  final String floor; // 층수
  final String buildingType; // 타운하우스, 아파트, 오피스텔 등
  final bool parkingAvailable;
  final String? parkingInfo;
  final bool elevatorAvailable;
  final int roomCount; // 방 개수
  final int bathroomCount; // 화장실 개수
  final int livingRoomCount; // 거실 개수
  final int kitchenCount; // 주방 개수
  final bool isDuplex; // 복층 여부

  // 가격 정보
  final int dailyRent; // 일 임대료
  final int? longTermWeeks; // 장기계약 기준 주수 (discounts.longTermWeeks, nullable)
  final int? longTermDiscount; // 장기계약 할인율 (%) (discounts.longTermDiscount, nullable)
  final int? quickMoveIn; // 빠른 입주 가능 일수 (숫자, 예: 13) (discounts.quickMoveIn)
  final int? quickMoveInDiscount; // 빠른 입주 할인 금액 (원) (discounts.quickMoveInDiscount, nullable)
  final int dailyMaintenanceFee; // 일 관리비
  final String? maintenanceDetail; // 관리비 상세 설명
  final bool includeElectricity; // 관리비에 전기 포함 여부
  final bool includeWater; // 관리비에 수도 포함 여부
  final bool includeGas; // 관리비에 가스 포함 여부
  final bool includeInternet; // 관리비에 인터넷 포함 여부
  final int cleaningFee; // 청소비
  final int deposit; // 보증금

  // 계약 정보
  final int minContractWeeks; // 최소 계약 주수
  final String refundPolicy; // 환불 규정 (flexible, moderate, strict)
  final String? description; // 방 설명
  final String? transportation; // 교통 정보
  final String? houseRules; // 하우스 룰
  final String checkInTime; // 체크인 시간 (예: "15:00")
  final String checkOutTime; // 체크아웃 시간 (예: "11:00")

  // 날짜 정보
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 연관 데이터
  final List<RoomPhoto> photos;
  final RoomAmenity? amenity;
  final RoomFreeService? freeService;
  final AvailableRentalItems? availableRentalItems;

  // UI 전용 필드
  final bool isNearSubway; // 역세권 (프론트에서 계산)
  final String? hostProfileImage;
  final bool? hostPhoneVerified;
  final bool? hostAccountVerified;
  final String? hostName;
  final int? hostId;
  final String status; // 방 상태 (draft, submitted, approved, rejected, published)

  const Room({
    required this.id,
    required this.roomName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.floor,
    required this.buildingType,
    required this.parkingAvailable,
    this.parkingInfo,
    required this.elevatorAvailable,
    required this.roomCount,
    required this.bathroomCount,
    required this.livingRoomCount,
    required this.kitchenCount,
    required this.isDuplex,
    required this.dailyRent,
    required this.longTermWeeks,
    required this.longTermDiscount,
    this.quickMoveIn,
    required this.quickMoveInDiscount,
    required this.dailyMaintenanceFee,
    this.maintenanceDetail,
    required this.includeElectricity,
    required this.includeWater,
    required this.includeGas,
    required this.includeInternet,
    required this.cleaningFee,
    required this.deposit,
    required this.minContractWeeks,
    required this.refundPolicy,
    this.description,
    this.transportation,
    this.houseRules,
    this.checkInTime = '15:00',
    this.checkOutTime = '11:00',
    this.submittedAt,
    this.approvedAt,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
    this.amenity,
    this.freeService,
    this.availableRentalItems,
    this.isNearSubway = false,
    this.hostProfileImage,
    this.hostPhoneVerified,
    this.hostAccountVerified,
    this.hostName,
    this.hostId,
    this.status = 'draft',
  });



  factory Room.fromJson(Map<String, dynamic> json) {
    // photos 파싱
    List<RoomPhoto> photoList = [];
    if (json['photos'] != null) {
      final photosData = json['photos'] as List<dynamic>;
      photoList = photosData.map((e) => RoomPhoto.fromJson(e as Map<String, dynamic>)).toList();
    }

    return Room(
      // 기본 정보
      id: json['id'] as int,
      roomName: json['roomName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      area: json['area']?.toString() ?? '0',
      floor: json['floor']?.toString() ?? '1',
      buildingType: json['buildingType'] as String? ?? '',
      parkingAvailable: json['parkingAvailable'] as bool? ?? false,
      parkingInfo: json['parkingInfo'] as String?,
      elevatorAvailable: json['elevatorAvailable'] as bool? ?? false,
      roomCount: json['roomCount'] as int? ?? 0,
      bathroomCount: json['bathroomCount'] as int? ?? 0,
      livingRoomCount: json['livingRoomCount'] as int? ?? 0,
      kitchenCount: json['kitchenCount'] as int? ?? 0,
      isDuplex: json['isDuplex'] as bool? ?? false,

      // 가격 정보
      dailyRent: json['dailyRent'] as int? ?? 0,
      // discounts 객체에서 할인 정보 파싱 (nullable 유지)
      longTermWeeks: json['discounts']?['longTermWeeks'] as int? ?? json['longTermWeeks'] as int?,
      longTermDiscount: json['discounts']?['longTermDiscount'] as int? ?? json['longTermDiscount'] as int?,
      quickMoveIn: json['discounts']?['quickMoveIn'] as int? ?? json['quickMoveIn'] as int?,
      quickMoveInDiscount: json['discounts']?['quickMoveInDiscount'] as int? ?? json['quickMoveInDiscount'] as int?,
      dailyMaintenanceFee: json['dailyMaintenanceFee'] as int? ?? 0,
      maintenanceDetail: json['maintenanceDetail'] as String?,
      includeElectricity: json['includeElectricity'] as bool? ?? false,
      includeWater: json['includeWater'] as bool? ?? false,
      includeGas: json['includeGas'] as bool? ?? false,
      includeInternet: json['includeInternet'] as bool? ?? false,
      cleaningFee: json['cleaningFee'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,

      // 계약 정보
      minContractWeeks: json['minContractWeeks'] as int? ?? 4,
      refundPolicy: json['refundPolicy'] as String? ?? 'moderate',
      description: json['description'] as String?,
      transportation: json['transportation'] as String?,
      houseRules: json['houseRules'] as String?,
      checkInTime: json['checkInTime'] as String? ?? '15:00',
      checkOutTime: json['checkOutTime'] as String? ?? '11:00',

      // 날짜 정보
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'] as String) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),

      // 연관 데이터
      photos: photoList,
      amenity: json['amenity'] != null ? RoomAmenity.fromJson(json['amenity'] as Map<String, dynamic>) : null,
      freeService: json['freeService'] != null ? RoomFreeService.fromJson(json['freeService'] as Map<String, dynamic>) : null,
      availableRentalItems: json['availableRentalItems'] != null ? AvailableRentalItems.fromJson(json['availableRentalItems'] as Map<String, dynamic>) : null,

      // UI 전용 필드
      isNearSubway: json['isNearSubway'] as bool? ?? false,
      // host 객체에서 정보 추출
      hostProfileImage: json['host'] != null ? json['host']['profileImageUrl'] as String? : json['hostProfileImage'] as String?,
      hostPhoneVerified: json['host'] != null ? json['host']['phoneVerified'] as bool? : json['hostPhoneVerified'] as bool?,
      hostAccountVerified: json['host'] != null ? json['host']['accountVerified'] as bool? : json['hostAccountVerified'] as bool?,
      hostName: json['host'] != null ? json['host']['name'] as String? : json['hostName'] as String?,
      hostId: json['host'] != null ? json['host']['id'] as int? : json['hostId'] as int?,
      status: json['status'] as String? ?? 'draft',
    );
  }

  /// latitude/longitude를 String 또는 num에서 double로 안전하게 파싱
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomName': roomName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'floor': floor,
      'buildingType': buildingType,
      'parkingAvailable': parkingAvailable,
      'parkingInfo': parkingInfo,
      'elevatorAvailable': elevatorAvailable,
      'roomCount': roomCount,
      'bathroomCount': bathroomCount,
      'livingRoomCount': livingRoomCount,
      'kitchenCount': kitchenCount,
      'isDuplex': isDuplex,
      'dailyRent': dailyRent,
      'longTermWeeks': longTermWeeks,
      'longTermDiscount': longTermDiscount,
      'quickMoveIn': quickMoveIn,
      'quickMoveInDiscount': quickMoveInDiscount,
      'dailyMaintenanceFee': dailyMaintenanceFee,
      'maintenanceDetail': maintenanceDetail,
      'includeElectricity': includeElectricity,
      'includeWater': includeWater,
      'includeGas': includeGas,
      'includeInternet': includeInternet,
      'cleaningFee': cleaningFee,
      'deposit': deposit,
      'minContractWeeks': minContractWeeks,
      'refundPolicy': refundPolicy,
      'description': description,
      'transportation': transportation,
      'houseRules': houseRules,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photos': photos.map((p) => p.toJson()).toList(),
      'amenity': amenity?.toJson(),
      'freeService': freeService?.toJson(),
      'availableRentalItems': availableRentalItems?.toJson(),
      'isNearSubway': isNearSubway,
      'hostProfileImage': hostProfileImage,
      'hostPhoneVerified': hostPhoneVerified,
      'hostAccountVerified': hostAccountVerified,
      'hostName': hostName,
      'hostId': hostId,
      'status': status,
    };
  }

  // === 계산 프로퍼티 (Computed Properties) ===

  /// 최소 계약 일수 (주 단위를 일 단위로 변환, React UI 호환)
  int get minContractDays => minContractWeeks * 7;

  /// 1일 임대료로 1주일 임대료 계산
  int get weeklyRent => (dailyRent * 7 / 1000).round() * 1000;

  /// 1일 관리비로 1주일 관리비 계산
  int get maintenanceFee => (dailyMaintenanceFee * 7 / 1000).round() * 1000;

  /// 장기 계약 할인 적용된 주 임대료
  int get longTermDiscountedRent {
    if (longTermDiscount != null && longTermDiscount! > 0) {
      return (weeklyRent * (100 - longTermDiscount!) / 100).round();
    }
    return weeklyRent;
  }

  /// 빠른 입주 할인 적용된 주 임대료
  int get quickMoveInDiscountedRent {
    if (quickMoveInDiscount != null && quickMoveInDiscount! > 0) {
      return (weeklyRent - quickMoveInDiscount!).round();
    }
    return weeklyRent;
  }

  /// 월 임대료 (주 임대료 × 4.3)
  int get monthlyRent => (weeklyRent * 4.3).round();

  /// 장기 계약 할인 적용된 월 임대료
  int get longTermDiscountedMonthlyRent => (longTermDiscountedRent * 4.3).round();

  /// 총 침대 수 (freeService의 bed 정보에서 계산)
  int get totalBeds {
    if (freeService == null) return 0;
    return freeService!.bedSizeSuperSingle +
           freeService!.bedSizeQueen +
           freeService!.bedSizeKing;
  }

  /// 편의시설 평탄화 리스트 (UI용)
  List<String> get amenitiesList => amenity?.toFlatList() ?? [];

  /// 무료 서비스 평탄화 리스트 (UI용)
  List<String> get freeServicesList => freeService?.toFlatList() ?? [];

  /// 반려동물 동반 가능 여부
  bool get isPetFriendly => amenity?.petsAllowed ?? false;

  Room copyWith({
    int? id,
    String? roomName,
    String? address,
    double? latitude,
    double? longitude,
    String? area,
    String? floor,
    String? buildingType,
    bool? parkingAvailable,
    String? parkingInfo,
    bool? elevatorAvailable,
    int? roomCount,
    int? bathroomCount,
    int? livingRoomCount,
    int? kitchenCount,
    bool? isDuplex,
    int? dailyRent,
    int? longTermWeeks,
    int? longTermDiscount,
    int? quickMoveIn,
    int? quickMoveInDiscount,
    int? dailyMaintenanceFee,
    String? maintenanceDetail,
    bool? includeElectricity,
    bool? includeWater,
    bool? includeGas,
    bool? includeInternet,
    int? cleaningFee,
    int? deposit,
    int? minContractWeeks,
    String? refundPolicy,
    String? description,
    String? transportation,
    String? houseRules,
    String? checkInTime,
    String? checkOutTime,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoomPhoto>? photos,
    RoomAmenity? amenity,
    RoomFreeService? freeService,
    AvailableRentalItems? availableRentalItems,
    bool? isNearSubway,
    String? hostProfileImage,
    bool? hostPhoneVerified,
    bool? hostAccountVerified,
    String? hostName,
    int? hostId,
    String? status,
  }) {
    return Room(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      area: area ?? this.area,
      floor: floor ?? this.floor,
      buildingType: buildingType ?? this.buildingType,
      parkingAvailable: parkingAvailable ?? this.parkingAvailable,
      parkingInfo: parkingInfo ?? this.parkingInfo,
      elevatorAvailable: elevatorAvailable ?? this.elevatorAvailable,
      roomCount: roomCount ?? this.roomCount,
      bathroomCount: bathroomCount ?? this.bathroomCount,
      livingRoomCount: livingRoomCount ?? this.livingRoomCount,
      kitchenCount: kitchenCount ?? this.kitchenCount,
      isDuplex: isDuplex ?? this.isDuplex,
      dailyRent: dailyRent ?? this.dailyRent,
      longTermWeeks: longTermWeeks ?? this.longTermWeeks,
      longTermDiscount: longTermDiscount ?? this.longTermDiscount,
      quickMoveIn: quickMoveIn ?? this.quickMoveIn,
      quickMoveInDiscount: quickMoveInDiscount ?? this.quickMoveInDiscount,
      dailyMaintenanceFee: dailyMaintenanceFee ?? this.dailyMaintenanceFee,
      maintenanceDetail: maintenanceDetail ?? this.maintenanceDetail,
      includeElectricity: includeElectricity ?? this.includeElectricity,
      includeWater: includeWater ?? this.includeWater,
      includeGas: includeGas ?? this.includeGas,
      includeInternet: includeInternet ?? this.includeInternet,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      deposit: deposit ?? this.deposit,
      minContractWeeks: minContractWeeks ?? this.minContractWeeks,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      description: description ?? this.description,
      transportation: transportation ?? this.transportation,
      houseRules: houseRules ?? this.houseRules,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      amenity: amenity ?? this.amenity,
      freeService: freeService ?? this.freeService,
      availableRentalItems: availableRentalItems ?? this.availableRentalItems,
      isNearSubway: isNearSubway ?? this.isNearSubway,
      hostProfileImage: hostProfileImage ?? this.hostProfileImage,
      hostPhoneVerified: hostPhoneVerified ?? this.hostPhoneVerified,
      hostAccountVerified: hostAccountVerified ?? this.hostAccountVerified,
      hostName: hostName ?? this.hostName,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
    );
  }
}
