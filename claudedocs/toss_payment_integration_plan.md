# 토스페이먼츠 위젯 통합 구현 계획

## 📋 개요
게스트가 승인된 계약(APPROVED 상태)의 "결제하기" 버튼 클릭 시 토스페이먼츠 위젯을 불러와 결제를 진행하는 기능을 로컬/개발 환경에서 구현합니다.

---

## 🎯 구현 목표

### 필수 기능
- ✅ 게스트 계약 상세 페이지에서 결제 수단 선택 모달 표시
- ✅ 토스페이먼츠 SDK 통합 (로컬 테스트 모드)
- ✅ 결제 정보 조회 API 연동
- ✅ 토스 결제창 호출 및 결제 승인 처리
- ✅ 결제 성공/실패 처리 및 계약 상태 업데이트

### 선택 기능
- 🔄 Mock 모드 (네트워크 없이 UI 테스트)
- 🔄 테스트 카드 결제 플로우

---

## 📂 프로젝트 구조

### 새로 생성할 파일
```
building_map_app/
├── lib/
│   ├── config/
│   │   └── payment_config.dart         # NEW - 토스페이먼츠 SDK 설정
│   ├── services/
│   │   └── payment_service.dart        # NEW - 결제 API 서비스
│   ├── widgets/
│   │   └── payment_method_modal.dart   # NEW - 결제 수단 선택 모달
│   └── .env.development                # NEW - 개발 환경 변수
```

### 수정할 파일
```
building_map_app/
├── lib/
│   ├── pages/contract/
│   │   └── guest_contract_detail_page.dart  # MODIFY - 결제 UI 추가
│   └── main.dart                             # MODIFY - SDK 초기화
├── pubspec.yaml                              # MODIFY - 패키지 추가
└── .gitignore                                # MODIFY - .env 추가
```

---

## 🔧 Phase 1: 환경 설정 (1-2시간)

### 1.1 패키지 설치
**파일**: `pubspec.yaml`

**추가할 패키지**:
```yaml
dependencies:
  # 기존 패키지...

  # 토스페이먼츠 SDK
  tosspayments_widget_sdk: ^1.0.0  # 최신 버전 확인 필요

  # 환경변수 관리 (이미 있으면 생략)
  flutter_dotenv: ^5.1.0
```

**설치 명령**:
```bash
cd building_map_app
flutter pub get
```

### 1.2 환경변수 설정
**파일**: `building_map_app/.env.development`

**내용**:
```env
# 토스페이먼츠 테스트 클라이언트 키
TOSS_CLIENT_KEY=test_ck_OEP59LybZ8BN3Y1Y7kVrwYxAdXy1

# API 서버 URL (로컬 개발)
API_BASE_URL=http://10.0.2.2:8080  # Android Emulator
# API_BASE_URL=http://localhost:8080  # iOS Simulator

# Mock 모드 (선택)
PAYMENT_MOCK_MODE=false
```

**파일**: `.gitignore` (추가)
```gitignore
# 환경변수 파일
.env
.env.development
.env.production
```

### 1.3 SDK 초기화 설정
**파일**: `lib/config/payment_config.dart` (신규 생성)

**내용**:
```dart
import 'package:tosspayments_widget_sdk/tosspayments_widget_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './api_config.dart';

/// 토스페이먼츠 SDK 설정
class PaymentConfig {
  /// 테스트 클라이언트 키
  static String get clientKey => dotenv.env['TOSS_CLIENT_KEY']!;

  /// Mock 모드 사용 여부
  static bool get useMockMode =>
      dotenv.env['PAYMENT_MOCK_MODE'] == 'true';

  /// 토스페이먼츠 SDK 인스턴스
  static late TossPayments tossPayments;

  /// SDK 초기화
  static void initialize() {
    tossPayments = TossPayments(clientKey: clientKey);
  }

  /// 결제 성공 URL
  static String get successUrl => '${ApiConfig.baseUrl}/payment/success';

  /// 결제 실패 URL
  static String get failUrl => '${ApiConfig.baseUrl}/payment/fail';
}
```

**파일**: `lib/main.dart` (수정)

