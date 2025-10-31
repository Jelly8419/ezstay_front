# 결제 수단 선택 모달 디자인 명세서

## 개요
계약 상세 페이지의 결제 수단 선택 UI를 페이지 내 섹션에서 모던한 팝업(모달) 형태로 변경

## 디자인 목표
- 깔끔한 UI: 결제하기 버튼만 표시, 필요시 모달로 선택
- 모던한 스타일: 부드러운 애니메이션, 그라데이션, 그림자 효과
- 직관적인 UX: 명확한 단계별 플로우

---

## 1. UI 구조 변경

### Before (현재)
```
┌─────────────────────────────────┐
│  방 정보 카드 + 채팅 버튼        │
├─────────────────────────────────┤
│  계약 정보                       │
├─────────────────────────────────┤
│  📋 결제 수단 선택               │ ← 제거
│  ☑️ 신용카드                     │
│  ☐ 계좌이체                      │
│  ☐ 가상계좌                      │
│  ☐ 간편결제                      │
│  ☐ 휴대폰결제                    │
├─────────────────────────────────┤
│  💳 결제 정보 확인               │ ← 제거
│  선택: 간편결제                  │
│  금액: ₩13,103,743              │
├─────────────────────────────────┤
│  [₩13,103,743 결제하기]         │
└─────────────────────────────────┘
```

### After (변경 후)
```
┌─────────────────────────────────┐
│  방 정보 카드 + 채팅 버튼        │
├─────────────────────────────────┤
│  계약 정보                       │
├─────────────────────────────────┤
│  (결제 수단 섹션 제거)           │
│                                 │
│  [₩13,103,743 결제하기]  ← 클릭 │
└─────────────────────────────────┘

클릭 시 ↓

┌─────────────────────────────────┐
│ ◀━━━━━ 모달 팝업 ━━━━━▶        │
│ ┌───────────────────────────┐   │
│ │ 결제 수단 선택        ✕  │   │
│ ├───────────────────────────┤   │
│ │                           │   │
│ │ ☑️ 💳 신용카드             │   │
│ │ 간편하고 빠른 결제         │   │
│ │                           │   │
│ │ ☐ 🏦 계좌이체             │   │
│ │ 수수료 없이 안전한 결제    │   │
│ │                           │   │
│ │ ☐ 📃 가상계좌             │   │
│ │ 계좌번호 발급 후 입금      │   │
│ │                           │   │
│ │ ☐ 📱 간편결제             │   │
│ │ 카카오·네이버·토스페이     │   │
│ │                           │   │
│ │ ☐ 📞 휴대폰 결제          │   │
│ │ 휴대폰 소액결제로 간편하게 │   │
│ │                           │   │
│ ├───────────────────────────┤   │
│ │ [선택한 수단으로 결제하기] │   │
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

---

## 2. 모달 디자인 명세

### 2.1 모달 컨테이너
```yaml
레이아웃:
  최대_너비: 500px
  최대_높이: 80vh (화면 높이의 80%)
  여백: 16px (모바일), 24px (데스크톱)
  위치: 화면 중앙

배경:
  색상: Colors.white
  모서리: BorderRadius.circular(24)
  그림자:
    - offset: (0, 20)
    - blur: 60
    - color: Colors.black.withValues(alpha: 0.25)

애니메이션:
  등장: SlideTransition (아래 → 위) + FadeTransition
  사라짐: SlideTransition (위 → 아래) + FadeTransition
  지속시간: 400ms
  곡선: Curves.easeOutCubic
```

### 2.2 모달 헤더
```yaml
레이아웃:
  높이: 64px
  패딩: EdgeInsets.symmetric(horizontal: 24, vertical: 16)

구성요소:
  - 제목: "결제 수단 선택"
    - 폰트: 20px, FontWeight.w700
    - 색상: AppColors.textPrimary
  - 닫기_버튼:
    - 아이콘: Icons.close
    - 크기: 28px
    - 색상: Colors.grey.shade600
    - 호버: Colors.grey.shade400
    - 클릭: 모달 닫기
```

### 2.3 결제 수단 카드 (모달 내)
```yaml
레이아웃:
  스크롤: 활성화 (많은 항목 대비)
  패딩: EdgeInsets.symmetric(horizontal: 20, vertical: 12)
  간격: 12px (카드 간)

