# 방 일정 관리 백엔드 API 명세서

## 개요

이 문서는 `RoomSchedulePage` (방 일정 관리 페이지) 기능을 지원하기 위해 필요한 백엔드 API 엔드포인트를 정의합니다.

**기준 파일**: `lib/pages/host/room_schedule_page.dart`
**작성일**: 2026-01-16

---

## 1. 방 기본 정보 조회 API

### `GET /api/host/rooms/{roomId}/schedule-info`

**목적**: 일정 관리 페이지 상단에 표시할 방 기본 정보 조회

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID

**요청 예시**:
```http
GET /api/host/rooms/room-12345/schedule-info
Authorization: Bearer {jwt_token}
```

**응답 성공 (200 OK)**:
```json
{
  "success": true,
  "data": {
    "roomId": "room-12345",
    "propertyName": "강남역 도보 5분 원룸",
    "propertyAddress": "서울시 강남구 역삼동 123-45"
  }
}
```

**응답 실패**:
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID가 존재하지 않음

---

## 2. 계약 목록 조회 API

### `GET /api/host/rooms/{roomId}/contracts`

**목적**: 해당 방의 계약된 기간 목록 조회 (12개월 기준)

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID

**쿼리 파라미터**:
- `startDate` (string, optional): 조회 시작일 (ISO 8601, 기본값: 오늘)
- `endDate` (string, optional): 조회 종료일 (ISO 8601, 기본값: 오늘+12개월)

**요청 예시**:
```http
GET /api/host/rooms/room-12345/contracts?startDate=2026-01-01&endDate=2026-12-31
Authorization: Bearer {jwt_token}
```

**응답 성공 (200 OK)**:
```json
{
  "success": true,
  "data": {
    "contracts": [
      {
        "id": "C001",
        "startDate": "2026-01-05",
        "endDate": "2026-01-12",
        "guestName": "김서연",
        "guestId": "user-789",
        "status": "confirmed",
        "totalPrice": 350000,
        "createdAt": "2025-12-15T10:30:00Z"
      },
      {
        "id": "C002",
        "startDate": "2026-01-20",
        "endDate": "2026-02-10",
        "guestName": "홍길동",
        "guestId": "user-456",
        "status": "confirmed",
        "totalPrice": 1050000,
        "createdAt": "2025-12-20T14:20:00Z"
      }
    ],
    "totalCount": 6
  }
}
```

**데이터 모델 (Contract)**:
```typescript
interface Contract {
  id: string;              // 계약 고유 ID
  startDate: string;       // 체크인 날짜 (ISO 8601)
  endDate: string;         // 체크아웃 날짜 (ISO 8601)
  guestName: string;       // 게스트 이름
  guestId: string;         // 게스트 사용자 ID
  status: 'confirmed' | 'cancelled' | 'completed';  // 계약 상태
  totalPrice: number;      // 총 결제 금액
  createdAt: string;       // 계약 생성 시간 (ISO 8601)
}
```

**응답 실패**:
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID가 존재하지 않음

**비즈니스 로직**:
- 계약 상태가 `confirmed`인 것만 조회 (취소된 계약 제외)
- 날짜 범위는 `startDate`와 `endDate`가 겹치는 모든 계약 포함
- 시간대는 서버의 기본 시간대 사용 (UTC+9)

---

## 3. 계약 불가 기간 목록 조회 API

### `GET /api/host/rooms/{roomId}/blocked-periods`

**목적**: 호스트가 설정한 계약 불가 기간 목록 조회

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID

**쿼리 파라미터**:
- `startDate` (string, optional): 조회 시작일 (ISO 8601, 기본값: 오늘)
- `endDate` (string, optional): 조회 종료일 (ISO 8601, 기본값: 오늘+12개월)

**요청 예시**:
```http
GET /api/host/rooms/room-12345/blocked-periods?startDate=2026-01-01&endDate=2026-12-31
Authorization: Bearer {jwt_token}
```

