# EZStay Frontend 리팩토링 계획 & 로드맵

---

## 전체 로드맵

```
Phase 1+2 (반복)  ──▶  Phase 3  ──▶  Phase 4  ──▶  Phase 5
파일 크기 축소          공통 패턴       서비스 레이어    테스트
위젯 추출               정규화          비즈니스 로직    구조 안정화
```

### Phase 1+2 — 파일 분해 (긴급, 현재 진행 중)
**목표**: 500줄 초과 파일을 위젯 추출 + 유틸 분리로 해소
**진입 기준**: 없음 (지금 바로)
**완료 기준**: 주요 파일이 500줄 이하로 내려올 때

### Phase 3 — 공통 패턴 정규화
**목표**: 위젯/유틸 파일이 쌓이면서 보이는 중복 패턴 통합
**진입 신호** (이미 보이기 시작):
- `ContractStatusHelper` — 상태 뱃지/색상/메시지 통합
- `EmptyStateBox` — 공통 빈 상태 UI
- `FeeCalculator` — 정산 계산 유틸
- `ContractUtils.isCheckoutTimeReached` — 날짜 판단 유틸
**완료 기준**: `widgets/contract/`, `widgets/common/`, `utils/` 내 중복 로직 0

### Phase 4 — 서비스 레이어 강화
**목표**: 페이지 State에 남아 있는 비즈니스 로직을 서비스로 추출
**진입 기준**: Phase 1+2로 파일 크기 문제 어느 정도 해소 후
**완료 기준**: State 클래스 = 상태 관리 + 콜백 위임만 잔존

### Phase 5 — 테스트
**목표**: 안정된 구조에 단위/위젯 테스트 추가
**진입 기준**: Phase 4 완료 후 구조가 안정됐을 때

---

## 완료 이력

---

### ✅ guest_contracts_page.dart (3,726줄 → 887줄, -76%)

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| Phase 1 | 위젯 8개 추출 | 3,726 → 2,244줄 |
| Phase 2 | shared/widgets → widgets/common 통합 | 경로 정리 |
| Phase 3 | 서비스 추출 (옵션/퇴실/다이얼로그/카드/헬퍼) | 2,244 → 1,154줄 |
| Phase 4 | 결제 로직 → `guest_payment_service.dart` | ~120줄 추출 |
| Phase 5 | `_cancel_option_modal_state.dart` 분해 (998줄 → 삭제) | 6개 파일로 분리 |
| Phase 6 | 데이터 로딩/필터 통합 + part 제거 + 데드코드 정리 | 1,154 → 887줄 |

**추출 파일 목록**:
`add_option_modal.dart`, `contract_tab_menu.dart`, `contract_info_box.dart`,
`contract_options_section.dart`, `contract_room_info_section.dart`,
`checkout_status_section.dart`, `refund_row.dart`, `empty_state_box.dart`,
`guest_contract_option_service.dart`, `guest_checkout_service.dart`,
`guest_contract_dialogs.dart`, `guest_contract_card.dart`,
`contract_status_helper.dart`, `guest_payment_service.dart`,
`delivery_status_helper.dart`, `order_item_rows.dart`,
`cancel_tab_content.dart`, `return_tab_content.dart`, `cancel_option_modal.dart`,
`rental_item_enrichment_service.dart`

---

### ✅ host_contracts_page_new.dart (2,454줄 → 909줄, -63%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| Phase 1 | 위젯 4개 추출 (카드/퇴실섹션/다이얼로그/안내) | 2,454 → 1,115줄 |
| Phase 2 | 공용 위젯 재사용 (`ContractTabMenu`, `ContractStatusHelper`, `EmptyStateBox`) | 1,115 → 913줄 |
| Phase 3 | 코드 품질 정리 (데드코드, 하드코딩 색상 → AppColors) | 913 → 909줄 |

**추출 파일 목록**:
`host_contract_card.dart` (803줄), `host_checkout_section.dart` (337줄),
`host_contract_dialogs.dart` (228줄), `host_info_message.dart` (59줄)

