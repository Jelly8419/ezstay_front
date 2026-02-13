/// 방 상세페이지에서 계산된 금액 정보
/// PRD: 반드시 상세페이지 계산값 그대로 사용하고 재계산 금지
class CalculatedPricing {
  final int totalDays;
  final int totalWeeks;
  final int rentalFee;
  final int maintenanceFee;
  final int cleaningFee;
  final int discount;
  final String? discountType; // 'long_term', 'quick_move_in', null
  final int? longTermWeeks; // 장기계약 기준 주수
  final int? longTermDiscount; // 장기계약 할인율 (%)
  final int? quickMoveInDiscount; // 빠른 입주 할인 금액
  final int platformFee;
  final int rentalItemsFee;
  final int subtotal;
  final int totalUsageFee;
  final int deposit;
  final int finalTotalAmount;

  const CalculatedPricing({
    required this.totalDays,
    required this.totalWeeks,
    required this.rentalFee,
    required this.maintenanceFee,
    required this.cleaningFee,
    this.discount = 0,
    this.discountType,
    this.longTermWeeks,
    this.longTermDiscount,
    this.quickMoveInDiscount,
    required this.platformFee,
    this.rentalItemsFee = 0,
    required this.subtotal,
    required this.totalUsageFee,
    required this.deposit,
    required this.finalTotalAmount,
  });

  factory CalculatedPricing.fromJson(Map<String, dynamic> json) {
    return CalculatedPricing(
      totalDays: json['totalDays'] as int? ?? 0,
      totalWeeks: json['totalWeeks'] as int? ?? 0,
      rentalFee: json['rentalFee'] as int? ?? 0,
      maintenanceFee: json['maintenanceFee'] as int? ?? 0,
      cleaningFee: json['cleaningFee'] as int? ?? 0,
      discount: json['discount'] as int? ?? 0,
      discountType: json['discountType'] as String?,
      longTermWeeks: json['longTermWeeks'] as int?,
      longTermDiscount: json['longTermDiscount'] as int?,
      quickMoveInDiscount: json['quickMoveInDiscount'] as int?,
      platformFee: json['platformFee'] as int? ?? 0,
      rentalItemsFee: json['rentalItemsFee'] as int? ?? 0,
      subtotal: json['subtotal'] as int? ?? 0,
      totalUsageFee: json['totalUsageFee'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 300000,
      finalTotalAmount: json['finalTotalAmount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDays': totalDays,
      'totalWeeks': totalWeeks,
      'rentalFee': rentalFee,
      'maintenanceFee': maintenanceFee,
      'cleaningFee': cleaningFee,
      'discount': discount,
      if (discountType != null) 'discountType': discountType,
      if (longTermWeeks != null) 'longTermWeeks': longTermWeeks,
      if (longTermDiscount != null) 'longTermDiscount': longTermDiscount,
      if (quickMoveInDiscount != null) 'quickMoveInDiscount': quickMoveInDiscount,
      'platformFee': platformFee,
      'rentalItemsFee': rentalItemsFee,
      'subtotal': subtotal,
      'totalUsageFee': totalUsageFee,
      'deposit': deposit,
      'finalTotalAmount': finalTotalAmount,
    };
  }

  /// 빈 가격 정보 (날짜 미선택 시)
  static const CalculatedPricing empty = CalculatedPricing(
    totalDays: 0,
    totalWeeks: 0,
    rentalFee: 0,
    maintenanceFee: 0,
    cleaningFee: 0,
    platformFee: 0,
    subtotal: 0,
    totalUsageFee: 0,
    deposit: 300000,
    finalTotalAmount: 0,
  );

  /// 유효한 가격 정보인지 확인
  bool get isValid => totalDays > 0 && finalTotalAmount > 0;

  CalculatedPricing copyWith({
    int? totalDays,
    int? totalWeeks,
    int? rentalFee,
    int? maintenanceFee,
    int? cleaningFee,
    int? discount,
    String? discountType,
    int? longTermWeeks,
    int? longTermDiscount,
    int? quickMoveInDiscount,
    int? platformFee,
    int? rentalItemsFee,
    int? subtotal,
    int? totalUsageFee,
    int? deposit,
    int? finalTotalAmount,
  }) {
    return CalculatedPricing(
      totalDays: totalDays ?? this.totalDays,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      rentalFee: rentalFee ?? this.rentalFee,
      maintenanceFee: maintenanceFee ?? this.maintenanceFee,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      longTermWeeks: longTermWeeks ?? this.longTermWeeks,
      longTermDiscount: longTermDiscount ?? this.longTermDiscount,
      quickMoveInDiscount: quickMoveInDiscount ?? this.quickMoveInDiscount,
      platformFee: platformFee ?? this.platformFee,
      rentalItemsFee: rentalItemsFee ?? this.rentalItemsFee,
      subtotal: subtotal ?? this.subtotal,
      totalUsageFee: totalUsageFee ?? this.totalUsageFee,
      deposit: deposit ?? this.deposit,
      finalTotalAmount: finalTotalAmount ?? this.finalTotalAmount,
    );
  }
}

/// 선택된 렌탈 아이템 (수량 포함)
class SelectedRentalItem {
  final int id;
  final String name;
  final String? description;
  final int price;
  final int quantity;

  const SelectedRentalItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
  });

  factory SelectedRentalItem.fromJson(Map<String, dynamic> json) {
    return SelectedRentalItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as int,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'quantity': quantity,
    };
  }

  /// API payload용 간소화된 형식
  Map<String, dynamic> toApiJson() {
    return {
      'itemId': id,
      'quantity': quantity,
    };
  }

  /// 아이템 총 금액
  int get totalPrice => price * quantity;
}
