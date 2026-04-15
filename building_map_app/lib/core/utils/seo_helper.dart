/// SEO 헬퍼 — 페이지별 동적 title / description / canonical 업데이트
///
/// Flutter Web에서만 실제로 동작하며, 非웹 빌드에서는 no-op입니다.
/// GoRouter 각 경로의 builder 또는 페이지 initState에서 호출하세요.
///
/// 사용 예:
/// ```dart
/// SeoHelper.updatePage(
///   title: '숙소 찾기 | EZStay',
///   description: '전국 단기임대 숙소를 지도와 리스트로 검색하세요.',
///   canonicalPath: '/guest',
/// );
/// ```
library;

export 'seo_helper_stub.dart'
    if (dart.library.html) 'seo_helper_web.dart';
