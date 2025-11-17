import 'pagination.dart';

/// 문의 카테고리 타입
enum InquiryCategoryType {
  general,
  reservation,
  payment,
  room,
  account,
  other;

  String get displayName {
    switch (this) {
      case InquiryCategoryType.general:
        return '일반 문의';
      case InquiryCategoryType.reservation:
        return '예약 문의';
      case InquiryCategoryType.payment:
        return '결제 문의';
      case InquiryCategoryType.room:
        return '방 등록 문의';
      case InquiryCategoryType.account:
        return '계정 문의';
      case InquiryCategoryType.other:
        return '기타 문의';
    }
  }

  static InquiryCategoryType fromString(String value) {
    return InquiryCategoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InquiryCategoryType.other,
    );
  }
}

/// 문의 상태
enum InquiryStatus {
  pending,
  answered,
  closed;

  String get displayName {
    switch (this) {
      case InquiryStatus.pending:
        return '확인중';
      case InquiryStatus.answered:
        return '답변완료';
      case InquiryStatus.closed:
        return '종료';
    }
  }

  static InquiryStatus fromString(String value) {
    return InquiryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InquiryStatus.pending,
    );
  }
}

/// 문의 모델
class Inquiry {
  final int id;
  final InquiryCategoryType categoryType;
  final String title;
  final String content;
  final InquiryStatus status;
  final String? answer;
  final DateTime createdAt;
  final DateTime? answeredAt;

  Inquiry({
    required this.id,
    required this.categoryType,
    required this.title,
    required this.content,
    required this.status,
    this.answer,
    required this.createdAt,
    this.answeredAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    try {
      return Inquiry(
        id: _parseField<int>(json, 'id'),
        categoryType: InquiryCategoryType.fromString(
          _parseField<String>(json, 'categoryType'),
        ),
        title: _parseField<String>(json, 'title'),
        content: json['content'] as String? ?? '',
        status: InquiryStatus.fromString(_parseField<String>(json, 'status')),
        answer: json['answer'] as String?,
        createdAt: DateTime.parse(_parseField<String>(json, 'createdAt')),
        answeredAt: json['answeredAt'] != null
            ? DateTime.parse(_parseField<String>(json, 'answeredAt'))
            : null,
      );
    } catch (e) {
      throw FormatException('Inquiry.fromJson 파싱 실패: $e\n원본 JSON: $json');
    }
  }

  static T _parseField<T>(Map<String, dynamic> json, String fieldName) {
    try {
      final value = json[fieldName];
      if (value == null) {
        throw FormatException('필드 "$fieldName"이 null입니다');
      }
      if (value is! T) {
        throw FormatException(
          '필드 "$fieldName" 타입 오류: 예상 $T, 실제 ${value.runtimeType}, 값: $value',
        );
      }
      return value;
    } catch (e) {
      throw FormatException('필드 "$fieldName" 파싱 실패: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryType': categoryType.name,
      'title': title,
      'content': content,
    };
  }
}

/// 문의 목록 응답
class InquiryListResponse {
  final List<Inquiry> inquiries;
  final Pagination pagination;

  InquiryListResponse({required this.inquiries, required this.pagination});

  factory InquiryListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return InquiryListResponse(
      inquiries: (data['inquiries'] as List)
          .map((item) => Inquiry.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        data['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}
