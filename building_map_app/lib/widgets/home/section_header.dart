import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 홈 섹션용 제목 + 부제 블록.
///
/// 크기는 화면 폭에 따라 자동 스케일된다.
///
/// 사용 예시:
/// ```dart
/// SectionHeader(
///   title: '이지스테이가 안전한 이유',
///   subtitle: '안심하고 거래할 수 있는 시스템을 제공합니다',
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.kicker,
    this.textAlign = TextAlign.center,
  });

  final String title;
  final String? subtitle;

  /// 제목 위에 표시되는 짧은 영문/라벨 텍스트 (선택).
  final String? kicker;

  /// 기본 center 정렬. 좌측 정렬이 필요한 경우 명시적으로 override.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (textAlign) {
      TextAlign.left => CrossAxisAlignment.start,
      TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };

    final titleFontSize = AppTextStyles.responsiveFontSize(
      context,
      mobile: 24,
      desktop: 32,
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (kicker != null) ...[
          Text(
            kicker!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary600,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            textAlign: textAlign,
          ),
          SizedBox(height: AppSpacing.xs),
        ],
        Text(
          title,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
