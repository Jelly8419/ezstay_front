# 백엔드 정적 파일 서빙 설정 가이드

## 문제 상황

- 프론트엔드(Flutter Web)가 `http://localhost:8080/uploads/rooms/...` 경로로 이미지를 요청
- 실제 파일은 `C:\study\uploads\rooms\...`에 저장됨
- 백엔드가 정적 파일을 서빙하지 않아 이미지 로드 실패

## 해결 방법

### Spring Boot 설정

#### 1. application.yml 또는 application.properties

**application.yml 예시:**
```yaml
spring:
  web:
    resources:
      static-locations: file:///C:/study/uploads/
      # 또는 리눅스: file:///home/user/study/uploads/

# CORS 설정 (필요한 경우)
cors:
  allowed-origins: http://localhost:3000
  allowed-methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
  allowed-headers: '*'
```

**application.properties 예시:**
```properties
spring.web.resources.static-locations=file:///C:/study/uploads/
```

#### 2. WebMvcConfigurer 구성 (추천)

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // /uploads/** 요청을 C:\study\uploads\ 폴더로 매핑
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:///C:/study/uploads/")
                .setCachePeriod(3600); // 캐시 1시간

        // 프로덕션 환경에서는 다른 경로 사용
        // registry.addResourceHandler("/uploads/**")
        //         .addResourceLocations("file:///var/www/uploads/")
        //         .setCachePeriod(86400); // 캐시 24시간
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:3000") // Flutter 웹 주소
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
```

#### 3. SecurityConfig 설정 (Spring Security 사용 시)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/uploads/**").permitAll() // 정적 파일 접근 허용
                .requestMatchers("/api/auth/**").permitAll()
                .anyRequest().authenticated()
            )
            .cors(withDefaults()) // CORS 활성화
            .csrf(csrf -> csrf.disable());

        return http.build();
    }
}
```

### Node.js (Express) 설정

```javascript
const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();

// CORS 설정
app.use(cors({
  origin: 'http://localhost:3000',
  credentials: true
}));

// 정적 파일 서빙
app.use('/uploads', express.static('C:/study/uploads'));

// 또는 리눅스
// app.use('/uploads', express.static('/home/user/study/uploads'));

app.listen(8080, () => {
  console.log('Server running on http://localhost:8080');
});
```

## 테스트 방법

### 1. 백엔드 서버 재시작
```bash
# Spring Boot
./mvnw spring-boot:run

# Gradle
./gradlew bootRun
```

### 2. 브라우저에서 직접 접근 테스트
```
http://localhost:8080/uploads/rooms/test.jpg
```

### 3. curl 명령어로 테스트
```bash
curl -I http://localhost:8080/uploads/rooms/test.jpg
```

성공 시 응답:
```
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Length: 12345
```

## 프로덕션 환경 고려사항

### 1. 환경별 경로 설정
```java
@Value("${upload.path}")
private String uploadPath;

@Override
public void addResourceHandlers(ResourceHandlerRegistry registry) {
    registry.addResourceHandler("/uploads/**")
            .addResourceLocations("file:///" + uploadPath + "/");
}
```

**application-dev.yml:**
```yaml
upload:
  path: C:/study/uploads
```

**application-prod.yml:**
```yaml
upload:
  path: /var/www/uploads
```

### 2. CDN 사용 (권장)
프로덕션에서는 AWS S3, Cloudflare R2 등의 CDN 사용 권장
```java
if (isProduction) {
    return "https://cdn.example.com/uploads/" + filename;
} else {
    return "http://localhost:8080/uploads/" + filename;
}
```

### 3. 보안 설정
- 업로드 파일 크기 제한
- 허용된 파일 타입 검증 (JPEG, PNG, WebP만 허용)
- 파일명 sanitization (../ 경로 조작 방지)

## 현재 프로젝트 적용

위의 Spring Boot WebConfig 설정을 백엔드에 추가하면 됩니다.

설정 후:
- 프론트엔드 웹: `http://localhost:8080/uploads/rooms/...` 접근 가능
- 프론트엔드 데스크톱: `C:\study\uploads\rooms\...` 직접 접근

두 환경 모두 정상 작동합니다.
