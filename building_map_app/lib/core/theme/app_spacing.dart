import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체의 간격, Border Radius, Shadow 등을 정의합니다.
///
/// 사용 예시:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.md),
///   child: Container(
///     decoration: BoxDecoration(
///       borderRadius: BorderRadius.circular(AppRadius.md),
///       boxShadow: [AppShadows.md],
///     ),
///   ),
/// )
/// ```
class AppSpacing {
  AppSpacing._();

  // ============= Spacing Scale (8pt 그리드) =============
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // 세부적인 간격
  static const double space0 = 0;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;
  static const double space80 = 80;

  // ============= Edge Insets (자주 쓰는 패딩) =============
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Page padding (페이지 전체 패딩)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  // Screen padding (Safe Area 고려한 패딩)
  static EdgeInsets screenPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.fromLTRB(
      md,
      mediaQuery.padding.top + md,
      md,
      mediaQuery.padding.bottom + md,
    );
  }
}

/// Border Radius 시스템
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999; // 완전 둥근 형태

  // BorderRadius 객체
  static BorderRadius get radiusXs => BorderRadius.circular(xs);
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get radiusFull => BorderRadius.circular(full);

  // Top only
  static BorderRadius get radiusTopMd => BorderRadius.only(
        topLeft: Radius.circular(md),
        topRight: Radius.circular(md),
      );
  static BorderRadius get radiusTopLg => BorderRadius.only(
        topLeft: Radius.circular(lg),
        topRight: Radius.circular(lg),
      );
  static BorderRadius get radiusTopXl => BorderRadius.only(
        topLeft: Radius.circular(xl),
        topRight: Radius.circular(xl),
      );

  // Bottom only
  static BorderRadius get radiusBottomMd => BorderRadius.only(
        bottomLeft: Radius.circular(md),
        bottomRight: Radius.circular(md),
      );
  static BorderRadius get radiusBottomLg => BorderRadius.only(
        bottomLeft: Radius.circular(lg),
        bottomRight: Radius.circular(lg),
      );
}

/// Shadow (그림자) 시스템
/// 모던 플랫폼 스타일의 부드러운 그림자 효과를 포함합니다.
class AppShadows {
  AppShadows._();

  // Small shadow
  static const BoxShadow sm = BoxShadow(
    color: AppColors.shadowLight,
    offset: Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );

  // Medium shadow
  static const BoxShadow md = BoxShadow(
    color: AppColors.shadowMedium,
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  // Large shadow
  static const BoxShadow lg = BoxShadow(
    color: AppColors.shadowDark,
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );

  // Extra large shadow
  static const BoxShadow xl = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
  );

  // Shadow lists (BoxDecoration에서 사용)
  static const List<BoxShadow> shadowSm = [sm];
  static const List<BoxShadow> shadowMd = [md];
  static const List<BoxShadow> shadowLg = [lg];
  static const List<BoxShadow> shadowXl = [xl];

  // Bottom sheet shadow
  static const List<BoxShadow> bottomSheet = [
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, -2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // App bar shadow
  static const List<BoxShadow> appBar = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // ============= 인터랙티브 카드 그림자 (Interactive Card Shadows) =============

  /// 카드 기본 상태 그림자 (미세한 떠있는 느낌)
  static const List<BoxShadow> cardDefault = [
    BoxShadow(
      color: Color(0x0A000000), // 4% 검정
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// 카드 호버 상태 그림자 (강조된 떠있는 느낌)
  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x14000000), // 8% 검정
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A2196F3), // 10% Primary 색상
      offset: Offset(0, 12),
      blurRadius: 30,
      spreadRadius: -5,
    ),
  ];

  /// 카드 선택 상태 그림자 (더 강조된 느낌)
  static const List<BoxShadow> cardSelected = [
    BoxShadow(
      color: Color(0x1A000000), // 10% 검정
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x332196F3), // 20% Primary 색상
      offset: Offset(0, 14),
      blurRadius: 32,
      spreadRadius: -5,
    ),
  ];

  /// 플로팅 버튼 그림자 (강한 강조)
  static const List<BoxShadow> floatingButton = [
    BoxShadow(
      color: Color(0x26000000), // 15% 검정
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A2196F3), // 10% Primary
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  /// 모달/다이얼로그 그림자 (깊이감)
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x33000000), // 20% 검정
      offset: Offset(0, 16),
      blurRadius: 48,
      spreadRadius: -8,
    ),
  ];
}

/// 애니메이션 Duration 및 Curve
/// 모던 플랫폼 스타일의 부드러운 애니메이션 설정을 포함합니다.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);

  // ============= 인터랙티브 애니메이션 Duration =============

  /// 카드 호버 애니메이션 (부드럽고 빠름)
  static const Duration hoverCard = Duration(milliseconds: 300);

  /// 리스트 아이템 애니메이션
  static const Duration listItem = Duration(milliseconds: 250);

  /// 페이지 전환 애니메이션
  static const Duration pageTransition = Duration(milliseconds: 400);

  /// 모달/다이얼로그 등장 애니메이션
  static const Duration modal = Duration(milliseconds: 350);
}

class AppCurves {
  AppCurves._();

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve snappy = Curves.easeOutQuart;
  static const Curve bounce = Curves.bounceOut;

  // ============= 인터랙티브 애니메이션 Curve =============

  /// 카드 호버 커브 (부드러운 감속)
  static const Curve hoverCard = Curves.easeOutCubic;

  /// 리스트 아이템 커브
  static const Curve listItem = Curves.easeOutQuart;

  /// 페이지 전환 커브
  static const Curve pageTransition = Curves.easeInOutCubic;

  /// 모달 등장 커브
  static const Curve modal = Curves.easeOutQuart;
}

/// Border 시스템
class AppBorders {
  AppBorders._();

  static const BorderSide thin = BorderSide(
    color: AppColors.border,
    width: 1,
  );

  static const BorderSide medium = BorderSide(
    color: AppColors.border,
    width: 2,
  );

  static const BorderSide thick = BorderSide(
    color: AppColors.border,
    width: 3,
  );

  // Primary border
  static const BorderSide primary = BorderSide(
    color: AppColors.primary500,
    width: 2,
  );

  // Error border
  static const BorderSide error = BorderSide(
    color: AppColors.error500,
    width: 2,
  );
}

/// 반응형 브레이크포인트
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 960;
  static const double desktop = 1280;

  /// 현재 화면 크기가 모바일인지 확인
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// 현재 화면 크기가 태블릿인지 확인
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// 현재 화면 크기가 데스크톱인지 확인
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// 화면 크기에 따른 패딩 반환
  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return AppSpacing.md;
    if (isTablet(context)) return AppSpacing.lg;
    return AppSpacing.xl;
  }

  /// 화면 크기에 따른 컬럼 수 반환
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}

/// 공통 사이즈
class AppSizes {
  AppSizes._();

  // Button heights
  static const double buttonHeightSm = 36;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;

  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // Avatar sizes
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double avatarXl = 96;

  // Input heights
  static const double inputHeightSm = 40;
  static const double inputHeightMd = 48;
  static const double inputHeightLg = 56;

  // App bar height
  static const double appBarHeight = 56;

  // Bottom navigation bar height
  static const double bottomNavHeight = 64;

  // Minimum touch target (접근성)
  static const double minTouchTarget = 48;
}
