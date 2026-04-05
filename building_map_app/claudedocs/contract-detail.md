# 계약 상세 페이지 분석 및 개선 작업 기록

> 작성일: 2026-04-06
> 대상: 게스트/호스트 계약 상세 페이지 및 관련 위젯 전체

---

## 1. 파일 구조

### 페이지
| 파일 | 클래스 | 역할 |
|------|--------|------|
| `lib/pages/contract/guest_contract_detail_page.dart` | `GuestContractDetailPage` | 게스트 계약 상세 |
| `lib/pages/contract/host_contract_detail_page.dart` | `HostContractDetailPage` | 호스트 계약 상세 |

### 게스트 섹션 위젯 (`lib/widgets/contract/`)
| 파일 | 위젯 | 내용 |
|------|------|------|
| `guest_contract_basic_info_section.dart` | `GuestContractBasicInfoSection` | 방 사진, 계약번호, 주소, 기간, 결제 금액, 상태 배지 |
| `guest_contract_party_info_section.dart` | `GuestContractPartyInfoSection` | 호스트/게스트 카드 (반응형) |
| `guest_contract_amount_section.dart` | `GuestContractAmountSection` | 임대료, 관리비, 청소비, 수수료, 보증금, 합계 |
| `guest_contract_option_section.dart` | `GuestContractOptionSection` | EZ 옵션 상품 목록 |
| `guest_contract_cancellation_section.dart` | `GuestContractCancellationSection` | 환불 규정 (신규 분리) |
| `guest_contract_payment_history_section.dart` | `GuestContractPaymentHistorySection` | 결제 내역 (paymentHistory 비어있지 않을 때만) |
| `guest_contract_detail_dialogs.dart` | `GuestCheckoutConfirmDialog` | 퇴실 확인 다이얼로그 (단 1개만 유지) |

### 호스트 섹션 위젯 (`lib/widgets/contract/`)
| 파일 | 위젯 | 내용 |
|------|------|------|
| `host_contract_basic_info_section.dart` | `HostContractBasicInfoSection` | 방 이미지, 계약번호, 주소, 기간, 확정일 (반응형) |
| `host_contract_party_info_section.dart` | `HostContractPartyInfoSection` | 호스트/게스트 당사자 정보 (반응형) |
| `host_contract_amount_section.dart` | `HostContractAmountSection` | 정산 금액 (settlement 있음/없음 분기) |
| `host_contract_action_buttons.dart` | `HostContractActionButtons` | 상태별 액션 버튼 (퇴실 확인 / 취소 요청) |
| `host_deposit_agreement_section.dart` | `HostDepositAgreementSection` | 보증금 합의 (HOST_PENDING / AGREEMENT_SUBMITTED) |
| `host_contract_detail_dialogs.dart` | `HostCheckoutConfirmDialog` 외 2개 | 퇴실 확인, 퇴실 요청, 위약금 확인 다이얼로그 |

### 공통 유틸
| 파일 | 역할 |
|------|------|
| `lib/utils/contract_utils.dart` | 퇴실 조건, 주소 공개, 전화번호 표시 등 비즈니스 로직 중앙화 |

---

## 2. 페이지 렌더링 구조

### 게스트 계약 상세
```
ColoredBox(gray50)
└── SingleChildScrollView
    └── Center > Container(maxWidth: 896px)
        ├── "계약 상세 정보" 제목
        ├── ContractStatusBanner
        ├── GuestContractBasicInfoSection
        ├── GuestContractPartyInfoSection
        ├── GuestContractAmountSection
        ├── GuestContractOptionSection
        ├── [조건] CheckoutConfirmationWidget  ← IN_PROGRESS + 퇴실일 당일 이상
        ├── GuestContractCancellationSection   ← 환불 규정
        ├── NoticeContainer
        ├── [조건] GuestContractPaymentHistorySection  ← paymentHistory 있을 때
        └── AppFooter
```

