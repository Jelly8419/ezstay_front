# 프로덕션 빌드 스크립트 사용 가이드

## 📋 스크립트 종류

### 1. build_and_serve.bat (⭐ 권장 - Node.js)
**설명**: 프로덕션 빌드 실행 후 Node.js serve로 실행

**사용법**:
```bash
cd building_map_app
build_and_serve.bat
```

**요구사항**: Node.js

**포트**: 3000

**장점**:
- ✅ 안정적인 서버 실행
- ✅ 자동 MIME 타입 처리
- ✅ 빠른 서버 시작

---

### 2. build_and_serve_node.bat (Node.js)
**설명**: `build_and_serve.bat`과 동일 (호환성을 위해 유지)

**사용법**:
```bash
cd building_map_app
build_and_serve_node.bat
```

**요구사항**: Node.js

**포트**: 3000

---

### 3. build_and_serve_python.bat (Python - 대안)
**설명**: 프로덕션 빌드 실행 후 Python 서버로 실행

**사용법**:
```bash
cd building_map_app
build_and_serve_python.bat
```

**요구사항**: Python 3.x

**포트**: 3000

**주의사항**:
- ⚠️ Windows 환경에서 Python http.server가 제대로 작동하지 않을 수 있음
- ⚠️ Node.js 방식 사용 권장

---

### 4. serve_only.bat (빠른 테스트)
**설명**: 기존 빌드를 서버로만 실행 (빌드 스킵)

**사용법**:
```bash
cd building_map_app
serve_only.bat
```

**요구사항**: Python 또는 Node.js

**포트**: 3000

**언제 사용?**: 빌드를 이미 완료했고 빠르게 테스트만 하고 싶을 때

---

### 5. build_and_serve.sh (Linux/Mac)
**설명**: 프로덕션 빌드 실행 후 Python 서버로 실행

**사용법**:
```bash
cd building_map_app
chmod +x build_and_serve.sh
./build_and_serve.sh
```

**요구사항**: Python 3.x

**포트**: 3000

---

## 🚀 빠른 시작

### Windows 사용자 (⭐ 권장)

#### Node.js가 설치되어 있는 경우:
```bash
cd building_map_app
build_and_serve.bat
```

#### Python이 설치되어 있는 경우 (대안):
```bash
cd building_map_app
build_and_serve_python.bat
```

⚠️ **주의**: Windows에서 Python http.server가 작동하지 않을 수 있습니다. Node.js 방식을 권장합니다.

---

### Linux/Mac 사용자:
```bash
cd building_map_app
chmod +x build_and_serve.sh
./build_and_serve.sh
```

---

## 🌐 접속 방법

빌드가 완료되고 서버가 시작되면:

1. 브라우저 열기
2. `http://localhost:3000` 접속
3. 성능 측정:
   - **F12 → Network 탭** → Ctrl+Shift+R (하드 리프레시)
   - **F12 → Performance 탭** → 녹화 → 새로고침 → 분석
   - **F12 → Lighthouse 탭** → Performance 분석

---

## ⏹️ 서버 중지

**Ctrl+C** 입력

---

## 📊 성능 측정 방법

### 1. Chrome DevTools - Network 탭
```
1. F12 키 누르기
2. Network 탭 선택
3. Ctrl+Shift+R (하드 리프레시)
4. 확인:
   - Finish: 전체 로딩 시간
   - DOMContentLoaded: DOM 파싱 완료 시간
   - Load: 리소스 로딩 완료 시간
```

**목표**:
- Finish: < 3초
- DOMContentLoaded: < 1.5초

---

### 2. Chrome DevTools - Performance 탭
```
1. F12 키 누르기
2. Performance 탭 선택
3. 녹화 버튼 (⚫) 클릭
4. 페이지 새로고침 (Ctrl+R)
5. 녹화 중지 버튼 (⏹️) 클릭
6. 결과 분석:
   - FCP (First Contentful Paint): 첫 콘텐츠 표시
   - LCP (Largest Contentful Paint): 최대 콘텐츠 표시
   - TTI (Time to Interactive): 인터랙션 가능 시점
```

**목표**:
- FCP < 1.5초
- LCP < 2.0초
- TTI < 3.0초

---

### 3. Lighthouse 점수
```
1. F12 키 누르기
2. Lighthouse 탭 선택
3. Categories 선택:
   - Performance ✓
   - Accessibility ✓
   - Best Practices ✓
   - SEO ✓
4. Device: Desktop 선택
5. "Analyze page load" 클릭
6. 결과 확인
```

**목표 점수**:
- Performance: > 90점
- Accessibility: > 90점
- Best Practices: > 90점
- SEO: > 90점

---

## 🔧 문제 해결

### Python이 없다고 나옴
**해결책**:
1. Python 설치: https://www.python.org/downloads/
2. 또는 Node.js 사용: `build_and_serve_node.bat`

---

### Node.js serve가 없다고 나옴
**해결책**:
```bash
npm install -g serve
```

또는 npx 사용 (자동 설치):
```bash
npx serve build/web -p 3000
```

---

### 포트 3000이 이미 사용 중
**해결책 1**: 다른 포트 사용
```bash
# Python
python -m http.server 3001

# Node.js
npx serve build/web -p 3001
```

**해결책 2**: 기존 프로세스 종료 (Windows)
```bash
# 3000 포트 사용 중인 프로세스 확인
netstat -ano | findstr :3000

# 프로세스 종료 (PID 확인 후)
taskkill /PID <PID> /F
```

---

### 빌드가 실패함
**확인 사항**:
1. Flutter SDK 버전: `flutter --version`
2. 의존성 설치: `flutter pub get`
3. Flutter 업그레이드: `flutter upgrade`
4. 캐시 정리: `flutter clean`

**재시도**:
```bash
flutter clean
flutter pub get
flutter build web --release
```

---

## 📈 기대 성능

### Phase 1 + Phase 2 적용 후

**초기 로딩 시간**:
- **Before**: 5-8초
- **After**: 1.5-3초
- **개선율**: 70-75%

**번들 크기**:
- **개발 모드**: ~10MB
- **프로덕션 빌드**: 2.5-4MB
- **개선율**: 60-75%

**Core Web Vitals**:
- FCP: < 1.5초 ✓
- LCP: < 2.0초 ✓
- TTI: < 3.0초 ✓

---

## 💡 팁

### 빠른 반복 테스트
빌드를 한 번만 하고 여러 번 테스트하려면:

```bash
# 1. 한 번만 빌드
flutter build web --release --tree-shake-icons

# 2. 이후에는 serve_only.bat 사용
serve_only.bat
```

### 캐시 제거하고 테스트
브라우저 캐시 제거 후 테스트:
- **Ctrl+Shift+R** (하드 리프레시)
- **F12 → Network 탭 → Disable cache 체크**

### 다른 디바이스에서 테스트
같은 네트워크에서 다른 디바이스로 테스트:
```bash
# 로컬 IP 확인 (Windows)
ipconfig

# 다른 디바이스에서 접속
http://<로컬IP>:3000
```

---

## 📚 관련 문서

- **BUILD_OPTIMIZATION.md**: Phase 1 최적화 가이드
- **PHASE2_OPTIMIZATION.md**: Phase 2 최적화 보고서
- **CLAUDE.md**: 프로젝트 전체 문서
