import 'dart:convert';
import 'room_photo.dart';
import 'room_amenity_freezed.dart';
import 'room_ez_service.dart';
import 'rental_item.dart';
import 'promotion.dart';

/// 임대 불가능 기간 (계약 중이거나 호스트가 차단한 기간)
class UnavailablePeriod {
  final DateTime startDate;
  final DateTime endDate;
  final String type; // 'contract' | 'blocked'

  const UnavailablePeriod({
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  factory UnavailablePeriod.fromJson(Map<String, dynamic> json) {
    return UnavailablePeriod(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: json['type'] as String? ?? 'blocked',
    );
  }

  /// 특정 날짜가 이 기간에 포함되는지 확인
  bool contains(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }
}

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
  final int maxGuests; // 권장 최대 인원

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
  final int minContractDays; // 최소 계약 일수 (기본 7일)
  final int maxContractDays; // 최대 계약 일수 (기본 90일)
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
  final RoomAmenityFreezed? amenity;
  final RoomEzService? ezService;
  final AvailableRentalItems? availableRentalItems;

  // UI 전용 필드
  final bool isNearSubway; // 역세권 (프론트에서 계산)
  final String? hostProfileImage;
  final bool? hostPhoneVerified;
  final bool? hostAccountVerified;
  final String? hostName;
  final String? hostNickname;
  final int? hostId;
  // 스냅샷 전용 — 계약 당시 게스트 정보 (호스트가 스냅샷 조회 시에만 존재)
  final String? guestName;
  final String? guestNickname;
  final String? guestProfileImage;
  final bool? guestPhoneVerified;
  final int? guestId;
  final String status; // 방 상태 (draft, pending_review, approved, rejected)
  final bool isActive; // 게시 여부 (approved 상태에서만 의미 있음)
  final bool isAvailable; // 예약 가능 여부 (지도 검색 API 응답)
  final List<UnavailablePeriod> unavailablePeriods; // 임대 불가능 기간 목록
  final String? rejectionReason; // 반려 사유

  // 프로모션 정보 (로그인한 게스트에게 자격이 있는 이벤트)
  final List<EligiblePromotion> eligiblePromotions;

  /// 호스트 표시명 (닉네임 우선, 없으면 이름)
  String get hostDisplayName =>
      (hostNickname?.isNotEmpty == true) ? hostNickname! : (hostName ?? '임대인');

  /// 승인된 방인지 확인
  bool get isApproved => status == 'approved';

  /// 심사 중인 방인지 확인
  bool get isPendingReview => status == 'pending_review';

  /// 승인된 방에서 수정 가능한 필드 그룹인지 확인
  ///
  /// 정책: approved 상태에서는 가격/할인/소개/하우스룰만 수정 가능
  /// 주소, 구조, 편의시설 등 핵심 정보 변경 시 재심사 필요
  bool canEditFieldGroup(String fieldGroup) {
    // draft/rejected 상태에서는 모든 필드 수정 가능
    if (status == 'draft' || status == 'rejected') return true;

    // approved/pending_review 상태에서는 제한된 필드만 수정 가능
    const editableGroups = {
      'pricing',       // 일 임대료, 관리비, 청소비, 보증금
      'discount',      // 장기계약/빠른입주 할인
      'description',   // 방 소개, 교통정보
      'houseRules',    // 하우스 룰
      'checkInOut',    // 체크인/체크아웃 시간
      'photos',        // 사진 추가/삭제
      'ezService',     // EZ서비스 설정
    };
    return editableGroups.contains(fieldGroup);
  }

  /// 수정 시 재심사가 필요한지 확인
  bool get needsReReviewOnEdit => isApproved;

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
    required this.maxGuests,
    required this.dailyRent,
    this.longTermWeeks,
    this.longTermDiscount,
    this.quickMoveIn,
    this.quickMoveInDiscount,
    required this.dailyMaintenanceFee,
    this.maintenanceDetail,
    required this.includeElectricity,
    required this.includeWater,
    required this.includeGas,
    required this.includeInternet,
    required this.cleaningFee,
    required this.deposit,
    this.minContractDays = 7,
    this.maxContractDays = 90,
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
    this.ezService,
    this.availableRentalItems,
    this.isNearSubway = false,
    this.hostProfileImage,
    this.hostPhoneVerified,
    this.hostAccountVerified,
    this.hostName,
    this.hostNickname,
    this.hostId,
    this.guestName,
    this.guestNickname,
    this.guestProfileImage,
    this.guestPhoneVerified,
    this.guestId,
    this.status = 'draft',
    this.isActive = false,
    this.isAvailable = true,
    this.unavailablePeriods = const [],
    this.rejectionReason,
    this.eligiblePromotions = const [],
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
      parkingAvailable: _parseBool(json['parkingAvailable']) ?? false,
      parkingInfo: json['parkingInfo'] as String?,
      elevatorAvailable: _parseBool(json['elevatorAvailable']) ?? false,
      roomCount: _parseNullableInt(json['roomCount']) ?? 0,
      bathroomCount: _parseNullableInt(json['bathroomCount']) ?? 0,
      livingRoomCount: _parseNullableInt(json['livingRoomCount']) ?? 0,
      kitchenCount: _parseNullableInt(json['kitchenCount']) ?? 0,
      isDuplex: _parseBool(json['isDuplex']) ?? false,
      maxGuests: _parseNullableInt(json['maxGuests']) ?? 2,

      // 가격 정보
      dailyRent: _parseNullableInt(json['dailyRent']) ?? 0,
      // discounts 객체에서 할인 정보 파싱 (nullable with explicit null handling)
      longTermWeeks: _parseNullableInt(json['discounts']?['longTermWeeks']) ?? _parseNullableInt(json['longTermWeeks']),
      longTermDiscount: _parseNullableInt(json['discounts']?['longTermDiscount']) ?? _parseNullableInt(json['longTermDiscount']),
      quickMoveIn: _parseNullableInt(json['discounts']?['quickMoveIn']) ?? _parseNullableInt(json['quickMoveIn']),
      quickMoveInDiscount: _parseNullableInt(json['discounts']?['quickMoveInDiscount']) ?? _parseNullableInt(json['quickMoveInDiscount']),
      dailyMaintenanceFee: _parseNullableInt(json['dailyMaintenanceFee']) ?? 0,
      maintenanceDetail: json['maintenanceDetail'] as String?,
      includeElectricity: _parseBool(json['includeElectricity']) ?? false,
      includeWater: _parseBool(json['includeWater']) ?? false,
      includeGas: _parseBool(json['includeGas']) ?? false,
      includeInternet: _parseBool(json['includeInternet']) ?? false,
      cleaningFee: _parseNullableInt(json['cleaningFee']) ?? 0,
      deposit: _parseNullableInt(json['deposit']) ?? 0,

      // 계약 정보
      minContractDays: _parseNullableInt(json['minContractDays']) ?? 7,
      maxContractDays: _parseNullableInt(json['maxContractDays']) ?? 90,
      refundPolicy: json['refundPolicy'] as String? ?? 'moderate',
      description: json['description'] as String?,
      transportation: json['transportation'] as String?,
      houseRules: json['houseRules'] as String?,
      checkInTime: json['checkInTime'] != null ? json['checkInTime'].toString() : '15:00',
      checkOutTime: json['checkOutTime'] != null ? json['checkOutTime'].toString() : '11:00',

      // 날짜 정보
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'] as String) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),

      // 연관 데이터
      photos: photoList,
      amenity: json['amenity'] != null
          ? RoomAmenityFreezed.fromJson(_sanitizeJson({
              'roomId': json['id'] ?? 0,
              ...json['amenity'] as Map<String, dynamic>,
            }))
          : null,
      // ezService 우선, 없으면 freeService fallback (백엔드 마이그레이션 기간 호환성)
      ezService: json['ezService'] != null
          ? RoomEzService.fromJson(_sanitizeJson(json['ezService'] as Map<String, dynamic>))
          : json['freeService'] != null
              ? RoomEzService.fromJson(_sanitizeJson(json['freeService'] as Map<String, dynamic>))
              : null,
      // EZStay가 제공하는 렌탈 아이템 (모든 방에 표시)
      availableRentalItems: json['availableRentalItems'] != null
          ? AvailableRentalItems.fromJson(json['availableRentalItems'] as Map<String, dynamic>)
          : null,

      // UI 전용 필드
      isNearSubway: _parseBool(json['isNearSubway']) ?? false,
      // host 객체에서 정보 추출
      hostProfileImage: json['host'] != null ? json['host']['profileImageUrl'] as String? : json['hostProfileImage'] as String?,
      hostPhoneVerified: json['host'] != null ? _parseBool(json['host']['phoneVerified']) : _parseBool(json['hostPhoneVerified']),
      hostAccountVerified: json['host'] != null ? _parseBool(json['host']['accountVerified']) : _parseBool(json['hostAccountVerified']),
      hostName: json['host'] != null ? json['host']['name'] as String? : json['hostName'] as String?,
      hostNickname: json['host'] != null ? json['host']['nickname'] as String? : json['hostNickname'] as String?,
      hostId: json['host'] != null ? json['host']['id'] as int? : json['hostId'] as int?,
      // guest 객체에서 정보 추출 (스냅샷 전용 — null 방어 처리)
      guestName: json['guest']?['name'] as String?,
      guestNickname: json['guest']?['nickname'] as String?,
      guestProfileImage: json['guest']?['profileImageUrl'] as String?,
      guestPhoneVerified: _parseBool(json['guest']?['phoneVerified']),
      guestId: json['guest']?['id'] as int?,
      status: _normalizeStatus(json['status'] as String?),
      isActive: _parseBool(json['isActive']) ?? false,
      isAvailable: _parseBool(json['isAvailable']) ?? true,
      unavailablePeriods: json['unavailablePeriods'] != null
          ? (json['unavailablePeriods'] as List<dynamic>)
              .map((e) => UnavailablePeriod.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      rejectionReason: json['rejectionReason'] as String?,
      eligiblePromotions: parsePromotionList<EligiblePromotion>(
        json['eligiblePromotions'],
        EligiblePromotion.fromJson,
      ),
    );
  }