### 호스트 계약 상세
```
Stack
├── ColoredBox(gray50) > ResponsivePageLayout(maxWidth: 896px)
│   └── SingleChildScrollView
│       ├── "계약 상세 정보" 제목
│       ├── ContractStatusBanner
│       ├── HostContractBasicInfoSection
│       ├── HostContractPartyInfoSection
│       ├── HostContractAmountSection
│       ├── [조건] CheckoutConfirmationWidget  ← IN_PROGRESS + 퇴실일 당일 이상
│       ├── HostContractActionButtons           ← IN_PROGRESS 상태별 버튼
│       ├── HostDepositAgreementSection         ← HOST_PENDING / AGREEMENT_SUBMITTED
│       ├── ContractDetailCard > NoticeContainer
│       └── AppFooter
├── [조건] RequestCancellationModal
└── [조건] DepositAgreementModal
```

---

## 3. 상태 흐름 및 UI 조건

### 계약 상태 (`ContractStatus`)
```
PENDING_APPROVAL → APPROVED → PAYMENT_COMPLETED → IN_PROGRESS → COMPLETED
                                                 ↘ CANCELLED_BY_* / REFUNDED
```

### 상태별 UI 동작

| 상태 | 주소 표시 | 전화번호 | 퇴실 확인 위젯 | 게스트 결제 버튼 |
|------|----------|---------|--------------|----------------|
| PENDING_APPROVAL | 기본주소+층 | 비노출 | - | - |
| APPROVED | 기본주소+층 | 비노출 | - | ~~결제 버튼~~ (삭제됨) |
| PAYMENT_COMPLETED | 상세주소 | 노출 | - | - |
| IN_PROGRESS (퇴실일 전) | 상세주소 | 노출 | - | - |
| IN_PROGRESS (퇴실일 당일+) | 상세주소 | 노출 | ✅ 노출 | - |
| COMPLETED | 상세주소 | 노출 | - | - |

### 호스트 액션 버튼 조건 (`HostContractActionButtons`)

| 상태 | checkoutStatus | 퇴실 시간 도래 | 표시 버튼 |
|------|--------------|-------------|---------|
| IN_PROGRESS | null / NOT_STARTED | 미도래 + 요청 없음 | 취소 요청만 |
| IN_PROGRESS | null / NOT_STARTED | 도래 or 요청 있음 | 퇴실 확인 + 취소 요청 |
| 그 외 | - | - | 없음 |

> PAYMENT_COMPLETED 상태의 계약 취소(호스트 귀책)는 **계약관리 페이지에서 처리**.

---

## 4. 이번 작업에서 수행한 개선 내용

### 4-1. 결제 플로우 제거

**배경**: 결제는 계약관리 페이지에서 수행하는 것이 정책. 계약 상세 페이지에 결제 로직이 있는 것은 잘못된 설계.

**게스트 페이지에서 삭제된 항목**:
- `GuestPaymentService` 필드 및 import
- `_isPaymentProcessing` 상태 변수
- `_processPayment()`, `_processPaymentWeb()`, `_processPaymentMobile()`, `_processPaymentWithMock()`, `_confirmPayment()` 메서드
- `_buildBottomBar()` (APPROVED 상태 결제 버튼)
- `_showSuccessDialog()`, `_showErrorDialog()`, `_showPopupBlockedDialog()` 및 관련 다이얼로그 클래스 3개
- `PaymentConfig`, `payment_service_web`, `PaymentWebView`, `PaymentMethodModal` import

**호스트 페이지에서 삭제된 항목**:
- `_handleCancelByHost()` — RefundCalculationModal 호출 및 위약금 결제 진입점
- `_processHostPenaltyPayment()` — PayTag SDK mock 결제 호출 (recvPayparam: 'mock_key' 하드코딩 상태였음)
- `_executeCancelByHost()` — 위약금 없는 취소 처리
- `PaymentService` import, `RefundCalculationModal` import
- `HostContractActionButtons`의 `onCancelByHost` 콜백 파라미터 및 PAYMENT_COMPLETED 취소 버튼

### 4-2. 취소 정책 섹션 위젯 분리 (게스트)

**변경 전**: `guest_contract_detail_page.dart` 내 `_buildCancellationPolicySection()` 인라인 메서드

**변경 후**: `guest_contract_cancellation_section.dart` → `GuestContractCancellationSection` StatelessWidget

다른 섹션들과 동일한 패턴으로 통일.

### 4-3. 퇴실 확인 노출 조건 수정

**파일**: `lib/utils/contract_utils.dart` — `shouldShowCheckoutConfirmation()`

**변경 전 문제**: 퇴실 시간(`roomCheckoutTime`, 기본 11:00)을 무시하고 날짜만 비교하여 당일 오전에도 표시되는 문제. 또한 로직이 불명확했음.

