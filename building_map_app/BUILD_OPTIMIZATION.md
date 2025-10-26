# 프로덕션 빌드 최적화 가이드

## Phase 1 최적화 완료 사항

### ✅ Task 1.1: 비동기 Firebase 초기화 (완료)
**변경 파일**: `lib/main.dart`
- Firebase 초기화를 백그라운드로 이동 (`_initializeFirebase()` 함수)
- await 제거로 앱 시작 경로에서 차단 해제
- **예상 효과**: -1~2초

### ✅ Task 1.2: 자동 로그인 Non-Blocking (완료)
**변경 파일**:
- `lib/main.dart`: `unawaited(authService.tryAutoLogin())`
- `lib/services/auth_service.dart`: try-catch-finally 패턴으로 안전성 보장
- `lib/widgets/splash_screen.dart`: 초기화 중 표시 위젯 추가
- **예상 효과**: -0.5~1초

### ✅ Task 1.3: 웹 스크립트 async/defer 적용 (완료)
**변경 파일**: `web/index.html`

**최적화 내용**:
1. **Material Icons**: preload + async 로딩
   ```html
   <link rel="preload" href="..." as="style" onload="this.onload=null;this.rel='stylesheet'">
   ```

2. **Kakao Maps API**: defer 속성 추가
   ```html
   <script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=..." defer></script>
   ```

3. **Daum Postcode API**: defer 속성 추가
   ```html
   <script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/..." defer></script>
   ```

4. **Firebase SDK**: defer로 비차단 로딩
   ```html
   <script src="https://www.gstatic.com/firebasejs/.../firebase-app-compat.js" defer></script>
   ```

5. **Firebase 초기화**: DOMContentLoaded 후 실행, 5초 타임아웃 설정
   - SDK 로드 확인 후 초기화 (100ms 간격 체크)
   - 최대 50회 시도 (5초 타임아웃)

**예상 효과**: -1~3초

---

## Task 1.4: 프로덕션 빌드 최적화

### 프로덕션 빌드 명령어

#### 기본 릴리스 빌드
```bash
cd building_map_app
flutter build web --release
```

#### 최적화 플래그 추가
```bash
# 1. 트리 쉐이킹 강화 + Dart2JS 최적화
flutter build web --release \
  --tree-shake-icons \
  --dart2js-optimization=O4

# 2. 소스맵 제거 (번들 크기 감소)
flutter build web --release \
  --tree-shake-icons \
  --dart2js-optimization=O4 \
  --no-source-maps

# 3. 웹 렌더러 선택 (auto, canvaskit, html)
flutter build web --release \
  --tree-shake-icons \
  --dart2js-optimization=O4 \
  --no-source-maps \
  --web-renderer canvaskit
```

### 최적화 플래그 설명

| 플래그 | 설명 | 효과 |
|--------|------|------|
| `--release` | 프로덕션 빌드 모드 | 코드 난독화, 압축, 최적화 |
| `--tree-shake-icons` | 사용하지 않는 Material Icons 제거 | 번들 크기 -500KB~1MB |
| `--dart2js-optimization=O4` | 최고 수준 최적화 (기본값 O2) | 번들 크기 -10~15%, 빌드 시간 +30% |
| `--no-source-maps` | 소스맵 파일 생성 안 함 | 번들 크기 -20~30% |
| `--web-renderer` | 웹 렌더링 엔진 선택 | 성능/호환성 trade-off |

### 웹 렌더러 선택 가이드

#### auto (기본값, 권장)
- 모바일: HTML 렌더러 (작은 번들)
- 데스크톱: CanvasKit (고성능)
- **추천**: 대부분의 경우

#### canvaskit
- **장점**: 일관된 렌더링, 복잡한 그래픽 성능 우수
- **단점**: 번들 크기 +1.5~2MB
- **추천**: 그래픽 집약적 앱

#### html
- **장점**: 번들 크기 최소화, 빠른 초기 로딩
- **단점**: 일부 그래픽 품질 저하
- **추천**: 단순 UI, 빠른 로딩 우선

### 권장 프로덕션 빌드 명령어

```bash
# EZStay 프로젝트 권장 설정
cd building_map_app
flutter build web --release \
  --tree-shake-icons \
  --dart2js-optimization=O4 \
  --no-source-maps \
  --web-renderer auto
```

### 빌드 결과물

