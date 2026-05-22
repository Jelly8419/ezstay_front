# 게스트 입주 준비 서비스 — 라우트 트리

> 작성일: 2026-05-08
> 백엔드 API: `C:\study\backend_md_list\입주준비서비스_임차인_API.md`
> 프론트 가이드: `C:\study\front_md_list\입주준비서비스_임차인_프론트_가이드.md`

## 라우트 트리

```
/move-in/payment/:token                          # 비로그인 미리보기 (optionalAuth)
/login?returnUrl=<encoded-path>                  # 비로그인 → 본인확인 후 returnUrl 로 복귀
/guest/move-in                                   # 내 요청 목록 (인증 필요)
/guest/move-in/requests/:caseId                  # 상세 / 결제 후 재확인 (인증 필요)
/guest/move-in/requests/:caseId/payment          # 결제 화면 (인증 필요)
/guest/move-in/payments/:paymentId/complete      # 결제 완료 화면 (인증 필요)
/guest/more                                      # 모바일 더보기 탭 (인증 필요)
```

## 페이지 책임

| 라우트 | 페이지 클래스 | 진입점 | 주 책임 |
|---|---|---|---|
| `/move-in/payment/:token` | `MoveInInvitePreviewPage` | 임대인 알림톡 링크, SMS | optionalAuth — 룸/옵션/CTA 분기. 비로그인 시 sessionStorage 에 옵션 저장 후 로그인 유도 |
| `/guest/move-in` | `GuestMoveInHomePage` | GNB, 알림 폴백, 홈 진입 카드 | 본인 케이스 목록 + 상태 필터 (전체/결제 대기/결제 완료/완료) |
| `/guest/move-in/requests/:caseId` | `GuestMoveInDetailPage` | 목록 카드 탭, 알림 클릭 (`metadata.caseId`) | 결제 완료 후 재확인. 주문 내역 + 배송 상태 + 추가 결제 진입 |
| `/guest/move-in/requests/:caseId/payment` | `GuestMoveInPaymentPage` | 미리보기에서 bind 성공, 목록에서 결제 대기 카드 탭 | 옵션 선택 + PG 결제 (PayTag SDK). INITIAL/ADDITIONAL 분기는 `detail.hasPaidInitial` |
| `/guest/move-in/payments/:paymentId/complete` | `GuestMoveInCompletePage` | 결제 성공 직후, 알림 (`metadata.paymentId`) | 결제 결과 + CTA 3개 (목록/상세/홈) |
| `/guest/more` | `GuestMorePage` | 모바일 5탭 마지막 | 채팅/My/환불 계좌/고객센터 진입 |

## 인증 게이트

`router/app_router.dart` 의 `redirect` 로직:

- 비로그인 + `/guest/move-in*` 또는 `/guest/more*` 진입 시 → `/login?returnUrl=<현재 경로>`
- `/move-in/payment/:token` 은 비로그인 허용 (optionalAuth)
- 로그인된 상태에서 `/login?returnUrl=...` 접근 시 → 검증 후 디코드된 경로로 즉시 이동

## returnUrl 보안

- `/` 로 시작해야 함 (외부 URL 차단)
- `//` 시작 차단 (protocol-relative URL)
- `Uri.encodeComponent` / `Uri.decodeComponent` 페어로 처리

## 결제 플로우 (PayTag)

```
init (서버 가격 산정)
  ↓ INITIAL: /payment/init    ADDITIONAL: /additional/init
  ↓
PG 호출
  ├─ Mock 모드 (pgPayload.mock = true): 즉시 confirm
  └─ 실 PG: PayTag SDK → recvPayparam 수신 → confirm
  ↓
confirm
  ├─ 성공: /guest/move-in/payments/:paymentId/complete
  ├─ pgFailed: 토스트 + 재시도 (주문 PENDING 유지)
  └─ confirmFailed: 토스트 + 재시도 (주문 PENDING 유지)
```

## 알림 라우팅

| Type | 경로 | metadata 우선순위 |
|---|---|---|
| `MOVE_IN_PAYMENT_REQUEST` | `/guest/move-in/requests/:caseId` | `caseId` |
| `MOVE_IN_PAYMENT_COMPLETED` | `/guest/move-in/payments/:paymentId/complete` | `paymentId` → fallback `caseId` |

deeplink 폴백: `move-in` → `_navigateToGuestMoveIn` 헬퍼 (notification_page.dart)

## sessionStorage 키

| 키 | 용도 | 정리 시점 |
|---|---|---|
| `pending_move_in_options_<token>` | 비로그인 옵션 선택 보존 | 로그인 후 결제 화면 이동 시 유지, 결제 완료 후 자체 만료 |
