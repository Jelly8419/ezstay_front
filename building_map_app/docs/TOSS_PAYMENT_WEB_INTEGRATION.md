# 토스페이먼츠 웹 SDK 통합 가이드

## 📋 개요

Flutter 웹 환경에서 토스페이먼츠 JavaScript SDK를 사용하여 결제를 처리하는 구현 가이드입니다.

---

## 🎯 구현된 기능

### ✅ 완료된 작업

1. **웹 JavaScript SDK 통합**
   - `web/index.html`에 토스페이먼츠 SDK 추가
   - `dart:js` 패키지로 JavaScript 상호운용

2. **웹 전용 결제 서비스** (`payment_service_web.dart`)
   - 카드 결제
   - 토스페이 간편결제
   - 계좌이체
   - 가상계좌

3. **플랫폼 통합 서비스** (`payment_service_unified.dart`)
   - 웹/모바일 자동 분기 처리
   - 단일 API로 결제 요청

4. **결제 콜백 처리** (`payment_callback_page.dart`)
   - `/payment/success` - 결제 성공 처리
   - `/payment/fail` - 결제 실패 처리
   - 백엔드 결제 승인 API 연동

---

## 🏗️ 아키텍처

### 웹 결제 플로우

```
[게스트]
   ↓
[결제 수단 선택 모달]
   ↓
[결제 정보 조회 API] ← 백엔드
   ↓
[PaymentServiceUnified.requestPayment()]
   ↓
[PaymentServiceWeb.requestCardPayment()] ← JavaScript SDK
   ↓
[토스 결제창 표시] (팝업 또는 리다이렉트)
   ↓
[사용자 결제 진행]
   ↓
[자동 리다이렉트] → /payment/success?paymentKey=xxx&orderId=xxx&amount=xxx
   ↓
[PaymentCallbackPage]
   ↓
[백엔드 결제 승인 API 호출]
   ↓
[계약 상태 업데이트] → PAYMENT_COMPLETED
   ↓
[계약 목록 페이지로 이동]
```

### 모바일 결제 플로우 (기존 WebView 유지)

```
[게스트]
   ↓
[결제 수단 선택 모달]
   ↓
[PaymentWebView 위젯] ← WebView
   ↓
[토스 결제창 표시]
   ↓
[URL 리다이렉트 감지]
   ↓
[결제 승인 API 호출]
```

---

## 📂 파일 구조

```
building_map_app/
├── web/
│   └── index.html                          # ✅ 토스 SDK 추가됨
├── lib/
│   ├── config/
│   │   └── payment_config.dart             # ✅ 웹/모바일 URL 분기
│   ├── services/
│   │   ├── payment_service.dart            # 기존 API 서비스
│   │   ├── payment_service_web.dart        # ✅ 웹 전용 SDK 래퍼
│   │   ├── payment_service_stub.dart       # ✅ 모바일용 Stub
│   │   └── payment_service_unified.dart    # ✅ 통합 서비스
│   ├── pages/
│   │   └── payment/
│   │       └── payment_callback_page.dart  # ✅ 결제 콜백 페이지
│   ├── widgets/
│   │   ├── payment_method_modal.dart       # 기존 결제 수단 선택 모달
│   │   └── payment_webview.dart            # 기존 모바일 WebView
│   └── router/
│       └── app_router.dart                 # ✅ 결제 콜백 라우트 추가
```

---

## 🚀 사용 방법

### 1. 통합 서비스 초기화

```dart
// main.dart
import 'package:flutter/foundation.dart';
import 'services/payment_service_unified.dart';

final paymentService = PaymentServiceUnified();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 웹 환경에서만 JavaScript SDK 초기화
  if (kIsWeb) {
    paymentService.initializeWebSDK();
  }

  runApp(MyApp());
}
```

### 2. 결제 요청 (게스트 계약 상세 페이지)

```dart
import 'package:flutter/foundation.dart';
import '../services/payment_service_unified.dart';
import '../models/contract.dart';

class GuestContractDetailPage extends StatelessWidget {
  final PaymentServiceUnified _paymentService = PaymentServiceUnified();

  Future<void> _handlePayment(BuildContext context) async {
    try {
      // 1. 결제 정보 조회
      final paymentInfo = await _paymentService.getPaymentInfo(contractId);

      // 2. 결제 수단 선택 모달 표시
      final selectedMethod = await showModalBottomSheet<PaymentMethod>(
        context: context,
        builder: (context) => PaymentMethodModal(
          totalAmount: paymentInfo['amount'],
        ),
      );

      if (selectedMethod == null) return;

      // 3. 결제 요청
      if (kIsWeb) {
        // 웹: JavaScript SDK로 결제창 호출 (자동 리다이렉트)
        await _paymentService.requestPayment(
          contractId: contractId,
          paymentMethod: selectedMethod,
          paymentInfo: paymentInfo,
        );
        // 이후 /payment/success 또는 /payment/fail로 자동 리다이렉트됨
      } else {
        // 모바일: WebView로 결제창 표시
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(
              paymentUrl: paymentInfo['paymentUrl'],
              contractId: contractId,
            ),
          ),
        );

        if (result != null && result['success'] == true) {
          // 결제 승인 처리
          await _paymentService.confirmPayment(
            contractId: contractId,
            paymentKey: result['paymentKey'],
            orderId: result['orderId'],
            amount: result['amount'],
          );
        }
      }
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 오류: $e')),
      );
    }
  }
}
```

