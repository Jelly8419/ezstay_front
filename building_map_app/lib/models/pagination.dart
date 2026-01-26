/// 페이지네이션 모델 (공통)
class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    try {
      return Pagination(
        currentPage: _parseField<int>(json, 'page', 'currentPage'),
        totalPages: _parseField<int>(json, 'totalPages', 'totalPages'),
        totalItems: _parseField<int>(json, 'total', 'totalItems'),
        itemsPerPage: _parseField<int>(json, 'limit', 'itemsPerPage'),
      );
    } catch (e) {
      throw FormatException('Pagination.fromJson 파싱 실패: $e\n원본 JSON: $json');
    }
  }

  static T _parseField<T>(Map<String, dynamic> json, String key, String fieldName) {
    try {
      final value = json[key];
      if (value == null) {
        throw FormatException('필드 "$fieldName" (JSON 키: "$key")이 null입니다');
      }
      if (value is! T) {
        throw FormatException(
            '필드 "$fieldName" (JSON 키: "$key") 타입 오류: 예상 $T, 실제 ${value.runtimeType}, 값: $value');
      }
      return value as T;
    } catch (e) {
      throw FormatException('필드 "$fieldName" (JSON 키: "$key") 파싱 실패: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
    };
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  /// 빈 페이지네이션 (데이터가 없을 때 사용)
  factory Pagination.empty() {
    return Pagination(
      currentPage: 1,
      totalPages: 1,
      totalItems: 0,
      itemsPerPage: 10,
    );
  }
}
