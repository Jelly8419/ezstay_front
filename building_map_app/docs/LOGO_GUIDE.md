# EZStay 로고 저장 및 로드 방식

## 파일 저장 위치

### Flutter 앱 내 로고 소스
```
building_map_app/assets/logos/
├── ezstay_logo_primary.png   # GNB/스플래시 기본 컬러 로고 (1024x1024)
├── ezstay_logo_white.png     # 다크 배경용 흰색 로고 (1024x1024)
└── ezstay_icon_only.png      # 아이콘 전용 (1024x1024)
```

### 플랫폼별 앱 아이콘
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      # 48x48
├── mipmap-hdpi/ic_launcher.png      # 72x72
├── mipmap-xhdpi/ic_launcher.png     # 96x96
├── mipmap-xxhdpi/ic_launcher.png    # 144x144
└── mipmap-xxxhdpi/ic_launcher.png   # 192x192

ios/Runner/Assets.xcassets/AppIcon.appiconset/  # 20px ~ 1024px (16종)
macos/Runner/Assets.xcassets/AppIcon.appiconset/ # 16px ~ 1024px (7종)

web/
├── favicon.png              # 브라우저 탭 아이콘 (16x16)
└── icons/
    ├── Icon-192.png         # PWA 아이콘
    ├── Icon-512.png         # PWA 아이콘
    ├── Icon-maskable-192.png
    └── Icon-maskable-512.png
```

### 랜딩페이지
```
landing/assets/
├── logo.png      # 헤더 로고 (1024x1024 소스)
├── favicon.png   # 브라우저 탭 아이콘 (16x16)
└── og-image.png  # SNS 공유 이미지
```

---

## 로드 방식

### EZStayLogo 위젯
`lib/widgets/common/ezstay_logo.dart`

```dart
// 기본 사용
EZStayLogo(width: 120, height: 40)

// 아이콘 전용
EZStayLogo.iconOnly(size: 32)

// 화면 크기 자동 대응
ResponsiveEZStayLogo()
```

#### 변형(Variant) → 파일 매핑
| Variant | 파일 | 용도 |
|---------|------|------|
| `EZStayLogoVariant.primary` | `assets/logos/ezstay_logo_primary.png` | 기본 (라이트 배경) |
| `EZStayLogoVariant.white` | `assets/logos/ezstay_logo_white.png` | 다크 배경 |
| `EZStayLogoVariant.iconOnly` | `assets/logos/ezstay_icon_only.png` | 좁은 공간 |

#### 렌더링 설정
- `filterQuality: FilterQuality.high` — CanvasKit 렌더러에서 선명도 유지
- `frameBuilder`: 로드 중 페이드인 애니메이션
- `errorBuilder`: 로드 실패 시 'EZ' 텍스트 폴백

#### ResponsiveEZStayLogo 크기 분기
| 화면 너비 | 크기 | Variant |
|-----------|------|---------|
| 데스크톱 (>900px) | 120×40 | primary |
| 태블릿 (600~900px) | 80×32 | primary |
| 모바일 (<600px) | 32×32 | iconOnly |

---

## 사용 위치

| 파일 | 위치 | 크기 |
|------|------|------|
| `lib/widgets/common/app_gnb.dart:113` | GNB 좌측 | 40×40 |
| `lib/widgets/common/responsive_page_layout.dart:211` | AppBar | ResponsiveEZStayLogo |
| `lib/pages/auth/login_page.dart:71` | 로그인 화면 | 150×150 |
| `lib/widgets/splash_screen.dart` | 스플래시 화면 | 120×120 |
| `landing/index.html:139` | 랜딩 헤더 | width=120 height=36 |

---

## 로고 교체 시 체크리스트

1. **Flutter 앱 로고** (`assets/logos/` 3종) 교체
2. **Android mipmap** 5종 교체
3. **iOS AppIcon** 16종 교체
4. **macOS AppIcon** 7종 교체
5. **Web PWA 아이콘** 4종 + `favicon.png` 교체
6. **랜딩페이지** `logo.png` + `favicon.png` 교체
7. `flutter build web --no-tree-shake-icons` 재빌드
8. Cloudflare 캐시 퍼지 (Custom Purge → `/assets/*`, `/icons/*`)

> **주의**: Cloudflare `_headers`에서 `/assets/*`가 `max-age=86400`(24시간) 캐시로 설정되어 있어,  
> 교체 후 반드시 캐시 퍼지 필요.