### 3. Mock 결제 테스트 (로컬 개발)

```dart
// .env 파일 설정
PAYMENT_MOCK_MODE=true

// 코드에서 Mock 결제 사용
if (PaymentConfig.useMockMode) {
  await _paymentService.confirmPaymentMock(
    contractId: contractId,
    orderId: paymentInfo['orderId'],
    amount: paymentInfo['amount'],
  );
}
```

---

## 🔧 환경 설정

### .env 파일

```env
# 토스페이먼츠 테스트 클라이언트 키
TOSS_CLIENT_KEY=test_ck_PBal2vxj81voBvwla6xG35RQgOAN

# 백엔드 API URL
API_BASE_URL=http://localhost:8080

# Mock 모드 (로컬 테스트용)
PAYMENT_MOCK_MODE=true

# 프로덕션 환경 여부
IS_PRODUCTION=false
```

### web/index.html (이미 적용됨)

```html
<!-- Toss Payments JavaScript SDK -->
<script src="https://js.tosspayments.com/v2/standard"></script>
```

---

## 🧪 테스트 시나리오

### 웹 환경 테스트

1. **결제 성공 플로우**
   ```bash
   flutter run -d chrome
   ```
   - 계약 상세 페이지 → "결제하기" 버튼 클릭
   - 결제 수단 선택 (카드)
   - 토스 결제창에서 테스트 카드 입력
   - `/payment/success`로 리다이렉트 확인
   - "결제가 완료되었습니다!" 메시지 표시

2. **결제 실패 플로우**
   - 결제창에서 취소 버튼 클릭
   - `/payment/fail`로 리다이렉트 확인
   - 에러 메시지 표시

3. **Mock 모드 테스트**
   ```bash
   # .env에서 PAYMENT_MOCK_MODE=true 설정
   flutter run -d chrome
   ```
   - 실제 결제창 없이 백엔드 Mock API로 결제 완료 처리

### 모바일 환경 테스트 (기존 WebView)

```bash
flutter run  # Android/iOS
```

---

## ⚠️ 주의사항

### 웹 환경

1. **CORS 이슈**
   - 로컬 개발 시 `http://localhost:8080` 백엔드와 통신
   - 프로덕션 배포 시 동일 도메인 사용 권장

2. **리다이렉트 URL**
   - 웹: `window.location.origin/payment/success`
   - 반드시 토스 개발자센터에 승인된 URL 등록 필요

3. **JavaScript 에러 처리**
   - `dart:js` Promise 변환 시 에러는 Future.error로 처리됨
   - try-catch로 JavaScript SDK 에러 캐치 가능

### 모바일 환경

1. **WebView 권한**
   - Android: 인터넷 권한 필요
   - iOS: App Transport Security 설정

2. **URL 리다이렉트**
   - 백엔드 URL 사용 (`http://10.0.2.2:8080/payment/success`)

---

## 📊 성능 최적화

### Deferred Loading

결제 콜백 페이지는 지연 로딩으로 번들 크기 최적화:

```dart
// app_router.dart
import '../pages/payment/payment_callback_page.dart'
    deferred as payment_callback;

GoRoute(
  path: '/payment/success',
  builder: (context, state) {
    return _deferredWidget(
      payment_callback.loadLibrary,
      () => payment_callback.PaymentCallbackPage(...),
    );
  },
)
```

### 웹 번들 크기

- 토스 JavaScript SDK: ~50KB (gzip)
- `dart:js` 바인딩: ~10KB
- 총 추가 번들 크기: ~60KB

---

## 🐛 디버깅

### 웹 콘솔 로그

```javascript
// 브라우저 개발자 도구 콘솔에서 확인
console.log('토스 SDK 로드:', typeof TossPayments !== 'undefined');
```

### Flutter 디버그 로그

```dart
debugPrint('💳 [PaymentServiceWeb] 카드 결제 요청');
debugPrint('  - orderId: $orderId');
debugPrint('  - amount: $amount');
```

### 네트워크 요청 확인

```
Chrome DevTools → Network 탭
- /api/contracts/{contractId}/payment-info (GET)
- /api/contracts/{contractId}/confirm-payment (POST)
```

---

## 📚 참고 문서

- [토스페이먼츠 JavaScript SDK 문서](https://docs.tosspayments.com/reference/js-sdk)
- [Flutter 웹 플랫폼 감지](https://flutter.dev/docs/development/platform-integration/web)
- [dart:js 패키지 문서](https://api.dart.dev/stable/dart-js/dart-js-library.html)

---

## ✅ 다음 단계

1. **실제 결제 테스트**
   - 토스페이먼츠 개발자센터에서 테스트 클라이언트 키 발급
   - 리다이렉트 URL 등록
   - 테스트 카드로 결제 플로우 검증

2. **에러 핸들링 개선**
   - 네트워크 타임아웃 처리
   - 결제 승인 실패 시 재시도 로직
   - 사용자 친화적 에러 메시지

3. **프로덕션 배포**
   - 프로덕션 클라이언트 키로 변경
   - HTTPS 도메인 설정
   - 보안 헤더 설정 (CSP, CORS)
