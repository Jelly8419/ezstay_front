/// 자동 메시지 템플릿 모델 (React AutoMessageManagement.tsx 호환)

/// 발송 트리거 타입
enum TriggerType {
  contractConfirmed('contract_confirmed', '계약 확정(결제 완료) 즉시'),
  checkin('checkin', '입주일 기준'),
  checkout('checkout', '퇴실일 기준');

  final String value;
  final String displayName;
  const TriggerType(this.value, this.displayName);

  static TriggerType fromString(String value) {
    return TriggerType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerType.checkin,
    );
  }
}

/// 발송 트리거 설정
class MessageTrigger {
  final TriggerType type;
  final int? daysOffset; // 0=당일, 1=1일전, 2=2일전...
  final String? time; // "09:00" 형식

  MessageTrigger({
    required this.type,
    this.daysOffset,
    this.time,
  });

  factory MessageTrigger.fromJson(Map<String, dynamic> json) {
    return MessageTrigger(
      type: TriggerType.fromString(json['type'] ?? 'checkin'),
      daysOffset: json['daysOffset'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (daysOffset != null) 'daysOffset': daysOffset,
      if (time != null) 'time': time,
    };
  }

  MessageTrigger copyWith({
    TriggerType? type,
    int? daysOffset,
    String? time,
  }) {
    return MessageTrigger(
      type: type ?? this.type,
      daysOffset: daysOffset ?? this.daysOffset,
      time: time ?? this.time,
    );
  }

  /// 발송 시점 표시 문자열
  String get displayText {
    if (type == TriggerType.contractConfirmed) {
      return '계약 확정(결제 완료) 즉시';
    }

    final baseText = type == TriggerType.checkin ? '입주일' : '퇴실일';
    final dayText = daysOffset == 0 ? '당일' : '$daysOffset일 전';
    final timeText = time ?? '09:00';

    return '$baseText $dayText $timeText';
  }
}

/// 자동 메시지 템플릿
class AutoMessageTemplate {
  final String id;
  final String title;
  final String content;
  final MessageTrigger trigger;
  final List<String> appliedProperties; // 적용된 방 ID 목록
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AutoMessageTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.trigger,
    required this.appliedProperties,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory AutoMessageTemplate.fromJson(Map<String, dynamic> json) {
    return AutoMessageTemplate(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      trigger: json['trigger'] != null
          ? MessageTrigger.fromJson(json['trigger'])
          : MessageTrigger(type: TriggerType.checkin),
      appliedProperties: List<String>.from(json['appliedProperties'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'trigger': trigger.toJson(),
      'appliedProperties': appliedProperties,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  AutoMessageTemplate copyWith({
    String? id,
    String? title,
    String? content,
    MessageTrigger? trigger,
    List<String>? appliedProperties,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutoMessageTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      trigger: trigger ?? this.trigger,
      appliedProperties: appliedProperties ?? this.appliedProperties,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 방 정보 (자동 메시지 적용용)
class PropertyInfo {
  final String id;
  final String name;

  PropertyInfo({
    required this.id,
    required this.name,
  });

  factory PropertyInfo.fromJson(Map<String, dynamic> json) {
    return PropertyInfo(
      id: json['id'].toString(),
      name: json['name'] ?? json['roomName'] ?? '',
    );
  }
}