---

### ✅ host_contract_card.dart 내부 리팩토링 (803줄 → 580줄대, -28%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 내용 |
|------|-----------|------|
| 분석 | 메서드/섹션 목록 파악 | 13개 메서드, 분리 후보 식별 |
| 위젯 추출 1 | `_buildPricingSection` (182줄) → `ContractPricingSection` | 신규 파일 생성 |
| 위젯 추출 2 | IN_PROGRESS 버튼 블록 (90줄) → `_HostInProgressActions` + `_CancellationButton` | 같은 파일 내 클래스 분리 |
| 유틸 통합 1 | `_getStatusConfig` → `ContractStatusHelper.getStatusBadgeConfig()` | record 타입, 타입 안전 |
| 유틸 통합 2 | `_calculateSettlement` → `FeeCalculator.calculateHostSettlement()` | 신규 `utils/fee_calculator.dart` |
| 유틸 통합 3 | `_isCheckoutTimeReached` → `ContractUtils.isCheckoutTimeReached()` | `utils/contract_utils.dart` 에 추가 |

**신규 생성 파일**:
- `widgets/contract/contract_pricing_section.dart` — 금액 섹션 위젯
- `utils/fee_calculator.dart` — 호스트 정산 계산

**기존 파일 강화**:
- `widgets/contract/contract_status_helper.dart` — `getStatusBadgeConfig()` 추가
- `utils/contract_utils.dart` — `isCheckoutTimeReached()` 추가

---

### ✅ host_contract_detail_page.dart (2,017줄 → 540줄, -73%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| 1 | 다이얼로그 3개 추출 + `_CheckoutPendingDialog` 중복 제거 | `host_contract_detail_dialogs.dart` (169줄) |
| 2 | 금액 섹션 + 계산 메서드 추출 | `host_contract_amount_section.dart` (315줄) |
| 3 | 보증금 합의 섹션 추출 | `host_deposit_agreement_section.dart` (273줄) |
| 4 | 기본 정보 + 방 정보 섹션 추출 | `host_contract_basic_info_section.dart` (227줄) |
| 5 | 액션 버튼 섹션 추출 + `ContractUtils.isCheckoutTimeReachedFromDetail()` 추가 | `host_contract_action_buttons.dart` (141줄) |
| 6 | 당사자 정보 섹션 추출 | `host_contract_party_info_section.dart` (269줄) |

**추출 파일 목록**:
`host_contract_detail_dialogs.dart` (169줄), `host_contract_amount_section.dart` (315줄),
`host_deposit_agreement_section.dart` (273줄), `host_contract_basic_info_section.dart` (227줄),
`host_contract_action_buttons.dart` (141줄), `host_contract_party_info_section.dart` (269줄)

**기존 파일 강화**:
- `utils/contract_utils.dart` — `isCheckoutTimeReachedFromDetail()` 추가 (ContractDetail 버전)

---

### ✅ guest_contract_detail_page.dart (1,733줄 → 575줄, -67%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| 1 | 다이얼로그 4개 추출 → `GuestCheckoutConfirmDialog`, `GuestPaymentSuccessDialog`, `GuestPaymentErrorDialog`, `GuestPopupBlockedDialog` | `guest_contract_detail_dialogs.dart` (162줄) |
| 2 | 기본 정보 섹션 추출 | `guest_contract_basic_info_section.dart` (240줄) |
| 3 | 당사자 정보 섹션 추출 (`_buildPartyInfoSection` + `_buildHostCard` + `_buildGuestCard`) | `guest_contract_party_info_section.dart` (239줄) |
| 4 | 금액 섹션 추출 (`_buildRentalAmountSection` + 금액 행 유틸 3개) | `guest_contract_amount_section.dart` (198줄) |
| 5 | 옵션 상품 섹션 추출 | `guest_contract_option_section.dart` (169줄) |
| 6 | 결제 내역 섹션 추출 (섹션 + 타일 + 배지 + 상태 config) | `guest_contract_payment_history_section.dart` (160줄) |
| 7 | 결제 로직 → 기존 `guest_payment_service.dart` 통합 (`processMockPayment` 추가, 직접 `PaymentServiceUnified` new 제거) | 서비스 130줄 |

