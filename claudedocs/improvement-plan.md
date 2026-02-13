# EZStay 프론트엔드 정책 준수 개선 작업 계획

> 작성일: 2026-02-10
> 기준: policy-compliance-analysis.md
> 제외: Domain 9 (분쟁/이의제기), Domain 12 (관리자 기능)
> 수수료율: 하드코딩 유지 (게스트 9.9%, 호스트 3.3%)

---

## 전문가 패널 분석

### 참여 전문가

- **Porter** (경쟁전략): 서비스 신뢰도가 곧 경쟁 우위 — 계약 생명주기의 완성도가 플랫폼 신뢰를 결정
- **Christensen** (파괴적 혁신): 고객이 "고용"하는 진짜 Job = 안전한 거래 보장 — 시간 자동화/정보 보호가 핵심 JTBD
- **Meadows** (시스템 사고): 계약→결제→입주→퇴실→정산은 하나의 피드백 루프 — 끊어진 고리(퇴실 확인)가 전체 시스템 마비
- **Taleb** (안티프래질): 시간 기반 자동 만료가 없으면 "좀비 계약"이 누적 — 시스템 취약점
- **Doumont** (명확한 커뮤니케이션): 사용자가 현재 상태와 다음 액션을 즉시 이해할 수 있어야 함

### 패널 합의 사항

1. **계약 생명주기 완성이 최우선** — 41% 준수율은 서비스 신뢰도에 치명적
2. **시간 기반 자동화는 "보이는 것"이 핵심** — 백엔드 자동화가 있어도 사용자가 인지 못하면 무의미
3. **정보 접근 통제는 보안이 아닌 신뢰의 문제** — 호스트/게스트 각각 적절한 정보만 봐야 양측 모두 신뢰
4. **Phase 단위 순차 실행** — 의존 관계를 고려한 단계적 접근이 리스크 최소화

---

## Phase 구성 개요

| Phase | 테마 | 작업 수 | 예상 준수율 변화 |
|-------|------|---------|-----------------|
| Phase 1 | 계약 정보 보호 & 접근 통제 | 3개 | Contract 41% → 55% |
| Phase 2 | 시간 기반 UI & 계약 생명주기 | 4개 | Contract 55% → 75% |
| Phase 3 | 퇴실 확인 플로우 신규 개발 | 3개 | Contract 75% → 85% |
| Phase 4 | User 도메인 보강 | 3개 | User 75% → 90% |
| Phase 5 | Room 도메인 보강 | 3개 | Room 81% → 95% |
| Phase 6 | Communication 도메인 보강 | 3개 | Comm 65% → 85% |

---

## Phase 1: 계약 정보 보호 & 접근 통제

> **목표**: 정보 노출 정책 위반 즉시 수정 (가장 낮은 리스크, 높은 임팩트)
> **난이도**: ★★☆☆☆ | **의존성**: 없음

### Task 1-1: 게스트 계약 상세 — 상세주소 조건부 노출

**정책**: "상세주소는 결제 완료(PAID) 후에만 노출"

**대상 파일**: `lib/pages/contract/guest_contract_detail_page.dart`

**현재 문제**: 주소가 계약 상태와 무관하게 표시될 수 있음

**구현 내용**:
- 주소 표시 영역에 계약 상태 체크 로직 추가
- `REQUESTED`, `APPROVED` 상태: 시/구/동까지만 표시 + "결제 완료 후 상세주소가 공개됩니다" 안내
- `PAID`, `IN_PROGRESS`, `COMPLETED` 상태: 전체 상세주소 표시
- 주소 마스킹 헬퍼 함수 작성 (재사용 가능)

```dart
// 구현 방향
String _getMaskedAddress(ContractDetail contract) {
  final isPaid = ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED']
      .contains(contract.status);
  if (isPaid) return contract.fullAddress;
  return contract.districtAddress; // 시/구/동까지만
}
```

### Task 1-2: 호스트 계약 상세 — 게스트 정보 노출 제한

**정책**: "호스트는 자신의 수수료(3.3%)와 정산 금액만 확인 가능. 게스트 옵션/할인 정보 비노출"

**대상 파일**: `lib/pages/contract/host_contract_detail_page.dart`

