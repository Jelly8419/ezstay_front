# EZStay SEO 구현 가이드

> 작성일: 2026-04-16  
> 대상: Flutter Web (ezstay.io) — 앱은 추후 별도 대응

---

## 현황 요약

| 항목 | 상태 |
|------|------|
| URL 전략 (path-based) | ✅ 적용 완료 |
| 기본 메타태그 (index.html) | ✅ 적용 완료 |
| OG / Twitter 카드 | ✅ 적용 완료 |
| JSON-LD 구조화 데이터 (정적) | ✅ 적용 완료 |
| robots.txt / sitemap.xml | ✅ 적용 완료 |
| 페이지별 동적 title/description | ✅ 구현 완료 |
| FAQPage JSON-LD (동적) | ✅ 구현 완료 |
| BreadcrumbList JSON-LD (동적) | ✅ 구현 완료 |
| Google Search Console 등록 | ⏳ 미완료 (수동 작업 필요) |
| 네이버 웹마스터도구 등록 | ⏳ 미완료 (수동 작업 필요) |

---

## 크롤러 접근 가능 페이지

> 로그인 없이 접근 가능한 페이지만 SEO 적용 대상입니다.  
> 인증이 필요한 경로(`/host/*`, `*/contracts/*`, `*/chat/*`, `*/my-page` 등)는 크롤러가 `/login`으로 리다이렉트됩니다.

| URL | 설명 | SEO 적용 |
|-----|------|---------|
| `/guest` | 숙소 검색 홈 | ✅ |
| `/map` | 지도 검색 | ✅ |
| `/guest/room/detail/:id` | 방 상세 (동적 타이틀) | ✅ |
| `/support` | 고객센터 | ✅ |
| `/support/notices` | 공지사항 | ✅ |
| `/support/faqs` | 자주 묻는 질문 | ✅ |

---

## 구현 상세

### 1. SeoHelper 유틸리티

**위치**: `lib/core/utils/`

| 파일 | 역할 |
|------|------|
| `seo_helper.dart` | conditional export 진입점 |
| `seo_helper_web.dart` | Web 실제 구현 (`package:web`) |
| `seo_helper_stub.dart` | 비웹 빌드용 no-op |

**주요 메서드**:

```dart
// 페이지 title / description / canonical 업데이트
SeoHelper.updatePage(
  title: '페이지 타이틀 | EZStay',
  description: '페이지 설명문 (160자 이내 권장)',
  canonicalPath: '/경로',  // 예: '/guest'
);

// JSON-LD 구조화 데이터 주입 (id로 관리, 중복 시 교체)
SeoHelper.injectJsonLd(schema, scriptId: 'my-jsonld');

// JSON-LD 제거 (dispose 시 호출)
SeoHelper.removeJsonLd('my-jsonld');

// BreadcrumbList 주입 (내부적으로 injectJsonLd 사용)
SeoHelper.injectBreadcrumb([
  {'name': '홈', 'path': '/'},
  {'name': '고객센터', 'path': '/support'},
  {'name': '공지사항', 'path': '/support/notices'},
]);
```

### 2. 페이지별 적용 패턴

```dart
@override
void initState() {
  super.initState();
  // 기존 로직 ...
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SeoHelper.updatePage(
      title: '페이지 타이틀 | EZStay',
      description: '설명',
      canonicalPath: '/경로',
    );
    SeoHelper.injectBreadcrumb([/* ... */]);
  });
}

@override
void dispose() {
  SeoHelper.removeJsonLd('breadcrumb-jsonld'); // 필요 시
  super.dispose();
}
```

### 3. 방 상세 페이지 — 동적 데이터 기반 SEO

API 로드 완료 후 `room` 데이터를 사용해 메타 업데이트:

```dart
// _loadRoomDetail() 내부, room != null && !isSnapshot 조건
final monthlyPrice = (room.monthlyRent / 10000).round();
SeoHelper.updatePage(
  title: '${room.roomName} | EZStay',
  description: '${room.address} · ${room.buildingType} · 월 $monthlyPrice만원~.',
  canonicalPath: '/guest/room/detail/${room.id}',
);
SeoHelper.injectBreadcrumb([
  {'name': '홈', 'path': '/'},
  {'name': '숙소 찾기', 'path': '/guest'},
  {'name': room.roomName, 'path': '/guest/room/detail/${room.id}'},
]);
```

### 4. FAQ 구조화 데이터

API 데이터 로드 후 `FAQPage` JSON-LD 주입:

```dart
// _fetchFAQs() 완료 후 호출
void _injectFaqJsonLd(List<FAQ> faqs) {
  SeoHelper.injectJsonLd(
    {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      'mainEntity': faqs.map((faq) => {
        '@type': 'Question',
        'name': faq.question,
        'acceptedAnswer': {'@type': 'Answer', 'text': faq.answer},
      }).toList(),
    },
    scriptId: 'faq-jsonld',
  );
}
```

### 5. sitemap.xml 현황

**위치**: `web/sitemap.xml`

```
https://ezstay.io/           priority 1.0  weekly
https://ezstay.io/guest      priority 0.9  daily
https://ezstay.io/map        priority 0.8  daily
https://ezstay.io/support    priority 0.6  weekly
https://ezstay.io/support/notices  priority 0.5  weekly
https://ezstay.io/support/faqs    priority 0.5  monthly
```

> 방 상세 페이지(`/guest/room/detail/:id`)는 동적 URL이므로 sitemap 자동 생성이 필요하면 백엔드에서 sitemap 생성 API를 만들거나 별도 스크립트로 관리합니다.

---

## 배포 인프라 구조

```
Cloudflare DNS (ezstay.io)
  └── Cloudflare Pages → ezstay.io       (Flutter Web, master 브랜치 자동배포)
  └── Cloudflare Pages → admin.ezstay.io (React Admin, main 브랜치 자동배포)
  └── AWS EC2          → api.ezstay.io   (Node.js API, master 브랜치 자동배포)
                              └── AWS RDS MySQL
                              └── Docker Redis
                              └── AWS S3 (이미지)
```

> `ezstay.io` (Flutter Web)은 **Cloudflare Pages**에서 서빙됩니다.  
> DNS는 **Cloudflare**에서 직접 관리하므로 별도 등록업체 접속 없이 Cloudflare 대시보드에서 처리합니다.

---

## Phase 4 — Google Search Console 등록

### 준비물
- Google 계정
- Cloudflare 대시보드 접근 권한 (`ezstay.io` DNS 관리)

### Step 1. Search Console 속성 추가

