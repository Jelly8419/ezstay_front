# EZStay SEO 구현 계획

> 작성일: 2026-03-26
> 목표: 검색 엔진 노출 극대화 (Google 중심, 네이버 보조)

---

## 현황 진단

| 항목 | 상태 | 비고 |
|------|------|------|
| `usePathUrlStrategy()` | ✅ 적용됨 | `main.dart:81` |
| Cloudflare Pages fallback (`_redirects`) | ❌ 없음 | 직접 URL 접근 시 404 |
| Flutter 앱 사이트맵 서브 페이지 | ❌ 제거됨 | hash URL 문제로 제거 → path URL 복원 필요 |
| 랜딩 페이지 메타태그/JSON-LD | ✅ 완료 | `landing/index.html` |
| JSON-LD SearchAction URL | ❌ hash URL | `#/guest?q=` → `/guest?q=` 수정 필요 |
| 랜딩 콘텐츠 서브 페이지 | ❌ 없음 | 단일 페이지 한계 |
| Google Search Console 등록 | ⏳ 런칭 후 | 외부 IP 오픈 필요 |

---

## Phase 1: Flutter 앱 Path URL 완성

> 예상 공수: 1~2시간 | 우선순위: 🔴 높음

`usePathUrlStrategy()`가 켜져 있어도 서버 fallback이 없으면
`ezstay.io/guest`처럼 직접 URL 접근 시 404가 납니다.
이 Phase가 완료되어야 사이트맵 등록이 실질적 의미를 가집니다.

### 작업 1-1. `building_map_app/web/_redirects` 생성

Cloudflare Pages에서 모든 경로를 Flutter `index.html`로 fallback 처리.

```
/* /index.html 200
```

**파일 위치**: `building_map_app/web/_redirects`

### 작업 1-2. `building_map_app/web/sitemap.xml` path URL로 복원

hash URL 제거 후 path URL로 재등록. 크롤링 가능한 공개 페이지만 포함.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://ezstay.io/</loc>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://ezstay.io/guest</loc>
    <changefreq>daily</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>https://ezstay.io/map</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

> `/login`, `/host` 등 인증 필요 페이지는 제외 (봇이 크롤링해도 리다이렉트되므로 SEO 손해)

### 작업 1-3. `landing/index.html` JSON-LD SearchAction URL 수정

```json
// 변경 전
"target": "https://ezstay.io/#/guest?q={search_term_string}"

// 변경 후
"target": "https://ezstay.io/guest?q={search_term_string}"
```

---

## Phase 2: 랜딩 페이지 콘텐츠 강화

> 예상 공수: 반나절 | 우선순위: 🟡 중간

구글은 콘텐츠 양과 깊이를 평가합니다.
단일 랜딩 페이지 하나로는 다양한 키워드로 노출되기 어렵습니다.

### 작업 2-1. SEO 서브 페이지 추가

| 파일 | 타겟 키워드 | 내용 |
|------|------------|------|
| `landing/seoul.html` | "서울 단기임대", "서울 한달살기" | 서울 지역별 단기임대 가이드 |
| `landing/guide.html` | "단기임대 계약 방법", "단기 월세 주의사항" | 단기임대 이용 가이드 |

### 작업 2-2. `landing/sitemap.xml`에 서브 페이지 추가

```xml
<url>
  <loc>https://www.ezstay.io/seoul.html</loc>
  <changefreq>monthly</changefreq>
  <priority>0.8</priority>
</url>
<url>
  <loc>https://www.ezstay.io/guide.html</loc>
  <changefreq>monthly</changefreq>
  <priority>0.7</priority>
</url>
```

---

## Phase 3: Google Search Console 연동 준비

> 예상 공수: 1시간 | 우선순위: 🟡 중간 (런칭 후 즉시)

### 작업 3-1. `landing/robots.txt` sitemap 경로 명시

```
User-agent: *
Allow: /

Sitemap: https://www.ezstay.io/sitemap.xml
Sitemap: https://ezstay.io/sitemap.xml
```

### 작업 3-2. Search Console 등록 절차 (런칭 후)

1. `https://www.ezstay.io` 속성 등록 → sitemap 제출
2. `https://ezstay.io` 속성 등록 → sitemap 제출
3. "URL 검사" 도구로 주요 페이지 수동 크롤링 요청

---

## 구현 순서

```
Phase 1-1 → Phase 1-2 → Phase 1-3 → Phase 3-1 → Phase 2 → Phase 3-2(런칭 후)
```

---

## 추가 전략 (선택, 별도 공수)

### 네이버 (한국 시장 점유율 고려)

| 방법 | 효과 | 공수 |
|------|------|------|
| 네이버 서치어드바이저 등록 | 중간 | 1시간 |
| 네이버 블로그 운영 (지역별 단기임대 후기) | 높음 | 지속적 |
| 네이버 플레이스 등록 (사업자 등록 필요) | 높음 | 1일 |

### 백링크 확보

- 부동산 커뮤니티 (네이버 카페, 디시인사이드 부동산 갤러리)
- 외국인 커뮤니티 (Reddit r/korea, Facebook 한국 외국인 그룹)
- 에어비앤비 대안 서비스 비교 블로그 기고

---

## 파일 변경 목록

| 파일 | 작업 | Phase |
|------|------|-------|
| `building_map_app/web/_redirects` | 신규 생성 | 1-1 |
| `building_map_app/web/sitemap.xml` | path URL로 복원 | 1-2 |
| `landing/index.html` | JSON-LD SearchAction URL 수정 | 1-3 |
| `landing/robots.txt` | Sitemap 경로 추가 | 3-1 |
| `landing/sitemap.xml` | 서브 페이지 추가 | 2-2 |
| `landing/seoul.html` | 신규 생성 | 2-1 |
| `landing/guide.html` | 신규 생성 | 2-1 |
