/// 문의 상태 enum
enum InquiryStatus {
  pending,
  answered,
  closed;

  static InquiryStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return InquiryStatus.pending;
      case 'answered':
        return InquiryStatus.answered;
      case 'closed':
        return InquiryStatus.closed;
      default:
        return InquiryStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case InquiryStatus.pending:
        return 'pending';
      case InquiryStatus.answered:
        return 'answered';
      case InquiryStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case InquiryStatus.pending:
        return '답변 대기';
      case InquiryStatus.answered:
        return '답변 완료';
      case InquiryStatus.closed:
        return '처리 완료';
    }
  }
}

/// 문의 카테고리 타입 enum
enum InquiryCategoryType {
  general,
  reservation,
  payment,
  room,
  account,
  other;

  static InquiryCategoryType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'general':
        return InquiryCategoryType.general;
      case 'reservation':
        return InquiryCategoryType.reservation;
      case 'payment':
        return InquiryCategoryType.payment;
      case 'room':
        return InquiryCategoryType.room;
      case 'account':
        return InquiryCategoryType.account;
      case 'other':
        return InquiryCategoryType.other;
      default:
        return InquiryCategoryType.general;
    }
  }

  String get value {
    switch (this) {
      case InquiryCategoryType.general:
        return 'general';
      case InquiryCategoryType.reservation:
        return 'reservation';
      case InquiryCategoryType.payment:
        return 'payment';
      case InquiryCategoryType.room:
        return 'room';
      case InquiryCategoryType.account:
        return 'account';
      case InquiryCategoryType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case InquiryCategoryType.general:
        return '일반';
      case InquiryCategoryType.reservation:
        return '계약/예약';
      case InquiryCategoryType.payment:
        return '결제';
      case InquiryCategoryType.room:
        return '방 정보';
      case InquiryCategoryType.account:
        return '계정';
      case InquiryCategoryType.other:
        return '기타';
    }
  }
}

/// 문의 모델
class Inquiry {
  final int id;
  final InquiryCategoryType categoryType;
  final String userType; // 'host' or 'guest'
  final String title;
  final String content;
  final InquiryStatus status;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Inquiry({
    required this.id,
    required this.categoryType,
    required this.userType,
    required this.title,
    required this.content,
    required this.status,
    this.answer,
    this.answeredAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as int,
      categoryType: InquiryCategoryType.fromString(json['categoryType'] as String),
      userType: (json['userType'] as String?) ?? 'guest',
      title: json['title'] as String,
      content: json['content'] as String,
      status: InquiryStatus.fromString(json['status'] as String),
      answer: json['answer'] as String?,
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryType': categoryType.value,
      'userType': userType,
      'title': title,
      'content': content,
      'status': status.value,
      'answer': answer,
      'answeredAt': answeredAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 날짜 포맷팅 (yyyy.MM.dd)
  String get formattedDate {
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// 답변 날짜 포맷팅 (yyyy.MM.dd)
  String? get formattedAnsweredDate {
    if (answeredAt == null) return null;
    return '${answeredAt!.year}.${answeredAt!.month.toString().padLeft(2, '0')}.${answeredAt!.day.toString().padLeft(2, '0')}';
  }

  /// 수정/삭제 가능 여부
  bool get canEdit => status == InquiryStatus.pending;
  bool get canDelete => status == InquiryStatus.pending;
}

/// 문의 생성 요청 DTO
class CreateInquiryRequest {
  final InquiryCategoryType categoryType;
  final String title;
  final String content;
  final String userType; // 'host' or 'guest'

  CreateInquiryRequest({
    required this.categoryType,
    required this.title,
    required this.content,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryType': categoryType.value,
      'title': title,
      'content': content,
      'userType': userType,
    };
  }
}

/// 문의 수정 요청 DTO
class UpdateInquiryRequest {
  final InquiryCategoryType? categoryType;
  final String? title;
  final String? content;

  UpdateInquiryRequest({
    this.categoryType,
    this.title,
    this.content,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (categoryType != null) map['categoryType'] = categoryType!.value;
    if (title != null) map['title'] = title;
    if (content != null) map['content'] = content;
    return map;
  }
}