**응답 성공 (200 OK)**:
```json
{
  "success": true,
  "data": {
    "blockedPeriods": [
      {
        "id": "B001",
        "startDate": "2026-01-15",
        "endDate": "2026-01-18",
        "reason": "시설 점검",
        "createdAt": "2026-01-01T09:00:00Z"
      },
      {
        "id": "B002",
        "startDate": "2026-02-12",
        "endDate": "2026-02-20",
        "reason": "청소 및 정비",
        "createdAt": "2026-01-10T10:30:00Z"
      }
    ],
    "totalCount": 5
  }
}
```

**데이터 모델 (BlockedPeriod)**:
```typescript
interface BlockedPeriod {
  id: string;              // 불가 기간 고유 ID
  startDate: string;       // 시작 날짜 (ISO 8601)
  endDate: string;         // 종료 날짜 (ISO 8601)
  reason?: string;         // 사유 (선택사항)
  createdAt: string;       // 생성 시간 (ISO 8601)
}
```

**응답 실패**:
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID가 존재하지 않음

---

## 4. 계약 불가 기간 생성 API

### `POST /api/host/rooms/{roomId}/blocked-periods`

**목적**: 호스트가 새로운 계약 불가 기간 설정

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID

**요청 본문**:
```json
{
  "startDate": "2026-03-01",
  "endDate": "2026-03-10",
  "reason": "개인 사용"
}
```

**요청 필드**:
- `startDate` (string, required): 시작 날짜 (YYYY-MM-DD 형식)
- `endDate` (string, required): 종료 날짜 (YYYY-MM-DD 형식)
- `reason` (string, optional): 불가 사유 (최대 200자)

**요청 예시**:
```http
POST /api/host/rooms/room-12345/blocked-periods
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "startDate": "2026-03-01",
  "endDate": "2026-03-10",
  "reason": "개인 사용"
}
```

**응답 성공 (201 Created)**:
```json
{
  "success": true,
  "data": {
    "id": "B006",
    "startDate": "2026-03-01",
    "endDate": "2026-03-10",
    "reason": "개인 사용",
    "createdAt": "2026-01-16T14:30:00Z"
  },
  "message": "계약 불가 기간이 설정되었습니다"
}
```

**응답 실패**:
- `400 Bad Request`: 잘못된 요청 (날짜 형식 오류, 시작일 > 종료일 등)
  ```json
  {
    "success": false,
    "error": {
      "code": "INVALID_DATE_RANGE",
      "message": "종료일은 시작일보다 이후여야 합니다"
    }
  }
  ```
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID가 존재하지 않음
- `409 Conflict`: 해당 기간에 이미 계약이 존재함
  ```json
  {
    "success": false,
    "error": {
      "code": "CONFLICT_WITH_CONTRACT",
      "message": "해당 기간에 이미 확정된 계약이 있습니다",
      "details": {
        "conflictingContracts": [
          {
            "id": "C003",
            "startDate": "2026-03-05",
            "endDate": "2026-03-15"
          }
        ]
      }
    }
  }
  ```

**데이터 검증 규칙**:
1. `startDate`와 `endDate`는 반드시 ISO 8601 형식 (YYYY-MM-DD)
2. `startDate`는 오늘 이후의 날짜 (과거 날짜 불가)
3. `endDate`는 `startDate`와 같거나 이후
4. 설정하려는 기간에 이미 확정된 계약(`status: confirmed`)이 없어야 함
5. `reason`은 선택사항이지만, 입력 시 최대 200자 제한

**비즈니스 로직**:
- 계약된 기간과 겹치는지 확인 후 거부
- 기존 불가 기간과 겹치면 병합 또는 확장 (옵션)
- 생성 후 Firebase Analytics 이벤트 로깅 (호스트 행동 분석)

---

## 5. 계약 불가 기간 삭제 API

### `DELETE /api/host/rooms/{roomId}/blocked-periods/{blockedId}`

