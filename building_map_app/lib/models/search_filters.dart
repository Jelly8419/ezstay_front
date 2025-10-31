/// 검색 필터 모델
class SearchFilters {
  final DateRange? dateRange;
  final Set<String> buildingTypes; // 아파트, 오피스텔, 주택, 호텔, 고시원
  final Set<int> bedroomCounts; // 1, 2, 3+ (3은 3개 이상 의미)
  final PriceRange priceRange;
  final Set<String> otherOptions; // parking, subway, pet

  const SearchFilters({
    this.dateRange,
    this.buildingTypes = const {},
    this.bedroomCounts = const {},
    this.priceRange = const PriceRange(),
    this.otherOptions = const {},
  });

  bool get hasActiveFilters {
    return dateRange != null ||
        buildingTypes.isNotEmpty ||
        bedroomCounts.isNotEmpty ||
        !priceRange.isDefault ||
        otherOptions.isNotEmpty;
  }

  SearchFilters copyWith({
    DateRange? dateRange,
    Set<String>? buildingTypes,
    Set<int>? bedroomCounts,
    PriceRange? priceRange,
    Set<String>? otherOptions,
    bool clearDateRange = false,
  }) {
    return SearchFilters(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      buildingTypes: buildingTypes ?? this.buildingTypes,
      bedroomCounts: bedroomCounts ?? this.bedroomCounts,
      priceRange: priceRange ?? this.priceRange,
      otherOptions: otherOptions ?? this.otherOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateRange': dateRange?.toJson(),
      'buildingTypes': buildingTypes.toList(),
      'bedroomCounts': bedroomCounts.toList(),
      'priceRange': priceRange.toJson(),
      'otherOptions': otherOptions.toList(),
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      dateRange: json['dateRange'] != null
          ? DateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
          : null,
      buildingTypes: (json['buildingTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      bedroomCounts: (json['bedroomCounts'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      priceRange: json['priceRange'] != null
          ? PriceRange.fromJson(json['priceRange'] as Map<String, dynamic>)
          : const PriceRange(),
      otherOptions: (json['otherOptions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
    );
  }
}

/// 날짜 범위 모델
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  /// 임대 기간 (일 수)
  int get durationInDays {
    return endDate.difference(startDate).inDays;
  }

  /// 유효성 검증
  bool get isValid {
    final duration = durationInDays;
    return duration >= 7 && duration <= 90;
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }
}

/// 가격 범위 모델
class PriceRange {
  final int minPrice; // 최소 가격 (만원 단위)
  final int? maxPrice; // 최대 가격 (만원 단위, null이면 전체)

  const PriceRange({
    this.minPrice = 0,
    this.maxPrice,
  });

  bool get isDefault {
    return minPrice == 0 && maxPrice == null;
  }

  /// 가격이 범위 내에 있는지 확인
  bool isInRange(int price) {
    final priceInManWon = price ~/ 10000;
    if (priceInManWon < minPrice) return false;
    if (maxPrice != null && priceInManWon > maxPrice!) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    };
  }

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      minPrice: json['minPrice'] as int? ?? 0,
      maxPrice: json['maxPrice'] as int?,
    );
  }

  PriceRange copyWith({
    int? minPrice,
    int? maxPrice,
    bool clearMaxPrice = false,
  }) {
    return PriceRange(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }
}

/// 건물 유형 상수
class BuildingTypes {
  static const String apartment = '아파트';
  static const String officetel = '오피스텔';
  static const String house = '주택';
  static const String hotel = '호텔';
  static const String goshiwon = '고시원';

  static const List<String> all = [
    apartment,
    officetel,
    house,
    hotel,
    goshiwon,
  ];
}

/// 기타 옵션 상수
class OtherOptions {
  static const String parking = 'parking';
  // 백엔드 필드 없어서 주석 처리
  // static const String subway = 'subway';
  // static const String pet = 'pet';

  static const Map<String, String> labels = {
    parking: '주차가능',
    // subway: '역세권',
    // pet: '반려동물 가능',
  };

  static const List<String> all = [parking];
}
