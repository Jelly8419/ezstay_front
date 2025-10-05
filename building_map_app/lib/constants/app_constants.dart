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

  // 애니메이션
  static const defaultAnimationDuration = Duration(milliseconds: 300);
}

/// 앱 색상
class AppColors {
  // 기본 색상
  static const primary = Color(0xFF4A90E2);
  static const accent = Color(0xFF4DB5BD);
  static const background = Color(0xFFF5F5F5);

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

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
