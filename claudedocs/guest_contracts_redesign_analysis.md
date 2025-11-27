# 게스트 계약 관리 페이지 재설계 분석

## 📋 개요

리액트 UI/UX 기반으로 Flutter 페이지를 **거의 전면 재작성**해야 합니다.
현재 구현은 기본적인 리스트만 표시하고, 리액트 코드의 핵심 기능(옵션 관리, 상태별 액션)이 누락되어 있습니다.

---

## 🔍 현재 상태 비교

### ✅ 현재 Flutter에 구현된 것
1. **API 호출 로직** (`ContractService.getGuestContracts`)
2. **기본 필터링** (ChoiceChip 기반)
3. **로딩/에러 상태 처리**
4. **RefreshIndicator**
5. **기본 계약 카드** (사진, 방 정보, 날짜, 금액)

### ❌ 리액트 코드에는 있지만 Flutter에 없는 핵심 기능

#### 1. **옵션 상품 관리 기능** (가장 중요!)
- 옵션 추가 및 변경 버튼 (`<ShoppingCart />` 아이콘)
- 수량 증감 UI (Plus/Minus 버튼)
- 편집 모드 토글 (저장/취소 버튼)
- **입주일 5일 전까지만 변경 가능** (날짜 기반 제한)
- **추가 결제 금액 계산** (파란색 배경)
- **환불 금액 계산** (빨간색 배경)
- 배송 상태 표시 (pending/preparing/in_transit/delivered)

#### 2. **상태별 액션 버튼**
- **승인 대기** (`PENDING_APPROVAL`): "요청 취소" 버튼
- **승인됨** (`APPROVED`): "결제하기" 버튼 (CreditCard 아이콘)
- **결제 완료** (`PAYMENT_COMPLETED`): "계약 취소" 버튼 + InfoTooltip
- **임대 중** (`IN_PROGRESS`): "취소 요청" 버튼 + InfoTooltip

#### 3. **채팅 기능**
- 승인된 계약에만 채팅 아이콘 표시 (`<MessageSquare />`)
- 호스트와 실시간 소통

#### 4. **탭 기반 필터 UI**
- 3개 탭: 진행중 / 지난 계약 / 취소
- **탭별 계약 건수** 표시 (예: "진행중 (3)")
- 선택된 탭: bg-blue-600 (흰색 텍스트)

#### 5. **안내 메시지 박스**
- bg-blue-50, border-blue-100
- AlertCircle 아이콘
- 4개 안내사항 표시

#### 6. **상태별 안내 텍스트**
- "호스트의 승인/거절을 기다리고 있습니다" (승인 대기)
- "호스트가 승인했습니다. 결제를 진행해주세요" (승인됨)
- "입주일에 맞춰 방문해주세요" (결제 완료)

#### 7. **모달 3개**
- **환불 계산 모달** (`RefundCalculationModal`) - 계약 취소 시
- **옵션 환불 확인 모달** - 옵션 수량 감소 시
- **취소 요청 모달** - 입주일 이후 취소 요청 시

#### 8. **UI 개선 사항**
- 방 사진 크기: 80x80 → **전체 너비 (모바일) or 140px (데스크톱)**
- 상세 버튼: 우상단 고정 (`<FileText />` 아이콘)
- 거절 사유 표시: bg-red-50 박스
- 계약 번호 표시 (승인 시 생성)
- 추가 결제 금액 표시 (파란색 텍스트 `+50,000원`)

---

## 📐 리액트 UI 구조 분석

### 페이지 레이아웃
```
┌─────────────────────────────────────┐
│ PageHeader (뒤로가기 + 제목)         │
├─────────────────────────────────────┤
│ h1 "계약 관리"                       │
├─────────────────────────────────────┤
│ 탭 메뉴 (bg-white, rounded-xl)       │
│ [진행중(3)] [지난계약(1)] [취소(2)]   │
├─────────────────────────────────────┤
│ 안내 메시지 박스 (bg-blue-50)         │
│ • 호스트 승인 후 채팅/결제 가능       │
│ • 입주일 5일 전까지 옵션 변경 가능     │
│ • 결제 선착순 확정                    │
│ • 입주일 이후 취소는 관리자 승인 필요  │
├─────────────────────────────────────┤
│ 계약 카드 1                          │
│ ┌───────────────────────────────┐   │
│ │ [배지] 안내텍스트     [상세▶]  │   │
│ │ ┌─────┐ 방 이름               │   │
│ │ │사진 │ 주소                  │   │
│ │ │140px│ 계약 기간 (35일)       │   │
│ │ └─────┘ 결제 금액 (+추가금액)  │   │
│ │         호스트 [채팅💬]        │   │
│ │ ┌─────────────────────────┐   │   │
│ │ │ 옵션 상품 [옵션변경🛒]    │   │   │
│ │ │ • 침구류 25,000원 x 1개   │   │   │
│ │ │ • 어메니티 5,000원 x 2개  │   │   │
│ │ └─────────────────────────┘   │   │
│ │ [결제하기💳] (상태별 버튼)     │   │
│ └───────────────────────────────┘   │
│ 계약 카드 2                          │
│ ...                                 │
└─────────────────────────────────────┘
```

