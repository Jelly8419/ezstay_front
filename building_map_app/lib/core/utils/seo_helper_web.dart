import 'dart:convert';
import 'package:web/web.dart' as web;

/// Flutter Web 전용 SEO 헬퍼
class SeoHelper {
  SeoHelper._();

  static const String _baseUrl = 'https://ezstay.io';

  /// 페이지 타이틀, description, canonical, og:image, robots를 업데이트합니다.
  ///
  /// [title] — 브라우저 탭 및 검색 결과에 표시되는 제목
  /// [description] — 검색 결과 스니펫에 표시되는 설명 (생략 시 유지)
  /// [canonicalPath] — '/guest' 형식의 경로 (생략 시 canonical 미변경)
  /// [imageUrl] — 페이지별 og:image (생략 시 기존 값 유지)
  /// [noindex] — true 시 robots=noindex,nofollow (방 재고 없는 페이지 등)
  static void updatePage({
    required String title,
    String? description,
    String? canonicalPath,
    String? imageUrl,
    bool noindex = false,
  }) {
    web.document.title = title;

    if (description != null) {
      _setMetaByName('description', description);
      _setMetaByProperty('og:title', title);
      _setMetaByProperty('og:description', description);
      _setMetaByName('twitter:title', title);
      _setMetaByName('twitter:description', description);
    }

    if (canonicalPath != null) {
      final canonical = '$_baseUrl$canonicalPath';
      _setCanonical(canonical);
      _setMetaByProperty('og:url', canonical);
    }

    if (imageUrl != null) {
      final absoluteUrl = imageUrl.startsWith('http') ? imageUrl : '$_baseUrl$imageUrl';
      _setMetaByProperty('og:image', absoluteUrl);
      _setMetaByName('twitter:image', absoluteUrl);
    }

    _setMetaByName('robots', noindex ? 'noindex, nofollow' : 'index, follow');
  }

  /// 동적 JSON-LD 구조화 데이터를 `<head>`에 주입합니다.
  /// 같은 [scriptId]가 이미 있으면 교체합니다.
  static void injectJsonLd(
    Map<String, dynamic> schema, {
    String scriptId = 'dynamic-jsonld',
  }) {
    removeJsonLd(scriptId);
    final script = web.document.createElement('script') as web.HTMLScriptElement
      ..id = scriptId
      ..type = 'application/ld+json'
      ..text = jsonEncode(schema);
    web.document.head!.append(script);
  }

  /// id로 동적 JSON-LD 스크립트를 제거합니다.
  static void removeJsonLd(String scriptId) {
    web.document.head?.querySelector('#$scriptId')?.remove();
  }

  /// BreadcrumbList JSON-LD를 주입합니다.
  ///
  /// [crumbs] — `{'name': '홈', 'path': '/'}` 형태의 리스트 (순서대로)
  static void injectBreadcrumb(List<Map<String, String>> crumbs) {
    injectJsonLd(
      {
        '@context': 'https://schema.org',
        '@type': 'BreadcrumbList',
        'itemListElement': crumbs.asMap().entries.map((e) {
          return {
            '@type': 'ListItem',
            'position': e.key + 1,
            'name': e.value['name'],
            'item': '$_baseUrl${e.value['path']}',
          };
        }).toList(),
      },
      scriptId: 'breadcrumb-jsonld',
    );
  }

  /// Breadcrumb JSON-LD 제거 (페이지 dispose 시 호출 권장)
  static void removeBreadcrumb() {
    removeJsonLd('breadcrumb-jsonld');
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────────

  static void _setMetaByName(String name, String content) {
    final head = web.document.head;
    if (head == null) return;
    var el = head.querySelector('meta[name="$name"]');
    if (el == null) {
      el = web.document.createElement('meta')..setAttribute('name', name);
      head.append(el);
    }
    el.setAttribute('content', content);
  }

  static void _setMetaByProperty(String property, String content) {
    final head = web.document.head;
    if (head == null) return;
    var el = head.querySelector('meta[property="$property"]');
    if (el == null) {
      el = web.document.createElement('meta')..setAttribute('property', property);
      head.append(el);
    }
    el.setAttribute('content', content);
  }

  static void _setCanonical(String href) {
    final head = web.document.head;
    if (head == null) return;
    var el = head.querySelector('link[rel="canonical"]');
    if (el == null) {
      el = web.document.createElement('link')..setAttribute('rel', 'canonical');
      head.append(el);
    }
    el.setAttribute('href', href);
  }
}
