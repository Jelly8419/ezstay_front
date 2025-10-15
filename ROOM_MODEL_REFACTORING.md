# Room 모델 리팩토링 계획

## 현재 상황 분석

### 문제점
- `room.dart` 모델에 **레거시 필드**와 **신규 API 응답 필드**가 혼재됨
- `toJson()`, `copyWith()` 메서드가 존재하지 않는 필드 참조
- API 응답 구조와 모델 구조 불일치

### 레거시 필드 (제거 대상)
```dart
// 제거할 필드
- name (→ roomName으로 통일)
- addressDetail (→ address에 포함)
- bedrooms (→ roomCount로 통일)
- bathrooms (→ bathroomCount로 통일)
- beds (제거)
- maxGuests (제거)
- weeklyPrice (→ weeklyRent로 통일)
- monthlyPrice (제거, 주 단위 계산)
- deposit (제거)
- managementFee (→ maintenanceFee로 통일)
- amenities (→ RoomAmenity 모델 사용)
- freeServices (→ RoomFreeService 모델 사용)
- isParkingAvailable (→ parkingAvailable로 통일)
- isPetFriendly (→ amenity.petsAllowed 사용)
- hasElevator (→ elevatorAvailable로 통일)
- discount (제거, longTermDiscount/quickMoveInDiscount 사용)
- checkInTime (제거)
- checkOutTime (제거)
- kitchens (→ kitchenCount로 통일)
- livingRooms (→ livingRoomCount로 통일)
- areaSize (→ area로 통일)
- managementFeeIncludes (→ includeElectricity/Water/Gas/Internet 사용)
- minRentalWeeks (→ minContractWeeks로 통일)
- maxRentalWeeks (제거)
```

### 신규 API 응답 필드 (유지)
```dart
// 기본 정보
- id, roomName, address, latitude, longitude
- area, floor, buildingType
- parkingAvailable, parkingInfo, elevatorAvailable
- roomCount, bathroomCount, livingRoomCount, kitchenCount, isDuplex

// 가격 정보
- weeklyRent, longTermWeeks, longTermDiscount
- quickMoveIn, quickMoveInDiscount
- maintenanceFee, maintenanceDetail
- includeElectricity, includeWater, includeGas, includeInternet
- cleaningFee

// 계약 정보
- minContractWeeks, refundPolicy
- description, transportation, houseRules

// 날짜 정보
- submittedAt, approvedAt, publishedAt, createdAt, updatedAt

// 연관 데이터
- photos: List<RoomPhoto>
- amenity: RoomAmenity
- freeService: RoomFreeService

// UI 전용 필드
- isNearSubway, hostProfileImage, hostPhoneVerified, hostAccountVerified
- hostName, hostId, status
```

---

## 리팩토링 체크리스트

### Phase 1: 모델 정리 ✅
- [ ] `room.dart` 레거시 필드 제거
- [ ] `fromJson()` 메서드를 API 응답 구조에 맞게 수정
- [ ] `toJson()` 메서드 완전히 재작성 (API 요청용)
- [ ] `copyWith()` 메서드 완전히 재작성
- [ ] 계산 프로퍼티 수정 (discountedWeeklyPrice 등)
- [ ] 주석 및 문서화 추가

### Phase 2: 검색 필터 호환성 ✅
- [ ] `search_filters.dart` 모델 확인 및 수정
- [ ] `guest_room_service.dart` 더미 데이터 수정
- [ ] 필터링 로직 업데이트 (bedrooms → roomCount 등)

### Phase 3: UI 업데이트 ✅
- [ ] `map_screen.dart` 수정 (Room 모델 사용처)
- [ ] `room_detail_page.dart` 수정 (상세 정보 표시)
- [ ] 리스트/카드 위젯 수정 (필드명 변경 반영)

### Phase 4: 테스트 및 검증 ✅
- [ ] API 응답 파싱 테스트 (실제 API 연동)
- [ ] 더미 데이터 동작 확인
- [ ] UI 렌더링 확인
- [ ] 에러 케이스 테스트

---

## 세부 작업 계획

### 1. Room 모델 리팩토링