### 계약 카드 구조 (상세)
```tsx
<div className="bg-white rounded-xl p-6 shadow-sm border">
  {/* 1. 상단: 상태 + 안내 + 상세버튼 */}
  <div className="flex items-start justify-between">
    <div className="flex flex-col lg:flex-row gap-2">
      {statusBadge}  {/* 승인 대기 / 결제 대기 등 */}
      {statusMessage} {/* "호스트의 승인을..." */}
    </div>
    <button>{/* 상세 버튼 */}</button>
  </div>

  {/* 2. 방 정보 */}
  <div className="flex flex-col sm:flex-row gap-4">
    <img /> {/* 방 사진 (큰 사이즈) */}
    <div>
      <div>{/* 방 이름 */}</div>
      <div>{/* 주소 */}</div>
      <div>{/* 계약 기간 (35일) */}</div>
      <div>{/* 결제 금액 (+추가금액) */}</div>
      <div>{/* 호스트 + 채팅 버튼 */}</div>
    </div>
  </div>

  {/* 3. 옵션 상품 섹션 (bg-gray-50) */}
  <div className="bg-gray-50 border rounded-lg p-4">
    <div>{/* "옵션 상품" + 변경 버튼 */}</div>
    {/* 편집 모드가 아닐 때 */}
    {currentOptions.map(item => (
      <div>{/* 상품명 + 가격 x 수량 */}</div>
    ))}
    {/* 편집 모드일 때 */}
    <div>
      <button>[-]</button>
      <span>{quantity}</span>
      <button>[+]</button>
      {/* 총 추가금액 / 환불금액 표시 */}
      <button>저장</button>
      <button>취소</button>
    </div>
  </div>

  {/* 4. 거절 사유 (상태가 REJECTED인 경우) */}
  {contract.status === 'REJECTED' && (
    <div className="bg-red-50">{/* 거절 사유 */}</div>
  )}

  {/* 5. 액션 버튼 (상태별) */}
  {/* 승인 대기 → 요청 취소 */}
  {/* 승인됨 → 결제하기 */}
  {/* 결제 완료 → 계약 취소 */}
  {/* 임대 중 → 취소 요청 */}
</div>
```

---

## 🎨 디자인 시스템 매핑

### 색상
| 리액트                | Flutter (AppColors)    | 용도                     |
|----------------------|------------------------|--------------------------|
| bg-blue-600          | primary600             | 탭 선택, 결제 버튼        |
| text-blue-600        | primary600             | 추가 금액 텍스트          |
| bg-blue-50           | primary100             | 안내 박스 배경            |
| bg-yellow-100        | warning100             | 승인 대기 배지            |
| text-yellow-700      | warning700             | 승인 대기 텍스트          |
| bg-green-100         | success100             | 결제 완료 배지            |
| text-green-700       | success700             | 결제 완료 텍스트          |
| bg-red-100           | error100               | 계약 거절 배지            |
| text-red-700         | error700               | 계약 거절 텍스트          |
| bg-gray-50           | surface                | 옵션 상품 배경            |
| border-gray-200      | border                 | 카드 테두리              |

### 간격
| 리액트               | Flutter (AppSpacing)   |
|---------------------|------------------------|
| p-6                 | paddingLg (24px)       |
| p-4                 | paddingMd (16px)       |
| gap-3               | md (12px)              |
| rounded-xl          | radiusLg (16px)        |
| rounded-lg          | radiusMd (12px)        |

---

## 🔄 API 매핑 (유지 + 추가 필요)

### ✅ 이미 구현된 API
```dart
// ContractService
Future<List<ContractListItem>> getGuestContracts({String? status})
```

### 🆕 추가 필요한 API
```dart
// 1. 계약 요청 취소 (승인 대기 상태)
Future<void> cancelContractRequest(int contractId)

// 2. 결제 페이지 이동 (승인됨 상태)
// → 네비게이션만 필요 (결제 API는 별도 페이지에서)

// 3. 옵션 상품 수량 변경
Future<void> updateContractOptions(
  int contractId,
  List<RentalItemUpdate> updates,
)

// 4. 계약 취소 (결제 완료 후, 입주일 이전)
Future<RefundCalculation> calculateRefund(int contractId)
Future<void> cancelContractWithRefund(int contractId)

// 5. 취소 요청 (입주일 이후)
Future<void> requestCancellation(int contractId, String reason)

// 6. 채팅 페이지 이동
// → 네비게이션만 필요
```