**변경 사항**:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/payment_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: ".env.development");

  // 토스페이먼츠 SDK 초기화
  PaymentConfig.initialize();

  runApp(const MyApp());
}
```

---

## 🛠️ Phase 2: 결제 서비스 구현 (2-3시간)

### 2.1 결제 API 서비스
**파일**: `lib/services/payment_service.dart` (신규 생성)

**구현 기능**:
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../config/payment_config.dart';
import '../services/token_service.dart';

class PaymentService {
  final TokenService _tokenService = TokenService();

  /// 결제 정보 조회 API
  /// GET /api/contracts/{contractId}/payment-info
  Future<Map<String, dynamic>> getPaymentInfo(int contractId) async {
    final token = await _tokenService.getAccessToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/payment-info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['data'];
    } else {
      throw Exception('결제 정보 조회 실패: ${response.statusCode}');
    }
  }

  /// 결제 승인 API
  /// POST /api/contracts/{contractId}/confirm-payment
  Future<void> confirmPayment({
    required int contractId,
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/confirm-payment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['message'] ?? '결제 승인 실패');
    }
  }

  /// Mock 결제 승인 (테스트용)
  /// POST /api/contracts/{contractId}/confirm-payment-mock
  Future<void> confirmPaymentMock({
    required int contractId,
    required String orderId,
    required int amount,
  }) async {
    if (!PaymentConfig.useMockMode) {
      throw Exception('Mock 모드가 활성화되지 않았습니다');
    }

    final token = await _tokenService.getAccessToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/confirm-payment-mock'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'orderId': orderId,
        'amount': amount,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Mock 결제 실패');
    }
  }
}
```

### 2.2 결제 수단 선택 모달
**파일**: `lib/widgets/payment_method_modal.dart` (신규 생성)

**디자인 명세**: `claudedocs/payment_modal_design.md` 참고

**핵심 기능**:
- 5가지 결제 수단 선택 UI (신용카드, 계좌이체, 가상계좌, 간편결제, 휴대폰결제)
- 모달 애니메이션 (SlideTransition + FadeTransition)
- 결제 수단 선택 상태 관리
- 하단 고정 버튼 (선택 시 활성화)

**주요 코드 구조**:
```dart
class PaymentMethodModal extends StatefulWidget {
  final int totalAmount;
  final PaymentMethod? initialSelectedMethod;

  const PaymentMethodModal({
    Key? key,
    required this.totalAmount,
    this.initialSelectedMethod,
  }) : super(key: key);

  @override
  State<PaymentMethodModal> createState() => _PaymentMethodModalState();
}

class _PaymentMethodModalState extends State<PaymentMethodModal> {
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialSelectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 모달 UI 구현
      // payment_modal_design.md 명세 참고
    );
  }

  Widget _buildPaymentCard(PaymentMethod method) {
    // 결제 수단 카드 UI
  }

  Widget _buildBottomButton() {
    // 하단 결제 버튼
  }
}
```

---

## 🎨 Phase 3: 게스트 계약 상세 페이지 수정 (2-3시간)

### 3.1 상태 변수 추가
**파일**: `lib/pages/contract/guest_contract_detail_page.dart`

**추가할 State 변수**:
```dart
class _GuestContractDetailPageState extends State<GuestContractDetailPage> {
  // 기존 변수들...

  // 결제 관련 추가
  PaymentMethod? _selectedPaymentMethod;  // 선택된 결제 수단
  bool _isPaymentProcessing = false;       // 결제 처리 중
  final PaymentService _paymentService = PaymentService();
}
```

### 3.2 결제 수단 선택 모달 표시
**메서드**: `_showPaymentMethodModal()`

```dart
/// 결제 수단 선택 모달 표시
Future<void> _showPaymentMethodModal() async {
  if (_contractDetail == null) return;

  final selectedMethod = await showModalBottomSheet<PaymentMethod>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaymentMethodModal(
      totalAmount: _contractDetail!.totalAmount,
      initialSelectedMethod: _selectedPaymentMethod,
    ),
  );

  if (selectedMethod != null) {
    setState(() => _selectedPaymentMethod = selectedMethod);

    // 결제 진행 확인 다이얼로그
    final confirmed = await _showPaymentConfirmDialog(selectedMethod);
    if (confirmed == true) {
      await _processPayment(selectedMethod);
    }
  }
}
```

### 3.3 결제 확인 다이얼로그
**메서드**: `_showPaymentConfirmDialog()`