**변경 후 정책**: 퇴실 당일 00:00부터 노출. 일찍 퇴실하는 케이스를 위해 시간 조건 없이 당일 전체 노출.

```dart
// 변경 후
static bool shouldShowCheckoutConfirmation(ContractDetail? contract) {
  if (contract == null) return false;
  if (ContractStatus.fromString(contract.status) != ContractStatus.inProgress) return false;
  final checkOutDate = DateTime.tryParse(contract.checkOutDate);
  if (checkOutDate == null) return false;
  final checkOutDay = DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  return !todayDay.isBefore(checkOutDay); // 당일 포함, 이후 모두 노출
}
```

### 4-4. 하드코딩 색상 → AppColors 교체

**대상 파일 (게스트)**: `guest_contract_amount_section`, `guest_contract_option_section`, `guest_contract_party_info_section`, `guest_contract_detail_dialogs`

**대상 파일 (호스트)**: `host_contract_basic_info_section`, `host_contract_amount_section`, `host_contract_party_info_section`, `host_contract_detail_dialogs`, `host_deposit_agreement_section`

**주요 매핑**:
| 하드코딩 값 | AppColors 대체 |
|------------|--------------|
| `Color(0xFF111827)` | `AppColors.gray900` |
| `Color(0xFF374151)` | `AppColors.neutral700` |
| `Color(0xFF4B5563)` / `0xFF6B7280` | `AppColors.neutral600` / `neutral500` |
| `Color(0xFFE5E7EB)` | `AppColors.gray200` |
| `Color(0xFF2563EB)` / `0xFF1D4ED8` | `AppColors.blue600` |
| `Color(0xFFDC2626)` / `0xFFE53935` | `AppColors.error600` |
| `Color(0xFFFFF7ED)` / `0xFFFED7AA` | `AppColors.warning50` / `warning500` |
| `Color(0xFFDBEAFE)` | `AppColors.blue100` |
| `Color(0xFFDCFCE7)` | `AppColors.green100` |
| `Color(0xFFEFF6FF)` / `0xFFBFDBFE` | `AppColors.blue50` / `blue100` |
| `Color(0xFFFEF2F2)` / `0xFFFECACA` | `AppColors.error50` |
| SnackBar `backgroundColor` 하드코딩 | `AppColors.warning500` / `error600` / `success500` |

### 4-5. 상태 문자열 → enum 교체

**대상**: `contract_utils.dart`, `host_contract_action_buttons.dart`, `host_deposit_agreement_section.dart`, `host_contract_basic_info_section.dart`

- `ContractStatus.fromString(contract.status)` 방식으로 모든 문자열 비교 교체
- `CheckoutStatus.fromString(contract.checkoutStatus)` 방식으로 퇴실 상태 비교 교체
- `ContractDetail.status`가 `String` 타입이므로 모델 전환 없이 `fromString()` 변환 방식 사용

### 4-6. 전역 함수 → 클래스 메서드로 이동 (호스트)

**문제**: `host_contract_party_info_section.dart`와 `host_deposit_agreement_section.dart`에서 클래스 바깥에 `_` prefix 함수가 선언되어 있었음. private처럼 보이지만 실제로는 파일 레벨 함수.

**변경**: 각각 클래스 내부 메서드로 이동.

---

## 5. 남은 주의사항

### `getGuestContractDetail` 공유 사용
`host_contract_detail_page.dart`에서 `_contractService.getGuestContractDetail()`을 호출함. 게스트/호스트가 동일한 API 엔드포인트를 공유하는 구조로 의도된 것. 별도 호스트 전용 API가 생기면 교체 필요.

### `HostPenaltyPaymentConfirmDialog` 잔존
`host_contract_detail_dialogs.dart`에 위약금 결제 확인 다이얼로그(`HostPenaltyPaymentConfirmDialog`)가 남아있음. 계약관리 페이지에서 위약금 결제 플로우를 구현할 때 해당 다이얼로그를 이동해서 재사용 가능.

### `ContractDetail.status` 타입
모델의 `status` 필드가 `String`으로 유지됨. 전체 교체 시 `ContractDetail.fromJson` 파싱 및 `toJson`, `toContract()` 변환 로직까지 연쇄 수정 필요 — 별도 작업으로 분리 권장.
