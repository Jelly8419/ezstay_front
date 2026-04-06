# 환불규정 섹션 노출 위치 분석

## "환불 규정" 섹션으로 유저에게 노출되는 곳

| # | 위치 | 파일 | 대상 | 섹션 타이틀 | 데이터 소스 |
|---|------|------|------|-------------|-------------|
| 1 | 방 상세 페이지 | `lib/pages/guest/room_detail_page.dart:1153` | 게스트 | `환불 규정` | `GET /api/refund-policies` → `RefundPolicy.rules` bullet 렌더링 |
| 2 | 계약 시작 페이지 | `lib/pages/contract/contract_start_page.dart` | 게스트 | `환불 규정` | `GET /api/refund-policies` → `ContractCancellationSection` 위젯 |
| 3 | 게스트 계약 상세 | `lib/widgets/contract/guest_contract_cancellation_section.dart` | 게스트 | `환불 규정` | `GET /api/contracts/{contractId}` → `contract.refundPolicySnapshot` |
| 4 | 채팅 계약정보 모달 | `lib/widgets/chat/contract_info_modal.dart:118` | 게스트/호스트 | `환불 규정` | `GET /api/contracts/{contractId}` → `contract.refundPolicyDetail` |

---

## API 상세

### 1·2번 — 계약 전 (방 탐색 / 계약 동의)

| 항목 | 내용 |
|------|------|
| API | `GET /api/refund-policies` |
| 서비스 | `lib/services/refund_policy_service.dart` `getRefundPolicies()` |
| 반환 모델 | `RefundPolicy` (`lib/models/refund_policy.dart`) |
| 정책 타입 | `flexible` (약하게) / `moderate` (보통) / `strict` (엄격하게) |
| 캐싱 | 메모리 캐싱 적용 (`_cachedPolicies`) |

### 3·4번 — 계약 후 (계약 상세 / 채팅)

| 항목 | 내용 |
|------|------|
| API | `GET /api/contracts/{contractId}` |
| 서비스 | `lib/services/contract_service.dart:1044` `getGuestContractDetail()` |
| 반환 모델 | `ContractDetail` (`lib/models/contract_detail.dart`) |
| 환불 규정 필드 | `refundPolicySnapshot` (계약 시점 스냅샷) / `refundPolicyDetail` (문자열) |
| 특이사항 | `/api/refund-policies` 별도 호출 없이 계약 조회 응답에 환불 규정이 함께 포함됨 |

---

## 데이터 흐름 요약

```
계약 전                              계약 후
  ↓                                    ↓
GET /api/refund-policies           GET /api/contracts/{contractId}
  ↓                                    ↓
RefundPolicy.rules                 ContractDetail.refundPolicySnapshot
(현재 정책 기준)                    (계약 시점 스냅샷 — 정책 변경 무관)
  ↓                                    ↓
방 상세 / 계약 시작                 게스트 계약 상세 / 채팅 계약정보 모달
```

**핵심 설계 포인트:**
- 계약 전: 현재 정책(`/api/refund-policies`)을 표시
- 계약 후: 계약 당시 스냅샷(`refundPolicySnapshot`)을 사용 → 이후 정책 변경 시에도 계약 시점 기준 유지
