# 백엔드 CORS 설정 가이드

## 문제 상황

프론트엔드(`http://localhost:3000`)에서 백엔드(`http://localhost:8080`)의 이미지를 불러올 때 CORS 에러가 발생합니다:

```
Access to XMLHttpRequest at 'http://localhost:8080/uploads/dummy/room793_photo1.jpg'
from origin 'http://localhost:3000' has been blocked by CORS policy
```

## 해결 방법

백엔드 서버에서 CORS(Cross-Origin Resource Sharing)를 올바르게 설정해야 합니다.

### Spring Boot 백엔드 설정 예시

#### 방법 1: `@CrossOrigin` 어노테이션 사용

```java
@RestController
@CrossOrigin(origins = "http://localhost:3000")
public class RoomController {
    // ... 컨트롤러 메서드
}
```

#### 방법 2: Global CORS 설정 (권장)

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:3000")  // 프론트엔드 주소
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 정적 파일 (이미지 등) 서빙 설정
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:uploads/")
                .setCachePeriod(3600)
                .resourceChain(true);
    }
}
```

#### 방법 3: SecurityConfig에서 CORS 설정 (Spring Security 사용 시)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/uploads/**").permitAll()  // 이미지 접근 허용
                .anyRequest().authenticated()
            );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("http://localhost:3000"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

### Node.js/Express 백엔드 설정 예시

```javascript
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

// CORS 설정
app.use(cors({
  origin: 'http://localhost:3000',
  credentials: true
}));

// 정적 파일 서빙
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.listen(8080, () => {
  console.log('Server running on http://localhost:8080');
});
```

## 프로덕션 환경 설정

개발 환경에서는 `http://localhost:3000`을 허용하지만, **프로덕션에서는 실제 도메인을 명시해야 합니다**.

### 환경 변수를 사용한 동적 설정 (권장)

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.cors.allowed-origins}")
    private String[] allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins(allowedOrigins)  // application.yml에서 읽어옴
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}
```

**application.yml** 설정:

```yaml
app:
  cors:
    allowed-origins:
      - http://localhost:3000        # 개발 환경
      - https://ezstay.example.com   # 프로덕션 환경
```

## CORS 동작 원리

1. **Simple Request**: `GET`, `POST` 등 단순 요청은 바로 서버에 요청
2. **Preflight Request**: 복잡한 요청(커스텀 헤더 포함)은 먼저 `OPTIONS` 메서드로 사전 요청
3. 서버는 응답 헤더에 다음을 포함해야 함:
   - `Access-Control-Allow-Origin`: 허용된 출처
   - `Access-Control-Allow-Methods`: 허용된 HTTP 메서드
   - `Access-Control-Allow-Headers`: 허용된 헤더
   - `Access-Control-Allow-Credentials`: 쿠키/인증 정보 포함 여부

## 중요 주의사항

### ❌ 클라이언트에서 CORS 헤더를 추가하면 안 됨

```dart
// 잘못된 방법 (CORS 에러 발생!)
Image.network(
  imageUrl,
  headers: const {
    'Access-Control-Allow-Origin': '*',  // ❌ 이렇게 하면 안 됨!
  },
)
```

`Access-Control-Allow-Origin`은 **서버 응답 헤더**이므로, 클라이언트가 요청에 포함하면 오히려 CORS preflight 검사에서 차단됩니다.

### ✅ 올바른 방법

```dart
// 올바른 방법 (헤더 없이 요청)
Image.network(
  imageUrl,
  errorBuilder: (context, error, stackTrace) {
    return Placeholder();
  },
)
```

서버에서 CORS를 올바르게 설정하면, 클라이언트는 특별한 헤더 없이도 정상적으로 리소스를 불러올 수 있습니다.

## 테스트 방법

### 1. CORS 헤더 확인

브라우저 개발자 도구 → Network 탭에서 이미지 요청의 Response Headers를 확인:

```
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Credentials: true
```

### 2. curl로 테스트

```bash
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     http://localhost:8080/uploads/dummy/room793_photo1.jpg -v
```

Preflight 응답에 `Access-Control-Allow-Origin` 헤더가 포함되어야 합니다.

### 3. 실제 이미지 요청 테스트

```bash
curl -H "Origin: http://localhost:3000" \
     http://localhost:8080/uploads/dummy/room793_photo1.jpg -v
```

## 체크리스트

- [ ] 백엔드에서 CORS 설정 추가 (`allowedOrigins`에 `http://localhost:3000` 포함)
- [ ] 정적 파일 경로(`/uploads/**`) 접근 허용
- [ ] Spring Security 사용 시 `.permitAll()` 추가
- [ ] 프론트엔드에서 불필요한 CORS 헤더 제거 (이미 완료)
- [ ] 브라우저 개발자 도구에서 CORS 헤더 확인
- [ ] 이미지가 정상적으로 로드되는지 확인

## 추가 리소스

- [MDN - CORS](https://developer.mozilla.org/ko/docs/Web/HTTP/CORS)
- [Spring Boot CORS 설정](https://spring.io/guides/gs/rest-service-cors/)
- [Express CORS 미들웨어](https://expressjs.com/en/resources/middleware/cors.html)
