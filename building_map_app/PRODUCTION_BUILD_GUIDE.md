# 프로덕션 빌드 가이드

## 🔍 개발 모드 vs 프로덕션 빌드 차이점

### 개발 모드 (`flutter run -d chrome`)
- **번들 크기**: 10-15MB (디버그 정보 포함)
- **로딩 속도**: 5-8초
- **최적화**: 없음
- **환경 변수**: `.env` 파일 자동 로드
- **핫 리로드**: 지원 ✅
- **포트**: 기본적으로 랜덤 포트

### 프로덕션 빌드 (`flutter build web --release`)
- **번들 크기**: 2.5-4MB (70% 감소)
- **로딩 속도**: 1.5-3초 (75% 개선)
- **최적화**: Tree-shaking, Minification, O4 최적화
- **환경 변수**: `.env` 파일을 `build/web`에 수동 복사 필요
- **핫 리로드**: 지원 안 함 ❌
- **포트**: 3000 (스크립트 기본값)

---

## ⚠️ 중요: 백엔드 API 연동 주의사항

### 문제 상황
프로덕션 빌드 후 백엔드 API 요청이 안 되는 경우:

**원인:**
- `.env` 파일이 `build/web` 디렉토리에 복사되지 않음
- `flutter_dotenv`가 `.env` 파일을 찾지 못해 기본값 사용
- API 요청이 잘못된 URL로 전송됨

**해결책:**
빌드 스크립트가 자동으로 `.env` 파일을 복사합니다:
```cmd
.\build_and_serve.bat
```

스크립트 실행 시 다음 메시지 확인:
```
[OK] Environment variables copied
```

---

## 🚀 프로덕션 빌드 실행

### 1. Node.js 방식 (⭐ 권장)
```cmd
cd c:\study\ezstay_front\building_map_app
.\build_and_serve.bat
```

**장점:**
- ✅ 안정적인 서버 실행
- ✅ `.env` 파일 자동 복사
- ✅ 포트 3000 고정

**실행 과정:**
```
[1/4] Updating dependencies...
[2/4] Building production bundle...
[OK] Environment variables copied          # ← 중요!
[3/4] Checking bundle size...
   main.dart.js: 3 MB
[4/4] Starting local server on port 3000...
```

### 2. 백엔드 API 서버 확인

프로덕션 빌드는 `localhost:3000`에서 실행되므로, 백엔드 API 서버가 실행 중인지 확인:

```cmd
# 백엔드 서버 상태 확인
curl http://localhost:8080/health

# 또는 브라우저에서
http://localhost:8080
```

**.env 파일 설정 확인:**
```env
API_BASE_URL=http://localhost:8080
API_TIMEOUT_SECONDS=10
IS_PRODUCTION=false
```

---

## 🔧 트러블슈팅

### 1. API 요청이 안 되는 경우

**증상:**
- 로그인 실패
- 데이터 로드 안 됨
- 네트워크 에러

**해결 방법:**

#### A. 브라우저 콘솔 확인
1. `F12` → Console 탭
2. 에러 메시지 확인:
   ```
   Failed to load resource: net::ERR_CONNECTION_REFUSED
   http://localhost:8080/api/auth/...
   ```

#### B. .env 파일 복사 확인
```cmd
# build/web 디렉토리에 .env 파일이 있는지 확인
dir build\web\.env
```

없다면 수동 복사:
```cmd
copy .env build\web\.env
```

#### C. 백엔드 서버 실행 확인
```cmd
# 포트 8080이 사용 중인지 확인
netstat -ano | findstr ":8080"
```

백엔드가 실행 중이 아니라면 백엔드 서버 시작:
```cmd
# 백엔드 프로젝트 디렉토리에서
npm start
# 또는
java -jar backend.jar
```

### 2. CORS 에러가 발생하는 경우

**증상:**
```
Access to fetch at 'http://localhost:8080/api/...' from origin
'http://localhost:3000' has been blocked by CORS policy
```

**해결 방법:**

백엔드에서 CORS 설정 추가 (Spring Boot 예시):
```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:3000")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH")
                .allowCredentials(true);
    }
}
```

### 3. 직접 URL 접근 시 404 Not Found 에러

