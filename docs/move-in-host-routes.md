# 입주 준비 서비스 (호스트) — 라우트 트리 설계

> Phase 0.4 산출물 — Phase 1에서 `app_router.dart`에 등록하기 전 합의용

## 라우트 트리

```
/host
├─ /host/move-in                         MoveInHomePage           입주 준비 서비스 홈 (목록 + 요약)
├─ /host/move-in/new                     MoveInCreatePage         새 입주 준비 등록 (탭 2개)
│   ?tab=existing|new                                              초기 탭 (기본 existing)
└─ /host/move-in/:caseId                 MoveInDetailPage         입주 준비 등록 상세
```

### 진입 경로
- 데스크탑 GNB 중앙 메뉴 4번째 → `/host/move-in`
- 모바일 하단 탭 3번째 → `/host/move-in`
- 홈 목록의 `+ 새 입주 준비 등록` 버튼 → `/host/move-in/new`
- 홈 목록의 `상세` 버튼 → `/host/move-in/:caseId`
- 홈 목록의 `결제` 버튼 → `/host/move-in/:caseId` (상세에서 PG 결제 모달 자동 오픈)

### 결제 화면
이미지 ④번 PG 결제는 **별도 라우트가 아니라 상세 페이지의 모달/오버레이**로 구현.
이유:
- 결제 성공/취소 후 같은 상세 페이지로 자연스럽게 복귀
- 기존 PayTag 콜백(`/payment-callback`)과 중복 라우트 회피
- PRD 7.3 — "성공 시 상세 페이지로 복귀" 요구사항과 일치

## 각 페이지의 책임

### MoveInHomePage (`/host/move-in`)
- 케이스 목록 조회 (`GET /cases`)
- 요약 카드 4개
- 검색/필터/정렬
- 케이스 카드 → 상세로 이동
- 신규 등록 버튼 → 등록 페이지로 이동

### MoveInCreatePage (`/host/move-in/new`)
- 두 개 탭: **등록된 방에서 선택** / **새 주소로 간편 등록**
- 탭 1 저장 → 케이스 생성 → 상세로 이동
- 탭 2 저장 → 방 등록만 → 탭 1로 자동 전환 + 신규 방 선택 상태

### MoveInDetailPage (`/host/move-in/:caseId`)
- 케이스 상세 조회 (`GET /cases/:id`)
- 청소 서비스 액션: 신청 / 결제 / 취소
- 임차인 결제 요청 액션: 보내기 / 다시 보내기 / 링크 복사
- 정보 수정 (PATCH)
- 결제 모달 (PG init → SDK → confirm)

## go_router 등록 위치
`lib/router/app_router.dart`의 ShellRoute 내부, 기존 호스트 라우트 (`/host/contracts` 다음 줄 부근)에 추가.
deferred 로딩 패턴을 따름:

```dart
import '../pages/host/move_in/move_in_home_page.dart' deferred as move_in_home;
import '../pages/host/move_in/move_in_create_page.dart' deferred as move_in_create;
import '../pages/host/move_in/move_in_detail_page.dart' deferred as move_in_detail;

GoRoute(
  path: '/host/move-in',
  name: 'host-move-in',
  builder: (context, state) => _deferredShellWidget(
    move_in_home.loadLibrary,
    () => move_in_home.MoveInHomePage(),
  ),
  routes: [
    GoRoute(
      path: 'new',
      name: 'host-move-in-create',
      builder: (context, state) => _deferredShellWidget(
        move_in_create.loadLibrary,
        () => move_in_create.MoveInCreatePage(
          initialTab: state.uri.queryParameters['tab'],
        ),
      ),
    ),
    GoRoute(
      path: ':caseId',
      name: 'host-move-in-detail',
      builder: (context, state) {
        final caseId = int.tryParse(state.pathParameters['caseId'] ?? '');
        if (caseId == null) {
          return _buildShellInvalidAccessWidget(
            context,
            message: '잘못된 접근입니다.',
            buttonText: '입주 준비 서비스로 돌아가기',
            redirectPath: '/host/move-in',
          );
        }
        return _deferredShellWidget(
          move_in_detail.loadLibrary,
          () => move_in_detail.MoveInDetailPage(caseId: caseId),
        );
      },
    ),
  ],
),
```

## 모바일 GNB 활성 탭 판정

`mobile_bottom_nav.dart`에 다음 헬퍼 추가:

```dart
bool _isMoveIn(String location) =>
    location.startsWith('/host/move-in');
```

기존 `_isHostHome`은 `_isMoveIn`도 false 조건에 포함시켜야 함.

## 모바일 GNB 탭 재배치 (Q4-A)

```
기존: [홈] [방관리] [계약] [채팅] [My]
신규: [홈] [방관리] [입주준비] [계약] [더보기]
```

`더보기` 탭 추가 작업:
- 신규 페이지 `host_more_page.dart` 또는 바텀시트 모달
- 라우트 `/host/more` (페이지 방식 채택 시)
- 메뉴 항목: 채팅, 정산, My, 고객센터