**추출 파일 목록**:
`guest_contract_detail_dialogs.dart` (162줄), `guest_contract_basic_info_section.dart` (240줄),
`guest_contract_party_info_section.dart` (239줄), `guest_contract_amount_section.dart` (198줄),
`guest_contract_option_section.dart` (169줄), `guest_contract_payment_history_section.dart` (160줄)

**기존 파일 강화**:
- `services/guest_payment_service.dart` — `processMockPayment()`, `getPaymentInfo()` 위임 추가 (117 → 130줄)

---

### ✅ contract_start_page.dart (1,802줄 → 588줄, -67%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| 분석 | 메서드/섹션 목록 파악 | 30개 메서드, 분리 후보 식별 |
| 위젯 추출 1 | 다이얼로그 4개 → `ContractStartDialogs` | 신규 파일 생성 |
| 위젯 추출 2 | `_buildRentalItemsSection` → `ContractRentalItemsSection` | 신규 파일 생성 |
| 위젯 추출 3 | 결제 카드 2개 + 헬퍼 → `ContractPaymentSummaryCard` (isMobile 통합) | 신규 파일 생성 |
| 위젯 추출 4 | 해지 조항 + 안내사항 → `ContractCancellationSection` | 신규 파일 생성 |
| 위젯 추출 5 | 방 정보 섹션 → `ContractStartRoomSection` (기존 파일 재사용 불가, 신규 생성) | 신규 파일 생성 |
| 위젯 추출 6 | 호스트 섹션 → `ContractHostInfoSection` | 신규 파일 생성 |

**추출 파일 목록**:
`contract_start_dialogs.dart` (231줄), `contract_rental_items_section.dart` (240줄),
`contract_payment_summary_card.dart` (396줄), `contract_cancellation_section.dart` (223줄),
`contract_start_room_section.dart` (202줄), `contract_host_info_section.dart` (97줄)

---

---

### ✅ host_my_page.dart (1,982줄 → 662줄, -67%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| 1 | 다이얼로그 3개 → `showMyPageSuccessDialog` 등 top-level 함수 | `widgets/common/my_page_dialogs.dart` (99줄) |
| 2 | 영수증 편집 폼 + 라디오/입력 위젯 → `HostReceiptEditForm` | `widgets/host/host_receipt_edit_form.dart` (436줄) |
| 3 | 계좌 서브섹션 → `HostBankAccountSection` | `widgets/host/host_bank_account_section.dart` (149줄) |
| 4 | 비밀번호 편집 → `HostPasswordEditSection` | `widgets/host/host_password_edit_section.dart` (180줄) |
| 5 | 닉네임 편집 → `HostNicknameEditSection` | `widgets/host/host_nickname_edit_section.dart` (162줄) |
| 6 | 검증 유틸 4개 → `ReceiptValidator` static class | `utils/receipt_validator.dart` (46줄) |
| 7 | 영수증 표시 모드 + 편집 모드 통합 → `HostReceiptDisplaySection` | `widgets/host/host_receipt_display_section.dart` (153줄) |
| 8 | `_buildProfileField` → `ProfileInfoRow` 공통 위젯 | `widgets/common/profile_info_row.dart` (63줄) |
| 9 | `_handleWithdrawal` 인라인 AlertDialog → `showWithdrawalConfirmDialog` | `widgets/common/my_page_dialogs.dart` 에 추가 (99 → 145줄) |
| 10 | 영수증 CRUD + 검증 + 타입명 → `HostReceiptService` (Phase 4) | `services/host_receipt_service.dart` (183줄) |
| 11 | 닉네임/비밀번호/연락처/탈퇴 → `HostAccountService` (Phase 4) | `services/host_account_service.dart` (119줄) |