```dart
/// 결제 확인 다이얼로그
Future<bool?> _showPaymentConfirmDialog(PaymentMethod method) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('결제 진행'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결제 수단: ${method.label}'),
          const SizedBox(height: 8),
          Text('결제 금액: ₩${_formatCurrency(_contractDetail!.totalAmount)}'),
          const SizedBox(height: 16),
          const Text(
            '⚠️ 결제 진행 시 계약이 확정됩니다.',
            style: TextStyle(color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('결제하기'),
        ),
      ],
    ),
  );
}
```

### 3.4 토스 결제 처리
**메서드**: `_processPayment()`

```dart
/// 결제 처리 (토스페이먼츠 연동)
Future<void> _processPayment(PaymentMethod method) async {
  setState(() => _isPaymentProcessing = true);

  try {
    // 1. 결제 정보 조회
    final paymentInfo = await _paymentService.getPaymentInfo(widget.contractId);

    if (PaymentConfig.useMockMode) {
      // Mock 모드: 토스 결제창 없이 바로 승인
      await _paymentService.confirmPaymentMock(
        contractId: widget.contractId,
        orderId: paymentInfo['orderId'],
        amount: paymentInfo['amount'],
      );

      _showSuccessDialog('[MOCK] 결제가 완료되었습니다!');
      _reloadContractDetail(); // 계약 상태 갱신
    } else {
      // 실제 토스 결제창 호출
      final result = await PaymentConfig.tossPayments.requestPayment(
        method: _mapToTossPaymentMethod(method),
        amount: paymentInfo['amount'],
        orderId: paymentInfo['orderId'],
        orderName: paymentInfo['orderName'],
        successUrl: PaymentConfig.successUrl,
        failUrl: PaymentConfig.failUrl,
        customerEmail: paymentInfo['customerEmail'],
        customerName: paymentInfo['customerName'],
      );

      if (result != null && result.success) {
        // 2. 결제 승인 요청
        await _paymentService.confirmPayment(
          contractId: widget.contractId,
          paymentKey: result.paymentKey!,
          orderId: paymentInfo['orderId'],
          amount: paymentInfo['amount'],
        );

        _showSuccessDialog('결제가 완료되었습니다!');
        _reloadContractDetail(); // 계약 상태 갱신
      } else {
        throw Exception(result?.errorMessage ?? '결제 실패');
      }
    }
  } on SocketException {
    _showErrorDialog('네트워크 연결을 확인해주세요');
  } on HttpException {
    _showErrorDialog('서버 오류가 발생했습니다');
  } catch (e) {
    debugPrint('결제 오류: $e');
    _showErrorDialog('결제 중 오류가 발생했습니다: ${e.toString()}');
  } finally {
    setState(() => _isPaymentProcessing = false);
  }
}

/// PaymentMethod → TossPaymentMethod 변환
TossPaymentMethod _mapToTossPaymentMethod(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.creditCard:
      return TossPaymentMethod.card;
    case PaymentMethod.bankTransfer:
      return TossPaymentMethod.transfer;
    case PaymentMethod.virtualAccount:
      return TossPaymentMethod.virtualAccount;
    case PaymentMethod.easyPay:
      return TossPaymentMethod.easyPay;
    case PaymentMethod.mobilePayment:
      return TossPaymentMethod.mobile;
  }
}
```

### 3.5 하단 결제 버튼 수정
**메서드**: `_buildBottomBar()` (기존 메서드 수정)

**변경 사항**:
```dart
/// 하단 고정 바 (게스트 전용)
Widget _buildBottomBar() {
  if (_contractDetail == null) return const SizedBox.shrink();

  final contract = _contractDetail!;

  // APPROVED 상태일 때만 결제 버튼 표시
  if (contract.status == ContractStatus.approved) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isPaymentProcessing
                ? null
                : _showPaymentMethodModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isPaymentProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '₩${_formatCurrency(contract.totalAmount)} 결제하기',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  return const SizedBox.shrink();
}
```

---

## 🧪 Phase 4: 로컬 테스트 (1-2시간)

### 4.1 백엔드 API 준비
**필요 API 엔드포인트**:
```
GET  /api/contracts/{contractId}/payment-info
POST /api/contracts/{contractId}/confirm-payment
POST /api/contracts/{contractId}/confirm-payment-mock  (선택)
```

**API 응답 예시**:
```json
// GET /api/contracts/1/payment-info
{
  "success": true,
  "data": {
    "orderId": "ORDER_20250111_123456",
    "orderName": "강남역 도보 5분 - 계약 결제",
    "amount": 13103743,
    "customerEmail": "user@example.com",
    "customerName": "홍길동"
  }
}

// POST /api/contracts/1/confirm-payment
{
  "success": true,
  "message": "결제가 완료되었습니다",
  "data": {
    "paymentKey": "tgen_...",
    "status": "PAYMENT_COMPLETED"
  }
}
```

