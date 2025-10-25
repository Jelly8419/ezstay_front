# 🌐 플러터 웹 출시 가이드

## 📋 출시 전 체크리스트

### 1. 성능 최적화 ✅

#### 이미지 최적화
```dart
// ❌ 나쁜 예: 큰 원본 이미지 로드
Image.network('https://example.com/large-image.jpg')

// ✅ 좋은 예: 캐싱과 크기 제한
CachedNetworkImage(
  imageUrl: 'https://example.com/large-image.jpg',
  placeholder: (context, url) => Shimmer(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
  maxHeightDiskCache: 800,
  maxWidthDiskCache: 800,
)
```

#### 지연 로딩 (Lazy Loading)
```dart
// 리스트에서 이미지를 지연 로딩
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return PropertyCard(...); // 보이는 것만 렌더링
  },
)
```

#### 번들 사이즈 줄이기
```yaml
# pubspec.yaml
flutter:
  # 사용하지 않는 폰트 제거
  fonts:
    - family: Pretendard
      fonts:
        - asset: fonts/Pretendard-Regular.ttf
        - asset: fonts/Pretendard-Bold.ttf
          weight: 700
```

---

### 2. SEO 최적화 🔍

#### HTML 메타 태그 설정
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- SEO 메타 태그 -->
  <title>단기임대 No.1 - 편리하고 안전한 단기 숙소 찾기</title>
  <meta name="description" content="출장, 이사, 한달살기에 필요한 단기임대 숙소를 쉽고 빠르게. 1주일부터 계약 가능한 전국의 원룸, 오피스텔, 아파트를 찾아보세요.">
  <meta name="keywords" content="단기임대, 한달살기, 원룸, 오피스텔, 단기숙소, 출장숙소">
  
  <!-- Open Graph (소셜 미디어 공유) -->
  <meta property="og:title" content="단기임대 No.1 - 편리하고 안전한 단기 숙소 찾기">
  <meta property="og:description" content="출장, 이사, 한달살기에 필요한 단기임대 숙소를 쉽고 빠르게">
  <meta property="og:image" content="https://yourdomain.com/og-image.jpg">
  <meta property="og:url" content="https://yourdomain.com">
  <meta property="og:type" content="website">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="단기임대 No.1">
  <meta name="twitter:description" content="편리하고 안전한 단기 숙소 찾기">
  <meta name="twitter:image" content="https://yourdomain.com/twitter-card.jpg">
  
  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

#### robots.txt 설정
```txt
# web/robots.txt
User-agent: *
Allow: /

Sitemap: https://yourdomain.com/sitemap.xml
```

---

### 3. 반응형 디자인 검증 📱💻

#### 테스트할 화면 크기
- [ ] 모바일: 360px ~ 599px
- [ ] 태블릿: 600px ~ 1279px
- [ ] 데스크톱: 1280px ~ 1920px
- [ ] 대형 모니터: 1920px+

#### 브라우저 호환성
- [ ] Chrome (최신)
- [ ] Safari (최신)
- [ ] Firefox (최신)
- [ ] Edge (최신)
- [ ] 모바일 Safari (iOS)
- [ ] 모바일 Chrome (Android)

---

### 4. 로딩 속도 개선 ⚡

#### 스플래시 스크린 추가
```html
<!-- web/index.html의 <body> 안에 -->
<div id="loading" style="
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
">
  <div style="text-align: center;">
    <img src="icons/Icon-192.png" width="80" height="80" alt="로고">
    <div style="margin-top: 20px; color: #2196F3; font-size: 16px;">
      로딩 중...
    </div>
  </div>
</div>

<script>
  window.addEventListener('flutter-first-frame', function() {
    document.getElementById('loading').style.display = 'none';
  });
</script>
```

#### CanvasKit vs HTML Renderer
```bash
# HTML 렌더러 (더 작은 번들, 더 빠른 로딩)
flutter build web --web-renderer html

# CanvasKit (더 나은 성능, 일관성)
flutter build web --web-renderer canvaskit

# 자동 선택 (권장)
flutter build web --web-renderer auto
```

---

### 5. 접근성 (Accessibility) ♿

```dart
// Semantic 위젯 사용
Semantics(
  label: '매물 검색',
  hint: '검색할 지역이나 역 이름을 입력하세요',
  child: AppSearchBar(...),
)

// 버튼에 라벨 추가
IconButton(
  icon: Icon(Icons.favorite),
  tooltip: '찜하기',
  onPressed: () {},
)
```

---

### 6. 에러 처리 🚨

```dart
// 글로벌 에러 핸들러
void main() {
  FlutterError.onError = (details) {
    // 에러 로깅 (Sentry, Firebase Crashlytics 등)
    print('Flutter Error: ${details.exception}');
  };

  runApp(MyApp());
}

// 비동기 에러 핸들러
runZonedGuarded(() {
  runApp(MyApp());
}, (error, stack) {
  print('Async Error: $error');
});
```