**목적**: 호스트가 설정한 계약 불가 기간 삭제 (계약 가능으로 전환)

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID
- `blockedId` (string, required): 불가 기간 고유 ID

**요청 예시**:
```http
DELETE /api/host/rooms/room-12345/blocked-periods/B001
Authorization: Bearer {jwt_token}
```

**응답 성공 (200 OK)**:
```json
{
  "success": true,
  "message": "계약 불가 기간이 삭제되었습니다",
  "data": {
    "deletedId": "B001"
  }
}
```

**응답 실패**:
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID 또는 불가 기간 ID가 존재하지 않음

**비즈니스 로직**:
- 삭제 후 해당 날짜는 예약 가능 상태로 전환
- Firebase Analytics 이벤트 로깅

---

## 6. 계약 불가 기간 부분 해제 API

### `POST /api/host/rooms/{roomId}/blocked-periods/unblock`

**목적**: 기존 불가 기간의 일부 날짜를 가능으로 전환 (기간 분할)

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID

**요청 본문**:
```json
{
  "startDate": "2026-02-15",
  "endDate": "2026-02-17"
}
```

**요청 필드**:
- `startDate` (string, required): 해제할 시작 날짜 (YYYY-MM-DD 형식)
- `endDate` (string, required): 해제할 종료 날짜 (YYYY-MM-DD 형식)

**요청 예시**:
```http
POST /api/host/rooms/room-12345/blocked-periods/unblock
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "startDate": "2026-02-15",
  "endDate": "2026-02-17"
}
```

**응답 성공 (200 OK)**:
```json
{
  "success": true,
  "message": "계약 가능으로 전환되었습니다",
  "data": {
    "deletedPeriods": ["B002"],
    "createdPeriods": [
      {
        "id": "B002_before",
        "startDate": "2026-02-12",
        "endDate": "2026-02-14",
        "reason": "청소 및 정비"
      },
      {
        "id": "B002_after",
        "startDate": "2026-02-18",
        "endDate": "2026-02-20",
        "reason": "청소 및 정비"
      }
    ]
  }
}
```

**응답 실패**:
- `400 Bad Request`: 잘못된 요청 (날짜 형식 오류, 시작일 > 종료일 등)
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID가 존재하지 않음 또는 해당 날짜에 불가 기간이 없음

**비즈니스 로직**:
1. 선택한 날짜 범위가 포함된 모든 불가 기간(`BlockedPeriod`) 검색
2. 각 불가 기간을 선택 범위 기준으로 분할:
   - **이전 부분**: `blocked.startDate` ~ `(선택 시작일 - 1일)`
   - **이후 부분**: `(선택 종료일 + 1일)` ~ `blocked.endDate`
3. 원본 불가 기간은 삭제하고, 분할된 부분들을 새로운 불가 기간으로 생성
4. 분할 결과가 없는 경우 (완전히 포함되어 삭제만) 빈 배열 반환

**예시 시나리오**:
```
원본 불가 기간: 2026-02-12 ~ 2026-02-20 (B002)
해제 요청: 2026-02-15 ~ 2026-02-17

결과:
- B002 삭제
- B002_before 생성: 2026-02-12 ~ 2026-02-14
- B002_after 생성: 2026-02-18 ~ 2026-02-20
- 해제된 날짜: 2026-02-15, 2026-02-16, 2026-02-17 (예약 가능)
```

---

## 7. 통합 일정 데이터 조회 API (최적화)

### `GET /api/host/rooms/{roomId}/schedule`

**목적**: 계약, 불가 기간, 방 정보를 한 번에 조회 (페이지 초기화 최적화)

**인증**: JWT Bearer Token (호스트 권한 필요)

**경로 파라미터**:
- `roomId` (string, required): 방 고유 ID

**쿼리 파라미터**:
- `startDate` (string, optional): 조회 시작일 (ISO 8601, 기본값: 오늘)
- `endDate` (string, optional): 조회 종료일 (ISO 8601, 기본값: 오늘+12개월)

