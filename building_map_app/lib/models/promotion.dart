/// 게스트가 방 상세 조회 시 자격이 있는 프로모션 이벤트
/// API: GET /api/rooms/:id → eligiblePromotions[]
class EligiblePromotion {
  final String eventCode;
  final String eventName;
  final int discountAmount;

  const EligiblePromotion({
    required this.eventCode,
    required this.eventName,
    required this.discountAmount,
  });

  factory EligiblePromotion.fromJson(Map<String, dynamic> json) {
    return EligiblePromotion(
      eventCode: json['eventCode'] as String? ?? '',
      eventName: json['eventName'] as String? ?? '',
      discountAmount: _parseInt(json['discountAmount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'eventCode': eventCode,
        'eventName': eventName,
        'discountAmount': discountAmount,
      };

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// 계약에 실제 적용된 프로모션 이벤트
/// API: POST /api/contracts/request, GET /api/contracts/host, GET /api/contracts/:id
///      → appliedPromotions[]
class AppliedPromotion {
  final String eventCode;
  final String eventName;
  final int discountAmount;
  final String? benefitType;

  const AppliedPromotion({
    required this.eventCode,
    required this.eventName,
    required this.discountAmount,
    this.benefitType,
  });

  factory AppliedPromotion.fromJson(Map<String, dynamic> json) {
    return AppliedPromotion(
      eventCode: json['eventCode'] as String? ?? '',
      eventName: json['eventName'] as String? ?? '',
      discountAmount: EligiblePromotion._parseInt(json['discountAmount']),
      // 백엔드 응답에 'benefitType' 또는 'benetfitType'(오타) 혼재 가능 — 둘 다 수용
      benefitType:
          (json['benefitType'] ?? json['benetfitType']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventCode': eventCode,
        'eventName': eventName,
        'discountAmount': discountAmount,
        if (benefitType != null) 'benefitType': benefitType,
      };
}

/// 프로모션 배열 파싱 유틸
List<T> parsePromotionList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}
