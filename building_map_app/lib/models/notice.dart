import 'pagination.dart';

/// 공지사항 모델
class Notice {
  final int id;
  final String title;
  final String? content; // 목록에서는 null, 상세에서만 포함
  final bool isImportant;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    this.content,
    required this.isImportant,
    required this.viewCount,
    this.publishedAt,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    try {
      return Notice(
        id: _parseField<int>(json, 'id'),
        title: _parseField<String>(json, 'title'),
        content: json['content'] as String?, // 목록에서는 null, 상세에서만 있음
        isImportant: json['isImportant'] as bool? ?? false,
        viewCount: json['viewCount'] as int? ?? 0,
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(_parseField<String>(json, 'publishedAt'))
            : null,
        createdAt: DateTime.parse(_parseField<String>(json, 'createdAt')),
      );
    } catch (e) {
      throw FormatException('Notice.fromJson 파싱 실패: $e\n원본 JSON: $json');
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
            '필드 "$fieldName" 타입 오류: 예상 $T, 실제 ${value.runtimeType}, 값: $value');
      }
      return value as T;
    } catch (e) {
      throw FormatException('필드 "$fieldName" 파싱 실패: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isImportant': isImportant,
      'viewCount': viewCount,
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 공지사항 목록 응답
class NoticeListResponse {
  final List<Notice> notices;
  final Pagination pagination;

  NoticeListResponse({
    required this.notices,
    required this.pagination,
  });

  factory NoticeListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NoticeListResponse(
      notices: (data['notices'] as List)
          .map((item) => Notice.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
          data['pagination'] as Map<String, dynamic>),
    );
  }
}
