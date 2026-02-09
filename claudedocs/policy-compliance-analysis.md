# EZStay 프론트엔드 정책 준수 분석 보고서

> 분석일: 2026-02-10
> 대상: EZStay Flutter 프론트엔드 (develop 브랜치)
> 분석 범위: 서비스 정책 Domain 0~14 중 프론트엔드 관련 도메인

---

## 1. 전체 요약

| 도메인 | 준수율 | 상태 | 비고 |
|--------|--------|------|------|
| Domain 1: User (회원/계정/권한) | ~75% | ⚠️ 보완 필요 | 필수정보 게이트 미구현 |
| Domain 2: Room (방 등록/수정/노출) | 81% | ⚠️ 보완 필요 | 승인 후 수정 범위 초과 |
| Domain 3: Contract (계약) | 41% | 🚨 심각 | 시간 자동화 전무 |
| Domain 4-8: Pricing/Payment/Settlement | 96% | ✅ 우수 | 금전 모델 정확 |
| Domain 10: Communication (채팅/알림) | 65% | ⚠️ 보완 필요 | 접근 권한 검증 부족 |
| **전체 평균** | **~72%** | **⚠️ 보완 필요** | |

---

## 2. 도메인별 상세 분석

### 2.1 Domain 1: User (회원/계정/권한) — 75%

#### ✅ 구현 완료
- **역할 전환**: `AuthService.switchUserMode(UserMode.host)` 로 게스트↔호스트 전환 구현
  - 파일: `lib/services/auth_service.dart`
- **회원가입 플로우**: 이메일→비밀번호→이메일인증→전화번호인증→호스트계정설정 다단계 구현
  - 파일: `lib/pages/auth/register_flow_page.dart`
  - 파일: `lib/pages/auth/steps/` (4개 스텝 파일)
- **게스트→호스트 전환**: 별도 호스트 계정 설정 페이지 존재
  - 파일: `lib/pages/host/host_account_setup_standalone_page.dart`
- **프로필 관리**: 게스트/호스트 마이페이지 구현
  - 파일: `lib/pages/guest/guest_my_page.dart`
  - 파일: `lib/pages/host/host_my_page.dart`

#### ❌ 미구현
- **필수 정보 검증 게이트**: 계약 요청 등 핵심 액션 시 이름/전화번호 미입력 시 모달로 입력 유도하는 기능 없음
  - 정책: "핵심 액션 시 필수 정보 미입력이면 모달로 유도"
  - 영향: `contract_start_page.dart` 진입 시 검증 누락
- **계정 상태 관리 UI**: 정상/정지/탈퇴 상태에 따른 UI 분기 미구현
  - 정책: "정지 상태 사용자는 로그인 차단 또는 제한 안내"

---

### 2.2 Domain 2: Room (방 등록/수정/노출) — 81%

#### ✅ 구현 완료 (95%)
- **5단계 등록 프로세스**: 기본정보→사진→요금→서비스→소개 충실히 구현
  - 파일: `lib/pages/host/room_registration/room_registration_flow_page.dart`
  - `_saveCurrentStepToApi()`, `_calculateCurrentStep()` 로 단계별 저장
- **단계별 유효성 검증**: 5개 스텝 모두 별도 validator 구현
  - 파일: `lib/pages/host/room_registration/validators/registration_validator.dart`
  - `validateStep1()` ~ `validateStep5()`, `validateAll()`, `isValidUpToStep()`
- **임시저장**: 초안(draft) 상태로 저장 후 이어서 등록 가능
- **사진 관리**: 최대 20장, 드래그 정렬, 업로드/삭제 구현
  - 파일: `lib/pages/host/room_registration/components/draggable_image_grid.dart`
- **방 상태 필터**: draft, pending_review, approved_active, approved_inactive, rejected 필터
  - 파일: `lib/pages/host/room_management_page.dart`

#### ⚠️ 문제점
- **EZ서비스 비밀번호 UX**: 토글 표시 방식 → 항상 표시되어야 함
  - 파일: `lib/pages/host/room_registration/steps/services_step.dart`
  - 정책: "EZ서비스 활성화 시 현관 비밀번호는 필수 입력"
- **승인 후 수정 범위 초과**: `canEdit` getter가 approved 상태에서 전체 편집 허용
  - 파일: `lib/models/room.dart`
  - 코드: `status == 'draft' || status == 'rejected' || status == 'approved'`
  - 정책: "승인 후에는 가격, 편의시설, 설명만 수정 가능. 주소/구조 변경 시 재심사"
- **스냅샷 메커니즘 미확인**: 결제 완료 시점의 방 정보 고정 여부 프론트엔드에서 불명확

---

### 2.3 Domain 3: Contract (계약) — 41% 🚨

#### ✅ 구현 완료
- **계약 상태 정의**: 7+ 상태 (REQUESTED, APPROVED, REJECTED, PAID, IN_PROGRESS, COMPLETED, CANCELLED + APPROVAL_EXPIRED, PAYMENT_EXPIRED, REFUNDED)
  - 파일: `lib/models/contract.dart`
