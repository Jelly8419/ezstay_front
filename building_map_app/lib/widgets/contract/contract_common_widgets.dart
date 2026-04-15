import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 안내사항 컨테이너 (Yellow 스타일)
///
/// Guest/Host 계약 상세 페이지에서 공통으로 사용하는 안내사항 박스입니다.
class NoticeContainer extends StatelessWidget {
  final List<String> notices;

  const NoticeContainer({
    super.key,
    required this.notices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8), // bg-yellow-50
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFDE68A), // border-yellow-200
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notices.map((text) => NoticeBulletText(text: text)).toList(),
      ),
    );
  }
}

/// 안내사항 불릿 텍스트 (yellow 스타일)
class NoticeBulletText extends StatelessWidget {
  final String text;

  const NoticeBulletText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF92400E), // text-yellow-800
          height: 1.625,
        ),
      ),
    );
  }
}

/// 일반 불릿 텍스트 (gray 스타일)
class BulletText extends StatelessWidget {
  final String text;

  const BulletText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 계약 상세 카드 래퍼
///
/// 계약 상세 페이지 각 섹션의 카드 스타일을 통일합니다.
class ContractDetailCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ContractDetailCard({
    super.key,
    required this.child,
    this.padding,
  });

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: cardShadow,
      ),
      child: child,
    );
  }
}