1. [Google Search Console](https://search.google.com/search-console) 접속
2. 좌측 상단 속성 드롭다운 → **속성 추가**
3. **도메인** 탭 선택 → `ezstay.io` 입력 → 계속

### Step 2. Cloudflare DNS로 소유권 인증

Google이 TXT 레코드를 제공합니다:
```
google-site-verification=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Cloudflare 대시보드에서 추가:**

1. [Cloudflare Dashboard](https://dash.cloudflare.com) 로그인
2. `ezstay.io` 도메인 선택
3. 좌측 메뉴 **DNS** → **Records** 탭
4. **Add record** 클릭
   ```
   Type  : TXT
   Name  : @
   Content: google-site-verification=xxxxxxxx...
   TTL   : Auto
   Proxy : DNS only (회색 구름) ← 반드시 Proxied 아닌 DNS only
   ```
5. **Save** 클릭
6. Search Console로 돌아와 **확인** 클릭

> Cloudflare는 DNS 전파가 빠릅니다. 보통 수 분 이내 인증 완료됩니다.

### Step 3. sitemap 제출

1. 좌측 메뉴 **Sitemaps** 클릭
2. URL 입력란에 `https://ezstay.io/sitemap.xml` 입력 후 **제출** (풀 URL로 입력해야 정상 처리됨)
3. 상태가 **성공**으로 표시되면 완료

### Step 4. 주요 페이지 색인 요청

1. 상단 URL 검색창에 아래 URL 순서대로 입력
2. 각 URL마다 **URL 검사** → **색인 생성 요청** 클릭

```
https://ezstay.io/
https://ezstay.io/guest
https://ezstay.io/map
https://ezstay.io/support
https://ezstay.io/support/notices
https://ezstay.io/support/faqs
```

> 색인 반영까지 수 일~수 주 소요될 수 있습니다.

---

## Phase 4 — 네이버 웹마스터도구 등록

> 네이버는 DNS 인증을 지원하지 않습니다.  
> **HTML 메타태그 방식**을 사용합니다 — `web/index.html` 수정 후 Cloudflare Pages 자동배포로 처리합니다.

### Step 1. 웹마스터도구 사이트 추가

1. [네이버 웹마스터도구](https://searchadvisor.naver.com) 접속
2. 네이버 계정 로그인
3. **사이트 추가** → `https://ezstay.io` 입력

### Step 2. 메타태그 소유권 인증

1. 네이버가 제공하는 메타태그 복사:
   ```html
   <meta name="naver-site-verification" content="여기에_값" />
   ```

2. `web/index.html` `<head>` 안에 추가 (google 태그 아래 나란히):
   ```html
   <!-- Google Search Console 소유권 인증 -->
   <meta name="google-site-verification" content="google_값" />
   <!-- 네이버 웹마스터도구 소유권 인증 -->
   <meta name="naver-site-verification" content="naver_값" />
   ```

3. **master 브랜치에 push** → Cloudflare Pages 자동배포 대기 (보통 1~3분)

4. 배포 완료 후 네이버 웹마스터도구에서 **소유확인** 클릭

### Step 3. sitemap 제출

1. 좌측 **요청** → **사이트맵 제출**
2. `https://ezstay.io/sitemap.xml` 입력 후 확인

### Step 4. 웹페이지 수집 요청

1. 좌측 **요청** → **웹페이지 수집**
2. 주요 URL 순서대로 입력 후 수집 요청:
   ```
   https://ezstay.io/guest
   https://ezstay.io/map
   https://ezstay.io/support/faqs
   https://ezstay.io/support/notices
   ```

---

## 전체 진행 순서 체크리스트

```
[ ] 1. 외부 IP 차단 해제
[ ] 2. flutter build web 후 master push → Cloudflare Pages 자동배포
[ ] 3. https://ezstay.io 브라우저 접속 정상 확인

[ ] 4. Google Search Console 속성 추가
[ ] 5. Cloudflare DNS에 TXT 레코드 추가 (google-site-verification)
[ ] 6. Google 소유권 인증 완료
[ ] 7. sitemap.xml 제출
[ ] 8. 주요 페이지 색인 요청 (6개 URL)

[ ] 9. 네이버 웹마스터도구 사이트 추가
[ ] 10. web/index.html에 naver-site-verification 메타태그 추가
[ ] 11. master push → Cloudflare Pages 자동배포 확인
[ ] 12. 네이버 소유확인 클릭
[ ] 13. sitemap.xml 제출
[ ] 14. 웹페이지 수집 요청
```

---

## 향후 개선 과제

### 단기
- [ ] 방 상세 페이지 OG 이미지 동적 설정 (`og:image`를 숙소 대표 이미지로)
- [ ] robots.txt에 `/login`, `/register` 등 색인 불필요 경로 `Disallow` 추가 검토

### 중기
- [ ] 동적 sitemap 생성 (백엔드 API 또는 빌드 스크립트로 방 목록 URL 자동 생성)
- [ ] 지역별 랜딩 페이지 (예: `/guest?area=강남구`) — 검색 트래픽 유입 강화
- [ ] 공지사항 개별 페이지 SEO (`/support/notices/:id`)

### 장기
- [ ] SSR(Server-Side Rendering) 도입 검토 — Flutter Web SPA는 크롤러가 JS 렌더링 결과를 기다려야 하므로 색인 품질에 한계가 있음
- [ ] Google Analytics 4 이벤트와 Search Console 연동하여 검색 유입 분석
