# 방 관리 페이지 UI 비교 분석

## 📋 분석 일시
2025-01-14

## 🎯 분석 목적
React UI (PropertyManagement.tsx)와 Flutter UI (room_management_page.dart)의 **완벽한 일치**를 확인하고, 버튼 및 요소 크기 불일치 사항을 파악합니다.

---

## 1. 전역 네비게이션 바 (GNB)

### React (GNB.tsx)
```tsx
// 높이: h-16 (64px)
<nav className="bg-white border-b border-gray-200 fixed top-0 left-0 right-0 z-50">
  <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div className="flex items-center justify-between h-16">
```

**주요 치수:**
- 높이: `h-16` = **64px**
- 최대 너비: `max-w-7xl` = **1280px**
- 패딩: `px-4 sm:px-6 lg:px-8` = 16px / 24px / 32px
- 아이콘 크기: `w-5 h-5` = **20px**
- 버튼 패딩: `px-4 py-2` = 16px 8px (높이 약 **40px**)

### Flutter (global_navigation_bar.dart)
```dart
// ✅ 구현 완료
height: 64, // h-16
maxWidth: 1280, // max-w-7xl
icon: Icon(icon, size: 20), // w-5 h-5
constraints: BoxConstraints(minWidth: 36, minHeight: 36),
```

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| GNB 높이 | 64px | 64px | ✅ 일치 |
| 최대 너비 | 1280px | 1280px | ✅ 일치 |
| 아이콘 크기 | 20px | 20px | ✅ 일치 |
| 버튼 높이 | ~40px | 36-40px | ⚠️ **약간 차이** |
| 패딩 | 16/24/32px | 16/32px | ⚠️ **중간 값 누락** |

**🔧 수정 필요 사항:**
1. **버튼 최소 높이**: Flutter IconButton의 `minHeight`를 36px → **40px**로 변경
2. **패딩**: sm 브레이크포인트 24px 추가 필요

---

## 2. 페이지 헤더 (Sticky Header)

### React
```tsx
// Line 235-255
<div className="bg-white border-b border-gray-200 sticky top-0 z-50">
  <div className="max-w-5xl mx-auto px-4 lg:px-8">
    {/* 제목 */}
    <div className="py-3 lg:py-4 hidden lg:block">
      <h1 className="text-gray-900 font-bold text-[24px]">방 관리</h1>
    </div>

    {/* 검색 바 */}
    <div className="pb-3 lg:pb-4 pt-3 lg:pt-0">
      <input className="w-full pl-10 pr-4 py-2.5 ..." />
    </div>

    {/* 필터 + 버튼 */}
    <div className="flex items-center justify-between py-3">
```

**주요 치수:**
- 최대 너비: `max-w-5xl` = **1024px**
- 제목 크기: `text-[24px]` = **24px**
- 제목 패딩: `py-3 lg:py-4` = 12px / 16px
- 검색 input 패딩: `py-2.5` = **10px** (높이 약 **42px**)
- 필터/버튼 섹션 패딩: `py-3` = **12px**

### Flutter
```dart
// ✅ 현재 구현
maxWidth: 1024,  // max-w-5xl
fontSize: 24,    // text-[24px]
SizedBox(height: 12), // py-3
CustomTextField(...),  // 검색 바
SizedBox(height: 12), // py-3
```

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| 최대 너비 | 1024px | 1024px | ✅ 일치 |
| 제목 크기 | 24px | 24px | ✅ 일치 |
| 제목 패딩 | 12/16px | 12/16px | ✅ 일치 |
| 검색 input 높이 | ~42px | ? | ❓ **확인 필요** |
| 섹션 간격 | 12px | 12px | ✅ 일치 |

**🔧 수정 필요 사항:**
1. **CustomTextField 높이 확인**: React의 `py-2.5` (10px) → 총 높이 **42px** 맞춤
2. **테두리 두께**: `border` = **1px** 확인

---

## 3. 버튼 크기 비교

### 3.1 등록 버튼 (Primary Button)

#### React
```tsx
// Line 345-352 (데스크톱)
<button className="px-4 py-2 lg:px-6 lg:py-2.5 bg-blue-600 ...">
  <Plus className="w-5 h-5" />
  <span className="hidden lg:inline">방 등록하기</span>
  <span className="lg:hidden">등록</span>
</button>
```

**치수:**
- 모바일 패딩: `px-4 py-2` = 16px 8px (높이 약 **36px**)
- 데스크톱 패딩: `px-6 py-2.5` = 24px 10px (높이 약 **42px**)
- 아이콘: `w-5 h-5` = **20px**
- 폰트: `font-semibold` = **600 weight**

#### Flutter
```dart
// Line 213-228 (현재 구현)
CustomButton(
  text: '방 등록하기',  // 데스크톱
  backgroundColor: AppColors.primary500,
  foregroundColor: AppColors.textOnPrimary,
  icon: const Icon(Icons.add, size: 20),
),
CustomButton(
  text: '등록',  // 모바일
  ...
),
```