- **계약 생성 플로우**: 방 선택→가격 확인→옵션 선택→계약 요청
  - 파일: `lib/pages/contract/contract_start_page.dart`
- **계약 목록**: 호스트/게스트 각각 탭 필터링 (진행중/과거/취소)
  - 파일: `lib/pages/contract/host_contracts_page_new.dart`
  - 파일: `lib/pages/contract/guest_contracts_page.dart`
- **승인/거절**: 호스트의 계약 승인/거절 액션 구현
  - 파일: `lib/services/contract_service.dart`
- **수수료 계산**: 호스트 3.3% 수수료 표시
  - 파일: `lib/pages/contract/host_contract_detail_page.dart`

#### ❌ 미구현 (Critical)
- **결제 만료 타이머 (24시간)**: 승인 후 24시간 이내 결제 필요 → 카운트다운 UI 없음
  - 정책: "승인 후 24시간 미결제 시 자동 만료"
  - 영향: 게스트가 결제 기한을 인지할 수 없음
- **자동 임대중(IN_PROGRESS) 전환**: 입주일 도래 시 자동 상태 전환 트리거 없음
  - 정책: "입주일에 자동으로 임대중 상태 전환"
- **퇴실 확인 플로우**: 퇴실일 이후 게스트 확인 → 호스트 확인 → 48시간 자동 확정 전체 미구현
  - 정책: "퇴실 후 양측 확인, 48시간 미확인 시 자동 COMPLETED"
  - 영향: COMPLETED 상태로 전환할 수 있는 UI가 없음
- **상세주소 조건부 노출**: 결제 완료 전에는 상세주소 마스킹 필요
  - 파일: `lib/pages/contract/guest_contract_detail_page.dart`
  - 정책: "상세주소는 결제 완료 후에만 노출"
- **호스트 정보 과다 노출**: 게스트의 옵션/할인 정보가 호스트에게 노출
  - 파일: `lib/pages/contract/host_contract_detail_page.dart`
  - 정책: "호스트는 자신의 수수료(3.3%)와 정산 금액만 확인 가능"
- **관리자 취소 요청 (1회)**: 임대 중 취소는 관리자 요청 1회만 가능 → UI 없음

---

### 2.4 Domain 4-8: Pricing/Payment/Deposit/Settlement — 96% ✅

#### ✅ 구현 완료
- **계약 금액 구성**: 임대료 + 관리비 + 청소비 + 옵션 + 보증금 정확히 구현
  - 파일: `lib/models/calculated_pricing.dart`
  - `finalTotalAmount` 계산 로직 정확
- **보증금 300,000원 고정**: 정책대로 고정값 구현
- **수수료 적용**: 호스트 3.3%, 게스트 9.9% 정확히 구현
  - 파일: `lib/pages/contract/host_contract_detail_page.dart` (`_getHostCommissionFee()`)
- **정산 모델**: 임대료 + 관리비 + 청소비 - 플랫폼수수료(3.3%)
  - 파일: `lib/models/settlement.dart`
  - `SettlementBreakdown`: rentalFee, maintenanceFee, cleaningFee, platformFee
- **옵션 D-5 정책**: 결제 전 수정 가능, D-5 이전 추가/취소, D-5 이후 취소만, 임대중 요청만
  - 파일: `lib/services/rental_order_service.dart`
- **TossPayments 결제**: PG 결제 콜백 구현
  - 파일: `lib/pages/payment/payment_callback_page.dart`
  - 파일: `lib/pages/payment/rental_payment_callback_page.dart`
- **정산 UI**: 대기/완료 탭, 상세 내역 표시
  - 파일: `lib/pages/host/host_settlement_page.dart`
  - 파일: `lib/pages/host/host_settlement_detail_page.dart`

#### ⚠️ Minor
- **수수료율 하드코딩**: 3.3%, 9.9%가 코드에 직접 기입 → 서버에서 관리하는 것이 이상적
- **6일 정책 재계산**: D-5 기준 프론트엔드 계산 → 백엔드 위임이 더 안전

---

### 2.5 Domain 10: Communication (채팅/알림) — 65%

#### ✅ 구현 완료
- **계약 기반 채팅**: 채팅방 생성 시 contractId 필수
  - 파일: `lib/services/chat_service.dart` - `createChatRoom(contractId)`
  - 파일: `lib/models/chat_message.dart` - `ChatRoomMetadata`에 contractId/hostId/guestId
- **메시지 타입**: text/image/system 메시지 지원
- **알림 타입**: 계약 상태 변경 알림 정의
  - 파일: `lib/models/notification_item.dart`
- **알림 딥링크**: 알림 클릭 시 관련 페이지로 이동
  - 파일: `lib/pages/notification/notification_page.dart`
- **자동 메시지 관리**: 트리거 타입별 자동 메시지 CRUD
  - 파일: `lib/services/auto_message_service.dart`
  - 파일: `lib/models/auto_message_template.dart` - contractConfirmed, checkin, checkout

