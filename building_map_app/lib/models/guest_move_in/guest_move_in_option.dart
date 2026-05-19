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

  /// 케이스 내 본인 보유 수량 (PAID/PARTIAL_REFUND 주문 ACTIVE 라인 합산).
  /// 백엔드가 옵션 카탈로그 응답에 동봉. 추가 결제 가드 기준.
  final int ownedQuantity;

  /// 추가 결제 가능 잔여 수량 = max(0, maxPerOption - ownedQuantity).
  final int remainingQuantity;

  /// 품목당 최대 보유 가능 수량 (백엔드 정책 상수, 현재 5).
  final int maxPerOption;

  const GuestMoveInOption({
    required this.optionId,
    required this.name,
    this.description,
    required this.type,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.available,
    this.ownedQuantity = 0,
    this.remainingQuantity = 5,
    this.maxPerOption = 5,
  });

  factory GuestMoveInOption.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final maxPer = (json['maxPerOption'] as num? ?? 5).toInt();
    final owned = (json['ownedQuantity'] as num? ?? 0).toInt();
    // remainingQuantity 미동봉 시 maxPer - owned 로 계산 (안전 폴백)
    final remaining = json['remainingQuantity'] is num
        ? (json['remainingQuantity'] as num).toInt()
        : (maxPer - owned).clamp(0, maxPer);
    return GuestMoveInOption(
      optionId: (json['optionId'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: GuestOptionType.fromCode(json['type']?.toString()),
      category: GuestOptionCategory.fromCode(json['category']?.toString()),
      price: (json['price'] as num? ?? 0).toInt(),
      imageUrl: json['imageUrl']?.toString(),
      available: (json['available'] as bool?) ?? false,
      ownedQuantity: owned,
      remainingQuantity: remaining,
      maxPerOption: maxPer,
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
