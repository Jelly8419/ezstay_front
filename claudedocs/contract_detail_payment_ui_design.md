# 계약 상세 페이지 - 결제 UI 디자인 명세

## 📋 개요
게스트가 승인된 계약(status == approved)을 볼 때, 채팅 기능과 토스페이먼츠 스타일의 결제 UI를 제공합니다.

---

## 🎨 UI 구성 요소

### 1. 방 정보 카드 + 채팅하기 버튼

**위치**: 기존 방 정보 섹션 (_buildRoomSection)
**레이아웃**: Row - 방 정보 카드 + 채팅하기 버튼

```
┌─────────────────────────────────────────┐
│ 방 정보                                  │
│ ┌──────────────────────┬──────────────┐ │
│ │ [이미지]  방 이름      │  [채팅하기]   │ │
│ │         주소          │              │ │
│ │         면적·타입     │              │ │
│ └──────────────────────┴──────────────┘ │
└─────────────────────────────────────────┘
```

**채팅하기 버튼 스펙**:
- 크기: 아이콘 + 텍스트, 세로 정렬
- 색상: AppColors.primary (배경), Colors.white (텍스트)
- 모양: 둥근 모서리 (BorderRadius 12px)
- 아이콘: Icons.chat_bubble_outline
- 그림자: 미세한 elevation

---

### 2. 결제 수단 선택 섹션

**위치**: 금액 정보 섹션 이후, 계약 당사자 섹션 이전
**조건**: 게스트 & status == approved