**현재 문제**: 호스트에게 게스트의 옵션/할인 정보가 노출됨

**구현 내용**:
- 호스트 뷰에서 게스트 수수료(9.9%) 항목 제거
- 게스트 할인 금액 상세 제거
- 옵션 목록은 "옵션 N건" 정도로만 요약 표시
- 호스트에게 보여줄 정보:
  - 임대료, 관리비, 청소비 (원래 금액)
  - 호스트 수수료 3.3% (차감)
  - 최종 정산 예상 금액
  - 보증금 300,000원 (정보성)

### Task 1-3: 수수료 상수 정리

**정책**: 수수료율 하드코딩 유지 (사용자 요청)

**대상 파일**: 신규 `lib/constants/fee_constants.dart` + 기존 파일 참조 변경

**현재 문제**: 0.099, 0.033이 여러 파일에 분산 하드코딩

**구현 내용**:
```dart
// lib/constants/fee_constants.dart
class FeeConstants {
  static const double guestFeeRate = 0.099;  // 9.9%
  static const double hostFeeRate = 0.033;   // 3.3%
  static const int depositAmount = 300000;    // 보증금 30만원

  /// 게스트 수수료 계산 (원 단위 절삭)
  static int calculateGuestFee(int baseAmount) => (baseAmount * guestFeeRate).floor();

  /// 호스트 수수료 계산 (원 단위 절삭)
  static int calculateHostFee(int baseAmount) => (baseAmount * hostFeeRate).floor();
}
```
- `price_calculator.dart`의 0.099 → `FeeConstants.guestFeeRate`
- `host_contract_detail_page.dart`의 0.033 → `FeeConstants.hostFeeRate`
- 기타 산발적 하드코딩 일괄 치환

---

## Phase 2: 시간 기반 UI & 계약 생명주기

> **목표**: 결제 기한 타이머, 승인 기한 표시, 자동 상태 전환 UI 반영
> **난이도**: ★★★☆☆ | **의존성**: Phase 1 완료 권장

### Task 2-1: 결제 만료 타이머 (24시간) — 게스트 계약 상세

**정책**: "승인 후 24시간 미결제 시 자동 만료"

**대상 파일**: `lib/pages/contract/guest_contract_detail_page.dart`

**구현 내용**:
- `APPROVED` 상태일 때 결제 기한 카운트다운 타이머 위젯 표시
- 승인 시각(`approvedAt`) + 24시간 = 만료 시각 계산
- 남은 시간을 `HH:MM:SS` 형식으로 실시간 표시
- 2시간 이하 시 빨간색 경고 스타일
- 만료 시 "결제 기한이 만료되었습니다" 안내 + 재요청 유도

```dart
// 위젯 구조
Widget _buildPaymentTimer(ContractDetail contract) {
  if (contract.status != 'APPROVED') return SizedBox.shrink();
  final deadline = contract.approvedAt.add(Duration(hours: 24));
  final remaining = deadline.difference(DateTime.now());
  // ... 카운트다운 UI
}
```

### Task 2-2: 승인 기한 표시 (72시간) — 호스트 계약 상세

**정책**: "호스트 72시간 내 응답, 미응답 시 자동 만료"

**대상 파일**: `lib/pages/contract/host_contract_detail_page.dart`

**구현 내용**:
- `PENDING_APPROVAL` 상태일 때 승인 기한 표시
- 요청 시각(`requestedAt`) + 72시간 = 만료 시각
- 남은 시간 표시 + "기한 내 승인 또는 거절해주세요" 안내
- 12시간 이하 시 경고 스타일

### Task 2-3: 계약 상태 배너 컴포넌트 신규 개발

**목적**: 계약 상태별 안내 메시지를 일관된 UI로 제공

**대상 파일**: 신규 `lib/widgets/contract/contract_status_banner.dart`

**구현 내용**:
```dart
// 상태별 배너 메시지 매핑
class ContractStatusBanner extends StatelessWidget {
  // REQUESTED → "호스트의 승인을 기다리고 있습니다 (N시간 남음)"
  // APPROVED → "24시간 내 결제를 완료해주세요 (카운트다운)"
  // PAID → "결제가 완료되었습니다. 입주일: YYYY-MM-DD"
  // IN_PROGRESS → "현재 임대 중입니다. 퇴실일: YYYY-MM-DD"
  // COMPLETED → "계약이 정상 종료되었습니다"
  // 만료 상태들 → "기한 만료로 취소되었습니다"
}
```

