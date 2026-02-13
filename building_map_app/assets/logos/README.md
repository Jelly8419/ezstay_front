# EZStay 로고 에셋 가이드

## 📁 이미지 파일 저장 방법

제공받은 로고 이미지를 다음과 같이 저장해주세요:

### 1. 기본 로고 이미지
대화에 첨부된 로고 이미지를 다운로드하여 아래 경로에 저장:

```
building_map_app/assets/logos/ezstay_logo_primary.png
```

### 2. 권장 파일 구조

```
assets/logos/
├── ezstay_logo_primary.png       # 기본 로고 (제공된 이미지)
├── ezstay_logo_white.png         # 흰색 버전 (다크 배경용, 선택사항)
├── ezstay_icon_only.png          # 아이콘만 (32x32, AppBar 모바일용)
└── README.md                     # 이 파일
```

### 3. 추가 버전 생성 (선택사항)

필요한 경우 이미지 편집 도구로 다음 버전을 생성할 수 있습니다:

**아이콘 전용 버전 (ezstay_icon_only.png)**
- 크기: 32x32px 또는 64x64px
- 용도: 모바일 AppBar, Favicon
- 방법: 원본 이미지를 정사각형으로 크롭 후 리사이즈

**흰색 버전 (ezstay_logo_white.png)**
- 용도: 다크 배경에서 사용
- 방법: 원본 이미지의 청록색을 흰색으로 변경

### 4. 저장 후 확인

이미지 저장 후 다음 명령어로 파일 확인:

```bash
ls assets/logos/
```

다음과 같이 출력되어야 합니다:
```
ezstay_logo_primary.png
README.md
```

---

**참고:** SVG 파일이 있다면 PNG 대신 SVG를 사용하는 것이 확장성 면에서 더 좋습니다.
