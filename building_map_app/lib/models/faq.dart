/// FAQ 카테고리 모델
class FAQCategory {
  final int id;
  final String name;
  final String userType; // 'all', 'host', 'guest'
  final int displayOrder;
  final int faqCount;

  FAQCategory({
    required this.id,
    required this.name,
    required this.userType,
    required this.displayOrder,
    this.faqCount = 0,
  });

  factory FAQCategory.fromJson(Map<String, dynamic> json) {
    return FAQCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      userType: json['userType'] as String? ?? 'all',
      displayOrder: json['displayOrder'] as int? ?? 0,
      faqCount: json['faqCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userType': userType,
      'displayOrder': displayOrder,
      'faqCount': faqCount,
    };
  }
}

/// FAQ 모델
class FAQ {
  final int id;
  final int categoryId;
  final String question;
  final String answer;
  final int displayOrder;
  final int viewCount;
  final FAQCategory? category;

  FAQ({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.answer,
    required this.displayOrder,
    required this.viewCount,
    this.category,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      category: json['category'] != null
          ? FAQCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'question': question,
      'answer': answer,
      'displayOrder': displayOrder,
      'viewCount': viewCount,
      'category': category?.toJson(),
    };
  }

  /// 카테고리 이름 (null-safe)
  String get categoryName => category?.name ?? '';
}