### Task 2-4: 자동 상태 전환 UI 반영

**정책**: "입주일 도래 시 자동 IN_PROGRESS 전환"

**대상 파일**: `lib/pages/contract/guest_contract_detail_page.dart`, `host_contract_detail_page.dart`

**구현 내용**:
- PAID 상태에서 현재 날짜 ≥ 입주일이면 "임대 시작" 상태로 UI 표시
- 실제 상태 전환은 백엔드에서 수행하므로, 프론트엔드는:
  - 페이지 진입 시 계약 상세 API 재조회 (최신 상태 반영)
  - PAID 상태인데 입주일이 지났으면 "상태 업데이트 중..." 표시 후 API 재호출
  - Pull-to-refresh 지원

---

## Phase 3: 퇴실 확인 플로우 신규 개발

> **목표**: 퇴실 확인 프로세스 전체 구현 (게스트 확인 → 호스트 확인 → 48h 자동 확정)
> **난이도**: ★★★★☆ | **의존성**: Phase 2 완료 필수

### Task 3-1: 퇴실 확인 위젯 개발

**대상 파일**: 신규 `lib/widgets/contract/checkout_confirmation_widget.dart`

**구현 내용**:
- 퇴실일 이후 + IN_PROGRESS 상태일 때 표시
- 게스트 뷰: "퇴실 확인" 버튼 (체크아웃 시간 이후 활성화)
- 호스트 뷰: 게스트 확인 후 "퇴실 확인" 버튼 활성화
- 48시간 자동 확정 타이머 표시
- 확인 완료 시 체크 마크 + 확인 시각 표시

```
퇴실 확인 상태:
┌─────────────────────────────────┐
│  ✅ 게스트 퇴실 확인  2/15 11:00 │
│  ⏳ 호스트 퇴실 확인  대기 중     │
│  ⏱️ 자동 확정까지 36시간 남음    │
└─────────────────────────────────┘
```

### Task 3-2: ContractService에 퇴실 확인 API 연동

**대상 파일**: `lib/services/contract_service.dart`

**구현 내용**:
```dart
/// 게스트 퇴실 확인
Future<void> confirmGuestCheckout(int contractId);

/// 호스트 퇴실 확인
Future<void> confirmHostCheckout(int contractId);

/// 퇴실 확인 상태 조회
Future<CheckoutStatus> getCheckoutStatus(int contractId);
```

### Task 3-3: 계약 상세 페이지에 퇴실 확인 플로우 통합

**대상 파일**: `guest_contract_detail_page.dart`, `host_contract_detail_page.dart`

**구현 내용**:
- IN_PROGRESS 상태 + 퇴실일 도래 시 `CheckoutConfirmationWidget` 표시
- 퇴실 확인 완료 후 계약 상태 자동 갱신
- 보증금 반환 예정 안내 표시

---

## Phase 4: User 도메인 보강

> **목표**: 필수 정보 검증 게이트, 계정 상태 관리
> **난이도**: ★★★☆☆ | **의존성**: 없음 (Phase 1~3과 병렬 가능)

### Task 4-1: 필수 정보 검증 게이트 모달

**정책**: "계약 요청 시 이름/전화번호 미입력이면 모달로 유도"

**대상 파일**:
- 신규: `lib/widgets/modals/required_info_gate_modal.dart`
- 수정: `lib/pages/contract/contract_start_page.dart`

**구현 내용**:
- `RequiredInfoGateModal` — 이름/전화번호 입력 폼 모달
- `contract_start_page.dart` 진입 시 사용자 프로필 검증
  - 이름 또는 전화번호 미입력 → 모달 표시 → 입력 완료 후 진행
  - 이미 입력됨 → 정상 진행
- 모달은 재사용 가능하도록 범용 설계 (향후 다른 핵심 액션에도 적용)

```dart
// 사용 예시
Future<bool> _checkRequiredInfo() async {
  final user = context.read<AuthService>().currentUser;
  if (user?.name == null || user?.phone == null) {
    final result = await RequiredInfoGateModal.show(context);
    return result == true; // 입력 완료 여부
  }
  return true;
}
```

