# 토스페이먼츠 위젯 키 없이 결제 시스템 구현 계획

## 📋 개요
토스페이먼츠 위젯 키가 없는 상태에서도 결제 시스템을 구현할 수 있습니다.
UI와 Mock 모드를 먼저 구현하고, 나중에 토스 SDK만 추가하는 방식입니다.

---

## 🎯 구현 순서 (위젯 키 불필요 → 필요 순)

### **Step 1: UI 구현 (100% 위젯 키 불필요) ✅**
**예상 시간**: 3-4시간

**구현 내용**:
1. ✅ 결제 수단 선택 모달 (`PaymentMethodModal`)
2. ✅ 게스트 계약 상세 페이지 결제 버튼
3. ✅ 결제 확인 다이얼로그
4. ✅ 결제 수단 상태 관리
5. ✅ 로딩 상태 UI

**토스 SDK 의존성**: 없음

### **Step 2: Mock 결제 시스템 (100% 위젯 키 불필요) ✅**
**예상 시간**: 2-3시간

**구현 내용**:
1. ✅ `PaymentService` 클래스 (Mock 모드)
2. ✅ 백엔드 Mock 결제 API 연동
   - `GET /api/contracts/{contractId}/payment-info`
   - `POST /api/contracts/{contractId}/confirm-payment-mock`
3. ✅ 결제 성공/실패 처리
4. ✅ 계약 상태 업데이트 (APPROVED → PAYMENT_COMPLETED)

**토스 SDK 의존성**: 없음

**테스트 가능**:
- 결제 UI 전체 플로우
- 결제 API 연동
- 에러 핸들링
- 계약 상태 변경

### **Step 3: 토스 SDK 연동 (위젯 키 필요) ⏳**
**예상 시간**: 1-2시간

**구현 내용**:
1. ⏳ 토스페이먼츠 개발자센터 가입
2. ⏳ 테스트 클라이언트 키 발급
3. ⏳ `tosspayments_widget_sdk` 패키지 설치
4. ⏳ `PaymentConfig` 설정
5. ⏳ `PaymentService`에 실제 결제 로직 추가

**토스 SDK 의존성**: 있음 (테스트 키 필요)

---

## 📂 Step 1: UI 구현 (위젯 키 불필요)

### 1.1 결제 수단 선택 모달
**파일**: `lib/widgets/payment_method_modal.dart`

**구현 내용**:
```dart
import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

/// 결제 수단 선택 모달
class PaymentMethodModal extends StatefulWidget {
  final int totalAmount;
  final PaymentMethod? initialSelectedMethod;

  const PaymentMethodModal({
    super.key,
    required this.totalAmount,
    this.initialSelectedMethod,
  });

  @override
  State<PaymentMethodModal> createState() => _PaymentMethodModalState();
}

class _PaymentMethodModalState extends State<PaymentMethodModal>
    with SingleTickerProviderStateMixin {
  PaymentMethod? _selectedMethod;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialSelectedMethod;

    // 애니메이션 설정
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.modal,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.modal,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.modal,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              _buildHeader(),

              // 결제 수단 리스트
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: PaymentMethod.values.map((method) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPaymentCard(method),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 하단 고정 버튼
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 모달 헤더
  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '결제 수단 선택',
            style: AppTextStyles.headingMedium,
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 28),
            color: Colors.grey.shade600,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 결제 수단 카드
  Widget _buildPaymentCard(PaymentMethod method) {
    final isSelected = _selectedMethod == method;

    return AnimatedContainer(
      duration: AppDurations.listItem,
      curve: AppCurves.listItem,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 16 : 8,
            offset: Offset(0, isSelected ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedMethod = method);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    method.icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // 제목 + 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.description,
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                    ],
                  ),
                ),

                // 체크 아이콘 (선택 시)
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 하단 고정 버튼
  Widget _buildBottomButton() {
    final isEnabled = _selectedMethod != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
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
          child: AnimatedContainer(
            duration: AppDurations.hoverCard,
            curve: AppCurves.hoverCard,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEnabled ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled
                    ? () => Navigator.pop(context, _selectedMethod)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    isEnabled
                        ? '₩${_formatCurrency(widget.totalAmount)} 결제하기'
                        : '결제 수단을 선택해주세요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 금액 포맷팅
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
```

