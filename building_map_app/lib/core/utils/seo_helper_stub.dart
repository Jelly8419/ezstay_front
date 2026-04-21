/// Non-web 빌드용 no-op stub
class SeoHelper {
  SeoHelper._();

  static void updatePage({
    required String title,
    String? description,
    String? canonicalPath,
    String? imageUrl,
    bool noindex = false,
  }) {}

  static void injectJsonLd(Map<String, dynamic> schema, {String scriptId = 'dynamic-jsonld'}) {}

  static void removeJsonLd(String scriptId) {}

  static void injectBreadcrumb(List<Map<String, String>> crumbs) {}

  static void removeBreadcrumb() {}
}