**추출 파일 목록**:
`widgets/common/my_page_dialogs.dart` (145줄),
`widgets/host/host_receipt_edit_form.dart` (436줄),
`widgets/host/host_bank_account_section.dart` (149줄),
`widgets/host/host_password_edit_section.dart` (180줄),
`widgets/host/host_nickname_edit_section.dart` (162줄),
`widgets/host/host_receipt_display_section.dart` (153줄),
`widgets/common/profile_info_row.dart` (63줄),
`utils/receipt_validator.dart` (46줄),
`services/host_receipt_service.dart` (183줄),
`services/host_account_service.dart` (119줄)

---

---

### ✅ map_screen.dart (1,830줄 → 945줄, -48%)

**작업일**: 2026-03-31

| 단계 | 주요 작업 | 결과 |
|------|-----------|------|
| 1 | `_buildMobilePropertyCard` (251줄) → `MobilePropertyCard` StatelessWidget | `widgets/map/mobile_property_card.dart` (270줄) |
| 2 | `_buildMap` (247줄) → `KakaoMapSection` + `_buildRoomJson` 헬퍼 추출 | `widgets/map/kakao_map_section.dart` (73줄) |
| 3 | `_buildMapOnly` (218줄) → `MapOnlyLayout` StatelessWidget | `widgets/map/map_only_layout.dart` (236줄) |
| 4 | `_buildPropertyList` (129줄) → `PropertyListPanel` StatelessWidget | `widgets/map/property_list_panel.dart` (125줄) |
| 5 | `_buildDraggableScrollIndicator` (100줄) → `DraggableScrollIndicator` StatelessWidget | `widgets/map/draggable_scroll_indicator.dart` (111줄) |
| 6 | `_getFilteredRooms` / `_getFilteredRoomsForList` (105줄) → `MapFilterUtils` static | `utils/map_filter_utils.dart` (109줄) |
| 7 | `_formatPriceShort` 인라인 → `FormatUtils.formatManWon` 직접 호출로 제거 | 3줄 제거 |
| 8 | `_buildDesktopLayout` (130줄) build에서 분리 + `_buildEmptyMessage` 헬퍼 추출 | map_screen 내 메서드 분리 |
| 9 | `_buildMap` 인라인 람다 → `_handleMarkerTap` / `_handleBoundsChanged` 메서드화 | map_screen 내 메서드 분리 |
| 10 | `_loadRoomsByBounds` 내 빈 else 블록/디버그 주석 제거, `hasPhotos` 계산 간소화 | 코드 품질 정리 |

**추출 파일 목록**:
`widgets/map/mobile_property_card.dart` (270줄),
`widgets/map/kakao_map_section.dart` (73줄),
`widgets/map/map_only_layout.dart` (236줄),
`widgets/map/property_list_panel.dart` (125줄),
`widgets/map/draggable_scroll_indicator.dart` (111줄),
`utils/map_filter_utils.dart` (109줄)

---

## 현재 파일 상태 (주요 대상)

| 파일 | 현재 줄 수 | 상태 |
|------|-----------|------|
| `guest_contracts_page.dart` | ~887 | ✅ 완료 |
| `host_contracts_page_new.dart` | ~909 | ✅ 완료 |
| `host_contract_card.dart` | ~580 | ✅ 완료 |
| `contract_pricing_section.dart` | ~215 | ✅ 신규 |
| `contract_start_page.dart` | 588 | ✅ 완료 |
| `host_contract_detail_page.dart` | 540 | ✅ 완료 |
| `guest_contract_detail_page.dart` | 575 | ✅ 완료 |
| `host_my_page.dart` | 662 | 🔄 진행 중 (1,982줄 → 662줄, -67%, 목표 500줄 미만) |
| `map_screen.dart` | 945 | ✅ 완료 (1,830줄 → 945줄, -48%) |
| 나머지 500줄+ 파일 | 미측정 | 🎯 Phase 1+2 대상 |

---

## Phase 3 진입 신호 (현재 보이는 패턴)

이미 추출되어 공통화 대기 중인 것들:

