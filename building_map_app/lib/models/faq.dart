/// FAQ 카테고리 모델
class FAQCategory {
  final int id;
  final String name;
  final String userType; // 'all', 'host', 'guest'
  final int displayOrder;
  final bool isActive;

  FAQCategory({
    required this.id,
    required this.name,
    required this.userType,
    required this.displayOrder,
    required this.isActive,
  });

  factory FAQCategory.fromJson(Map<String, dynamic> json) {
    return FAQCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      userType: json['userType'] as String? ?? 'all',
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userType': userType,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}

/// FAQ 모델
class FAQ {
  final int id;
  final String question;
  final String answer;
  final int viewCount;
  final String? categoryName;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.viewCount,
    this.categoryName,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    try {
      return FAQ(
        id: _parseField<int>(json, 'id'),
        question: _parseField<String>(json, 'question'),
        answer: _parseField<String>(json, 'answer'),
        viewCount: json['viewCount'] as int? ?? 0,
        categoryName: json['categoryName'] as String?,
      );
    } catch (e) {
      throw FormatException('FAQ.fromJson 파싱 실패: $e\n원본 JSON: $json');
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
      'question': question,
      'answer': answer,
      'viewCount': viewCount,
      if (categoryName != null) 'categoryName': categoryName,
    };
  }
}

/// FAQ 목록 응답 (카테고리별 그룹화)
class FAQListResponse {
  final Map<String, List<FAQ>> faqsByCategory;

  FAQListResponse({required this.faqsByCategory});

  factory FAQListResponse.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ API 응답: data는 List이고, 각 FAQ에 category 객체가 포함됨
      final dataList = json['data'] as List;
      final faqsByCategory = <String, List<FAQ>>{};

      for (var item in dataList) {
        final faqItem = item as Map<String, dynamic>;

        // category 객체에서 name 추출
        final categoryData = faqItem['category'] as Map<String, dynamic>;
        final categoryName = categoryData['name'] as String;

        // FAQ 객체 생성 (categoryName 추가)
        final faq = FAQ.fromJson({
          ...faqItem,
          'categoryName': categoryName,
        });

        // 카테고리별로 그룹화
        if (!faqsByCategory.containsKey(categoryName)) {
          faqsByCategory[categoryName] = [];
        }
        faqsByCategory[categoryName]!.add(faq);
      }

      return FAQListResponse(faqsByCategory: faqsByCategory);
    } catch (e) {
      throw FormatException('FAQListResponse.fromJson 파싱 실패: $e\n원본 JSON: $json');
    }
  }
}