**CustomButton 기본 치수 확인 필요:**
```dart
// custom_button.dart 확인 필요
padding: EdgeInsets.symmetric(horizontal: ?, vertical: ?),
height: ?,
```

**치수 비교:**
| 요소 | React (모바일) | React (데스크톱) | Flutter | 상태 |
|------|---------------|-----------------|---------|------|
| 패딩 (수평) | 16px | 24px | ? | ❓ **확인 필요** |
| 패딩 (수직) | 8px | 10px | ? | ❓ **확인 필요** |
| 버튼 높이 | ~36px | ~42px | ? | ❓ **확인 필요** |
| 아이콘 크기 | 20px | 20px | 20px | ✅ 일치 |

### 3.2 드롭다운 버튼

#### React
```tsx
// Line 258-265
<button className="px-4 py-2 border border-gray-300 rounded-lg ...">
  <span>{getStatusLabel(activeTab)}</span>
  <span className="text-gray-600">(...)</span>
  <ChevronDown className="w-5 h-5 ..." />
</button>
```

**치수:**
- 패딩: `px-4 py-2` = 16px 8px (높이 약 **36px**)
- 아이콘: `w-5 h-5` = **20px**
- 폰트: `font-semibold` = **600 weight**

#### Flutter
```dart
// Line 240-286 (현재 구현)
DropdownButton<String>(
  items: [...],
  onChanged: (value) { ... },
)
```

**Flutter DropdownButton 기본 높이:**
- 기본 높이: **48px** (Material Design 기본값)
- React 목표: **36px**

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| 버튼 높이 | ~36px | ~48px | ❌ **12px 차이!** |
| 패딩 | 16px 8px | 기본값 | ❌ **불일치** |
| 아이콘 크기 | 20px | 24px | ❌ **4px 차이!** |

**🔧 수정 필요 (중요!):**
```dart
// DropdownButton 높이 커스터마이징 필요
Container(
  height: 36, // React와 동일
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      isDense: true,  // 높이 줄이기
      icon: Icon(Icons.keyboard_arrow_down, size: 20), // 20px
      ...
    ),
  ),
)
```

### 3.3 Empty State 버튼

#### React
```tsx
// Line 373-379
<button className="px-6 py-2.5 bg-blue-600 ...">
  <Plus className="w-5 h-5" />
  첫 번째 방 등록하기
</button>
```

**치수:**
- 패딩: `px-6 py-2.5` = 24px 10px (높이 약 **42px**)
- 아이콘: `w-5 h-5` = **20px**

#### Flutter
```dart
// Line 381-386 (현재 구현)
CustomButton(
  text: '첫 번째 방 등록하기',  // ✅ + 제거됨
  onPressed: _onRegisterRoom,
  backgroundColor: AppColors.primary500,
  foregroundColor: AppColors.textOnPrimary,
),
```

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| 패딩 | 24px 10px | ? | ❓ **확인 필요** |
| 버튼 높이 | ~42px | ? | ❓ **확인 필요** |
| 아이콘 크기 | 20px | ? | ❓ **확인 필요** |

---

## 4. 드롭다운 메뉴 크기

### React
```tsx
// Line 268-341 (드롭다운 메뉴)
<div className="absolute left-0 mt-2 w-56 bg-white ...">
  <button className="w-full px-4 py-2 text-left text-sm ...">
    <span>전체</span>
    <span className="text-gray-500">(...)</span>
  </button>
```

**치수:**
- 드롭다운 너비: `w-56` = **224px**
- 메뉴 아이템 패딩: `px-4 py-2` = 16px 8px (높이 약 **36px**)
- 폰트 크기: `text-sm` = **14px**

### Flutter
```dart
// DropdownButton의 메뉴 아이템
DropdownMenuItem<String>(
  value: 'all',
  child: Text('전체 (${statusCounts['all'] ?? 0})'),
),
```

**Flutter 기본값:**
- 메뉴 아이템 높이: **48px** (Material Design)
- 패딩: **16px**

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| 메뉴 너비 | 224px | 자동 | ⚠️ **확인 필요** |
| 아이템 높이 | ~36px | ~48px | ❌ **12px 차이!** |
| 폰트 크기 | 14px | 기본값 | ⚠️ **확인 필요** |

**🔧 수정 필요:**
```dart
DropdownMenuItem<String>(
  value: 'all',
  child: Container(
    height: 36, // React와 동일
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('전체', style: AppTextStyles.bodySmall), // 14px
        Text('(${count})', style: AppTextStyles.bodySmallSecondary),
      ],
    ),
  ),
),
```

---

## 5. 텍스트 필드 (검색 바)