| 패턴 | 현황 | 다음 단계 |
|------|------|-----------|
| 상태 뱃지 색상/텍스트 | `ContractStatusHelper.getStatusBadgeConfig` — 호스트용만 | 게스트 카드에도 동일 적용 검토 |
| 정산 계산 | `FeeCalculator.calculateHostSettlement` | 다른 파일의 동일 계산식 탐색 후 통합 |
| 퇴실 시간 판단 | `ContractUtils.isCheckoutTimeReached` | 게스트 측 동일 로직 탐색 후 통합 |
| 빈 상태 UI | `EmptyStateBox` | 아직 인라인 사용 중인 곳 교체 |
| 금액 표시 행 | `_buildAmountRow` (pricing section 내부) | 게스트 측에도 동일 패턴 있으면 공통화 |

---

## 다음 작업 후보 (Phase 1+2 계속)

### 즉시 (긴급 파일 우선)
- [ ] 500줄 초과 파일 목록 파악 (`flutter analyze` + 수동 확인)
- [x] `guest_contract_detail_page.dart` — 1,733줄 → 575줄 (-67%) ✅ 완료
- [x] `host_contract_detail_page.dart` — 2,017줄 → 540줄 (-73%) ✅ 완료
- [x] `contract_start_page.dart` — 1,802줄 → 588줄 (-67%) ✅ 완료
- [x] `host_my_page.dart` — 1,982줄 → 662줄 (-67%) 🔄 500줄 미만 목표 잔여
- [x] `map_screen.dart` — 1,830줄 → 945줄 (-48%) ✅ 완료

### 단기 (Phase 3 준비)
- [ ] `host_contracts_page_new.dart` → `host_contracts_page.dart` 파일명 정리
- [ ] `withOpacity` → `.withValues()` 교체 (deprecated 경고 다수)
- [ ] `guest_contract_card.dart` 내 하드코딩 색상 → `AppColors` 정리

---


## 유틸/헬퍼 현황

| 파일 | 주요 기능 |
|------|-----------|
| `utils/contract_utils.dart` | 이미지 URL, 주소 표시, 퇴실 시간 판단 |
| `utils/fee_calculator.dart` | 호스트 정산 계산 (신규) |
| `utils/format_utils.dart` | 날짜/금액 포맷 |
| `constants/fee_constants.dart` | 수수료율/보증금, 수수료 계산 메서드 |
| `widgets/contract/contract_status_helper.dart` | 상태 색상/뱃지/메시지/필터/카운트 |
| `widgets/common/empty_state_box.dart` | 공통 빈 상태 UI |
| `widgets/common/my_page_dialogs.dart` | 마이페이지 공통 다이얼로그 (성공/에러/안내/탈퇴확인) |
| `widgets/common/profile_info_row.dart` | 레이블+값 행 위젯 (호스트/게스트 마이페이지 공통) |
| `utils/receipt_validator.dart` | 영수증 번호 유효성 검증 (휴대폰/카드/사업자/이메일) |
| `services/host_receipt_service.dart` | 영수증 CRUD + 필드 검증 + 타입명 변환 (호스트 전용) |
| `services/host_account_service.dart` | 닉네임/비밀번호 변경, 연락처 안내, 회원 탈퇴 (호스트 전용) |
| `utils/map_filter_utils.dart` | 지도 bounds + 검색 필터 적용 (지도용/리스트용 분리) |
| `widgets/map/mobile_property_card.dart` | 모바일 지도 하단 슬라이드 카드 위젯 |
| `widgets/map/kakao_map_section.dart` | 카카오맵 위젯 래퍼 (마커/bounds 콜백 위임) |
| `widgets/map/map_only_layout.dart` | 모바일/태블릿 지도 전체화면 레이아웃 |
| `widgets/map/property_list_panel.dart` | 데스크톱 좌측 매물 리스트 패널 |
| `widgets/map/draggable_scroll_indicator.dart` | 모바일 카드 슬라이드 인디케이터 (드래그/탭 페이지 이동) |
