/// 방/숙소 정보 모델
class Room {
  final int id;
  final String name;
  final String address;
  final String addressDetail;
  final double latitude;
  final double longitude;
  final String buildingType; // 아파트, 오피스텔, 주택, 호텔, 고시원
  final int bedrooms; // 방 개수
  final int bathrooms; // 화장실 개수
  final int beds; // 침대 개수
  final int maxGuests; // 최대 인원
  final int weeklyPrice; // 주 임대료
  final int monthlyPrice; // 월 임대료
  final List<String> photos; // 사진 URL 리스트
  final List<String> amenities; // 편의시설
  final List<String> freeServices; // 무료 부가서비스
  final bool isParkingAvailable; // 주차 가능
  final bool isPetFriendly; // 반려동물 가능
  final bool isNearSubway; // 역세권
  final int? discount; // 할인율 (%)
  final String description; // 방 설명
  final String hostName; // 호스트 이름
  final int hostId; // 호스트 ID
  final String status; // 방 상태 (available, booked, pending)

  const Room({
    required this.id,
    required this.name,
    required this.address,
    required this.addressDetail,
    required this.latitude,
    required this.longitude,
    required this.buildingType,
    required this.bedrooms,
    required this.bathrooms,
    required this.beds,
    required this.maxGuests,
    required this.weeklyPrice,
    required this.monthlyPrice,
    required this.photos,
    required this.amenities,
    required this.freeServices,
    required this.isParkingAvailable,
    required this.isPetFriendly,
    required this.isNearSubway,
    this.discount,
    required this.description,
    required this.hostName,
    required this.hostId,
    this.status = 'available',
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      addressDetail: json['addressDetail'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      buildingType: json['buildingType'] as String,
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      beds: json['beds'] as int,
      maxGuests: json['maxGuests'] as int,
      weeklyPrice: json['weeklyPrice'] as int,
      monthlyPrice: json['monthlyPrice'] as int,
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      freeServices: (json['freeServices'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isParkingAvailable: json['isParkingAvailable'] as bool? ?? false,
      isPetFriendly: json['isPetFriendly'] as bool? ?? false,
      isNearSubway: json['isNearSubway'] as bool? ?? false,
      discount: json['discount'] as int?,
      description: json['description'] as String? ?? '',
      hostName: json['hostName'] as String,
      hostId: json['hostId'] as int,
      status: json['status'] as String? ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'addressDetail': addressDetail,
      'latitude': latitude,
      'longitude': longitude,
      'buildingType': buildingType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'beds': beds,
      'maxGuests': maxGuests,
      'weeklyPrice': weeklyPrice,
      'monthlyPrice': monthlyPrice,
      'photos': photos,
      'amenities': amenities,
      'freeServices': freeServices,
      'isParkingAvailable': isParkingAvailable,
      'isPetFriendly': isPetFriendly,
      'isNearSubway': isNearSubway,
      'discount': discount,
      'description': description,
      'hostName': hostName,
      'hostId': hostId,
      'status': status,
    };
  }

  /// 주소에서 동까지만 추출 (상세 주소 제외)
  String get addressWithoutDetail {
    return address;
  }

  /// 할인 적용된 주 임대료
  int get discountedWeeklyPrice {
    if (discount != null && discount! > 0) {
      return (weeklyPrice * (100 - discount!) / 100).round();
    }
    return weeklyPrice;
  }

  /// 할인 적용된 월 임대료
  int get discountedMonthlyPrice {
    if (discount != null && discount! > 0) {
      return (monthlyPrice * (100 - discount!) / 100).round();
    }
    return monthlyPrice;
  }

  Room copyWith({
    int? id,
    String? name,
    String? address,
    String? addressDetail,
    double? latitude,
    double? longitude,
    String? buildingType,
    int? bedrooms,
    int? bathrooms,
    int? beds,
    int? maxGuests,
    int? weeklyPrice,
    int? monthlyPrice,
    List<String>? photos,
    List<String>? amenities,
    List<String>? freeServices,
    bool? isParkingAvailable,
    bool? isPetFriendly,
    bool? isNearSubway,
    int? discount,
    String? description,
    String? hostName,
    int? hostId,
    String? status,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      buildingType: buildingType ?? this.buildingType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      beds: beds ?? this.beds,
      maxGuests: maxGuests ?? this.maxGuests,
      weeklyPrice: weeklyPrice ?? this.weeklyPrice,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      photos: photos ?? this.photos,
      amenities: amenities ?? this.amenities,
      freeServices: freeServices ?? this.freeServices,
      isParkingAvailable: isParkingAvailable ?? this.isParkingAvailable,
      isPetFriendly: isPetFriendly ?? this.isPetFriendly,
      isNearSubway: isNearSubway ?? this.isNearSubway,
      discount: discount ?? this.discount,
      description: description ?? this.description,
      hostName: hostName ?? this.hostName,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
    );
  }
}
