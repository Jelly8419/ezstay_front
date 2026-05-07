import 'guest_move_in_enums.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// 입주 준비 옵션 카탈로그 (활성 옵션)
class GuestMoveInOption {
  final int optionId;
  final String name;
  final String? description;
  final GuestOptionType type;
  final GuestOptionCategory category;
  final int price;
  final String? imageUrl;
  final bool available;

  const GuestMoveInOption({
    required this.optionId,
    required this.name,
    this.description,
    required this.type,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.available,
  });

  factory GuestMoveInOption.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestMoveInOption(
      optionId: (json['optionId'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: GuestOptionType.fromCode(json['type']?.toString()),
      category: GuestOptionCategory.fromCode(json['category']?.toString()),
      price: (json['price'] as num? ?? 0).toInt(),
      imageUrl: json['imageUrl']?.toString(),
      available: (json['available'] as bool?) ?? false,
    );
  }
}

/// 사용자가 선택한 옵션 (결제 init 요청용)
class GuestSelectedItem {
  final int optionId;
  final int quantity;

  const GuestSelectedItem({required this.optionId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'optionId': optionId,
        'quantity': quantity,
      };
}