#### 1-1. 레거시 필드 제거
**파일**: `building_map_app/lib/models/room.dart`

**작업**:
- 생성자에서 레거시 파라미터 제거
- 필드 선언부 정리
- `fromJson()`에서 레거시 필드 매핑 제거

**상태**: ⬜ 미완료

---

#### 1-2. `fromJson()` 메서드 수정
**파일**: `building_map_app/lib/models/room.dart:120-202`

**작업**:
- API 응답 구조에 정확히 맞춤
- 레거시 필드명 fallback 제거 (예: `roomName ?? name`)
- `photos`, `amenity`, `freeService` 파싱 유지

**상태**: ⬜ 미완료

---

#### 1-3. `toJson()` 메서드 재작성
**파일**: `building_map_app/lib/models/room.dart:213-258`

**현재 문제**:
```dart
// 존재하지 않는 필드 참조
'name': name,  // ❌ name 필드 없음
'addressDetail': addressDetail,  // ❌ addressDetail 필드 없음
'bedrooms': bedrooms,  // ❌ bedrooms 필드 없음
```

**수정안**:
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'roomName': roomName,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'area': area,
    'floor': floor,
    'buildingType': buildingType,
    'parkingAvailable': parkingAvailable,
    'parkingInfo': parkingInfo,
    'elevatorAvailable': elevatorAvailable,
    'roomCount': roomCount,
    'bathroomCount': bathroomCount,
    'livingRoomCount': livingRoomCount,
    'kitchenCount': kitchenCount,
    'isDuplex': isDuplex,
    'weeklyRent': weeklyRent,
    'longTermWeeks': longTermWeeks,
    'longTermDiscount': longTermDiscount,
    'quickMoveIn': quickMoveIn,
    'quickMoveInDiscount': quickMoveInDiscount,
    'maintenanceFee': maintenanceFee,
    'maintenanceDetail': maintenanceDetail,
    'includeElectricity': includeElectricity,
    'includeWater': includeWater,
    'includeGas': includeGas,
    'includeInternet': includeInternet,
    'cleaningFee': cleaningFee,
    'minContractWeeks': minContractWeeks,
    'refundPolicy': refundPolicy,
    'description': description,
    'transportation': transportation,
    'houseRules': houseRules,
    'submittedAt': submittedAt?.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'publishedAt': publishedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'amenity': amenity?.toJson(),
    'freeService': freeService?.toJson(),
    'isNearSubway': isNearSubway,
    'hostProfileImage': hostProfileImage,
    'hostPhoneVerified': hostPhoneVerified,
    'hostAccountVerified': hostAccountVerified,
    'hostName': hostName,
    'hostId': hostId,
    'status': status,
  };
}
```

**상태**: ⬜ 미완료

---

#### 1-4. `copyWith()` 메서드 재작성
**파일**: `building_map_app/lib/models/room.dart:281-369`

**현재 문제**:
- 존재하지 않는 필드 참조 (name, addressDetail, bedrooms 등)

**수정안**:
- 모든 현재 필드에 대해 `copyWith()` 파라미터 추가
- 레거시 필드 제거

**상태**: ⬜ 미완료

---

#### 1-5. 계산 프로퍼티 수정
**파일**: `building_map_app/lib/models/room.dart:260-279`

**현재 문제**:
```dart
int get discountedWeeklyPrice {
  if (discount != null && discount! > 0) {  // ❌ discount 필드 없음
    return (weeklyPrice * (100 - discount!) / 100).round();  // ❌ weeklyPrice 필드 없음
  }
  return weeklyPrice;
}
```

**수정안**:
```dart
/// 장기 계약 할인 적용된 주 임대료
int get longTermDiscountedRent {
  if (longTermDiscount > 0) {
    return (weeklyRent * (100 - longTermDiscount) / 100).round();
  }
  return weeklyRent;
}

/// 빠른 입주 할인 적용된 주 임대료
int get quickMoveInDiscountedRent {
  if (quickMoveInDiscount > 0) {
    return (weeklyRent * (100 - quickMoveInDiscount) / 100).round();
  }
  return weeklyRent;
}

