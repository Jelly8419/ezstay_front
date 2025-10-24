import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체의 타이포그래피 시스템을 정의합니다.
///
/// 사용 예시:
/// ```dart
/// Text(
///   '제목',
///   style: AppTextStyles.headingLarge,
/// )
/// ```
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // ============= Font Family =============
  static const String fontFamily = 'Pretendard';
  static const List<String> fontFamilyFallback = [
    'Apple SD Gothic Neo',
    'Roboto',
    'sans-serif',
  ];

  // ============= Display (화면 제목) =============
  /// 가장 큰 제목 (32px)
  /// 용도: 랜딩 페이지, 큰 헤더
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// 중간 크기 제목 (28px)
  /// 용도: 페이지 타이틀
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// 작은 제목 (24px)
  /// 용도: 섹션 타이틀
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  // ============= Heading (섹션 제목) =============
  /// 큰 헤딩 (22px)
  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.36,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  /// 중간 헤딩 (20px)
  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
  );

  /// 작은 헤딩 (18px)
  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
  );

  // ============= Body (본문) =============
  /// 큰 본문 (16px)
  /// 용도: 주요 본문 텍스트
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// 중간 본문 (14px)
  /// 용도: 일반 텍스트
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  /// 작은 본문 (12px)
  /// 용도: 보조 설명
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  // ============= Label (라벨) =============
  /// 큰 라벨 (16px)
  /// 용도: 버튼 텍스트, 강조 라벨
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// 중간 라벨 (14px)
  /// 용도: 폼 라벨, 탭 라벨
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  /// 작은 라벨 (12px)
  /// 용도: 작은 버튼, 배지
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  // ============= Caption (캡션) =============
  /// 캡션 (11px)
  /// 용도: 작은 설명, 힌트
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.36,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // ============= Common Usage (자주 쓰는 변형) =============

  // Primary colored text
  static TextStyle get displayLargePrimary =>
      displayLarge.copyWith(color: AppColors.primary700);
  static TextStyle get headingMediumPrimary =>
      headingMedium.copyWith(color: AppColors.primary700);

  // Secondary colored text
  static TextStyle get bodyMediumSecondary =>
      bodyMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodySmallSecondary =>
      bodySmall.copyWith(color: AppColors.textSecondary);

  // White text (for dark backgrounds)
  static TextStyle get headingLargeWhite =>
      headingLarge.copyWith(color: AppColors.neutral0);
  static TextStyle get bodyLargeWhite =>
      bodyLarge.copyWith(color: AppColors.neutral0);

  // Error text
  static TextStyle get bodySmallError =>
      bodySmall.copyWith(color: AppColors.error500);

  // Success text
  static TextStyle get bodySmallSuccess =>
      bodySmall.copyWith(color: AppColors.success500);

  // Price text (강조된 가격)
  static TextStyle get priceText => headingMedium.copyWith(
    fontWeight: FontWeight.w700,
    color: AppColors.primary700,
  );

  // Discount price text (할인 가격)
  static TextStyle get discountPriceText => bodyMedium.copyWith(
    decoration: TextDecoration.lineThrough,
    color: AppColors.neutral500,
  );

  // Button text
  static TextStyle get buttonText => labelLarge.copyWith(
    fontWeight: FontWeight.w600,
  );

  // Link text
  static TextStyle get linkText => bodyMedium.copyWith(
    color: AppColors.primary600,
    decoration: TextDecoration.underline,
  );
}
