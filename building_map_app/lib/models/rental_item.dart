/// 렌탈 아이템 모델
class RentalItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final int totalStock;
  final String? imageUrl;

  const RentalItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.totalStock,
    this.imageUrl,
  });

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    return RentalItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int,
      totalStock: json['totalStock'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'totalStock': totalStock,
      'imageUrl': imageUrl,
    };
  }
}

/// 대여 가능한 렌탈 아이템 목록 (카테고리별)
class AvailableRentalItems {
  final List<RentalItem> hairDryers;      // 헤어드라이기
  final List<RentalItem> beddingSets;     // 침구류
  final List<RentalItem> amenityKits;     // 어메니티 키트
  final List<RentalItem> towelSets;       // 타올

  const AvailableRentalItems({
    this.hairDryers = const [],
    this.beddingSets = const [],
    this.amenityKits = const [],
    this.towelSets = const [],
  });

  factory AvailableRentalItems.fromJson(Map<String, dynamic> json) {
    return AvailableRentalItems(
      hairDryers: (json['hairDryers'] as List<dynamic>?)
              ?.map((e) => RentalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      beddingSets: (json['beddingSets'] as List<dynamic>?)
              ?.map((e) => RentalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      amenityKits: (json['amenityKits'] as List<dynamic>?)
              ?.map((e) => RentalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      towelSets: (json['towelSets'] as List<dynamic>?)
              ?.map((e) => RentalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hairDryers': hairDryers.map((e) => e.toJson()).toList(),
      'beddingSets': beddingSets.map((e) => e.toJson()).toList(),
      'amenityKits': amenityKits.map((e) => e.toJson()).toList(),
      'towelSets': towelSets.map((e) => e.toJson()).toList(),
    };
  }

  /// 모든 카테고리의 아이템을 평탄화한 리스트
  List<RentalItem> get allItems {
    return [
      ...hairDryers,
      ...beddingSets,
      ...amenityKits,
      ...towelSets,
    ];
  }

  /// 대여 가능한 아이템이 있는지 여부
  bool get hasItems {
    return hairDryers.isNotEmpty ||
        beddingSets.isNotEmpty ||
        amenityKits.isNotEmpty ||
        towelSets.isNotEmpty;
  }
}
