import 'package:flutter/material.dart';

/// 앱 전체의 컬러 시스템을 정의합니다.
///
/// 사용 예시:
/// ```dart
/// Container(
///   color: AppColors.primary500,
///   child: Text(
///     'Hello',
///     style: TextStyle(color: AppColors.neutral0),
///   ),
/// )
/// ```
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============= Primary Colors (메인 브랜드 컬러) =============
  /// EZStay 브랜드 컬러 - Material Blue (#2196F3)
  static const Color primary50 = Color(0xFFE3F2FD);   // --color-primary-light
  static const Color primary100 = Color(0xFFBBDEFB);  // Lighter blue
  static const Color primary200 = Color(0xFF90CAF9);  // Light blue
  static const Color primary300 = Color(0xFF64B5F6);  // Light-medium blue
  static const Color primary400 = Color(0xFF42A5F5);  // Medium blue
  static const Color primary500 = Color(0xFF2196F3);  // Main - --color-primary (브랜드 대표)
  static const Color primary600 = Color(0xFF1E88E5);  // Deeper blue
  static const Color primary700 = Color(0xFF1976D2);  // Dark blue - --color-primary-dark
  static const Color primary800 = Color(0xFF1565C0);  // Darker blue
  static const Color primary900 = Color(0xFF0D47A1);  // Darkest blue

  // ============= Secondary Colors (보조 컬러 - Wood Accent) =============
  /// 따뜻한 우디 계열 (검색 버튼, 포인트 컬러)
  static const Color secondary50 = Color(0xFFFAF3EB);
  static const Color secondary100 = Color(0xFFF0DFC8);
  static const Color secondary200 = Color(0xFFE4CBA5);
  static const Color secondary300 = Color(0xFFD4B088);
  static const Color secondary400 = Color(0xFFC49A6C); // Wood Accent (원본)
  static const Color secondary500 = Color(0xFFB08456); // Main
  static const Color secondary600 = Color(0xFF9A7048);
  static const Color secondary700 = Color(0xFF7A5A3A);
  static const Color secondary800 = Color(0xFF5E442C);
  static const Color secondary900 = Color(0xFF3A2A1C);

  // ============= Blue Colors (Material Blue) — DEPRECATED =============
  /// Material Blue 스타일 시스템 (primary와 동기화)
  ///
  /// ⚠️ Phase 2: blue 팔레트는 primary와 값이 동일하므로 deprecate.
  /// 신규 코드는 `AppColors.primaryXXX`를 사용할 것.
  /// 기존 참조는 Phase 3+에서 점진적으로 마이그레이션 예정.
  @Deprecated('Use AppColors.primary50 instead')
  static const Color blue50 = Color(0xFFE3F2FD);
  @Deprecated('Use AppColors.primary100 instead')
  static const Color blue100 = Color(0xFFBBDEFB);
  @Deprecated('Use AppColors.primary500 instead')
  static const Color blue500 = Color(0xFF2196F3);
  @Deprecated('Use AppColors.primary700 instead')
  static const Color blue600 = Color(0xFF1976D2); // 주의: primary700와 동일값
  @Deprecated('Use AppColors.primary800 instead')
  static const Color blue700 = Color(0xFF1565C0);
  @Deprecated('Use AppColors.primary900 instead')
  static const Color blue900 = Color(0xFF0D47A1);

  // ============= Green Colors (Host-specific) =============
  /// 호스트 전용 섹션 강조색
  static const Color green100 = Color(0xFFD1FAE5);
  static const Color green500 = Color(0xFF10B981);
  static const Color green600 = Color(0xFF059669);

  // ============= Purple Colors (Delivery service) =============
  /// 배송 서비스 차별화 색상
  static const Color purple50  = Color(0xFFF3E8FF);
  static const Color purple600 = Color(0xFF9333EA);

  // ============= Gray Colors (Neutral additions) =============
  /// 추가 중립 색상
  static const Color gray50   = Color(0xFFF8FAFE);  // --color-bg-light
  static const Color gray200  = Color(0xFFE5E7EB);  // --color-border
  static const Color gray300  = Color(0xFFD1D5DB);
  static const Color gray600  = Color(0xFF666666);  // --color-text-secondary
  static const Color gray900  = Color(0xFF1A1A1A);  // --color-text

  // ============= Neutral Colors (중립 컬러) =============
  /// 텍스트, 배경, 구분선 등
  static const Color neutral0 = Color(0xFFFFFFFF); // 흰색
  static const Color neutral50 = Color(0xFFFAFAFA); // 배경
  static const Color neutral100 = Color(0xFFF5F5F5); // 카드 배경
  static const Color neutral200 = Color(0xFFEEEEEE); // 구분선
  static const Color neutral300 = Color(0xFFE0E0E0); // Border
  static const Color neutral400 = Color(0xFFBDBDBD); // Disabled
  static const Color neutral500 = Color(0xFF9E9E9E); // Secondary text
  static const Color neutral600 = Color(0xFF757575); // Body text
  static const Color neutral700 = Color(0xFF616161); // Title
  static const Color neutral800 = Color(0xFF424242); // Heading
  static const Color neutral900 = Color(0xFF1A1A1A); // Primary text - --color-text
  static const Color neutral1000 = Color(0xFF000000); // 검정

  // ============= Semantic Colors (의미 색상) =============
  /// 성공
  static const Color success50 = Color(0xFFE8F5E9);
  static const Color success100 = Color(0xFFC8E6C9);
  static const Color success500 = Color(0xFF4CAF50);
  static const Color success600 = Color(0xFF43A047);
  static const Color success700 = Color(0xFF388E3C);

  /// 에러
  static const Color error50 = Color(0xFFFFEBEE);
  static const Color error500 = Color(0xFFF44336);
  static const Color error600 = Color(0xFFE53935);
  static const Color error700 = Color(0xFFD32F2F);

  /// 경고
  static const Color warning50 = Color(0xFFFFF8E1);
  static const Color warning500 = Color(0xFFFFC107);
  static const Color warning600 = Color(0xFFFFB300);
  static const Color warning700 = Color(0xFFFFA000);

  /// 정보 (primary와 동기화) — DEPRECATED
  ///
  /// ⚠️ Phase 2: info 팔레트는 primary와 값이 동일하므로 deprecate.
  /// 정보 표기가 필요한 경우에도 `AppColors.primaryXXX`로 통일.
  @Deprecated('Use AppColors.primary50 instead')
  static const Color info50 = Color(0xFFE3F2FD);
  @Deprecated('Use AppColors.primary500 instead')
  static const Color info500 = Color(0xFF2196F3);
  @Deprecated('Use AppColors.primary600 instead')
  static const Color info600 = Color(0xFF1E88E5);
  @Deprecated('Use AppColors.primary700 instead')
  static const Color info700 = Color(0xFF1976D2);

  // ============= Special Colors (특수 색상) =============
  /// 배지, 태그 등 특별한 용도
  static const Color badge = Color(0xFFE91E63); // 핑크 (새 매물)
  static const Color premium = Color(0xFFFFD700); // 골드 (프리미엄)
  static const Color verified = Color(0xFF2196F3); // 블루 (인증됨)
  static const Color discount = Color(0xFF9C27B0); // 퍼플 (할인)

  // ============= Common Usage (자주 쓰는 조합) =============
  /// 일반적으로 자주 사용되는 색상 조합

  // 배경
  static const Color background = neutral50;
  static const Color surface = neutral0;

  // 텍스트
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textDisabled = neutral400;
  static const Color textOnPrimary = neutral0;

  // Border & Divider
  static const Color border = gray200; // border 기본값 (#E0E7EA)
  static const Color divider = neutral200;

  // Overlay
  static const Color overlay = Color(0x80000000); // 50% 검정
  static const Color scrim = Color(0xCC000000); // 80% 검정

  // Shadow colors
  static const Color shadowLight = Color(0x0D000000); // 5% 검정
  static const Color shadowMedium = Color(0x1A000000); // 10% 검정
  static const Color shadowDark = Color(0x26000000); // 15% 검정
}

/// 색상 확장 메서드
extension ColorExtension on Color {
  /// 색상 어둡게 만들기
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// 색상 밝게 만들기
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