### 4.2 테스트 시나리오

#### 시나리오 1: Mock 모드 테스트
**환경**: `.env.development`에서 `PAYMENT_MOCK_MODE=true`

**테스트 순서**:
1. ✅ 앱 실행 및 로그인
2. ✅ 승인된 계약(APPROVED) 상세 페이지 진입
3. ✅ "₩13,103,743 결제하기" 버튼 클릭
4. ✅ 결제 수단 선택 모달 표시 확인
5. ✅ "간편결제" 선택
6. ✅ "[MOCK] 결제 완료!" 메시지 확인
7. ✅ 계약 상태 PAYMENT_COMPLETED로 변경 확인

**기대 결과**: 토스 결제창 없이 바로 결제 완료

#### 시나리오 2: 실제 토스 결제 테스트
**환경**: `.env.development`에서 `PAYMENT_MOCK_MODE=false`

**테스트 카드 정보**:
- 카드번호: `5449-0300-0000-0009` (신한카드)
- 비밀번호: `1234` (아무거나)
- CVC: `123`
- 유효기간: `12/25`

**테스트 순서**:
1. ✅ 앱 실행 및 로그인
2. ✅ 승인된 계약(APPROVED) 상세 페이지 진입
3. ✅ "₩13,103,743 결제하기" 버튼 클릭
4. ✅ 결제 수단 선택 모달 표시 확인
5. ✅ "신용카드" 선택
6. ✅ 결제 확인 다이얼로그에서 "결제하기" 클릭
7. ✅ 토스 결제창 표시 확인
8. ✅ 테스트 카드 정보 입력
9. ✅ 결제 승인 완료
10. ✅ "결제가 완료되었습니다!" 메시지 확인
11. ✅ 계약 상태 PAYMENT_COMPLETED로 변경 확인

**기대 결과**: 실제 토스 결제 플로우 완료 (실제 금액 차감 없음)

#### 시나리오 3: 결제 실패 테스트
**테스트 순서**:
1. ✅ 토스 결제창에서 "취소" 버튼 클릭
2. ✅ "결제가 취소되었습니다" 메시지 확인
3. ✅ 계약 상태 APPROVED 유지 확인

**기대 결과**: 결제 취소 시 계약 상태 변경 없음

### 4.3 디버깅 체크리스트
- [ ] `.env.development` 파일 존재 및 값 확인
- [ ] `TOSS_CLIENT_KEY` 유효성 확인
- [ ] Android Emulator: `API_BASE_URL=http://10.0.2.2:8080`
- [ ] iOS Simulator: `API_BASE_URL=http://localhost:8080`
- [ ] 백엔드 서버 실행 확인
- [ ] 네트워크 로그 확인 (결제 정보 조회 API)
- [ ] 토큰 만료 여부 확인

---

## 📊 Phase 5: 에러 핸들링 및 최적화 (1-2시간)

### 5.1 에러 처리
**구현할 에러 케이스**:
```dart
try {
  // 결제 처리
} on SocketException {
  _showErrorDialog('네트워크 연결을 확인해주세요');
} on HttpException {
  _showErrorDialog('서버 오류가 발생했습니다');
} on FormatException {
  _showErrorDialog('잘못된 응답 형식입니다');
} on TimeoutException {
  _showErrorDialog('요청 시간이 초과되었습니다');
} catch (e) {
  if (e.toString().contains('이미 결제된')) {
    _showErrorDialog('이미 결제된 계약입니다');
  } else {
    _showErrorDialog('결제 중 오류가 발생했습니다: ${e.toString()}');
  }
}
```

### 5.2 중복 결제 방지
**구현 방법**:
```dart
Future<void> _processPayment(PaymentMethod method) async {
  // 이미 처리 중이면 무시
  if (_isPaymentProcessing) return;

  setState(() => _isPaymentProcessing = true);

  try {
    // 결제 처리 로직
  } finally {
    setState(() => _isPaymentProcessing = false);
  }
}
```

### 5.3 로딩 상태 표시
**UI 개선**:
- 결제 버튼 로딩 스피너
- 결제 중 백그라운드 탭 차단
- 결제 진행 중 메시지 표시