**증상:**
- `http://localhost:3000/` (루트)는 작동
- `http://localhost:3000/map` → 404 Not Found ❌
- `http://localhost:3000/login` → 404 Not Found ❌

**원인:**
- SPA (Single Page Application)는 모든 라우팅을 클라이언트에서 처리
- 서버가 `/map` 경로를 파일로 인식하여 404 반환

**해결 방법:**

#### A. 스크립트에 `--single` 플래그 추가 (✅ 이미 적용됨)
```cmd
npx serve -p 3000 --single
```

`--single` 플래그가 모든 경로를 `index.html`로 리다이렉트합니다.

#### B. 수동으로 서버 실행 시
```cmd
cd build\web
npx serve . -p 3000 --single
```

#### C. Python 서버는 SPA 라우팅 미지원
Python `http.server`는 `--single` 같은 옵션이 없으므로:
- ⚠️ 직접 URL 접근 불가 (404 발생)
- ✅ 루트에서 시작 후 앱 내 네비게이션은 작동
- 💡 Node.js 서버 사용 권장

### 4. 빌드는 되지만 화면이 하얗게 나오는 경우

**원인:**
- JavaScript 에러
- Firebase 설정 문제
- Kakao Map API 키 문제

**해결 방법:**

브라우저 콘솔에서 에러 확인:
```
F12 → Console
```

주요 체크포인트:
- [ ] Firebase 설정이 올바른지 (`web/index.html`)
- [ ] Kakao JavaScript Key가 올바른지 (`.env`)
- [ ] 모든 스크립트가 로드되었는지 (`Network` 탭)

---

## 📊 성능 측정

### Chrome DevTools로 성능 측정

1. **Lighthouse 실행**
   ```
   F12 → Lighthouse 탭 → Generate report
   ```

2. **확인 지표**
   - **FCP (First Contentful Paint)**: < 1.5초 (목표)
   - **LCP (Largest Contentful Paint)**: < 2.0초 (목표)
   - **TTI (Time to Interactive)**: < 3.0초 (목표)
   - **Performance Score**: > 90점 (목표)

3. **Network 탭으로 번들 크기 확인**
   ```
   F12 → Network 탭 → Disable cache 체크 → 새로고침
   ```
   - `main.dart.js`: ~3MB
   - 전체 로드 시간: 1.5-3초

---

## 🎯 체크리스트

프로덕션 빌드 전:

- [ ] `.env` 파일 존재 확인
- [ ] 백엔드 API 서버 실행 중
- [ ] API_BASE_URL이 올바르게 설정됨
- [ ] Firebase 설정 완료
- [ ] Kakao API 키 설정 완료

빌드 후:

- [ ] `build/web/.env` 파일 존재 확인
- [ ] 브라우저에서 `http://localhost:3000` 접속
- [ ] 콘솔에 에러 없음
- [ ] API 요청 정상 작동
- [ ] 로그인 테스트 성공
- [ ] 데이터 로드 테스트 성공

---

## 📝 추가 참고사항

### 프로덕션 배포 시

실제 서버에 배포할 때는 `.env` 파일 대신 환경 변수를 직접 설정:

```bash
# 서버 환경 변수 설정
export API_BASE_URL=https://api.yourdomain.com
export IS_PRODUCTION=true
```

또는 `build/web/index.html`에 직접 삽입:
```html
<script>
  window.ENV = {
    API_BASE_URL: 'https://api.yourdomain.com',
    IS_PRODUCTION: 'true'
  };
</script>
```

### 보안 주의사항

- ⚠️ API 키는 절대 클라이언트에 노출하지 말 것
- ⚠️ `.env` 파일을 Git에 커밋하지 말 것
- ⚠️ 프로덕션 환경에서는 HTTPS 사용
- ⚠️ CORS 설정을 특정 도메인으로 제한

---

## 🔄 빠른 참조

```cmd
# 전체 빌드 + 서버 실행
.\build_and_serve.bat

# 서버만 재시작 (빌드 스킵)
.\serve_only.bat

# 백엔드 연결 확인
curl http://localhost:8080/health

# 브라우저 콘솔 열기
F12 → Console

# 네트워크 모니터링
F12 → Network → Disable cache
```
