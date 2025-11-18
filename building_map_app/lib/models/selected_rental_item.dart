/// 선택된 렌탈 아이템 (수량 포함)
/// React UI의 optionalProducts 상태와 동일한 구조
class SelectedRentalItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final int quantity;

  const SelectedRentalItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
  });

  factory SelectedRentalItem.fromJson(Map<String, dynamic> json) {
    return SelectedRentalItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
    };
  }

  /// 총 가격 계산 (가격 × 수량)
  int get totalPrice => price * quantity;

  SelectedRentalItem copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    int? quantity,
  }) {
    return SelectedRentalItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
