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
  static const cardRadius = 16.0;
  static const cardElevation = 4.0;

  // 애니메이션
  static const defaultAnimationDuration = Duration(milliseconds: 300);
}