**요청 예시**:
```http
GET /api/host/rooms/room-12345/schedule?startDate=2026-01-01&endDate=2026-12-31
Authorization: Bearer {jwt_token}
```

**응답 성공 (200 OK)**:
```json
{
  "success": true,
  "data": {
    "roomInfo": {
      "roomId": "room-12345",
      "propertyName": "강남역 도보 5분 원룸",
      "propertyAddress": "서울시 강남구 역삼동 123-45"
    },
    "contracts": [
      {
        "id": "C001",
        "startDate": "2026-01-05",
        "endDate": "2026-01-12",
        "guestName": "김서연",
        "guestId": "user-789",
        "status": "confirmed",
        "totalPrice": 350000,
        "createdAt": "2025-12-15T10:30:00Z"
      }
    ],
    "blockedPeriods": [
      {
        "id": "B001",
        "startDate": "2026-01-15",
        "endDate": "2026-01-18",
        "reason": "시설 점검",
        "createdAt": "2026-01-01T09:00:00Z"
      }
    ],
    "totalContracts": 6,
    "totalBlockedPeriods": 5
  }
}
```

**응답 실패**:
- `401 Unauthorized`: 인증 토큰 없음 또는 만료
- `403 Forbidden`: 호스트가 해당 방의 소유자가 아님
- `404 Not Found`: 방 ID가 존재하지 않음

**성능 최적화**:
- 단일 API 호출로 모든 데이터 조회 (Network Round-Trip 최소화)
- 프론트엔드 초기 로딩 속도 개선
- 캐싱 전략 적용 가능

---

## 공통 규칙

### 인증 및 권한

**인증 방식**: JWT Bearer Token
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**권한 검증**:
1. 모든 API는 호스트 권한 필요 (`user.role === 'host'`)
2. 호스트는 자신이 등록한 방만 접근 가능
3. `roomId`와 토큰의 `userId`가 매칭되는지 검증