```
┌─────────────────────────────────────────┐
│ 결제 수단 선택                            │
│                                          │
│ ┌──────────────────────────────────────┐ │
│ │ 💳 신용카드                           │ │
│ │ 간편하고 빠른 결제                     │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ┌──────────────────────────────────────┐ │
│ │ 🏦 계좌이체                           │ │
│ │ 수수료 없이 안전한 결제                │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ┌──────────────────────────────────────┐ │
│ │ 🏪 가상계좌                           │ │
│ │ 계좌번호 발급 후 입금                  │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ┌──────────────────────────────────────┐ │
│ │ 💸 간편결제                           │ │
│ │ 카카오페이·네이버페이·토스페이        │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ┌──────────────────────────────────────┐ │
│ │ 📱 휴대폰 결제                         │ │
│ │ 휴대폰 소액결제로 간편하게             │ │
│ └──────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**결제 수단 카드 스펙**:
- 선택 안됨:
  - 배경: Colors.white
  - 테두리: Colors.grey.shade300, 1px
  - 그림자: AppShadows.cardDefault
- 선택됨:
  - 배경: AppColors.primary.withValues(alpha: 0.05)
  - 테두리: AppColors.primary, 2px
  - 그림자: AppShadows.cardHover
- 호버 효과: HoverCard 사용
- 패딩: 16px
- 간격: 12px
- BorderRadius: 12px
- 애니메이션: AppDurations.hoverCard

**구조**:
```dart
Row(
  children: [
    Icon(emoji아이콘, size: 24),
    SizedBox(width: 12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(결제수단명, AppTextStyles.bodyMedium, fontWeight: w600),
          Text(설명, AppTextStyles.bodySmallSecondary),
        ],
      ),
    ),
    if (선택됨) Icon(Icons.check_circle, color: AppColors.primary),
  ],
)
```

---

### 3. 결제 정보 요약 카드

**위치**: 결제 수단 선택 섹션 하단
**조건**: 결제 수단이 선택된 경우

```
┌─────────────────────────────────────────┐
│ 📝 결제 정보 확인                         │
│                                          │
│ • 결제 수단: 신용카드                     │
│ • 결제 금액: ₩12,773,743                │
│                                          │
│ ⚠️ 결제 진행 시 계약이 확정됩니다.        │
└─────────────────────────────────────────┘
```

**스펙**:
- 배경: AppColors.primary.withValues(alpha: 0.05)
- 테두리: AppColors.primary.withValues(alpha: 0.3)
- BorderRadius: 12px
- 패딩: 20px

---

### 4. 하단 결제 버튼

**위치**: _buildBottomBar()
**조건**: 게스트 & status == approved

```
┌─────────────────────────────────────────┐
│              [결제하기]                   │
└─────────────────────────────────────────┘
```

**활성 상태**:
- 배경: AppColors.primary
- 텍스트: Colors.white, fontSize: 18, fontWeight: w700
- 패딩: vertical 20px
- BorderRadius: 16px
- 그림자: AppShadows.floatingButton
- 아이콘: Icons.payment
- 텍스트: "₩12,773,743 결제하기"

**비활성 상태** (결제 수단 미선택):
- 배경: Colors.grey.shade300
- 텍스트: Colors.grey.shade600
- 텍스트: "결제 수단을 선택해주세요"

---

## 🎯 결제 수단 데이터 모델

```dart
enum PaymentMethod {
  creditCard,      // 신용카드
  bankTransfer,    // 계좌이체
  virtualAccount,  // 가상계좌
  easyPay,        // 간편결제
  mobilePayment,  // 휴대폰 결제
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.creditCard:
        return '신용카드';
      case PaymentMethod.bankTransfer:
        return '계좌이체';
      case PaymentMethod.virtualAccount:
        return '가상계좌';
      case PaymentMethod.easyPay:
        return '간편결제';
      case PaymentMethod.mobilePayment:
        return '휴대폰 결제';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.creditCard:
        return '간편하고 빠른 결제';
      case PaymentMethod.bankTransfer:
        return '수수료 없이 안전한 결제';
      case PaymentMethod.virtualAccount:
        return '계좌번호 발급 후 입금';
      case PaymentMethod.easyPay:
        return '카카오페이·네이버페이·토스페이';
      case PaymentMethod.mobilePayment:
        return '휴대폰 소액결제로 간편하게';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.virtualAccount:
        return Icons.receipt_long;
      case PaymentMethod.easyPay:
        return Icons.smartphone;
      case PaymentMethod.mobilePayment:
        return Icons.phone_android;
    }
  }
}
```

---

## 💻 State 관리

**추가할 State 변수**:
```dart
PaymentMethod? _selectedPaymentMethod;  // 선택된 결제 수단
bool _isPaymentProcessing = false;       // 결제 처리 중
```

---

## 🔄 사용자 플로우

### 게스트 - 승인된 계약 결제

1. **계약 상세 페이지 진입** (status == approved)
   - 방 정보 카드 + 채팅하기 버튼 표시
   - 금액 정보 확인
   - 결제 수단 선택 섹션 표시

2. **결제 수단 선택**
   - 5가지 결제 수단 카드 중 하나 선택
   - 선택된 카드 강조 표시 (Primary 테두리)
   - 하단에 결제 버튼 활성화

3. **결제 진행**
   - "₩12,773,743 결제하기" 버튼 클릭
   - 확인 다이얼로그 표시
   - 결제 API 호출 (토스페이먼츠 연동 대기)
   - 성공 시: status → paymentCompleted
   - 실패 시: 에러 메시지 표시

---

## 🎨 디자인 시스템 준수

### 색상
- Primary: `AppColors.primary` (#4A90E2)
- Secondary: `AppColors.secondary`
- 텍스트: `AppColors.textPrimary`, `AppColors.textSecondary`
- 배경: `AppColors.surface`, `AppColors.background`
- 테두리: `AppColors.border`

### 타이포그래피
- 제목: `AppTextStyles.headingMedium`
- 본문: `AppTextStyles.bodyMedium`
- 부제: `AppTextStyles.bodySmallSecondary`
- 가격: `AppTextStyles.priceText`

### 간격
- 섹션 간격: `AppSpacing.xl` (32px)
- 카드 내부 패딩: `AppSpacing.md` (16px)
- 요소 간격: `AppSpacing.sm` (8px)

### 그림자
- 기본 카드: `AppShadows.cardDefault`
- 호버 카드: `AppShadows.cardHover`
- 선택 카드: `AppShadows.cardSelected`
- 플로팅 버튼: `AppShadows.floatingButton`

### 애니메이션
- Duration: `AppDurations.hoverCard` (300ms)
- Curve: `AppCurves.hoverCard` (easeOutCubic)

---

## 📱 반응형 고려사항

### 모바일 (<600px)
- 방 정보 카드: 세로 스택 (이미지 위, 정보 아래)
- 채팅하기 버튼: 카드 하단 전체 너비
- 결제 수단 카드: 전체 너비

### 태블릿 (600-1024px)
- 방 정보 카드: 가로 배치 유지
- 채팅하기 버튼: 오른쪽 배치
- 결제 수단 카드: 전체 너비

### 데스크톱 (>1024px)
- 방 정보 카드: 가로 배치
- 채팅하기 버튼: 오른쪽 상단
- 결제 수단 카드: 2열 그리드 (선택사항)

---

## 🚀 구현 우선순위

### Phase 1 (현재)
1. ✅ 방 정보 카드에 채팅하기 버튼 추가
2. ✅ 결제 수단 선택 UI 구현
3. ✅ 결제하기 버튼 추가

### Phase 2 (토스페이먼츠 연동)
1. ⏳ 토스페이먼츠 SDK 통합
2. ⏳ 결제 API 연동
3. ⏳ 결제 성공/실패 처리

### Phase 3 (추가 기능)
1. ⏳ 할부 옵션 선택
2. ⏳ 결제 영수증 발급
3. ⏳ 결제 내역 조회

---

## 🔗 참고 자료

- [토스페이먼츠 공식 문서](https://docs.tosspayments.com/)
- [Flutter 토스페이먼츠 플러그인](https://pub.dev/packages/tosspayments_widget_sdk)
- [EZStay 디자인 시스템](../CLAUDE.md#ui디자인-가이드라인)
