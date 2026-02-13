# 코드 개선 작업 - 2025년 1월

## 개선 요약

### 1. app_router.dart 리팩토링
**개선 내용:**
- 중복되는 "잘못된 접근" 에러 페이지를 `_buildInvalidAccessPage()` 헬퍼 함수로 통합
- Path 파라미터 파싱 로직을 `_parseIntParameter()` 헬퍼 함수로 추출
- 총 9개 라우트에서 중복 코드 제거

**효과:**
- 코드 유지보수성 향상
- 일관된 에러 처리 패턴 적용
- 향후 에러 페이지 수정 시 한 곳만 수정하면 됨

### 2. api_client.dart 대폭 리팩토링
**개선 내용:**
- 모든 HTTP 메서드(GET, POST, PUT, PATCH, DELETE)에서 반복되는 에러 핸들링 코드를 `_executeRequest()` 공통 함수로 통합
- 318 라인 → 174 라인 (약 45% 감소)
- DRY(Don't Repeat Yourself) 원칙 준수

**효과:**
- 코드 중복 대폭 감소
- 에러 핸들링 로직 수정 시 한 곳만 수정하면 됨
- 새로운 HTTP 메서드 추가가 간단해짐
- 가독성 향상

### 3. Import 정리
**개선 내용:**
- contract_start_page.dart에서 사용하지 않는 import 제거

## 개선 전/후 비교

### app_router.dart
```dart
// 개선 전 (반복된 코드)
if (roomId == null) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('잘못된 접근입니다.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/map'),
            child: const Text('지도로 돌아가기'),
          ),
        ],
      ),
    ),
  );
}

// 개선 후 (헬퍼 함수 사용)
if (roomId == null) {
  return _buildInvalidAccessPage(
    context,
    message: '잘못된 접근입니다.',
    buttonText: '지도로 돌아가기',
    redirectPath: '/map',
  );
}
```

### api_client.dart
```dart
// 개선 전 (각 메서드마다 동일한 에러 핸들링 반복)
Future<http.Response?> get(...) async {
  try {
    // 로깅
    final response = await http.get(...);
    return _handleResponse(response);
  } on TimeoutException { ... }
  on SocketException { ... }
  on HttpException { ... }
  // ... 모든 메서드에서 반복
}

// 개선 후 (공통 함수로 통합)
Future<http.Response?> _executeRequest({
  required String method,
  required Uri url,
  required Future<http.Response> Function() request,
  // ... 통합된 에러 핸들링
}) async { ... }

Future<http.Response?> get(...) async {
  return _executeRequest(
    method: 'GET',
    url: url,
    request: () => http.get(...),
  );
}
```

## 코드 품질 지표

### 파일 크기 감소
- api_client.dart: 318 라인 → 174 라인 (-45%)

### 분석 결과
- 에러: 0개
- 경고: 일부 info 레벨 경고 존재 (withOpacity deprecated, TODO 주석 등)
- 치명적 문제: 없음

## 향후 개선 가능 항목

### High Priority (중요)
- [ ] 사용하지 않는 import 정리 (여러 파일에 산재)
- [ ] `withOpacity` deprecated 경고 해결 (`.withValues()` 사용)
- [ ] 사용하지 않는 변수 제거 (contract_start_page.dart의 `result`)

### Medium Priority (보통)
- [ ] Dead code 제거 (guest_contracts_page.dart, host_contracts_page.dart)
- [ ] Unnecessary cast 경고 해결 (models/ 파일들)
- [ ] FormField의 deprecated `value` → `initialValue` 변경

### Low Priority (낮음)
- [ ] TODO 주석 처리 (17개 발견)

## 테스트 필요 사항
- [ ] API 호출 테스트 (GET, POST, PUT, PATCH, DELETE)
- [ ] 라우팅 테스트 (에러 페이지, 파라미터 파싱)
- [ ] 통합 테스트 (전체 플로우 동작 확인)
