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

  /// 정책 타입 표시 라벨 (한글/영문 모두 대응)
  static String getLabel(String policyType) {
    switch (policyType.toLowerCase()) {
      case 'flexible':
      case '약하게':
        return '유연';
      case 'moderate':
      case '보통':
        return '보통';
      case 'strict':
      case '엄격하게':
        return '엄격';
      default:
        return policyType.isNotEmpty ? policyType : '기본';
    }
  }

  /// 정책 타입 색상 코드 (한글/영문 모두 대응)
  static int getColorValue(String policyType) {
    switch (policyType.toLowerCase()) {
      case 'flexible':
      case '약하게':
        return 0xFF4CAF50; // Colors.green
      case 'moderate':
      case '보통':
        return 0xFFFF9800; // Colors.orange
      case 'strict':
      case '엄격하게':
        return 0xFFF44336; // Colors.red
      default:
        return 0xFF9E9E9E; // Colors.grey
    }
  }
}

/// 환불 규칙
class RefundRule {
  final int? daysBeforeMin;
  final int? daysBeforeMax;
  final int refundRate; // 100 (%)
  final bool isSameDayCancellation;
  final String description;

  RefundRule({
    this.daysBeforeMin,
    this.daysBeforeMax,
    required this.refundRate,
    required this.isSameDayCancellation,
    required this.description,
  });

  factory RefundRule.fromJson(Map<String, dynamic> json) {
    return RefundRule(
      daysBeforeMin: json['daysBeforeMin'] as int?,
      daysBeforeMax: json['daysBeforeMax'] as int?,
      refundRate: json['refundRate'] as int? ?? 0,
      isSameDayCancellation: json['isSameDayCancellation'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daysBeforeMin': daysBeforeMin,
      'daysBeforeMax': daysBeforeMax,
      'refundRate': refundRate,
      'isSameDayCancellation': isSameDayCancellation,
      'description': description,
    };
  }

  /// daysBeforeMin/Max → 사람이 읽기 좋은 기간 문자열
  String get periodLabel {
    if (daysBeforeMin == null && daysBeforeMax == null) return '';
    if (daysBeforeMin == 0) return '입주일 $daysBeforeMin일 이전';
    return '입주일 ${daysBeforeMax ?? daysBeforeMin}일 이전';
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
