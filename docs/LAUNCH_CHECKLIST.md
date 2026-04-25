# EZstay 정식 런칭 체크리스트

> 목표 런칭일: **2026-05 초**
> 마지막 업데이트: 2026-04-21

---

## ⚠️ 런칭 D-Day 반드시 원복할 것

런칭 전까지는 "방 0개 + 사전 알림 신청 이벤트" 상태에 맞춰 문구/설정을 조정해둠.
정식 런칭 시 일반 서비스 카피로 **원복** 필요.

---

## 🔴 SEO / 메타 원복 (필수)

### 1. 홈 페이지 (`guest_home_page.dart`)

**현재 (이벤트 카피):**
```dart
title: 'EZstay (이지스테이) ― 단기임대 오픈 알림 신청 · 첫 계약 2만원 할인'
description: '단기임대 플랫폼 EZstay 정식 오픈 전 사전 알림 신청 시 첫 계약 2만원 할인. ...'
```

**런칭 후 원복:**
```dart
title: 'EZstay (이지스테이) ― 편리한 단기임대 방 구하기 · 방 등록'
description: '출장, 이사, 한달살기에 필요한 단기임대 숙소를 쉽고 빠르게. ...'
```

📍 파일: [lib/pages/guest/guest_home_page.dart:58-63](../building_map_app/lib/pages/guest/guest_home_page.dart#L58-L63)

---

### 2. 지도 페이지 (`map_screen.dart`)

**현재 (이벤트 카피):**
```dart
title: 'EZstay 정식 오픈 대기 중 · 알림 신청하기'
```

**런칭 후 원복:**
```dart
title: '지도로 단기임대 방 찾기 | EZstay (이지스테이)'
```

📍 파일: [lib/pages/guest/map_screen.dart:101-105](../building_map_app/lib/pages/guest/map_screen.dart#L101-L105)

---

### 3. `web/index.html` 정적 메타태그

**원복 항목:**
- `<title>` (line 30)
- `<meta name="description">` (line 31-32)
- `og:title`, `og:description` (line 39-40)
- `twitter:title`, `twitter:description` (line 49-50)
- `<noscript>` 본문 H1 (line 323)

📍 파일: [building_map_app/web/index.html](../building_map_app/web/index.html)

---

### 4. Event schema JSON-LD 제거

런칭 전 추가된 Event 구조화 데이터 **삭제**:
```html
<!-- 삭제할 블록 -->
<script type="application/ld+json">
{"@type": "Event", "name": "EZstay 정식 오픈 ..."}
</script>
```

📍 파일: [building_map_app/web/index.html](../building_map_app/web/index.html)

---

### 5. Event OG 이미지 교체

- **런칭 전**: `web/og-image-event.png` (이벤트 배너)
- **런칭 후**: `web/og-image-default.png` (서비스 기본 이미지)

`<meta property="og:image">` 경로 교체.

---

### 6. 오프닝 배너/모달 비활성화

**확인할 곳:**
- `OpeningEventModal.maybeShow` 호출부 (`guest_home_page.dart:70`)
- `_showOpeningBanner` 로직
- `_initOpeningBanner` 조건

**처리 방법:** 환경변수 또는 feature flag로 제어 권장
```dart
if (kLaunchMode) return;  // 런칭 후 모달 미노출
OpeningEventModal.maybeShow(...);
```

---

### 6-1. 지도 PRE-LAUNCH 플래그 ✅ 자동화 완료

더 이상 코드 토글 필요 없음. 백엔드 `GET /api/system/launch-status` 응답으로
제어되며, 관리자가 `LAUNCH_HOST_2026` 프로모션의 `startAt`을 세팅하는 순간
`isPrelaunch: false`로 전환됨.

- 서비스: [lib/services/launch_status_service.dart](../building_map_app/lib/services/launch_status_service.dart) (1시간 메모리 캐시, 실패 시 `true` 폴백)
- 등록: [lib/main.dart](../building_map_app/lib/main.dart) `MultiProvider`
- 구독: [lib/pages/guest/map_screen.dart](../building_map_app/lib/pages/guest/map_screen.dart) `_isPreLaunch` getter

**D-Day 확인:** 관리자 콘솔에서 `PATCH /api/admin/promotions/:id`로
`startAt` 세팅 → 새로고침한 클라이언트부터 지도 검색이 정상 동작.
(이미 접속 중인 세션은 캐시 만료까지 최대 1시간 지연 가능)

---

## 🟡 콘텐츠 / UI 원복

### 7. 랜딩 페이지 이벤트 카피

- `landing/index.html` 이벤트 문구 → 정상 서비스 카피
- `landing/event.html` (있다면) → 이벤트 종료 페이지로 전환 또는 삭제

### 8. 홈 화면 이벤트 배너

- 오픈 이벤트 관련 섹션 제거 또는 "런칭 기념 감사 인사"로 전환

---

## 🟢 검색 엔진 / 마케팅 원복

### 9. Google Search Console

- [ ] sitemap.xml 재제출 (방 상세 URL 포함 버전으로)
- [ ] "URL 검사" 도구로 주요 페이지 재크롤링 요청
  - `/`, `/guest`, `/map`, `/support`
- [ ] (선택) 이벤트 페이지가 남아있다면 "URL 제거" 요청

### 10. 네이버 서치어드바이저

- [ ] sitemap.xml 재제출
- [ ] 웹마스터 도구에서 "수집 요청"
- [ ] 사이트 설명 업데이트

### 11. sitemap.xml 업데이트

런칭 후 동적 방 상세 URL 포함 여부 결정:
- [ ] 방 재고 50개+ 시점에 `sitemap-rooms.xml` 도입
- [ ] 현재 고정 URL sitemap → sitemap index 구조로 변경

📍 파일: [building_map_app/web/sitemap.xml](../building_map_app/web/sitemap.xml)

---

## 🔧 배포 / 인프라

### 12. 환경변수

- [ ] `.env.production`의 `IS_PRODUCTION=true` 확인
- [ ] API_BASE_URL 프로덕션 엔드포인트 확인
- [ ] Firebase 프로덕션 프로젝트 키 확인

### 13. 캐시 설정

- [ ] Cloudflare Pages 캐시 purge (메타태그 변경 반영)
- [ ] `_headers`의 `Cache-Control` 확인
- [ ] 서비스 워커 해제 로직이 신규 유저에게 영향 없는지 확인

### 14. robots.txt / sitemap.xml

- [ ] `robots.txt`에 이벤트 전용 경로 Disallow 없는지 확인
- [ ] sitemap의 `changefreq`, `priority` 재조정 (`/guest`, `/map` 우선순위 ↑)

---

## 📊 측정 / 분석

### 15. Analytics

- [ ] GA4 이벤트: 런칭 전 전환 이벤트(`alert_signup`)는 유지, 런칭 후 신규 이벤트 추가
  - `signup_complete`, `first_booking`, `host_register_room`
- [ ] Firebase Analytics 기본 이벤트 확인

### 16. 모니터링 대시보드

- [ ] Sentry / 에러 트래킹 활성화 확인
- [ ] 성능 지표 (LCP, CLS, INP) 측정 시작
- [ ] API 응답 시간 모니터링

---

## 🎯 D-Day 작업 순서

**런칭 1주 전 (D-7)**
- [ ] 위 체크리스트 전체 리뷰
- [ ] 스테이징 환경에서 원복 버전 검증
- [ ] GSC / 네이버 서치어드바이저 준비 완료

**런칭 1일 전 (D-1)**
- [ ] 프로덕션 배포 리허설
- [ ] 캐시 purge 절차 확인
- [ ] 롤백 계획 수립

**런칭 당일 (D-Day)**
- [ ] 메타태그 원복 배포
- [ ] Cloudflare 캐시 전체 purge
- [ ] GSC sitemap 재제출
- [ ] 네이버 수집 요청
- [ ] 주요 페이지 수동 QA (`/`, `/guest`, `/map`, `/support`)
- [ ] SNS / 마케팅 채널 런칭 공지

**런칭 1주 후 (D+7)**
- [ ] 유입 키워드 분석
- [ ] Bounce rate / 이탈 페이지 확인
- [ ] Core Web Vitals 점수 체크
- [ ] A/B 테스트 결과 리뷰

---

## 📝 체크리스트 관리 규칙

- 이 문서를 **런칭 전후로 최종 업데이트** (각 항목 ✅ 체크 후 커밋)
- 누락 발견 시 즉시 이 문서에 추가
- 런칭 후 해당 섹션 아카이브 (`docs/archive/`로 이동)