카드_디자인:
  기본_상태:
    배경: Colors.white
    테두리: 1px, Colors.grey.shade300
    모서리: BorderRadius.circular(16)
    그림자:
      - offset: (0, 2)
      - blur: 8
      - color: Colors.black.withValues(alpha: 0.04)
    패딩: EdgeInsets.all(20)

  선택_상태:
    배경: Linear Gradient
      - colors: [AppColors.primary.withValues(alpha: 0.08), Colors.white]
      - begin: Alignment.topLeft
      - end: Alignment.bottomRight
    테두리: 2px, AppColors.primary
    그림자:
      - offset: (0, 4)
      - blur: 16
      - color: AppColors.primary.withValues(alpha: 0.2)
    체크_아이콘:
      - 위치: 우측 상단
      - 아이콘: Icons.check_circle
      - 색상: AppColors.primary
      - 크기: 28px

  호버_상태 (웹):
    배경: Colors.grey.shade50
    테두리: 1.5px, Colors.grey.shade400
    커서: pointer

  애니메이션:
    지속시간: 250ms
    곡선: Curves.easeOutCubic
    변화: 배경색, 테두리, 그림자, 스케일(1.0 → 1.02)
```

### 2.4 카드 내용 구조
```yaml
구조:
  - 좌측:
    - 아이콘 (28px, 원형 배경)
      배경: AppColors.primary.withValues(alpha: 0.1)
      아이콘_색상: AppColors.primary
  - 중앙 (Expanded):
    - 제목: 14px, FontWeight.w600, AppColors.textPrimary
    - 설명: 13px, FontWeight.w400, Colors.grey.shade600
      줄_간격: 4px
  - 우측:
    - 체크_아이콘 (선택 시만 표시)
```

### 2.5 하단 고정 버튼
```yaml
레이아웃:
  위치: 모달 하단 고정 (sticky)
  배경: Colors.white
  패딩: EdgeInsets.all(20)
  그림자:
    - offset: (0, -4)
    - blur: 12
    - color: Colors.black.withValues(alpha: 0.08)

버튼:
  비활성_상태 (미선택):
    배경: Colors.grey.shade300
    텍스트: "결제 수단을 선택해주세요"
    텍스트_색상: Colors.grey.shade600
    커서: not-allowed

  활성_상태 (선택됨):
    배경: Linear Gradient
      - colors: [AppColors.primary, AppColors.primary.darker(0.1)]
      - begin: Alignment.topLeft
      - end: Alignment.bottomRight
    텍스트: "₩{금액} 결제하기"
    텍스트_색상: Colors.white
    그림자:
      - offset: (0, 4)
      - blur: 16
      - color: AppColors.primary.withValues(alpha: 0.4)
    호버: 그림자 강화, 스케일(1.02)

  크기:
    높이: 56px
    너비: 100%
    모서리: BorderRadius.circular(16)

  애니메이션:
    지속시간: 300ms
    곡선: Curves.easeOutCubic
```

---

## 3. 배경 오버레이 디자인

```yaml
오버레이:
  색상: Colors.black.withValues(alpha: 0.6)
  애니메이션:
    등장: FadeTransition (0.0 → 0.6)
    사라짐: FadeTransition (0.6 → 0.0)
    지속시간: 300ms

상호작용:
  클릭: 모달 닫기 (dimiss on barrier tap)
  스크롤: 차단 (prevent background scroll)
```

---

## 4. UX 플로우

### 4.1 결제하기 버튼 클릭
```
사용자 액션: [결제하기] 버튼 클릭
           ↓
시스템 반응: 1. 배경 오버레이 페이드 인 (300ms)
           2. 모달 슬라이드 업 + 페이드 인 (400ms)
           3. 첫 번째 결제 수단 강조 (선택 안 됨)
```

### 4.2 결제 수단 선택
```
사용자 액션: 결제 수단 카드 클릭 (예: 간편결제)
           ↓
시스템 반응: 1. 기존 선택 해제 애니메이션 (250ms)
           2. 새로운 선택 활성화 애니메이션 (250ms)
           3. 하단 버튼 활성화 (금액 표시)
           4. 햅틱 피드백 (모바일)
```

### 4.3 결제 진행
```
사용자 액션: 모달 내 [₩금액 결제하기] 버튼 클릭
           ↓