  /// status 값 정규화 (API 응답값을 그대로 사용)
  static String _normalizeStatus(String? status) {
    if (status == null) return 'draft';
    return status;
  }

  /// latitude/longitude를 String 또는 num에서 double로 안전하게 파싱
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// nullable int 값을 안전하게 파싱 (null, int, double, String 지원)
  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// bool 값을 안전하게 파싱 (bool, int(1/0), String 지원)
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return null;
  }

  /// JSON을 순수 Dart 타입으로 재변환 (freezed 모델 호환용)
  ///
  /// JS interop에서 넘어온 타입이 Dart 타입과 불일치하는 문제 해결.
  /// json.encode → json.decode로 완전한 Dart 타입으로 변환 후
  /// bed 필드(Map→bool) 등 스키마 불일치도 처리.
  static Map<String, dynamic> _sanitizeJson(Map<String, dynamic> json) {
    // json.encode → json.decode로 순수 Dart 타입 보장
    final purified = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    return _fixSchemaTypes(purified);
  }

  /// 스키마 타입 불일치 수정 (재귀)
  static Map<String, dynamic> _fixSchemaTypes(Map<String, dynamic> json) {
    return json.map((key, value) {
      if (key == 'bed' && value is Map<String, dynamic>) {
        // bed: API에서 {king:0, queen:1, ...} Map → freezed는 bool
        final hasBed = value.values.any((v) => v is int && v > 0);
        return MapEntry(key, hasBed);
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _fixSchemaTypes(value));
      }
      return MapEntry(key, value);
    });
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
      'maxGuests': maxGuests,
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
      'minContractDays': minContractDays,
      'maxContractDays': maxContractDays,
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
      'ezService': ezService?.toJson(),
      'availableRentalItems': availableRentalItems?.toJson(),
      'isNearSubway': isNearSubway,
      'hostProfileImage': hostProfileImage,
      'hostPhoneVerified': hostPhoneVerified,
      'hostAccountVerified': hostAccountVerified,
      'hostName': hostName,
      'hostNickname': hostNickname,
      'hostId': hostId,
      'status': status,
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'eligiblePromotions': eligiblePromotions.map((p) => p.toJson()).toList(),
    };
  }


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

  /// 편의시설 평탄화 리스트 (UI용)
  List<String> get amenitiesList => amenity?.toFlatList() ?? [];

  /// 이지스테이 관리 서비스 평탄화 리스트 (UI용)
  List<String> get ezServicesList => ezService?.toFlatList() ?? [];

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
    int? maxGuests,
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
    int? minContractDays,
    int? maxContractDays,
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
    RoomAmenityFreezed? amenity,
    RoomEzService? ezService,
    AvailableRentalItems? availableRentalItems,
    bool? isNearSubway,
    String? hostProfileImage,
    bool? hostPhoneVerified,
    bool? hostAccountVerified,
    String? hostName,
    String? hostNickname,
    int? hostId,
    String? guestName,
    String? guestNickname,
    String? guestProfileImage,
    bool? guestPhoneVerified,
    int? guestId,
    String? status,
    bool? isActive,
    String? rejectionReason,
    List<EligiblePromotion>? eligiblePromotions,
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
      maxGuests: maxGuests ?? this.maxGuests,
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
      minContractDays: minContractDays ?? this.minContractDays,
      maxContractDays: maxContractDays ?? this.maxContractDays,
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
      ezService: ezService ?? this.ezService,
      availableRentalItems: availableRentalItems ?? this.availableRentalItems,
      isNearSubway: isNearSubway ?? this.isNearSubway,
      hostProfileImage: hostProfileImage ?? this.hostProfileImage,
      hostPhoneVerified: hostPhoneVerified ?? this.hostPhoneVerified,
      hostAccountVerified: hostAccountVerified ?? this.hostAccountVerified,
      hostName: hostName ?? this.hostName,
      hostNickname: hostNickname ?? this.hostNickname,
      hostId: hostId ?? this.hostId,
      guestName: guestName ?? this.guestName,
      guestNickname: guestNickname ?? this.guestNickname,
      guestProfileImage: guestProfileImage ?? this.guestProfileImage,
      guestPhoneVerified: guestPhoneVerified ?? this.guestPhoneVerified,
      guestId: guestId ?? this.guestId,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      eligiblePromotions: eligiblePromotions ?? this.eligiblePromotions,
    );
  }

  /// 방 관리 페이지용 헬퍼 메서드들

  /// 현재 표시할 상태 라벨
  String get displayStatus {
    switch (status) {
      case 'published':
        return isActive ? '게시중' : '게시중단';
      case 'approved':
        return '승인됨';
      case 'pending_review':
        return '심사중';
      case 'rejected':
        return '등록 반려';
      case 'hidden_by_admin':
        return '관리자 숨김';
      default:
        return '등록중';
    }
  }

  /// 수정 가능 여부
  bool get canEdit => status == 'draft' || status == 'rejected' || status == 'approved' || status == 'published';

  /// 일정관리 가능 여부
  bool get canSchedule => status == 'published';

  /// 복제 가능 여부
  bool get canDuplicate => status != 'draft';

  /// 삭제 가능 여부 (React: 항상 표시)
  bool get canDelete => true;

  /// 게시/비공개 토글 가능 여부 (published 상태에서만)
  bool get canTogglePublish => status == 'published';
}