빌드 완료 후 `building_map_app/build/web/` 디렉토리에 최적화된 파일 생성:
- `main.dart.js`: 최적화된 Dart → JavaScript 번들
- `assets/`: 압축된 이미지 및 리소스
- `canvaskit/`: CanvasKit WASM 파일 (auto 또는 canvaskit 선택 시)

### 로컬 테스트

프로덕션 빌드를 로컬에서 테스트:

```bash
# Python 웹 서버
cd building_map_app/build/web
python -m http.server 8000

# 또는 Node.js serve
npx serve building_map_app/build/web
```

브라우저에서 `http://localhost:8000` 접속하여 테스트

### 성능 측정

#### Chrome DevTools 측정
1. Chrome DevTools 열기 (F12)
2. **Performance** 탭 → 녹화 시작
3. 페이지 새로고침 (Ctrl+Shift+R)
4. 녹화 중지

**확인 지표**:
- **FCP (First Contentful Paint)**: < 1.8초 목표
- **LCP (Largest Contentful Paint)**: < 2.5초 목표
- **TTI (Time to Interactive)**: < 3.8초 목표

#### Lighthouse 측정
1. Chrome DevTools → **Lighthouse** 탭
2. Categories: Performance, Accessibility, Best Practices, SEO 선택
3. Device: Desktop 선택
4. **Analyze page load** 실행

**목표 점수**:
- Performance: > 90점
- Accessibility: > 90점
- Best Practices: > 90점
- SEO: > 90점

### 번들 크기 분석

```bash
# 번들 크기 상세 분석
flutter build web --release --analyze-size

# 결과 확인
cat .dart_tool/flutter_build/*/app.dill.size-analysis.json
```

### 예상 성능 개선

#### 개발 모드 → 프로덕션 빌드
- **번들 크기**: ~10MB → ~3-5MB (50-70% 감소)
- **초기 로딩**: ~5-8초 → ~2-4초 (50-60% 개선)
- **FCP**: ~3-4초 → ~1-1.5초
- **LCP**: ~4-5초 → ~1.5-2초
- **TTI**: ~6-8초 → ~2.5-3.5초

---

## Phase 1 완료 후 성능 목표

### 초기 로딩 시간
- **개선 전**: 5-8초
- **개선 후**: 2-4초
- **개선율**: 50-60%

### Core Web Vitals
- **FCP**: < 1.8초
- **LCP**: < 2.5초
- **TTI**: < 3.8초

---

## 다음 단계 (Phase 2)

Phase 1 최적화 검증 후 진행:
1. **Task 2.1**: Deferred Loading 확대 (호스트 페이지, 상세 페이지)
2. **Task 2.2**: 이미지 최적화 (WebP, 반응형 이미지)
3. **Task 2.3**: 코드 스플리팅 (큰 패키지 분리)
4. **Task 2.4**: 서비스 워커 설정 (오프라인 캐싱)

---

## 체크리스트

### Phase 1 완료 확인
- [x] Task 1.1: 비동기 Firebase 초기화
- [x] Task 1.2: 자동 로그인 Non-Blocking
- [x] Task 1.3: 웹 스크립트 async/defer
- [ ] Task 1.4: 프로덕션 빌드 실행 및 측정

### 검증 단계
1. [ ] 프로덕션 빌드 실행
2. [ ] 로컬 서버로 테스트
3. [ ] Chrome DevTools Performance 측정
4. [ ] Lighthouse 점수 확인
5. [ ] 목표 지표 달성 확인 (FCP < 1.8s, LCP < 2.5s, TTI < 3.8s)

### 배포 전 확인
- [ ] 프로덕션 환경 변수 설정 (`.env` 파일)
- [ ] Firebase 프로덕션 설정 확인
- [ ] API 엔드포인트 프로덕션 URL로 변경
- [ ] 에러 로깅 및 모니터링 설정

---

## 문제 해결

### 빌드 실패 시
```bash
# 의존성 재설치
flutter clean
flutter pub get
flutter build web --release
```

### Firebase 초기화 실패 시
- `web/index.html`의 Firebase 설정 확인
- 브라우저 콘솔에서 에러 메시지 확인
- Firebase SDK 버전 호환성 확인

### 성능 목표 미달 시
- Phase 2 최적화 진행
- 번들 크기 분석 (`--analyze-size`)
- 불필요한 패키지 제거
- 이미지 최적화 강화
