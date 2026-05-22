# 입주 준비 서비스 (호스트) — 운영 전환 체크리스트

> Phase 8 산출물 — 개발(Mock) ↔ 운영(실 PG/실 알림톡) 전환 시 점검할 항목.

## 🔴 운영 전환 시 필수 작업 (백엔드 / 운영 협업)

### 1. PayTag SDK 운영 키
- [ ] PayTag 실 운영 `shopcode` / 인증키 발급
- [ ] 백엔드 `.env`의 `PAYTAG_SHOP_CODE` 등 운영 값으로 교체
- [ ] 백엔드 `PAYMENT_USE_MOCK=false`로 변경
- ✅ **프론트 변경 불필요** — `CleaningPaymentController.pay()`가 응답의 `pgPayload.mock` 플래그를 보고 자동 분기

### 2. 알림톡 템플릿 등록 (알리고)
- [ ] 운영팀 → 알리고 어드민에서 `MOVE_IN_PAYMENT_REQUEST` 템플릿 등록 + 승인
- [ ] 백엔드 `dispatchPaymentRequestNotification()`이 등록된 템플릿 ID로 발송하도록 활성화
- [ ] 응답에서 `_note` 필드가 사라짐 → 프론트의 노란 "개발 모드 안내" 배너 자동 사라짐
- ✅ **프론트 변경 불필요** — `_note` 유무로 자동 분기

### 3. 임차인 결제 페이지 도메인
- [ ] 백엔드 `.env`의 `GUEST_MOVE_IN_PAYMENT_URL`을 운영 도메인으로 설정
- [ ] 게스트 PRD 후속 트랙에서 임차인 결제 페이지(`/move-in/payment/:token`) UI 구현 필요
- ⚠️ 호스트가 "링크 복사" 후 임차인이 클릭하면 동작해야 하므로 **운영 전 게스트 페이지 필수**

## 🟡 운영 후 검증

배포 후 호스트 계정으로 실 PG 결제 1건 시도 — 다음 항목 확인:

- [ ] 견적 다이얼로그에서 산식 + 금액 정상 표시
- [ ] PayTag 결제창이 팝업 차단 없이 호출됨
- [ ] 실 카드 결제 → confirm 성공 → 토스트의 `(Mock)` 접미사 **없어야 함**
- [ ] `cleaningStatus`가 PAID로 즉시 반영 (목록/상세 동시)
- [ ] 임차인 결제 요청 발송 시 응답에 `_note` 없음 → 노란 배너 노출되지 않음
- [ ] 임차인이 알림톡 정상 수신

## 🟢 후속 개선 항목 (V2 이후)

- [ ] 청소 가격 정책 어드민 UI (현재 코드 상수)
- [ ] 침구류 대여/회수 (`taskType` 확장)
- [ ] 정식 방 등록(Room) 전환 — 간편 방 → 정식 방으로 승격
- [ ] 케이스의 `roomSnapshot` 수정 API (현재 미지원)
- [ ] 모바일 PayTag WebView 결제 (현재 웹 전용)
- [ ] 케이스 목록 정렬 옵션 (현재 `createdAt DESC` 고정)

## 🛡️ 운영 시 모니터링 포인트

| 항목 | 모니터링 채널 |
|---|---|
| `409 CONFLICT_WITH_CONTRACT` 발생 빈도 | 호스트가 날짜 겹침을 자주 시도하면 UX 개선 필요 |
| `4605 PAYMENT_CONFIRMATION_FAILED` | 잦으면 PayTag 연동 점검 |
| `_note` 배너가 운영 환경에서 표시되면 | 알림톡 템플릿 등록 누락 — 즉시 운영팀 확인 |
| `autoSend.sent=false` 비율 | 알림톡 발송 실패율 — 알리고 잔액/네트워크 점검 |

## 📦 관련 파일 (프론트)

| 영역 | 파일 |
|---|---|
| API 클라이언트 | [lib/services/move_in_service.dart](../building_map_app/lib/services/move_in_service.dart) |
| 결제 컨트롤러 | [lib/services/cleaning_payment_controller.dart](../building_map_app/lib/services/cleaning_payment_controller.dart) |
| Provider | [lib/providers/move_in/](../building_map_app/lib/providers/move_in/) |
| 페이지 | [lib/pages/host/move_in/](../building_map_app/lib/pages/host/move_in/) |
| 도메인 모델 | [lib/models/move_in/](../building_map_app/lib/models/move_in/) |

## 📄 참고 문서

- 프론트 가이드: `C:\study\front_md_list\입주준비서비스_프론트_가이드.md`
- 구현 계획서: `C:\study\front_md_list\입주준비서비스_프론트_구현계획.md`
- 라우트 트리: [move-in-host-routes.md](./move-in-host-routes.md)
- 백엔드 API 상세: `C:\study\backend_md_list\입주준비서비스_임대인_API.md`
- PRD 원본: Notion `3587d336b0e580808dd3e1e1a7a8139c`
