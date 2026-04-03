# 채팅 실시간 갱신 — 이슈 목록

최종 수정일: 2026-04-03

---

## 해결 완료

| 이슈 | 파일 | 처리 |
|---|---|---|
| Firestore reads 폭발 — GNBProvider 컬렉션 전체 구독 | `gnb_provider.dart`, `app_gnb.dart`, `main.dart` | ✅ REST API 30초 폴링으로 교체 |
| Firestore reads 폭발 — 종료 채팅방 불필요 구독 | `chat_list_page.dart` | ✅ isReadOnly && unreadCount==0 방 구독 제외 |
| `getMessages()` 무한 재시도 루프 | `chat_service.dart` | ✅ 최대 3회 + 지수 백오프(1s/2s/3s) |
| 메타데이터 구독 onError 무한 재시도 | `chat_list_page.dart` | ✅ 최대 3회 + 지연 재구독, 성공 시 카운터 리셋 |
| 스냅샷 수신마다 전체 sort O(n log n) | `chat_list_page.dart` | ✅ 변경 방 ≤2개 시 삽입 정렬 O(n)으로 최적화 |
| lastMessage 수신자 미갱신 (변경 감지 AND→OR) | `chat_list_page.dart` | ✅ |
| unreadCount 타입 캐스팅 Stream 종료 | `chat_list_page.dart` | ✅ |
| unreadCount 비원자적 처리 | `chat_service.dart` | ✅ FieldValue.increment |
| 빈 for 루프 잔여 코드 | `chat_service.dart` | ✅ |
| PC 뷰 읽음 heartbeat 없음 | `chat_list_page.dart` | ✅ |
| ChatDetailPage 메시지 캐시 없음 (깜빡임) | `chat_detail_page.dart` | ✅ |
| Firebase ID Token 만료 미갱신 | `firebase_auth_service.dart` | ✅ |
| Stream permission-denied 시 재구독 없음 | `chat_service.dart`, `chat_window.dart`, `chat_list_page.dart` | ✅ |
| Firestore `allow write: if false` — lastMessage 업데이트 차단 | Firebase Console | ✅ 규칙 수정 |
| 채팅방 열려있는 동안 unreadCount 증가 | `chat_list_page.dart` | ✅ 선택된 방 즉시 0 처리 |
| GNB 레드닷 실시간 미반영 | `gnb_provider.dart`, `app_gnb.dart` | ✅ Firestore 구독 추가 |

---

## 오픈 이슈

| 이슈 | 파일 | 비고 |
|---|---|---|
| `ChatRoom.copyWith`에 `isReadOnly` 파라미터 없음 | `chat_room.dart` | Low — `ChatWindow._writeLockSub`로 우회 중 |
| GNB 레드닷 — 신규 채팅방 생성 시 즉시 감지 불가 | `gnb_provider.dart` | 현재 `hostId`/`guestId` 쿼리로 자동 감지되나, Firestore `list` 규칙이 인증된 전체 유저에게 열려있음 (보안 개선 필요) |
| 백그라운드 탭에서 실시간 이벤트 미수신 | — | 브라우저 WebSocket 스로틀링 — Flutter/Firestore 레벨 해결 불가 |