### 에러 응답 공통 형식

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "사용자 친화적 에러 메시지",
    "details": {
      // 추가 디버깅 정보 (선택사항)
    }
  }
}
```

**공통 에러 코드**:
- `UNAUTHORIZED`: 인증 실패
- `FORBIDDEN`: 권한 없음
- `NOT_FOUND`: 리소스 없음
- `INVALID_REQUEST`: 잘못된 요청
- `CONFLICT_WITH_CONTRACT`: 계약과 충돌
- `CONFLICT_WITH_BLOCKED_PERIOD`: 불가 기간과 충돌
- `INVALID_DATE_RANGE`: 날짜 범위 오류
- `PAST_DATE_NOT_ALLOWED`: 과거 날짜 불가
- `SERVER_ERROR`: 서버 내부 오류

### 날짜 형식

**모든 날짜는 ISO 8601 형식 사용**:
- 날짜만: `YYYY-MM-DD` (예: `2026-01-15`)
- 날짜+시간: `YYYY-MM-DDTHH:mm:ssZ` (예: `2026-01-15T14:30:00Z`)

**시간대**: 서버는 UTC+9 (한국 표준시) 기준으로 처리

### 페이지네이션

대량 데이터의 경우 페이지네이션 지원 (향후 추가):
```http
GET /api/host/rooms/{roomId}/contracts?page=1&limit=20
```

응답:
```json
{
  "data": [...],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalItems": 100,
    "itemsPerPage": 20
  }
}
```

### 캐싱 전략

**추천 캐싱 설정**:
- `GET /api/host/rooms/{roomId}/schedule`: 5분 캐시
- `GET /api/host/rooms/{roomId}/contracts`: 10분 캐시
- `GET /api/host/rooms/{roomId}/blocked-periods`: 10분 캐시

**Cache-Control 헤더**:
```http
Cache-Control: private, max-age=300
```

---

## Firebase Analytics 이벤트

**프론트엔드에서 로깅할 이벤트**:

1. **페이지 진입**:
   ```dart
   analytics.logEvent(
     name: 'room_schedule_page_view',
     parameters: {'room_id': roomId}
   );
   ```

2. **불가 기간 설정 완료**:
   ```dart
   analytics.logEvent(
     name: 'blocked_period_created',
     parameters: {
       'room_id': roomId,
       'start_date': startDate,
       'end_date': endDate,
       'reason': reason,
     }
   );
   ```

3. **불가 기간 삭제**:
   ```dart
   analytics.logEvent(
     name: 'blocked_period_deleted',
     parameters: {
       'room_id': roomId,
       'blocked_id': blockedId,
     }
   );
   ```

---

## 구현 우선순위

### Phase 1 (필수 기능)
1. ✅ `GET /api/host/rooms/{roomId}/schedule` - 통합 일정 조회
2. ✅ `POST /api/host/rooms/{roomId}/blocked-periods` - 불가 기간 생성
3. ✅ `DELETE /api/host/rooms/{roomId}/blocked-periods/{blockedId}` - 불가 기간 삭제

### Phase 2 (부가 기능)
4. ⏳ `POST /api/host/rooms/{roomId}/blocked-periods/unblock` - 부분 해제 (기간 분할)
5. ⏳ `GET /api/host/rooms/{roomId}/contracts` - 계약 목록 상세 조회

### Phase 3 (최적화)
6. ⏳ 캐싱 전략 적용
7. ⏳ 페이지네이션 지원
8. ⏳ WebSocket을 통한 실시간 업데이트 (다른 디바이스에서 변경 시 동기화)

---

## 테스트 시나리오

### 1. 불가 기간 설정 테스트

**시나리오**: 호스트가 2026-03-01 ~ 2026-03-10 기간을 불가로 설정

**테스트 케이스**:
1. ✅ 예약 가능한 날짜에 불가 기간 설정 성공
2. ❌ 계약된 날짜에 불가 기간 설정 시 409 Conflict
3. ❌ 과거 날짜에 불가 기간 설정 시 400 Bad Request
4. ❌ 종료일 < 시작일인 경우 400 Bad Request
5. ❌ 다른 호스트가 접근 시 403 Forbidden

### 2. 불가 기간 삭제 테스트

**시나리오**: 호스트가 불가 기간 B001 삭제

**테스트 케이스**:
1. ✅ 존재하는 불가 기간 삭제 성공
2. ❌ 존재하지 않는 불가 기간 삭제 시 404 Not Found
3. ❌ 다른 호스트가 삭제 시도 시 403 Forbidden

### 3. 부분 해제 테스트

**시나리오**: 불가 기간 2026-02-12 ~ 2026-02-20 중 2026-02-15 ~ 2026-02-17 해제

**테스트 케이스**:
1. ✅ 중간 날짜 해제 시 기간 분할 성공
2. ✅ 시작일 포함 해제 시 종료일만 남음
3. ✅ 종료일 포함 해제 시 시작일만 남음
4. ✅ 전체 기간 해제 시 원본 삭제만 (분할 없음)

---

## 보안 고려사항

1. **SQL Injection 방지**: 파라미터화된 쿼리 사용
2. **JWT 토큰 검증**: 만료 시간, 서명 무결성 확인
3. **권한 검증**: 호스트가 자신의 방만 접근하도록 강제
4. **Rate Limiting**: API 호출 빈도 제한 (DDoS 방지)
5. **입력 검증**: 모든 사용자 입력 서버 측에서 재검증
6. **로깅**: 민감한 정보 제외한 API 호출 기록

---

## API 버전 관리

**현재 버전**: v1
**Base URL**: `https://api.ezstay.com/v1`

향후 변경사항 발생 시 `/v2` 엔드포인트로 신규 API 제공

---

## 문의 및 피드백

**담당자**: EZStay 백엔드 개발팀
**문서 버전**: 1.0
**최종 수정**: 2026-01-16