---

## 📝 재설계 작업 단계

### Phase 1: UI 구조 재설계 (기본 골격)
**목표**: 리액트 코드의 레이아웃과 스타일을 Flutter로 완전 복제

**작업 내용**:
1. ✅ **탭 UI 재설계**
   - 현재: ChoiceChip (수평 스크롤)
   - 변경: 3개 고정 탭 (flex-1, 파란색 선택 상태)
   - 탭별 계약 건수 표시

2. ✅ **안내 메시지 박스 추가**
   - bg-blue-50, border-blue-100
   - AlertCircle 아이콘
   - 4개 안내사항 (리스트)

3. ✅ **계약 카드 레이아웃 변경**
   - 방 사진 크기: 80x80 → 전체 너비 (모바일) or 140px (데스크톱)
   - 상세 버튼: 우상단 고정
   - 주소 표시 방식 변경 (결제 완료 전: 층수만, 결제 완료 후: 상세주소)

4. ✅ **상태별 안내 텍스트 추가**
   - 상태 배지 옆에 동적 메시지 표시

5. ✅ **거절 사유 박스 추가**
   - bg-red-50, XCircle 아이콘

**API**: 기존 API 유지 (변경 없음)

---

### Phase 2: 옵션 상품 기능 (핵심 기능)
**목표**: 옵션 추가/변경/환불 로직 구현

**작업 내용**:
1. ✅ **옵션 상품 섹션 추가**
   - bg-gray-50 카드
   - "옵션 상품" 헤더 + 변경 버튼

2. ✅ **옵션 목록 표시**
   - 수량 > 0인 항목만 표시 (편집 모드 아닐 때)
   - 편집 모드: 모든 항목 표시

3. ✅ **수량 증감 UI**
   - Minus/Plus 버튼
   - 0~4 범위 제한
   - 이전 수량과 비교 표시 (파란색/빨간색)

4. ✅ **추가 결제 / 환불 계산**
   - 수량 변경 시 금액 차이 계산
   - 파란색 배경 (추가 결제)
   - 빨간색 배경 (환불)

5. ✅ **입주일 5일 전 제한**
   - 날짜 기반 변경 가능 여부 체크
   - 불가능하면 alert 표시

6. ✅ **저장/취소 버튼**
   - 변경사항 없으면 저장 버튼 비활성화

**API**:
```dart
Future<void> updateContractOptions(int contractId, List<RentalItemUpdate> updates)
```

---

### Phase 3: 상태별 액션 버튼
**목표**: 각 상태별로 올바른 버튼 표시 및 동작

**작업 내용**:
1. ✅ **승인 대기** (`PENDING_APPROVAL`)
   - "요청 취소" 버튼 (회색 테두리)
   - 클릭 시: 확인 후 API 호출

2. ✅ **승인됨** (`APPROVED`)
   - "결제하기" 버튼 (파란색, CreditCard 아이콘)
   - 클릭 시: 결제 페이지로 이동

3. ✅ **결제 완료** (`PAYMENT_COMPLETED`)
   - "계약 취소" 버튼 + InfoTooltip
   - 클릭 시: 환불 계산 모달 표시

4. ✅ **임대 중** (`IN_PROGRESS`)
   - "취소 요청" 버튼 + InfoTooltip
   - 클릭 시: 취소 요청 모달 표시

5. ✅ **채팅 버튼**
   - 승인된 계약에만 표시 (`APPROVED` ~ `COMPLETED`)
   - MessageSquare 아이콘
   - 클릭 시: 채팅 페이지로 이동

**API**:
```dart
Future<void> cancelContractRequest(int contractId)
Future<void> requestCancellation(int contractId, String reason)
```

---

### Phase 4: 모달 추가
**목표**: 3개 모달 구현

**작업 내용**:
1. ✅ **환불 계산 모달** (`RefundCalculationModal`)
   - 환불 정책 (flexible/moderate/strict) 기반 계산
   - 배송비 처리
   - 최종 환불 금액 표시
   - 확인 버튼 → API 호출

2. ✅ **옵션 환불 확인 모달**
   - 환불 금액 표시
   - 안내 메시지 (3-5일 내 입금)
   - 확인 버튼 → 수량 변경 저장

