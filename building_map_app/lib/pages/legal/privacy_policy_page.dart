import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 개인정보 처리방침 페이지
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이지스테이 개인정보처리방침',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildArticle1(),
                  _buildArticle(
                    '제2조 (개인정보의 이용 목적)',
                    null,
                    items: [
                      '회원 관리: 본인 식별, 미성년자 가입 차단, 부정 이용 방지',
                      '서비스 제공: 단기임대 예약·결제, 보증금 반환, 옵션 상품 배송, 정산 처리',
                      '민원 처리: 계약 분쟁 조정, 문의 사항 응대',
                    ],
                  ),
                  _buildArticle3(),
                  _buildArticle4(),
                  _buildArticle5(),
                  _buildArticle(
                    '제6조 (개인정보의 안전성 확보 조치)',
                    '회사는 개인정보보호법에 따라 안전성 확보에 필요한 기술적, 관리적 조치를 다하고 있습니다.',
                    items: [
                      '중요 데이터(비밀번호 등)의 암호화 저장 및 전송',
                      '개인정보 접근 권한의 최소화 및 접근 통제 시스템 운영',
                      '해킹, 컴퓨터 바이러스 등에 대비한 보안 프로그램 설치',
                    ],
                  ),
                  _buildArticle(
                    '제7조 (이용자의 권리와 행사 방법)',
                    '회원은 언제든지 자신의 개인정보를 열람, 수정, 가입 해지(탈퇴) 요청을 할 수 있으며, 개인정보 보호책임자에게 이메일로 연락하여 권리를 행사할 수 있습니다.',
                  ),
                  _buildArticle8(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 일반 조항 빌더
  Widget _buildArticle(
    String title,
    String? body, {
    List<String>? items,
  }) {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          if (body != null) Text(body, style: textStyle),
          if (items != null)
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${entry.key + 1}.', style: textStyle),
                    ),
                    Expanded(child: Text(entry.value, style: textStyle)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// 제1조 - 수집 항목 및 방법
  Widget _buildArticle1() {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제1조 (개인정보의 수집 항목 및 방법)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '회사는 원활한 서비스 제공을 위해 최소한의 개인정보를 수집합니다.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(textStyle, '1.', '회원가입 시: 이름, 휴대전화 번호, 이메일, 비밀번호, 본인인증 연계정보(CI/DI)'),
          _buildInfoRow(textStyle, '2.', '예약/결제 시: 신용카드 정보, 은행 계좌 번호, 체류 목적'),
          _buildInfoRow(textStyle, '3.', '호스트 등록 시: 신분증 또는 사업자등록증 사본, 공간 주소 정보'),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              '수집 방법: 서비스 화면 내 입력, 본인인증 기관을 통한 수집 등',
              style: textStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  /// 제3조 - 보관 및 파기
  Widget _buildArticle3() {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제3조 (개인정보의 보관 및 파기)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '회사는 회원의 탈퇴 등 수집 목적이 달성된 후 지체 없이 파기합니다. 단, 다음의 정보는 법령에 따라 명시된 기간 동안 보관합니다.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(textStyle, '1.', '대금 결제 및 재화 등의 공급에 관한 기록: 5년'),
          _buildInfoRow(textStyle, '2.', '계약 또는 청약철회 등에 관한 기록: 5년'),
          _buildInfoRow(textStyle, '3.', '소비자의 불만 또는 분쟁처리에 관한 기록: 3년'),
          _buildInfoRow(textStyle, '4.', '서비스 접속 로그 기록: 3개월'),
        ],
      ),
    );
  }

  /// 제4조 - 제3자 제공
  Widget _buildArticle4() {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제4조 (개인정보의 제3자 제공)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '회사는 원활한 임대차 계약 이행을 위하여 필수적인 정보만을 양 당사자에게 교차 제공합니다.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildLabeledRow(textStyle, '제공받는 자', '예약이 성립된 계약의 상대방 (호스트 ↔ 게스트)'),
          _buildLabeledRow(textStyle, '제공 목적', '원활한 입퇴실, 옵션 상품 이용 안내 및 상호 연락'),
          _buildLabeledRow(textStyle, '제공 항목', '이름, 휴대전화 번호'),
          _buildLabeledRow(textStyle, '보유 및 이용 기간', '계약 종료(정산 완료) 후 1년'),
        ],
      ),
    );
  }

  /// 제5조 - 처리 위탁
  Widget _buildArticle5() {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제5조 (개인정보 처리의 위탁)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '회사는 안정적인 서비스 제공을 위해 다음의 전문업체에 개인정보 처리를 위탁하고 있습니다.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(textStyle, '1.', '결제 대행 및 처리'),
          _buildInfoRow(textStyle, '2.', '한국모바일인증(주) 및 이통 3사: 휴대폰 본인인증'),
          _buildInfoRow(textStyle, '3.', '알리고(주): 알림톡 및 안내 메시지 발송'),
          _buildInfoRow(textStyle, '4.', 'Amazon Web Services (AWS): 클라우드 서버 호스팅 및 데이터 보관'),
        ],
      ),
    );
  }

  /// 제8조 - 보호책임자
  Widget _buildArticle8() {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );
    final boldStyle = textStyle.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제8조 (개인정보 보호책임자)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '회사는 개인정보 관련 문의 및 불만 처리를 위하여 아래와 같이 책임자를 지정하고 있습니다.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('개인정보 보호책임자: 박재민 (대표)', style: boldStyle),
                const SizedBox(height: AppSpacing.xs),
                Text('연락처/이메일: ezstay.kr@gmail.com', style: textStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(TextStyle style, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text(number, style: style)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }

  Widget _buildLabeledRow(TextStyle style, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('- ', style: style),
          Text(
            '$label: ',
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
