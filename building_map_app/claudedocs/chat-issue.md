# 채팅 실시간 갱신 — 발견된 이슈 목록

분석 일자: 2026-04-03

---

## 해결 완료 목록

| 이슈 | 파일 | 처리 |
|---|---|---|
| lastMessage 수신자 미갱신 (변경 감지 AND→OR) | `chat_list_page.dart` | ✅ 코드 수정 |
| unreadCount 타입 캐스팅 Stream 종료 | `chat_list_page.dart` | ✅ 코드 수정 |
| unreadCount 비원자적 처리 | `chat_service.dart` | ✅ FieldValue.increment 적용 |
| 빈 for 루프 제거 | `chat_service.dart` | ✅ 코드 수정 |
| PC 뷰 heartbeat 없음 | `chat_list_page.dart` | ✅ 코드 수정 |
| ChatDetailPage 메시지 캐시 없음 | `chat_detail_page.dart` | ✅ 코드 수정 |
| Firebase ID Token 만료 미갱신 | `firebase_auth_service.dart` | ✅ 코드 수정 |
| Stream permission-denied 시 재구독 없음 | `chat_service.dart`, `chat_window.dart`, `chat_list_page.dart` | ✅ 코드 수정 |
| Firestore `allow write: if false` — lastMessage 업데이트 차단 | Firebase Console 규칙 | ✅ 규칙 수정 (update 허용) |
| 채팅방 열려있는 동안 상대방 메시지로 unreadCount 증가 | `chat_list_page.dart` | ✅ 선택된 방 즉시 0 처리 |

---

## 이슈 1 — `ChatDetailPage` 캐시 없음 (UX 깜빡임) ✅ 해결

**파일**: `lib/pages/chat/chat_detail_page.dart:290`  
**심각도**: Low

**내용**  
`ChatDetailPage._buildMessageList()`의 `StreamBuilder`에 `initialData`가 없다.  
채팅방 재진입 시 Firestore 연결 대기(ConnectionState.waiting) 동안 로딩 스피너가 표시되어 깜빡임이 발생한다.

`ChatListPage`는 LRU 캐시 10개(`_messageCache`)를 두고 `initialData`로 공급해 깜빡임을 방지하고 있지만,  
`ChatDetailPage`(모바일 단독 진입 경로)에는 동일한 처리가 없어 두 경로 간 UX 불일치가 생긴다.

**재현 경로**: 모바일에서 채팅방 진입 → 뒤로가기 → 같은 채팅방 재진입 시 로딩 스피너 노출

---

## 이슈 2 — `_updateChatRoomMetadata` 비원자적 읽기-쓰기 (unreadCount 경합) ✅ 해결

**파일**: `lib/services/chat_service.dart:391-432`  
**심각도**: Medium

**내용**  
메시지 전송 후 unreadCount를 올릴 때 `chatRoomRef.get()` → `chatRoomRef.update()` 순서로 처리한다.  
두 사용자가 거의 동시에 메시지를 보내면 둘 다 같은 snapshot을 읽어 unreadCount를 계산하므로  
한쪽 increment가 손실될 수 있다.

**현재 코드 흐름**
```
get() → fromFirestore() → newCount = oldCount + 1 → update(newCount)
```

**권장 수정 방향**  
`FieldValue.increment(1)` 사용으로 원자적 처리:
```dart
await chatRoomRef.update({
  'unreadCount.${otherUserId}': FieldValue.increment(1),
  'lastMessageText': lastMessage,
  'lastMessageAt': FieldValue.serverTimestamp(),
});
```
→ `get()` 왕복 제거 + 경합 없음

---

## 이슈 3 — 빈 for 루프 잔여 코드 ✅ 해결

**파일**: `lib/services/chat_service.dart:82-83`  
**심각도**: Very Low (코드 품질)

**내용**  
`getChatRooms()` 내부에 빈 루프가 남아있다 (이전 로깅 코드 삭제 흔적).

```dart
for (final room in chatRooms) {
  // 아무것도 없음
}
```

불필요한 순회로 제거 대상.

---

## 이슈 4 — PC 뷰(`ChatListPage`)에 읽음 heartbeat 없음 ✅ 해결

**파일**: `lib/pages/chat/chat_detail_page.dart:110-116` (heartbeat 구현 위치)  
**심각도**: Medium

**내용**  
`ChatDetailPage`는 30초마다 `markAsReadOnServer()`를 호출해 채팅방에 머무는 동안 알림톡 발송을 차단한다.  
그러나 PC/웹 환경에서는 `ChatListPage` 안의 `ChatWindow`가 렌더링되고 `ChatDetailPage`는 사용되지 않아  
heartbeat가 동작하지 않는다.

**영향**: PC에서 채팅방을 오래 열어두면 서버가 상대방이 읽지 않은 것으로 판단해 알림톡이 중복 발송될 수 있다.

**재현 경로**: 웹/PC에서 채팅방 진입 → 30초 이상 머무는 동안 상대방이 메시지 전송 → 알림톡 수신

---

## 이슈 5 — `ChatRoom.copyWith`에 `isReadOnly` 파라미터 없음

**파일**: `lib/models/chat_room.dart:84-109`  
**심각도**: Low

**내용**  
`copyWith()`에 `isReadOnly` 파라미터가 없어 Firestore 구독으로 read-only 상태가 변경되어도  
`ChatRoom` 객체에 반영이 불가능하다.

현재는 `ChatWindow._writeLockSub`가 독립적으로 Firestore를 구독해 `_isWriteLocked` 상태를 별도 관리하는 것으로 우회하고 있으나,  
`ChatRoom` 객체와 실제 잠금 상태가 분리되어 있어 다른 위젯에서 `chatRoom.isReadOnly`를 직접 참조하면 오래된 값을 볼 수 있다.