### React
```tsx
// Line 244-252
<div className="relative">
  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 ..." />
  <input
    className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg ..."
    placeholder="방 이름이나 주소로 검색"
  />
</div>
```

**치수:**
- 패딩: `pl-10 pr-4 py-2.5` = 40px 16px 10px (높이 약 **42px**)
- 아이콘 위치: `left-3` = **12px**
- 아이콘 크기: `w-5 h-5` = **20px**
- 테두리: `border` = **1px**
- 모서리: `rounded-lg` = **8px**

### Flutter
```dart
// Line 194-199 (현재 구현)
CustomTextField(
  controller: _searchController,
  label: '',
  hint: '방 이름이나 주소로 검색',
  prefixIcon: const Icon(Icons.search),
),
```

**CustomTextField 기본 치수 확인 필요:**
```dart
// custom_text_field.dart 확인 필요
contentPadding: EdgeInsets.symmetric(horizontal: ?, vertical: ?),
height: ?,
prefixIcon padding: ?,
```

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| 입력 필드 높이 | ~42px | ? | ❓ **확인 필요** |
| 좌측 패딩 | 40px | ? | ❓ **확인 필요** |
| 우측 패딩 | 16px | ? | ❓ **확인 필요** |
| 상하 패딩 | 10px | ? | ❓ **확인 필요** |
| 아이콘 크기 | 20px | 24px? | ⚠️ **확인 필요** |
| 테두리 두께 | 1px | ? | ❓ **확인 필요** |

---

## 6. 카드 컴포넌트

### React (PropertyCard)
```tsx
// 카드 패딩 및 간격
<div className="bg-white rounded-xl border border-gray-200 p-4 lg:p-6 ...">
```

**치수:**
- 패딩: `p-4 lg:p-6` = 16px / 24px
- 모서리: `rounded-xl` = **12px**
- 테두리: `border` = **1px**

### Flutter (RoomManagementCard)
```dart
// room_management_card.dart 확인 필요
padding: EdgeInsets.all(?),
borderRadius: BorderRadius.circular(?),
```

**치수 비교:**
| 요소 | React | Flutter | 상태 |
|------|-------|---------|------|
| 카드 패딩 | 16/24px | ? | ❓ **확인 필요** |
| 모서리 반경 | 12px | ? | ❓ **확인 필요** |
| 테두리 두께 | 1px | ? | ❓ **확인 필요** |

---

## 📊 요약: 주요 불일치 사항

### 🔴 Critical (즉시 수정 필요)

1. **DropdownButton 높이**: 48px → **36px** 변경 필요
2. **DropdownButton 아이콘**: 24px → **20px** 변경 필요
3. **드롭다운 메뉴 아이템 높이**: 48px → **36px** 변경 필요

### 🟡 High Priority (확인 후 수정)

4. **CustomButton 패딩 및 높이** 확인:
   - 모바일: 16px 8px (높이 ~36px)
   - 데스크톱: 24px 10px (높이 ~42px)

5. **CustomTextField 치수** 확인:
   - 높이: ~42px
   - 패딩: 40px(좌) 16px(우) 10px(상하)
   - 아이콘: 20px

6. **GNB IconButton 높이**: 36px → **40px** 변경

### 🟢 Low Priority (세부 조정)

7. **GNB 패딩**: sm 브레이크포인트 24px 추가
8. **카드 패딩 및 모서리** 확인
9. **폰트 크기** 일관성 확인

---

## 🛠️ 다음 작업

1. ✅ **GNB 추가 완료**
2. ⏳ **CustomButton.dart 확인 및 수정**
3. ⏳ **CustomTextField.dart 확인 및 수정**
4. ⏳ **DropdownButton 커스터마이징**
5. ⏳ **RoomManagementCard 치수 확인**

---

## 📝 참고 자료

### Tailwind CSS 치수 변환표
| Tailwind | px | 설명 |
|----------|-----|------|
| `w-5 h-5` | 20px | 아이콘 |
| `px-4` | 16px | 패딩 (가로) |
| `py-2` | 8px | 패딩 (세로) |
| `py-2.5` | 10px | 패딩 (세로) |
| `px-6` | 24px | 패딩 (가로) |
| `rounded-lg` | 8px | 모서리 |
| `rounded-xl` | 12px | 모서리 |
| `text-sm` | 14px | 폰트 크기 |
| `text-[24px]` | 24px | 커스텀 크기 |
| `max-w-5xl` | 1024px | 최대 너비 |
| `max-w-7xl` | 1280px | 최대 너비 |

### Flutter Material Design 기본값
| 컴포넌트 | 기본 높이 | 목표 (React) |
|----------|----------|-------------|
| IconButton | 48px | 36-40px |
| TextField | 56px | 42px |
| DropdownButton | 48px | 36px |
| DropdownMenuItem | 48px | 36px |
| ElevatedButton | 40px | 36-42px |