### Task 4-2: 계정 상태 분기 처리

**정책**: "정지 상태 사용자는 주요 기능 차단"

**대상 파일**: `lib/services/auth_service.dart`, `lib/router/app_router.dart`

**구현 내용**:
- User 모델에 `accountStatus` 필드 확인 (정상/정지/탈퇴)
- `auth_service.dart`: 로그인 시 계정 상태 체크
  - 정지 → 정지 안내 페이지로 이동 (사유 표시)
  - 탈퇴 → 로그인 거부 + 안내 메시지
- 라우터 가드: 정지 상태에서 계약 요청, 방 등록 등 핵심 기능 차단

### Task 4-3: 정지 안내 페이지

**대상 파일**: 신규 `lib/pages/auth/account_suspended_page.dart`

**구현 내용**:
- 정지 사유 표시
- 고객센터 문의 안내 링크
- 로그아웃 버튼

---

## Phase 5: Room 도메인 보강

> **목표**: 승인 후 수정 범위 제한, EZ서비스 비밀번호 UX 개선
> **난이도**: ★★☆☆☆ | **의존성**: 없음

### Task 5-1: 승인 후 수정 범위 제한

**정책**: "승인 후에는 가격/편의시설/설명만 수정 가능. 주소/구조 변경 시 재심사"

**대상 파일**:
- `lib/models/room.dart` — `canEdit` → `canEditField(String field)` 세분화
- `lib/pages/host/room_registration/room_registration_flow_page.dart` — 수정 모드 분기
- 각 step 파일 — 필드별 readOnly 처리

**구현 내용**:
```dart
// room.dart에 추가
bool canEditField(String fieldGroup) {
  if (status == 'draft' || status == 'rejected') return true; // 전체 수정
  if (status == 'approved') {
    // 승인 후 수정 가능 필드
    return ['pricing', 'amenities', 'description', 'photos', 'maxGuests']
        .contains(fieldGroup);
  }
  return false; // pending_review 등
}
```

- Step 1 (기본정보): approved 상태면 주소, 건물유형, 면적, 방수, 층수 필드 readOnly + "승인 후 변경 불가" 안내
- Step 2 (사진): 수정 가능
- Step 3 (요금): 수정 가능 + "진행 중 계약이 있으면 다음 계약부터 적용" 안내
- Step 4 (서비스): 수정 가능
- Step 5 (소개): 수정 가능

### Task 5-2: EZ서비스 비밀번호 UX 개선

**정책**: "EZ서비스 활성화 시 현관 비밀번호는 필수 입력, 항상 표시"

**대상 파일**: `lib/pages/host/room_registration/steps/services_step.dart`

**구현 내용**:
- EZ서비스 토글 ON 시 비밀번호 입력 필드 항상 표시 (토글로 숨기지 않음)
- 필수 입력 표시 (*)
- 미입력 시 다음 단계 진행 차단 (validator에서도 검증)

### Task 5-3: 방 수정 시 재심사 안내

**대상 파일**: `lib/pages/host/room_management_page.dart`

**구현 내용**:
- approved 상태 방의 "수정" 버튼 탭 시 안내 다이얼로그:
  "승인된 방의 기본 정보(주소, 건물유형, 면적 등)는 변경할 수 없습니다. 가격, 편의시설, 소개 등만 수정 가능합니다."
- 수정 페이지 진입 후에도 readOnly 필드에 자물쇠 아이콘 + 툴팁 표시

---

## Phase 6: Communication 도메인 보강

> **목표**: 채팅 접근 권한 검증, 알림 타입 확장
> **난이도**: ★★☆☆☆ | **의존성**: Phase 3 완료 권장 (정산/보증금 알림)

### Task 6-1: 채팅 접근 권한 검증 & 읽기 전용

**정책**: "유효한 계약 당사자만 채팅 가능, 취소/종료된 계약은 읽기 전용"

**대상 파일**: `lib/services/chat_service.dart`, `lib/pages/chat/chat_detail_page.dart`

**구현 내용**:
- `chat_detail_page.dart`: 계약 상태 체크 후 입력 영역 제어
  - CANCELLED, COMPLETED, REJECTED → 메시지 입력 비활성화 + "종료된 계약입니다" 안내
  - 나머지 상태 → 정상 입력 가능