---

## 🚀 전체 구현 일정

### Day 1 (4-5시간)
- ✅ Phase 1: 환경 설정 (1-2시간)
  - 패키지 설치
  - 환경변수 설정
  - SDK 초기화
- ✅ Phase 2: 결제 서비스 구현 (2-3시간)
  - PaymentService 구현
  - PaymentMethodModal 구현

### Day 2 (3-4시간)
- ✅ Phase 3: 게스트 계약 상세 페이지 수정 (2-3시간)
  - 상태 변수 추가
  - 결제 모달 통합
  - 토스 결제 처리 로직
- ✅ Phase 4: 로컬 테스트 (1-2시간)
  - Mock 모드 테스트
  - 실제 토스 결제 테스트

### Day 3 (1-2시간)
- ✅ Phase 5: 에러 핸들링 및 최적화 (1-2시간)
  - 에러 처리
  - 중복 결제 방지
  - UI 개선

**총 예상 시간**: 8-11시간

---

## ✅ 구현 완료 체크리스트

### Phase 1: 환경 설정
- [ ] `tosspayments_widget_sdk` 패키지 설치
- [ ] `.env.development` 파일 생성 및 설정
- [ ] `PaymentConfig` 클래스 구현
- [ ] `main.dart`에서 SDK 초기화

### Phase 2: 결제 서비스
- [ ] `PaymentService` 클래스 구현
  - [ ] `getPaymentInfo()` 메서드
  - [ ] `confirmPayment()` 메서드
  - [ ] `confirmPaymentMock()` 메서드 (선택)
- [ ] `PaymentMethodModal` 위젯 구현
  - [ ] 결제 수단 카드 UI
  - [ ] 선택 상태 관리
  - [ ] 하단 버튼

### Phase 3: UI 통합
- [ ] 게스트 계약 상세 페이지 수정
  - [ ] 상태 변수 추가
  - [ ] `_showPaymentMethodModal()` 메서드
  - [ ] `_processPayment()` 메서드
  - [ ] `_buildBottomBar()` 수정

### Phase 4: 테스트
- [ ] Mock 모드 테스트 완료
- [ ] 실제 토스 결제 테스트 완료
- [ ] 결제 실패 시나리오 테스트

### Phase 5: 최적화
- [ ] 에러 핸들링 구현
- [ ] 중복 결제 방지
- [ ] 로딩 UI 개선

---

## 📚 참고 문서

- [토스페이먼츠 공식 문서](https://docs.tosspayments.com/)
- [Flutter 토스페이먼츠 플러그인](https://pub.dev/packages/tosspayments_widget_sdk)
- [PAYMENT_LOCAL_TEST_GUIDE_FLUTTER.md](../building_map_app/docs/PAYMENT_LOCAL_TEST_GUIDE_FLUTTER.md)
- [contract_detail_payment_ui_design.md](./contract_detail_payment_ui_design.md)
- [payment_modal_design.md](./payment_modal_design.md)

---

## 🔧 트러블슈팅

### 문제 1: Android Emulator에서 localhost 연결 안 됨
**원인**: Android Emulator는 자체 네트워크를 사용하므로 `localhost`는 에뮬레이터 자신을 가리킴
**해결**: `API_BASE_URL=http://10.0.2.2:8080` 사용

### 문제 2: 토스 결제창이 안 뜸
**원인**: 클라이언트 키가 잘못되었거나 SDK 초기화 실패
**해결**:
1. `.env.development`에서 `TOSS_CLIENT_KEY` 확인
2. `main.dart`에서 `PaymentConfig.initialize()` 호출 확인
3. 디버그 로그로 SDK 초기화 확인

### 문제 3: 결제 승인 API 호출 실패
**원인**: 백엔드 API 미구현 또는 토큰 만료
**해결**:
1. 백엔드 API 엔드포인트 확인
2. 토큰 만료 여부 확인 (`TokenService`)
3. API 응답 로그 확인

### 문제 4: Mock 모드가 작동 안 함
**원인**: 환경변수 로드 실패 또는 `PAYMENT_MOCK_MODE` 설정 오류
**해결**:
1. `.env.development` 파일 존재 확인
2. `dotenv.load()` 호출 확인
3. `PaymentConfig.useMockMode` 값 디버깅

---

**문서 버전**: 1.0.0
**작성일**: 2025-01-11
**작성자**: Claude Code
**상태**: Ready for Implementation