#### ❌ 미구현
- **채팅 접근 권한 검증**: 메시지 전송 시 계약 상태 검증 없음
  - 정책: "유효한 계약이 있는 당사자만 채팅 가능"
  - 영향: 취소/종료된 계약의 채팅방에서도 메시지 전송 가능할 수 있음
- **알림 타입 누락**: 정산/보증금/분쟁 관련 알림 타입 미정의
  - 정산 완료 알림
  - 보증금 반환 알림
  - 분쟁 관련 알림

---

### 2.6 미구현 도메인

| 도메인 | 프론트엔드 구현 상태 | 비고 |
|--------|---------------------|------|
| Domain 9: Dispute/Claim | 미구현 | 분쟁/이의제기 UI 전무 |
| Domain 11: Time & Schedule | 부분 구현 | 일정 관리 있으나 자동 전환 없음 |
| Domain 12: Admin & Exception | 미구현 | 관리자 개입 요청 UI 없음 |
| Domain 13: Data & Snapshot | 미확인 | 스냅샷 사용 여부 프론트엔드에서 불명확 |
| Domain 14: Tax & Compliance | 해당 없음 | 백엔드 영역 |

---

## 3. 우선순위별 개선 로드맵

### P0: 즉시 조치 (Critical)

| # | 항목 | 관련 파일 | 정책 위반 내용 |
|---|------|-----------|---------------|
| 1 | 결제 만료 타이머 (24h) | `guest_contract_detail_page.dart` | 승인 후 24시간 미결제 시 자동 만료 → 타이머 UI 없음 |
| 2 | 퇴실 확인 플로우 | 신규 개발 필요 | 게스트 확인→호스트 확인→48h 자동확정 전체 미구현 |
| 3 | 상세주소 조건부 노출 | `guest_contract_detail_page.dart` | 결제 전 상세주소 마스킹 필요 |
| 4 | 호스트 정보 노출 제한 | `host_contract_detail_page.dart` | 게스트 옵션/할인 정보 노출 차단 |

### P1: 단기 개선 (Important)

| # | 항목 | 관련 파일 | 정책 위반 내용 |
|---|------|-----------|---------------|
| 5 | 필수 정보 검증 게이트 | `contract_start_page.dart` | 계약 요청 시 이름/전화번호 미입력 검증 |
| 6 | 계정 상태 관리 UI | `auth_service.dart` | 정지/탈퇴 상태 분기 처리 |
| 7 | 승인 후 수정 범위 제한 | `room.dart` | approved 상태에서 전체 편집 → 일부만 허용 |
| 8 | EZ서비스 비밀번호 UX | `services_step.dart` | 토글 → 항상 표시로 변경 |
| 9 | 자동 임대중 전환 | `contract_detail_page.dart` | 입주일 도래 시 상태 전환 표시 |

### P2: 중기 개선

| # | 항목 | 관련 파일 | 정책 위반 내용 |
|---|------|-----------|---------------|
| 10 | 채팅 접근 권한 검증 | `chat_service.dart` | 계약 상태별 메시지 전송 제한 |
| 11 | 알림 타입 확장 | `notification_item.dart` | 정산/보증금/분쟁 알림 추가 |
| 12 | 스냅샷 메커니즘 확인 | 계약 상세 페이지들 | 결제 시점 데이터 고정 확인 |
| 13 | 관리자 취소 요청 (1회) | 신규 개발 필요 | 임대중 관리자 취소 요청 UI |

### P3: 장기 개선

| # | 항목 | 설명 |
|---|------|------|
| 14 | Domain 9: Dispute/Claim | 분쟁/이의제기 UI 신규 개발 |
| 15 | Domain 12: Admin & Exception | 관리자 개입 요청/처리 UI 신규 개발 |
| 16 | 수수료율 서버 관리 | 3.3%, 9.9% 하드코딩 → 서버 설정값 참조 |

---

## 4. 분석 방법론

- 5개 병렬 분석 에이전트를 사용하여 도메인별 코드 레벨 분석 수행
- 각 에이전트가 관련 pages, services, models 파일을 직접 읽고 정책 대조
- 정책 문서 15개 도메인 중 프론트엔드 관련 10개 도메인 집중 분석
- 준수율은 해당 도메인 정책 항목 중 프론트엔드에서 구현된 비율 기준

---

## 5. 참고 파일 목록

### 핵심 분석 대상 파일
```
lib/services/auth_service.dart
lib/services/contract_service.dart
lib/services/chat_service.dart
lib/services/rental_order_service.dart
lib/services/payment_service.dart
lib/models/contract.dart
lib/models/contract_detail.dart
lib/models/calculated_pricing.dart
lib/models/settlement.dart
lib/models/room.dart
lib/models/chat_message.dart
lib/models/notification_item.dart
lib/pages/contract/contract_start_page.dart
lib/pages/contract/guest_contract_detail_page.dart
lib/pages/contract/host_contract_detail_page.dart
lib/pages/contract/host_contracts_page_new.dart
lib/pages/host/room_registration/room_registration_flow_page.dart
lib/pages/host/room_registration/validators/registration_validator.dart
lib/pages/host/host_settlement_page.dart
lib/pages/notification/notification_page.dart
```