---

### 7. 분석 & 모니터링 📊

#### Google Analytics 설정
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^latest
  firebase_analytics: ^latest
```

```dart
// lib/main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// 페이지 뷰 추적
analytics.logScreenView(
  screenName: 'home',
  screenClass: 'WebHomePage',
);

// 이벤트 추적
analytics.logEvent(
  name: 'property_search',
  parameters: {
    'search_query': query,
    'filter_applied': true,
  },
);
```

---

### 8. 보안 설정 🔒

#### CORS 설정 (백엔드)
```dart
// 백엔드에서 CORS 헤더 설정
headers: {
  'Access-Control-Allow-Origin': 'https://yourdomain.com',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}
```

#### HTTPS 강제
```html
<!-- web/index.html -->
<meta http-equiv="Content-Security-Policy" 
      content="upgrade-insecure-requests">
```

---

## 🚀 빌드 & 배포

### 프로덕션 빌드
```bash
# 1. 최적화된 빌드 생성
flutter build web --release --web-renderer auto

# 2. 빌드 결과 확인
cd build/web
ls -la

# 주요 파일들:
# - index.html (메인 HTML)
# - main.dart.js (앱 코드)
# - assets/ (이미지, 폰트 등)
# - canvaskit/ (CanvasKit 사용 시)
```

### 배포 옵션

#### 1. Firebase Hosting (추천)
```bash
# Firebase CLI 설치
npm install -g firebase-tools

# 초기화
firebase init hosting

# firebase.json 설정
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}

# 배포
firebase deploy --only hosting
```

#### 2. Vercel
```bash
# Vercel CLI 설치
npm i -g vercel

# 배포
vercel --prod

# vercel.json 설정
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "framework": null
}
```

#### 3. Netlify
```bash
# netlify.toml 설정
[build]
  command = "flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

## 📈 성능 모니터링

### Lighthouse 점수 목표
- [ ] Performance: 90+ 
- [ ] Accessibility: 95+
- [ ] Best Practices: 95+
- [ ] SEO: 95+

### 측정 도구
```bash
# Chrome DevTools에서 Lighthouse 실행
# 또는 CLI로:
npm install -g lighthouse
lighthouse https://yourdomain.com --view
```

---

## 🎯 출시 전 최종 체크리스트

### 필수 항목
- [ ] 모든 페이지가 반응형으로 작동
- [ ] 이미지 최적화 완료
- [ ] SEO 메타 태그 설정
- [ ] 로딩 스플래시 추가
- [ ] 에러 처리 구현
- [ ] HTTPS 적용
- [ ] 브라우저 호환성 테스트 완료
- [ ] 모바일 테스트 완료

### 권장 항목
- [ ] Google Analytics 설정
- [ ] 소셜 미디어 미리보기 설정
- [ ] 푸터에 회사 정보, 이용약관 링크
- [ ] 404 에러 페이지
- [ ] Sitemap 생성
- [ ] 다크모드 지원 (선택)

---

## 🐛 일반적인 문제 해결

### 1. 이미지가 로드되지 않음
```dart
// CORS 문제일 수 있음
// 백엔드에서 CORS 허용 확인
// 또는 프록시 사용
```

### 2. 폰트가 표시되지 않음
```yaml
# pubspec.yaml에서 경로 확인
fonts:
  - family: Pretendard
    fonts:
      - asset: assets/fonts/Pretendard-Regular.ttf
```

### 3. 라우팅 문제 (#/home 형태)
```dart
// main.dart
MaterialApp(
  // URL에서 # 제거 (URL 전략)
  // CanvasKit 모드에서만 가능
)
```

### 4. 느린 로딩 속도
- 번들 크기 확인 (main.dart.js)
- 이미지 최적화
- HTML 렌더러 사용 고려
- CDN 사용

---

## 📝 배포 후 모니터링

### 주요 지표
1. **페이지 로드 시간**: < 3초
2. **First Contentful Paint**: < 1.5초
3. **Time to Interactive**: < 3.5초
4. **바운스율**: < 40%
5. **평균 세션 시간**: > 2분

### 분석 도구
- Google Analytics
- Hotjar (히트맵)
- Sentry (에러 추적)
- Firebase Performance Monitoring

---

## 🎉 출시 후 해야 할 일

1. **소셜 미디어 공유** - 출시 소식 알리기
2. **SEO 인덱싱** - Google Search Console에 사이트 등록
3. **사용자 피드백 수집** - 설문조사, 리뷰
4. **A/B 테스팅** - 전환율 개선
5. **지속적인 모니터링** - 성능, 에러 추적

---

**웹 출시 성공을 기원합니다! 🚀**