시스템 반응: 1. 모달 닫기 애니메이션 (400ms)
           2. 결제 확인 다이얼로그 표시
              - 선택한 결제 수단 표시
              - 최종 금액 표시
              - [취소] / [결제하기] 버튼
           ↓
사용자 확인: [결제하기] 클릭
           ↓
결제 처리: _processPayment() 실행
```

### 4.4 모달 닫기
```
방법 1: 닫기 버튼(✕) 클릭
방법 2: 배경 오버레이 클릭
방법 3: 뒤로 가기 (모바일)
방법 4: ESC 키 (웹)

반응: 1. 모달 슬라이드 다운 + 페이드 아웃 (400ms)
     2. 배경 오버레이 페이드 아웃 (300ms)
     3. 선택 상태 유지 (재오픈 시 복원)
```

---

## 5. 반응형 디자인

### 5.1 모바일 (< 600px)
```yaml
모달:
  너비: 100% - 32px (좌우 16px 여백)
  높이: 최대 85vh
  위치: 화면 하단 고정 (bottom sheet 스타일)
  모서리: 상단만 둥글게 (24px)

애니메이션:
  등장: 하단에서 슬라이드 업
  사라짐: 하단으로 슬라이드 다운
```

### 5.2 태블릿 (600px ~ 1024px)
```yaml
모달:
  너비: 500px
  위치: 화면 중앙
  모서리: 전체 둥글게 (24px)
```

### 5.3 데스크톱 (> 1024px)
```yaml
모달:
  너비: 500px
  위치: 화면 중앙
  모서리: 전체 둥글게 (24px)
  호버_효과: 활성화
```

---

## 6. 접근성 (Accessibility)

```yaml
시맨틱:
  - 모달: role="dialog", aria-modal="true"
  - 제목: aria-labelledby="payment-modal-title"
  - 닫기: aria-label="결제 수단 선택 닫기"

키보드_네비게이션:
  - Tab: 다음 결제 수단
  - Shift+Tab: 이전 결제 수단
  - Enter/Space: 결제 수단 선택
  - Escape: 모달 닫기
  - Arrow Up/Down: 결제 수단 이동

포커스_관리:
  - 모달_열림: 첫 번째 결제 수단에 포커스
  - 모달_닫힘: 결제하기 버튼에 포커스 복원
  - 포커스_트랩: 모달 내부에만 포커스 제한

스크린_리더:
  - 선택_상태: "신용카드, 선택됨"
  - 미선택_상태: "계좌이체, 선택 안 됨"
  - 결제_금액: "일천삼백만 삼천칠백사십삼원 결제하기"
```

---

## 7. 애니메이션 타이밍

```yaml
페이즈_1_오버레이_등장:
  지속시간: 300ms
  곡선: Curves.easeOut
  변화: opacity 0.0 → 0.6

페이즈_2_모달_등장:
  시작: 페이즈_1 완료 후 50ms 딜레이
  지속시간: 400ms
  곡선: Curves.easeOutCubic
  변화:
    - offset: (0, 100) → (0, 0)
    - opacity: 0.0 → 1.0
    - scale: 0.9 → 1.0

결제수단_선택_애니메이션:
  지속시간: 250ms
  곡선: Curves.easeOutCubic
  변화:
    - 배경색 전환
    - 테두리 두께 및 색상
    - 그림자 깊이
    - 스케일 1.0 → 1.02 → 1.0

버튼_활성화_애니메이션:
  지속시간: 300ms
  곡선: Curves.easeOutCubic
  변화:
    - 배경색 (회색 → Primary)
    - 텍스트 변경
    - 그림자 추가
```

---

## 8. 구현 가이드

### 8.1 코드 변경 사항

#### 제거할 메서드:
```dart
// ❌ 제거
Widget _buildPaymentMethodSection()
Widget _buildPaymentSummarySection()
```

#### 추가할 메서드:
```dart
// ✅ 추가
Future<void> _showPaymentMethodModal()
Widget _buildPaymentMethodModal()
Widget _buildModalHeader()
Widget _buildModalPaymentCard(PaymentMethod method)
Widget _buildModalBottomButton()
```

#### 수정할 메서드:
```dart
// 🔄 수정
Widget _buildBottomBar() {
  // 항상 결제하기 버튼 표시
  // 클릭 시 _showPaymentMethodModal() 호출
}
```

### 8.2 상태 관리
```dart
// 상태 변수 (기존 유지)
PaymentMethod? _selectedPaymentMethod;
bool _isPaymentProcessing = false;
```

### 8.3 핵심 구현 로직
```dart
// 1. 결제하기 버튼 → 모달 표시
ElevatedButton(
  onPressed: _showPaymentMethodModal,
  child: Text('₩${금액} 결제하기'),
)