/// 월 임대료 (주 임대료 × 4.3)
int get monthlyRent => (weeklyRent * 4.3).round();

/// 장기 계약 할인 적용된 월 임대료
int get longTermDiscountedMonthlyRent => (longTermDiscountedRent * 4.3).round();

/// 총 침대 수 (freeService의 bed 정보에서 계산)
int get totalBeds {
  if (freeService == null) return 0;
  return freeService!.bedSizeSuperSingle +
         freeService!.bedSizeQueen +
         freeService!.bedSizeKing;
}

/// 편의시설 평탄화 리스트 (UI용)
List<String> get amenitiesList => amenity?.toFlatList() ?? [];

/// 무료 서비스 평탄화 리스트 (UI용)
List<String> get freeServicesList => freeService?.toFlatList() ?? [];

/// 반려동물 동반 가능 여부
bool get isPetFriendly => amenity?.petsAllowed ?? false;
```

**상태**: ⬜ 미완료

---

### 2. SearchFilters 및 GuestRoomService 수정

#### 2-1. `search_filters.dart` 확인
**파일**: `building_map_app/lib/models/search_filters.dart`

**작업**:
- `bedroomCounts` 필터가 `roomCount`와 매핑되는지 확인
- 필요 시 필터 모델 수정

**상태**: ⬜ 미완료

---

#### 2-2. `guest_room_service.dart` 더미 데이터 수정
**파일**: `building_map_app/lib/services/guest_room_service.dart:164-292`

**현재 문제**:
```dart
Room(
  id: 1,
  name: '개봉역 바로 앞!',  // ❌ name 파라미터 없음
  bedrooms: 1,  // ❌ bedrooms 파라미터 없음
  weeklyPrice: 240000,  // ❌ weeklyPrice 파라미터 없음
  // ...
)
```

**수정안**:
```dart
Room(
  id: 1,
  roomName: '개봉역 바로 앞!',
  address: '서울시 구로구 개봉동 123-45',
  latitude: 37.4990,
  longitude: 126.8566,
  area: '33.0',
  floor: '3',
  buildingType: '아파트',
  parkingAvailable: false,
  elevatorAvailable: true,
  roomCount: 1,
  bathroomCount: 1,
  livingRoomCount: 1,
  kitchenCount: 1,
  isDuplex: false,
  weeklyRent: 240000,
  longTermWeeks: 12,
  longTermDiscount: 0,
  quickMoveInDiscount: 0,
  maintenanceFee: 50000,
  includeElectricity: true,
  includeWater: true,
  includeGas: true,
  includeInternet: false,
  cleaningFee: 30000,
  minContractWeeks: 4,
  refundPolicy: 'moderate',
  description: '개봉역 바로 앞 편리한 위치',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  photos: [
    RoomPhoto(id: 1, url: 'https://via.placeholder.com/400x300', order: 1),
  ],
  amenity: RoomAmenity(
    roomId: 1,
    basicOptions: {'wifi': true, 'tv': true, 'airConditioner': true, 'heater': false},
    additionalOptions: {'washer': true, 'dryer': false, 'iron': false},
    convenienceOptions: {'microwave': false, 'refrigerator': true, 'dishwasher': false},
    petsAllowed: false,
  ),
  freeService: RoomFreeService(
    roomId: 1,
    agreeTerms: true,
    cleaningService: true,
    hairDryerRental: true,
    beddingService: true,
    bedSizeSuperSingle: 0,
    bedSizeQueen: 1,
    bedSizeKing: 0,
    autoPasswordChange: true,
  ),
  isNearSubway: true,
  hostName: '김호스트',
  hostId: 1,
  status: 'published',
)
```

**상태**: ⬜ 미완료

---

#### 2-3. 필터링 로직 업데이트
**파일**: `building_map_app/lib/services/guest_room_service.dart:112-161`

**현재 문제**:
```dart
if (filters.bedroomCounts.isNotEmpty) {
  rooms = rooms.where((room) {
    // ...
    return filters.bedroomCounts.contains(room.bedrooms);  // ❌ bedrooms 필드 없음
  }).toList();
}