3. ✅ **취소 요청 모달** (입주일 이후)
   - 취소 사유 입력 (textarea)
   - 안내 메시지 (관리자 승인 필요)
   - 제출 버튼 → API 호출

**API**:
```dart
Future<RefundCalculation> calculateRefund(int contractId)
Future<void> cancelContractWithRefund(int contractId)
```

---

### Phase 5: 세부 기능 및 예외 처리
**목표**: 엣지 케이스 및 사용자 경험 개선

**작업 내용**:
1. ✅ **빈 상태 처리**
   - 계약 0건: "계약 내역이 없습니다" + 방 보러가기 버튼

2. ✅ **에러 처리**
   - API 실패 시: 에러 메시지 + 다시 시도 버튼

3. ✅ **로딩 상태**
   - CircularProgressIndicator + 스켈레톤 UI (선택)

4. ✅ **상태 불일치 처리**
   - 클라이언트 캐시 vs 서버 실제 상태 불일치 방어

5. ✅ **반응형 처리**
   - 모바일: 세로 배열, 방 사진 전체 너비
   - 데스크톱: 가로 배열, 방 사진 140px

---

## ⚠️ PRD vs 리액트 코드 불일치

### PRD 요구사항
- "이 페이지는 **리스트 관리 전용**"
- "옵션 수량 변경, 환불 계산 등은 **반드시 계약 상세 페이지에서 처리**"

### 리액트 코드 실제 구현
- ✅ **옵션 수량 변경 기능 포함**
- ✅ **환불 계산 모달 포함**
- ✅ **추가 결제 / 환불 로직 포함**

### 결론
**CLAUDE.md 규칙에 따라 리액트 UI/UX가 절대 우선순위**이므로,
**PRD 무시하고 리액트 코드를 그대로 Flutter로 구현**해야 합니다.

---

## 🎯 최종 체크리스트

### UI/UX (리액트 코드 완전 복제)
- [ ] 탭 기반 필터 (진행중/지난계약/취소 + 건수 표시)
- [ ] 안내 메시지 박스 (bg-blue-50)
- [ ] 계약 카드 레이아웃 (큰 사진, 상세 버튼 우상단)
- [ ] 상태별 안내 텍스트
- [ ] 옵션 상품 섹션 (bg-gray-50)
- [ ] 수량 증감 UI (Plus/Minus)
- [ ] 추가 결제 / 환불 금액 표시
- [ ] 상태별 액션 버튼 (결제하기, 요청 취소, 계약 취소, 취소 요청)
- [ ] 채팅 버튼 (MessageSquare 아이콘)
- [ ] 거절 사유 박스 (bg-red-50)
- [ ] 계약 번호 표시

### 모달
- [ ] 환불 계산 모달 (RefundCalculationModal)
- [ ] 옵션 환불 확인 모달
- [ ] 취소 요청 모달

### API 통합
- [ ] getGuestContracts (유지)
- [ ] cancelContractRequest (추가)
- [ ] updateContractOptions (추가)
- [ ] calculateRefund (추가)
- [ ] cancelContractWithRefund (추가)
- [ ] requestCancellation (추가)

### 예외 처리
- [ ] 빈 상태 (계약 0건)
- [ ] 에러 상태 (API 실패)
- [ ] 로딩 상태
- [ ] 상태 불일치 방어
- [ ] 입주일 5일 전 제한

### 반응형
- [ ] 모바일: 세로 배열, 전체 너비 사진
- [ ] 데스크톱: 가로 배열, 140px 사진

---

## 💡 구현 우선순위

### 1순위 (필수, 즉시)
- **Phase 1**: UI 구조 재설계 (탭, 안내박스, 카드 레이아웃)
- **Phase 3**: 상태별 액션 버튼 (결제하기, 요청 취소)

### 2순위 (핵심, 빠른 시일)
- **Phase 2**: 옵션 상품 기능 (수량 증감, 추가 결제/환불 계산)
- **Phase 4**: 환불 계산 모달

### 3순위 (보조, 가능한 빨리)
- **Phase 4**: 옵션 환불 모달, 취소 요청 모달
- **Phase 5**: 세부 기능 및 예외 처리

---

## 📌 결론

**현재 Flutter 구현은 기본 리스트만 표시하는 MVP 수준**이며,
**리액트 코드의 핵심 기능(옵션 관리, 상태별 액션)이 전혀 구현되지 않았습니다.**

**재설계 범위**: 약 70-80% 코드 재작성 필요
**유지 가능**: API 호출 로직, 로딩/에러 처리, RefreshIndicator
**완전 재작성**: UI, 옵션 관리, 액션 버튼, 모달

**예상 작업량**: 3-4일 (1인 개발자 기준, 풀타임)