### 1.2 게스트 계약 상세 페이지 수정
**파일**: `lib/pages/contract/guest_contract_detail_page.dart`

**추가할 import**:
```dart
import '../../widgets/payment_method_modal.dart';
import '../../models/payment_method.dart';
```

**추가할 State 변수**:
```dart
// 결제 관련
PaymentMethod? _selectedPaymentMethod;
bool _isPaymentProcessing = false;
```

**추가할 메서드**:
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
      await _processPaymentMock(selectedMethod);
    }
  }
}

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

/// Mock 결제 처리 (Step 2에서 구현)
Future<void> _processPaymentMock(PaymentMethod method) async {
  // TODO: Step 2에서 구현
  debugPrint('[Mock] 결제 진행: ${method.label}');
}
```

**수정할 메서드**: `_buildBottomBar()`
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
            onPressed: _isPaymentProcessing ? null : _showPaymentMethodModal,
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

## 📂 Step 2: Mock 결제 시스템 (위젯 키 불필요)

### 2.1 PaymentService (Mock 모드)
**파일**: `lib/services/payment_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import './token_service.dart';

/// 결제 서비스 (Mock 모드)
class PaymentService {
  final TokenService _tokenService = TokenService();

  /// 결제 정보 조회
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

  /// Mock 결제 승인
  /// POST /api/contracts/{contractId}/confirm-payment-mock
  Future<void> confirmPaymentMock({
    required int contractId,
    required String orderId,
    required int amount,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/contracts/$contractId/confirm-payment-mock',
      ),
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
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['message'] ?? 'Mock 결제 실패');
    }
  }
}
```

### 2.2 게스트 계약 상세 페이지 - Mock 결제 로직
**파일**: `lib/pages/contract/guest_contract_detail_page.dart`

**추가할 import**:
```dart
import '../../services/payment_service.dart';
import 'dart:io';
```

**추가할 State 변수**:
```dart
final PaymentService _paymentService = PaymentService();
```

**구현할 메서드**: `_processPaymentMock()`
```dart
/// Mock 결제 처리
Future<void> _processPaymentMock(PaymentMethod method) async {
  setState(() => _isPaymentProcessing = true);

  try {
    // 1. 결제 정보 조회
    final paymentInfo = await _paymentService.getPaymentInfo(widget.contractId);

    // 2. Mock 결제 승인
    await _paymentService.confirmPaymentMock(
      contractId: widget.contractId,
      orderId: paymentInfo['orderId'],
      amount: paymentInfo['amount'],
    );

    // 3. 성공 메시지
    if (mounted) {
      _showSuccessDialog('[MOCK] 결제가 완료되었습니다!');
      _loadContractDetail(); // 계약 상태 갱신
    }
  } on SocketException {
    if (mounted) {
      _showErrorDialog('네트워크 연결을 확인해주세요');
    }
  } on HttpException {
    if (mounted) {
      _showErrorDialog('서버 오류가 발생했습니다');
    }
  } catch (e) {
    debugPrint('결제 오류: $e');
    if (mounted) {
      _showErrorDialog('결제 중 오류가 발생했습니다: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isPaymentProcessing = false);
    }
  }
}

/// 성공 다이얼로그
void _showSuccessDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('결제 완료'),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

/// 에러 다이얼로그
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('오류'),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
```

---

## 🧪 Step 2 테스트 (Mock 모드)

### 테스트 시나리오
1. ✅ 게스트 계약 상세 페이지 진입 (APPROVED 상태)
2. ✅ "₩13,103,743 결제하기" 버튼 클릭
3. ✅ 결제 수단 선택 모달 표시
4. ✅ "간편결제" 선택
5. ✅ 결제 확인 다이얼로그에서 "결제하기" 클릭
6. ✅ "[MOCK] 결제 완료!" 메시지 확인
7. ✅ 계약 상태 PAYMENT_COMPLETED로 변경 확인

**기대 결과**: 토스 결제창 없이 전체 플로우 테스트 완료

---

## 📚 Step 3: 토스 SDK 연동 (나중에)

### 3.1 토스페이먼츠 테스트 키 발급 (무료)
**방법**:
1. https://developers.tosspayments.com 접속
2. 회원가입 (이메일, 비밀번호)
3. "내 앱" → "새 앱 만들기"
4. 앱 이름 입력 (예: "EZStay 테스트")
5. **테스트 클라이언트 키** 복사 (`test_ck_xxx`)

**비용**: 무료 (사업자 등록 불필요)

### 3.2 SDK 설치 및 설정
**파일**: `pubspec.yaml`

```yaml
dependencies:
  tosspayments_widget_sdk: ^1.0.0
```

**파일**: `lib/config/payment_config.dart`

```dart
import 'package:tosspayments_widget_sdk/tosspayments_widget_sdk.dart';

class PaymentConfig {
  static const String clientKey = 'test_ck_xxx';  // 발급받은 키
  static late TossPayments tossPayments;

  static void initialize() {
    tossPayments = TossPayments(clientKey: clientKey);
  }
}
```

**파일**: `lib/main.dart`

```dart
import 'config/payment_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 토스페이먼츠 SDK 초기화
  PaymentConfig.initialize();

  runApp(const MyApp());
}
```

### 3.3 PaymentService에 실제 결제 로직 추가
**파일**: `lib/services/payment_service.dart`

**추가 메서드**:
```dart
/// 실제 결제 승인 (토스 SDK 사용)
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
```

### 3.4 게스트 계약 상세 페이지 - 실제 결제 로직
**파일**: `lib/pages/contract/guest_contract_detail_page.dart`

**추가 import**:
```dart
import '../../config/payment_config.dart';
import 'package:tosspayments_widget_sdk/tosspayments_widget_sdk.dart';
```

**새 메서드 추가**:
```dart
/// 실제 토스 결제 처리 (Step 3에서 추가)
Future<void> _processPaymentReal(PaymentMethod method) async {
  setState(() => _isPaymentProcessing = true);

  try {
    // 1. 결제 정보 조회
    final paymentInfo = await _paymentService.getPaymentInfo(widget.contractId);

    // 2. 토스 결제창 호출
    final result = await PaymentConfig.tossPayments.requestPayment(
      method: _mapToTossPaymentMethod(method),
      amount: paymentInfo['amount'],
      orderId: paymentInfo['orderId'],
      orderName: paymentInfo['orderName'],
      successUrl: '${ApiConfig.baseUrl}/payment/success',
      failUrl: '${ApiConfig.baseUrl}/payment/fail',
      customerEmail: paymentInfo['customerEmail'],
      customerName: paymentInfo['customerName'],
    );

    if (result != null && result.success) {
      // 3. 결제 승인
      await _paymentService.confirmPayment(
        contractId: widget.contractId,
        paymentKey: result.paymentKey!,
        orderId: paymentInfo['orderId'],
        amount: paymentInfo['amount'],
      );

      if (mounted) {
        _showSuccessDialog('결제가 완료되었습니다!');
        _loadContractDetail();
      }
    } else {
      throw Exception(result?.errorMessage ?? '결제 실패');
    }
  } catch (e) {
    debugPrint('결제 오류: $e');
    if (mounted) {
      _showErrorDialog('결제 중 오류가 발생했습니다: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isPaymentProcessing = false);
    }
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

**결제 처리 메서드 분기**:
```dart
/// 결제 수단 선택 모달에서 "결제하기" 클릭 시
final confirmed = await _showPaymentConfirmDialog(selectedMethod);
if (confirmed == true) {
  // TODO: 토스 SDK 연동 후 _processPaymentReal()로 변경
  await _processPaymentMock(selectedMethod);  // 현재는 Mock
}
```

---

## ✅ 구현 체크리스트

### Step 1: UI 구현 (위젯 키 불필요)
- [ ] `PaymentMethodModal` 위젯 생성
  - [ ] 모달 헤더 (제목 + 닫기 버튼)
  - [ ] 결제 수단 카드 (5개)
  - [ ] 선택 상태 애니메이션
  - [ ] 하단 고정 버튼
- [ ] 게스트 계약 상세 페이지 수정
  - [ ] 상태 변수 추가
  - [ ] `_showPaymentMethodModal()` 메서드
  - [ ] `_showPaymentConfirmDialog()` 메서드
  - [ ] `_buildBottomBar()` 수정 (APPROVED 상태만 결제 버튼)

### Step 2: Mock 결제 시스템 (위젯 키 불필요)
- [ ] `PaymentService` 클래스 생성
  - [ ] `getPaymentInfo()` 메서드
  - [ ] `confirmPaymentMock()` 메서드
- [ ] 게스트 계약 상세 페이지
  - [ ] `_processPaymentMock()` 메서드
  - [ ] `_showSuccessDialog()` 메서드
  - [ ] `_showErrorDialog()` 메서드
  - [ ] 에러 핸들링 (SocketException, HttpException)
- [ ] Mock 결제 테스트
  - [ ] 결제 UI 플로우
  - [ ] API 연동
  - [ ] 계약 상태 변경

### Step 3: 토스 SDK 연동 (나중에, 위젯 키 필요)
- [ ] 토스페이먼츠 개발자센터 가입
- [ ] 테스트 클라이언트 키 발급
- [ ] `tosspayments_widget_sdk` 패키지 설치
- [ ] `PaymentConfig` 클래스 생성
- [ ] `PaymentService`에 `confirmPayment()` 추가
- [ ] `_processPaymentReal()` 메서드 추가
- [ ] 실제 토스 결제 테스트

---

## 🚀 권장 작업 순서

### 오늘 (2-3시간)
1. ✅ **Step 1: UI 구현** (위젯 키 불필요)
   - PaymentMethodModal 위젯 생성
   - 게스트 계약 상세 페이지 결제 버튼 추가
   - 결제 확인 다이얼로그

### 내일 (2-3시간)
2. ✅ **Step 2: Mock 결제** (위젯 키 불필요)
   - PaymentService 생성
   - Mock 결제 API 연동
   - 전체 플로우 테스트

### 나중에 (1-2시간, 토스 키 발급 후)
3. ⏳ **Step 3: 토스 SDK 연동** (위젯 키 필요)
   - 토스페이먼츠 가입 및 키 발급
   - SDK 설치 및 설정
   - 실제 결제 로직 추가

---

## 📚 추가 정보

### 토스페이먼츠 무료 테스트 키 발급
**URL**: https://developers.tosspayments.com
**필요사항**: 이메일만 (사업자 등록 불필요)
**제한사항**: 없음 (실제 결제 안 됨, 테스트만 가능)

### Mock 모드 vs 실제 결제 모드
| 비교 항목 | Mock 모드 | 실제 결제 모드 |
|----------|----------|--------------|
| 토스 SDK | ❌ 불필요 | ✅ 필요 |
| 위젯 키 | ❌ 불필요 | ✅ 필요 |
| 결제창 | ❌ 없음 | ✅ 토스 결제창 |
| 테스트 가능 | ✅ UI 플로우 | ✅ 전체 플로우 |
| 백엔드 연동 | ✅ 가능 | ✅ 가능 |

---

**문서 버전**: 1.0.0
**작성일**: 2025-01-11
**작성자**: Claude Code
**상태**: Ready for Implementation
