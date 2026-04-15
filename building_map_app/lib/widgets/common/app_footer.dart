import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_text_styles.dart';

/// 공용 푸터 위젯
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  // ============= 색상 =============
  static const Color _bgColor = Color(0xFFF3F4F6);
  static const Color _textColor = Color(0xFF374151);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textLight = Color(0xFF6B7280);
  static const Color _blue600 = Color(0xFF2563EB);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _borderMedium = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 horizontal padding
    double horizontalPadding;
    if (screenWidth >= 1024) {
      horizontalPadding = 32;
    } else if (screenWidth >= 640) {
      horizontalPadding = 24;
    } else {
      horizontalPadding = 16;
    }

    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        border: Border(
          top: BorderSide(color: _borderLight, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerServiceSection(context),
                _buildBusinessInfoSection(context),
                _buildTermsSection(context),
                _buildDisclaimerSection(),
                _buildCopyrightSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 고객센터 섹션
  Widget _buildCustomerServiceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '고객센터',
              style: AppTextStyles.headingSmall.copyWith(
                color: _textDark,
                height: 1.0,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/support/inquiries/new'),
              child: Text(
                '문의하기 →',
                style: AppTextStyles.labelLarge.copyWith(
                  color: _blue600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사업자 정보 섹션
  Widget _buildBusinessInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '사업자 정보',
              style: AppTextStyles.labelLarge.copyWith(
                color: _textDark,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
          // 1행: 서비스명 | 대표자 | 사업자 등록번호
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _textColor,
                  height: 1.625,
                ),
                children: const [
                  TextSpan(
                    text: '이지스테이',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  TextSpan(text: '  |  '),
                  TextSpan(text: '대표자 : 박재민'),
                  TextSpan(text: '  |  '),
                  TextSpan(text: '사업자 등록번호 : 139-13-03547'),
                ],
              ),
            ),
          ),
          // 2행: 주소 | 이메일
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: _textColor,
                height: 1.625,
              ),
              children: [
                const TextSpan(text: '주소 : 경기도 하남시 미사강변중앙로198번길 35 우성르보아리버'),
                const TextSpan(text: '  |  '),
                const TextSpan(text: '이메일 : '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('mailto:ezstay.kr@gmail.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Text(
                        'ezstay.kr@gmail.com',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _blue600,
                          height: 1.625,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 이용약관 및 개인정보 처리방침
  Widget _buildTermsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _FooterLinkButton(
            label: '이용약관',
            onTap: () => launchUrl(Uri.parse('/terms.html'), webOnlyWindowName: '_blank'),
          ),
          _FooterLinkButton(
            label: '개인정보 처리방침',
            onTap: () => launchUrl(Uri.parse('/privacy.html'), webOnlyWindowName: '_blank'),
          ),
        ],
      ),
    );
  }

  /// 면책 조항
  Widget _buildDisclaimerSection() {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _borderMedium, width: 1),
        ),
      ),
      child: Text(
        '이지스테이는 일부 상품의 통신판매 중개자로서 통신판매의 당사자가 아닙니다. '
        '해당 상품, 상품정보, 거래에 관한 의무와 책임은 계약 당사자에게 있습니다.',
        style: AppTextStyles.bodySmall.copyWith(
          color: _textLight,
          height: 1.625,
        ),
      ),
    );
  }

  /// Copyright
  Widget _buildCopyrightSection() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _borderMedium, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          '© 2025 EZstay. All rights reserved.',
          style: AppTextStyles.bodySmall.copyWith(
            color: _textLight,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _FooterLinkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLinkButton({required this.label, required this.onTap});

  @override
  State<_FooterLinkButton> createState() => _FooterLinkButtonState();
}

class _FooterLinkButtonState extends State<_FooterLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: _hovered ? const Color(0xFF1565C0) : const Color(0xFF111827),
            height: 1.0,
            decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF1565C0),
          ),
        ),
      ),
    );
  }
}