- `chat_service.dart`: `sendMessage()` 호출 전 계약 상태 재검증

```dart
// chat_detail_page.dart
bool get _isChatReadOnly {
  final status = chatRoom.contractStatus;
  return ['CANCELLED', 'COMPLETED', 'REJECTED', 'CANCELLED_BY_GUEST',
          'CANCELLED_BY_HOST', 'REFUNDED'].contains(status);
}
```

### Task 6-2: 알림 타입 확장

**정책**: "정산 완료, 보증금 반환, 퇴실 안내 알림 필요"

**대상 파일**: `lib/models/notification_item.dart`, `lib/pages/notification/notification_page.dart`

**구현 내용**:
- NotificationType enum에 추가:
  - `settlementCompleted` — 정산 완료
  - `depositReturned` — 보증금 반환
  - `checkoutReminder` — 퇴실 안내 (D-1)
  - `checkinReminder` — 입주 안내 (D-1)
  - `checkoutConfirmation` — 퇴실 확인 요청
- 각 알림 타입별 아이콘, 메시지 템플릿, 딥링크 대상 페이지 매핑
- notification_page.dart에서 신규 타입 렌더링 지원

### Task 6-3: 자동 메시지 트리거 확장

**정책**: 현재 contractConfirmed, checkin, checkout만 존재

**대상 파일**: `lib/models/auto_message_template.dart`, `lib/services/auto_message_service.dart`

**구현 내용**:
- TriggerType에 추가:
  - `paymentCompleted` — 결제 완료 시
  - `checkoutConfirmed` — 퇴실 확인 시
- 자동 메시지 관리 UI에서 신규 트리거 타입 선택 가능하도록 수정

---

## 작업 순서 요약

```
Phase 1 (정보 보호)     ─── 독립 실행 가능
  ├── 1-1: 상세주소 마스킹
  ├── 1-2: 호스트 정보 제한
  └── 1-3: 수수료 상수 정리

Phase 2 (시간 기반 UI)   ─── Phase 1 이후 권장
  ├── 2-1: 결제 만료 타이머
  ├── 2-2: 승인 기한 표시
  ├── 2-3: 상태 배너 컴포넌트
  └── 2-4: 자동 상태 전환 UI

Phase 3 (퇴실 확인)     ─── Phase 2 이후 필수
  ├── 3-1: 퇴실 확인 위젯
  ├── 3-2: API 연동
  └── 3-3: 페이지 통합

Phase 4 (User 보강)     ─── 독립 실행 가능
  ├── 4-1: 필수 정보 게이트 모달
  ├── 4-2: 계정 상태 분기
  └── 4-3: 정지 안내 페이지

Phase 5 (Room 보강)     ─── 독립 실행 가능
  ├── 5-1: 수정 범위 제한
  ├── 5-2: EZ서비스 비밀번호 UX
  └── 5-3: 재심사 안내

Phase 6 (Communication)  ─── Phase 3 이후 권장
  ├── 6-1: 채팅 읽기 전용
  ├── 6-2: 알림 타입 확장
  └── 6-3: 자동 메시지 트리거
```

### 병렬 실행 가능 조합
- **Phase 1 + Phase 4 + Phase 5**: 완전히 독립적, 동시 진행 가능
- **Phase 2 → Phase 3**: 순차 (Phase 3이 Phase 2의 상태 배너에 의존)
- **Phase 6**: Phase 3의 퇴실 확인 완료 후 알림 타입 연동

---

## 예상 결과

| 도메인 | 현재 | Phase 완료 후 | 목표 |
|--------|------|--------------|------|
| User | 75% | 90% (Phase 4) | 90% |
| Room | 81% | 95% (Phase 5) | 95% |
| Contract | 41% | 85% (Phase 1+2+3) | 85% |
| Pricing/Payment | 96% | 97% (Phase 1-3) | 97% |
| Communication | 65% | 85% (Phase 6) | 85% |
| **전체** | **72%** | **~90%** | **90%** |

> 참고: Domain 9 (분쟁), Domain 12 (관리자)는 제외 범위이므로 100%는 달성 불가.
> 제외 범위를 포함하면 최종 목표는 ~85%.
