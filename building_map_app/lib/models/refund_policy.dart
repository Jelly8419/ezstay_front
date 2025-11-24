/// 환불 정책 모델
class RefundPolicy {
  final String policyType; // "약하게", "보통", "엄격하게"
  final String displayName; // 표시 이름
  final String description; // 설명
  final List<RefundRule> rules; // 환불 규칙 목록
  final SpecialRules? specialRules; // 특별 규칙

  RefundPolicy({
    required this.policyType,
    required this.displayName,
    required this.description,
    required this.rules,
    this.specialRules,
  });

  factory RefundPolicy.fromJson(Map<String, dynamic> json) {
    return RefundPolicy(
      policyType: json['policyType'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      rules: (json['rules'] as List<dynamic>)
          .map((rule) => RefundRule.fromJson(rule as Map<String, dynamic>))
          .toList(),
      specialRules: json['specialRules'] != null
          ? SpecialRules.fromJson(json['specialRules'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyType': policyType,
      'displayName': displayName,
      'description': description,
      'rules': rules.map((rule) => rule.toJson()).toList(),
      'specialRules': specialRules?.toJson(),
    };
  }

  /// 정책 타입의 한글 → 영문 매핑
  static String toEnglishType(String koreanType) {
    switch (koreanType) {
      case '약하게':
        return 'flexible';
      case '보통':
        return 'moderate';
      case '엄격하게':
        return 'strict';
      default:
        return koreanType;
    }
  }

  /// 정책 타입의 영문 → 한글 매핑
  static String toKoreanType(String englishType) {
    switch (englishType) {
      case 'flexible':
        return '약하게';
      case 'moderate':
        return '보통';
      case 'strict':
        return '엄격하게';
      default:
        return englishType;
    }
  }
}

/// 환불 규칙
class RefundRule {
  final String period; // "입주일 20일 이전"
  final int refundRate; // 100 (%)
  final String description; // "입주일 20일 이전"

  RefundRule({
    required this.period,
    required this.refundRate,
    required this.description,
  });

  factory RefundRule.fromJson(Map<String, dynamic> json) {
    return RefundRule(
      period: json['period'] as String,
      refundRate: json['refundRate'] as int,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'refundRate': refundRate,
      'description': description,
    };
  }
}

/// 특별 규칙
class SpecialRules {
  final String? alwaysRefund; // "청소비와 관리비는 100% 환불됩니다."

  SpecialRules({
    this.alwaysRefund,
  });

  factory SpecialRules.fromJson(Map<String, dynamic> json) {
    return SpecialRules(
      alwaysRefund: json['alwaysRefund'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alwaysRefund': alwaysRefund,
    };
  }
}
