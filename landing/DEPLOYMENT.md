# EZStay SEO 랜딩 페이지 - 배포 & SEO 가이드

## 현재 상태

| 항목 | 상태 |
|------|------|
| 랜딩 페이지 코드 | 완료 |
| SEO 메타태그 / OG / Twitter Card | 완료 |
| JSON-LD 구조화 데이터 (Organization, WebSite, WebApplication, FAQPage) | 완료 |
| sitemap.xml / robots.txt | 완료 |
| Flutter 앱 index.html SEO 강화 | 완료 |
| AppColors 리브랜딩 (Electric Aqua) | 완료 |

---

## 1단계: Cloudflare Pages 배포 (지금 가능)

### 랜딩 페이지 배포

1. **Cloudflare Dashboard** → Pages → "Create a project"
2. **방법 A (Direct Upload)**: `landing/` 폴더를 직접 업로드
3. **방법 B (Git 연결)**: 리포지토리 연결 → Build output directory: `landing`
4. **Custom domain 설정**: `www.ezstay.io`
5. Cloudflare DNS에서 `www` CNAME → Cloudflare Pages URL 자동 추가됨

### 배포 파일 구조

```
landing/
├── index.html        ← 메인 랜딩 (SEO 최적화)
├── style.css         ← 반응형 스타일시트
├── robots.txt        ← 크롤러 설정
├── sitemap.xml       ← 사이트맵
├── _headers          ← Cloudflare 캐시/보안 헤더
├── _redirects        ← 리다이렉트 규칙
└── assets/
    ├── logo.png      ← 헤더/푸터 로고
    ├── favicon.png   ← 파비콘
    └── og-image.png  ← 소셜 공유 이미지
```

### DNS 최종 구조

```
www.ezstay.io    → Cloudflare Pages (SEO 랜딩 페이지)
ezstay.io        → Cloudflare Pages (Flutter Web 앱)
api.ezstay.io    → AWS EC2 (Node.js API 서버)
admin.ezstay.io  → Cloudflare Pages (React Admin)
```

---

## 2단계: Google Search Console 등록 (런칭 시, 외부 IP 오픈 후)

### 2-1. 소유권 인증

1. https://search.google.com/search-console 접속
2. "속성 추가" → `https://www.ezstay.io` 입력
3. **인증 방법 (택 1)**:
   - **(추천) DNS TXT 레코드**: Cloudflare DNS → TXT 레코드 추가
   - HTML 파일 업로드: 제공되는 파일을 `landing/`에 추가 후 재배포
   - HTML 메타태그: `index.html` `<head>`에 태그 추가 후 재배포

### 2-2. Sitemap 제출

1. Search Console → "Sitemaps" 메뉴
2. URL 입력: `https://www.ezstay.io/sitemap.xml`
3. "제출" 클릭

### 2-3. Flutter 앱 도메인도 등록

1. `https://ezstay.io`도 별도 속성으로 추가
2. sitemap: `https://ezstay.io/sitemap.xml` 제출

> **참고**: Flutter 앱은 hash URL 방식(`#/guest`, `#/host` 등)을 사용하므로 서브 페이지를 사이트맵에 등록해도 검색엔진이 별도 페이지로 인식하지 않습니다. `ezstay.io/sitemap.xml`에는 메인 진입점(`https://ezstay.io/`)만 등록되어 있습니다.

### 예상 일정

- 등록 후 **1~2주**: 브랜드 검색 ("EZStay", "이지스테이") 노출 시작
- 등록 후 **4~8주**: 키워드 검색 ("단기임대", "한달살기") 순위 진입 시작

---

## 3단계: 네이버 SEO (선택, 추가 공수 1일 이내)

### 3-1. 네이버 서치어드바이저 등록

1. https://searchadvisor.naver.com 접속
2. `www.ezstay.io` 사이트 등록
3. 소유권 인증 (HTML 메타태그 또는 파일 업로드)
4. sitemap 제출

### 3-2. 네이버 전용 메타태그 추가

`landing/index.html`의 `<head>`에 추가:

```html
<meta name="naver-site-verification" content="발급받은_인증코드" />
```

### 3-3. 네이버에서 더 효과적인 방법

- **네이버 플레이스** 등록 (사업자 정보 기반)
- **네이버 블로그** 운영 (단기임대 관련 콘텐츠)
- 네이버는 자체 콘텐츠(블로그/카페) 노출을 우대하므로, 기술적 SEO보다 콘텐츠 마케팅이 더 효과적

---

## OG 이미지 교체 가이드

현재 `assets/og-image.png`은 Flutter 앱 아이콘을 임시로 사용 중.
런칭 전 전용 OG 이미지를 제작하여 교체 권장:

- **권장 크기**: 1200 x 630px
- **내용**: EZStay 로고 + 서비스 한 줄 소개 + 브랜드 컬러 배경
- **파일 위치**: `landing/assets/og-image.png` 덮어쓰기

---

## 체크리스트

### 지금 (런칭 전)
- [ ] Cloudflare Pages에 `landing/` 배포
- [ ] `www.ezstay.io` 커스텀 도메인 연결
- [ ] 브라우저에서 `www.ezstay.io` 접속 확인
- [ ] OG 이미지 전용 제작 및 교체

### 런칭 시 (외부 IP 오픈 후)
- [ ] Google Search Console `www.ezstay.io` 등록
- [ ] Google Search Console `ezstay.io` 등록
- [ ] sitemap.xml 제출 (두 도메인 모두)
- [ ] Google에서 "site:www.ezstay.io" 검색하여 인덱싱 확인
- [ ] (선택) 네이버 서치어드바이저 등록
- [ ] (선택) 네이버 플레이스 등록