// 2. 모달 표시
Future<void> _showPaymentMethodModal() async {
  final selectedMethod = await showModalBottomSheet<PaymentMethod>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _buildPaymentMethodModal(),
  );

  if (selectedMethod != null) {
    setState(() => _selectedPaymentMethod = selectedMethod);
    await _processPayment();
  }
}

// 3. 모달 내 버튼 클릭 → 선택 반환 → 결제 처리
Navigator.pop(context, _selectedPaymentMethod);
```

---

## 9. 디자인 시스템 준수

### 사용할 컴포넌트:
```dart
// AppColors
- AppColors.primary (Primary 500)
- AppColors.primary.withValues(alpha: 0.08) (선택 배경)
- AppColors.textPrimary (제목)
- Colors.grey.shade600 (설명)
- Colors.grey.shade300 (비활성 테두리)

// AppSpacing
- AppSpacing.paddingMd (16px)
- AppSpacing.paddingLg (24px)
- AppRadius.radiusLg (16px)
- AppRadius.radiusXl (24px)

// AppDurations
- AppDurations.modal (400ms)
- AppDurations.hoverCard (300ms)
- AppDurations.listItem (250ms)

// AppCurves
- AppCurves.modal (Curves.easeOutCubic)
- AppCurves.hoverCard (Curves.easeOutCubic)
```

---

## 10. 테스트 체크리스트

### 기능 테스트:
- [ ] 결제하기 버튼 클릭 시 모달 정상 표시
- [ ] 결제 수단 선택 시 UI 상태 변경
- [ ] 모달 닫기 버튼 동작 확인
- [ ] 배경 오버레이 클릭 시 모달 닫힌 확인
- [ ] 모달 내 버튼 클릭 시 결제 진행
- [ ] 결제 수단 미선택 시 버튼 비활성화

### UI/UX 테스트:
- [ ] 애니메이션 부드러움 확인
- [ ] 반응형 레이아웃 (모바일/태블릿/데스크톱)
- [ ] 스크롤 동작 (많은 결제 수단 추가 시)
- [ ] 호버 효과 (웹 데스크톱)
- [ ] 터치 피드백 (모바일)

### 접근성 테스트:
- [ ] 키보드 네비게이션
- [ ] 스크린 리더 호환성
- [ ] 포커스 트랩
- [ ] ARIA 속성

---

## 11. 구현 우선순위

### Phase 1: 기본 모달 구조 ✅
- 모달 표시/숨김 기능
- 기본 레이아웃 (헤더, 본문, 하단 버튼)
- 결제 수단 카드 리스트

### Phase 2: 인터랙션 ✅
- 결제 수단 선택 상태 관리
- 하단 버튼 활성화/비활성화
- 모달 닫기 기능

### Phase 3: 애니메이션 ✅
- 모달 등장/사라짐 애니메이션
- 카드 선택 애니메이션
- 버튼 활성화 애니메이션

### Phase 4: 스타일 개선 ✅
- 그라데이션 배경
- 그림자 효과
- 호버 효과 (웹)

### Phase 5: 접근성 및 최적화 (선택)
- 키보드 네비게이션
- 스크린 리더 지원
- 성능 최적화

---

## 참고 자료

### Flutter 위젯:
- `showModalBottomSheet()` - 모달 표시 (모바일 스타일)
- `showDialog()` - 다이얼로그 표시 (데스크톱 스타일)
- `AnimatedContainer` - 카드 선택 애니메이션
- `SlideTransition` + `FadeTransition` - 모달 등장 애니메이션

### 디자인 참고:
- Toss Payments 결제 모달
- 카카오페이 결제 수단 선택
- Airbnb 예약 확인 모달
- Material Design 3 Dialog 패턴

---

**문서 버전**: 1.0.0
**작성일**: 2025-10-30
**작성자**: Claude Code
**상태**: Ready for Implementation
