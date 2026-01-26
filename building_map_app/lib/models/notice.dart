/// 공지사항 모델
class Notice {
  final int id;
  final String title;
  final String? content;
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
    return Notice(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String?,
      isImportant: json['isImportant'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
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

  /// 날짜 포맷팅 (yyyy.MM.dd)
  String get formattedDate {
    final date = publishedAt ?? createdAt;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 조회수 포맷팅
  String get formattedViewCount {
    if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }
}
