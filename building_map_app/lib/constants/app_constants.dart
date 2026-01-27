import 'package:flutter/material.dart';

/// 앱 전역 상수
class AppConstants {
  // API 타임아웃
  static const apiTimeout = Duration(seconds: 10);
  static const imageUploadTimeout = Duration(seconds: 30);

  // 이미지 설정
  static const maxImageSize = 5 * 1024 * 1024; // 5MB
  static const maxImagesPerRoom = 10;

  // 레이아웃
  static const maxContentWidth = 1200.0;
  static const defaultPadding = 16.0;
  static const defaultRadius = 12.0;
  static const cardRadius = 16.0; // 카드 둥근 모서리
  static const cardElevation = 4.0; // 카드 그림자 높이

  // 애니메이션
  static const defaultAnimationDuration = Duration(milliseconds: 300);
}

/// 앱 색상
class AppColors {
  // 기본 색상
  static const primary = Color(0xFF4A90E2);
  static const accent = Color(0xFF4DB5BD);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);

  // Primary 색상 변형
  static const primary50 = Color(0xFFE3F2FD);
  static const primary100 = Color(0xFFBBDEFB);
  static const primary200 = Color(0xFF90CAF9);
  static const primary500 = Color(0xFF4A90E2);
  static const primary600 = Color(0xFF3B7AC7);

  // 텍스트 색상
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF6C7B7F);
  static const textHint = Color(0xFF95A1A6);

  // 상태 색상
  static const success = Color(0xFF2ECC71);
  static const error = Color(0xFFE74C3C);
  static const warning = Color(0xFFF39C12);
  static const info = Color(0xFF3498DB);

  // 회색 음영
  static final grey50 = Colors.grey[50]!;
  static final grey100 = Colors.grey[100]!;
  static final grey200 = Colors.grey[200]!;
  static final grey300 = Colors.grey[300]!;
  static final grey600 = Colors.grey[600]!;

  // 기타 유틸리티 색상
  static final border = Colors.grey[300]!;
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

/// 텍스트 스타일
class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyMediumBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const priceText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}

/// 앱 테마
class AppTheme {
  /// 라이트 테마 생성
  static ThemeData lightTheme() {
    return ThemeData(
      // Material 3 사용
      useMaterial3: true,

      // 색상 스킴
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.error,
      ),

      // 배경색
      scaffoldBackgroundColor: AppColors.background,

      // 카드 테마
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // 아웃라인 버튼 테마
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.button,
        ),
      ),

      // 텍스트 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button,
        ),
      ),

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: TextStyle(color: AppColors.textHint),
      ),

      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading3.copyWith(color: Colors.white),
      ),

      // 플로팅 액션 버튼 테마
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // 다이얼로그 테마
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        backgroundColor: Colors.white,
      ),

      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),

      // 칩 테마
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        deleteIconColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // 디바이더 테마
      dividerTheme: DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
        space: 1,
      ),

      // 아이콘 테마
      iconTheme: IconThemeData(color: AppColors.primary, size: 24),

      // 텍스트 테마
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        displaySmall: AppTextStyles.heading3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
      ),
    );
  }
}

/// 앱 Radius (둥근 모서리) 상수
class AppRadius {
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
}

/// 앱 Spacing (간격) 상수
class AppSpacing {
  static const EdgeInsets paddingXs = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSm = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLg = EdgeInsets.all(24.0);
  static const EdgeInsets paddingXl = EdgeInsets.all(32.0);

  // 수평/수직 패딩
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: 16.0,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: 16.0,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: 24.0,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: 24.0,
  );

  // SizedBox용 간격
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // 명시적 픽셀 값 (기존 코드 호환성)
  static const double space12 = 12.0;
  static const double space24 = 24.0;
}