if (!filters.priceRange.isDefault) {
  rooms = rooms.where((room) {
    return filters.priceRange.isInRange(room.weeklyPrice);  // ❌ weeklyPrice 필드 없음
  }).toList();
}

if (filters.otherOptions.contains(OtherOptions.parking)) {
  rooms = rooms.where((room) => room.isParkingAvailable).toList();  // ❌ isParkingAvailable 필드 없음
}

if (filters.otherOptions.contains(OtherOptions.pet)) {
  rooms = rooms.where((room) => room.isPetFriendly).toList();  // ❌ isPetFriendly 필드 없음
}
```

**수정안**:
```dart
if (filters.bedroomCounts.isNotEmpty) {
  rooms = rooms.where((room) {
    if (filters.bedroomCounts.contains(3)) {
      return room.roomCount >= 3 || filters.bedroomCounts.contains(room.roomCount);
    }
    return filters.bedroomCounts.contains(room.roomCount);
  }).toList();
}

if (!filters.priceRange.isDefault) {
  rooms = rooms.where((room) {
    return filters.priceRange.isInRange(room.weeklyRent);
  }).toList();
}

if (filters.otherOptions.contains(OtherOptions.parking)) {
  rooms = rooms.where((room) => room.parkingAvailable).toList();
}

if (filters.otherOptions.contains(OtherOptions.pet)) {
  rooms = rooms.where((room) => room.isPetFriendly).toList();  // getter 사용
}
```

**상태**: ⬜ 미완료

---

### 3. UI 업데이트

#### 3-1. `map_screen.dart` 수정
**파일**: `building_map_app/lib/pages/map_screen.dart`

**작업**:
- Room 모델 사용처 찾기
- 필드명 변경 반영 (weeklyPrice → weeklyRent 등)

**상태**: ⬜ 미완료

---

#### 3-2. `room_detail_page.dart` 수정
**파일**: `building_map_app/lib/pages/room_detail_page.dart`

**작업**:
- 방 상세 정보 표시 로직 수정
- photos, amenity, freeService 렌더링 확인
- 가격 표시 로직 수정 (monthlyRent getter 사용)

**상태**: ⬜ 미완료

---

#### 3-3. 리스트/카드 위젯 찾기 및 수정
**작업**:
```bash
# Room 모델 사용처 찾기
grep -r "room\." lib/pages/ lib/widgets/
grep -r "weeklyPrice\|bedrooms\|amenities\|freeServices" lib/
```

**상태**: ⬜ 미완료

---

### 4. 테스트 및 검증

#### 4-1. API 응답 파싱 테스트
**작업**:
- 실제 API 응답 JSON으로 `Room.fromJson()` 테스트
- 모든 필드 정확히 파싱되는지 확인

**테스트 케이스**:
```dart
test('Room.fromJson should parse API response correctly', () {
  final json = {
    "id": 782,
    "roomName": "종로구 타운하우스 776",
    "address": "서울특별시 종로구 테스트로 776",
    "latitude": "37.57980000",
    "longitude": "126.96010000",
    "area": "92.60",
    "floor": "2",
    "buildingType": "타운하우스",
    // ... 전체 JSON
  };

  final room = Room.fromJson(json);

  expect(room.id, 782);
  expect(room.roomName, "종로구 타운하우스 776");
  expect(room.latitude, 37.5798);
  expect(room.photos.length, 6);
  expect(room.amenity?.basicOptions['wifi'], false);
  expect(room.freeService?.cleaningService, true);
});
```

**상태**: ⬜ 미완료

---

#### 4-2. 더미 데이터 동작 확인
**작업**:
- 앱 실행 후 지도에서 더미 데이터 렌더링 확인
- 필터링 기능 동작 확인

**상태**: ⬜ 미완료

---

#### 4-3. UI 렌더링 확인
**작업**:
- 리스트 뷰 렌더링
- 카드 뷰 렌더링
- 상세 페이지 렌더링
- 에러 메시지 없는지 확인

**상태**: ⬜ 미완료

---

#### 4-4. 에러 케이스 테스트
**테스트 케이스**:
- [ ] photos가 null일 때
- [ ] amenity가 null일 때
- [ ] freeService가 null일 때
- [ ] 필수 필드가 누락되었을 때

**상태**: ⬜ 미완료

---

## 진행 상황 요약

### Phase 1: 모델 정리
- [ ] 0/6 작업 완료

### Phase 2: 검색 필터 호환성
- [ ] 0/3 작업 완료

### Phase 3: UI 업데이트
- [ ] 0/3 작업 완료

### Phase 4: 테스트 및 검증
- [ ] 0/4 작업 완료

**전체 진행률**: 0/16 (0%)

---

## 참고사항

### API 응답 예시
```json
{
  "success": true,
  "message": "성공",
  "data": {
    "id": 782,
    "roomName": "종로구 타운하우스 776",
    "address": "서울특별시 종로구 테스트로 776",
    "latitude": "37.57980000",
    "longitude": "126.96010000",
    "area": "92.60",
    "floor": "2",
    "buildingType": "타운하우스",
    "parkingAvailable": false,
    "parkingInfo": "건물 내 주차장 이용 가능",
    "elevatorAvailable": true,
    "roomCount": 3,
    "bathroomCount": 2,
    "livingRoomCount": 2,
    "kitchenCount": 1,
    "isDuplex": false,
    "weeklyRent": 430255,
    "longTermWeeks": 43,
    "longTermDiscount": 10,
    "quickMoveIn": null,
    "quickMoveInDiscount": 8,
    "maintenanceFee": 94439,
    "maintenanceDetail": "전기, 수도, 가스, 인터넷 포함",
    "includeElectricity": false,
    "includeWater": true,
    "includeGas": true,
    "includeInternet": false,
    "cleaningFee": 94107,
    "minContractWeeks": 12,
    "refundPolicy": "strict",
    "description": "종로구에 위치한...",
    "transportation": "지하철역 도보 5분 거리...",
    "houseRules": "반려동물 동반 가능...",
    "submittedAt": "2025-10-12T23:36:51.000Z",
    "approvedAt": "2025-10-12T23:36:51.000Z",
    "publishedAt": "2025-10-12T23:36:51.000Z",
    "createdAt": "2025-10-12T23:36:51.000Z",
    "updatedAt": "2025-10-12T23:36:51.000Z",
    "photos": [
      {
        "id": 4663,
        "url": "/uploads/dummy/room776_photo1.jpg",
        "order": 1
      }
    ],
    "amenity": {
      "roomId": 782,
      "basicOptions": "{\"wifi\":false,\"tv\":true,\"airConditioner\":true,\"heater\":false}",
      "additionalOptions": "{\"washer\":false,\"dryer\":true,\"iron\":false}",
      "convenienceOptions": "{\"microwave\":false,\"refrigerator\":false,\"dishwasher\":false}",
      "petsAllowed": false,
      "createdAt": "2025-10-12T23:36:51.000Z",
      "updatedAt": "2025-10-12T23:36:51.000Z"
    },
    "freeService": {
      "roomId": 782,
      "agreeTerms": true,
      "cleaningService": true,
      "cleaningToolImageUrl": null,
      "hairDryerRental": true,
      "beddingService": false,
      "bedSizeSuperSingle": 0,
      "bedSizeQueen": 0,
      "bedSizeKing": 1,
      "autoPasswordChange": true,
      "roomPassword": "1709",
      "createdAt": "2025-10-12T23:36:51.000Z",
      "updatedAt": "2025-10-12T23:36:51.000Z"
    }
  }
}
```

### 호환성 유지 전략
- `RoomAmenity.toFlatList()` - 기존 UI와 호환
- `RoomFreeService.toFlatList()` - 기존 UI와 호환
- `Room.isPetFriendly` getter - 기존 필터링 로직 호환
- `Room.monthlyRent` getter - 주 임대료 기반 계산

---

## 다음 단계

1. **Phase 1 시작**: Room 모델 정리부터 시작
2. 각 작업 완료 후 체크박스 업데이트
3. 에러 발생 시 이 문서에 기록
4. 모든 Phase 완료 후 최종 검증
