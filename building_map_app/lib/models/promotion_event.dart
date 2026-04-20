/// 프로모션 이벤트 대상 역할
enum TargetRole { host, guest }

/// 프로모션 혜택 종류
enum BenefitType { hostFeeWaiver, guestDiscount, unknown }

/// 로그인 사용자의 프로모션 참여 상태 (비로그인 시 null)
class PromotionUserStatus {
  final bool isParticipant;
  final bool hasConsumed;

  const PromotionUserStatus({
    required this.isParticipant,
    required this.hasConsumed,
  });

  factory PromotionUserStatus.fromJson(Map<String, dynamic> json) {
    return PromotionUserStatus(
      isParticipant: json['isParticipant'] as bool? ?? false,
      hasConsumed: json['hasConsumed'] as bool? ?? false,
    );
  }
}

/// 프로모션 이벤트 (GET /api/promotions/active 응답 요소)
class PromotionEvent {
  final String code;
  final String name;
  final String? description;
  final TargetRole targetRole;
  final BenefitType benefitType;
  final int discountAmount;
  final DateTime? startAt;
  final DateTime? endAt;
  final PromotionUserStatus? userStatus;

  const PromotionEvent({
    required this.code,
    required this.name,
    required this.description,
    required this.targetRole,
    required this.benefitType,
    required this.discountAmount,
    required this.startAt,
    required this.endAt,
    required this.userStatus,
  });

  factory PromotionEvent.fromJson(Map<String, dynamic> json) {
    return PromotionEvent(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      targetRole: _parseTargetRole(json['targetRole'] as String?),
      benefitType: _parseBenefitType(json['benefitType'] as String?),
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      startAt: _parseDate(json['startAt']),
      endAt: _parseDate(json['endAt']),
      userStatus: json['userStatus'] is Map<String, dynamic>
          ? PromotionUserStatus.fromJson(
              json['userStatus'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static TargetRole _parseTargetRole(String? value) {
    switch (value) {
      case 'HOST':
        return TargetRole.host;
      case 'GUEST':
      default:
        return TargetRole.guest;
    }
  }

  static BenefitType _parseBenefitType(String? value) {
    switch (value) {
      case 'HOST_FEE_WAIVER':
        return BenefitType.hostFeeWaiver;
      case 'GUEST_DISCOUNT':
        return BenefitType.guestDiscount;
      default:
        return BenefitType.unknown;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
