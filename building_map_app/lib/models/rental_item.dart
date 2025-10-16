/// 렌탈 아이템 모델 (헤어드라이어, 침구세트, 어메니티 키트, 타올 세트)
class RentalItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final int availableStock;
  final String? imageUrl;

  const RentalItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.availableStock,
    this.imageUrl,
  });

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    return RentalItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      availableStock: json['availableStock'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'availableStock': availableStock,
      'imageUrl': imageUrl,
    };
  }
}

/// 렌탈 아이템 카테고리별 묶음
class AvailableRentalItems {
  final List<RentalItem> hairDryers;
  final List<RentalItem> beddingSets;
  final List<RentalItem> amenityKits;
  final List<RentalItem> towelSets;

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

  /// 모든 카테고리가 비어있는지 확인
  bool get isEmpty =>
      hairDryers.isEmpty &&
      beddingSets.isEmpty &&
      amenityKits.isEmpty &&
      towelSets.isEmpty;
}
