import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 이용약관 페이지
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
                    '이지스테이 서비스 이용약관',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildArticle(
                    '제1조 (목적)',
                    '본 약관은 이지스테이(이하 "회사")가 제공하는 단기임대 계약 플랫폼 및 관련 제반 서비스(이하 "서비스")의 이용과 관련하여 회사와 회원 간의 권리, 의무, 책임 사항 및 기타 필요한 사항을 규정함을 목적으로 합니다.',
                  ),
                  _buildArticle(
                    '제2조 (용어의 정의)',
                    null,
                    items: [
                      '"서비스"란 회사가 회원들에게 제공하는 공간 정보 제공, 단기임대차 계약 체결 중개, 옵션 상품 판매 및 결제 시스템 등 모든 온·오프라인 서비스를 의미합니다.',
                      '"회원"이란 본 약관에 동의하고 회사와 이용계약을 체결한 자로, \'임차인\'과 \'임대인\'으로 구분됩니다.',
                      '"임차인"이란 공간 및 옵션 상품을 예약하고 결제하여 이용하는 회원을 말합니다.',
                      '"임대인"이란 자신의 공간 정보를 등록하고 임차인에게 공간을 제공하는 회원을 말합니다.',
                      '"옵션 상품"이란 임차인이 단기 거주 편의를 위해 공간과 함께 선택하여 구매 또는 대여하는 침구류, 생활 비품 등을 말합니다.',
                      '"보증금"이란 공간 및 옵션 파손 등에 대비하여 회사가 계약 기간 동안 예치하는 금액을 말합니다.',
                    ],
                  ),
                  _buildArticle(
                    '제3조 (약관의 명시, 효력 및 변경)',
                    null,
                    items: [
                      '회사는 본 약관을 서비스 초기 화면에 게시하여 회원이 쉽게 확인할 수 있도록 합니다.',
                      '회사는 관련 법령을 위배하지 않는 범위에서 약관을 개정할 수 있으며, 개정 시 적용일 7일 전(회원에게 불리한 변경은 30일 전)에 공지합니다.',
                    ],
                  ),
                  _buildArticle(
                    '제4조 (회원가입 및 계정 관리)',
                    null,
                    items: [
                      '안전한 임대차 계약을 위하여 만 19세 미만의 미성년자는 회원가입 및 서비스 이용이 불가합니다. (본인인증을 통한 차단)',
                      '회원의 아이디와 비밀번호 관리에 대한 책임은 회원 본인에게 있으며, 제3자에게 공유 또는 양도하여 발생한 손해는 회사가 책임지지 않습니다.',
                      '회원은 가입 시 기재한 정보(연락처 등)가 변경된 경우 즉시 수정해야 하며, 이를 소홀히 하여 발생한 불이익(회사의 중요 통지 누락 등)은 회원 본인이 부담합니다.',
                    ],
                  ),
                  _buildArticle(
                    '제5조 (개인정보보호 의무)',
                    null,
                    items: [
                      '회사는 「정보통신망 이용촉진 및 정보보호 등에 관한 법률」, 「개인정보 보호법」 등 관련 법령이 정하는 바에 따라 회원의 개인정보를 보호하기 위해 노력합니다.',
                      '개인정보의 보호 및 사용에 대해서는 관련 법령 및 회사의 \'개인정보처리방침\'이 적용됩니다.',
                      '회사가 제공하는 공식 서비스 이외의 외부 링크된 사이트에서는 회사의 개인정보처리방침이 적용되지 않습니다.',
                      '회원이 고의 또는 과실로 자신의 개인정보를 유출하거나 타인에게 제공하여 발생한 피해에 대하여 회사는 일절 책임을 지지 않습니다.',
                    ],
                  ),
                  _buildArticle(
                    '제6조 (회사의 의무)',
                    null,
                    items: [
                      '회사는 관련 법령과 공서양속에 반하는 행위를 하지 않으며, 안정적인 서비스 제공을 위해 최선을 다합니다.',
                      '회사는 컴퓨터 등 정보통신설비의 점검, 고장, 통신두절 등의 사유가 발생한 경우 서비스 제공을 일시적으로 중단할 수 있습니다.',
                      '회사는 분쟁 조정, 민원 처리, 불법 행위 조사를 위해 서비스 내의 회원 간 통신(채팅) 내용을 열람 및 보관할 수 있습니다.',
                    ],
                  ),
                  _buildArticle(
                    '제7조 (회원의 의무 및 이용 제한)',
                    null,
                    items: [
                      '회원은 다음 행위를 하여서는 안 되며, 위반 시 회사는 사전 통보 없이 회원 자격 제한, 서비스 이용 정지, 강제 탈퇴 등의 제재를 가할 수 있습니다.',
                      '회원의 귀책사유로 강제 탈퇴 처리된 경우, 회사는 해당 회원의 재가입을 최대 5년간 제한할 수 있습니다.',
                    ],
                    subItems: {
                      0: [
                        '플랫폼 수수료 회피를 위해 당사자 간 직거래를 유도하거나 합의하는 행위',
                        '타인의 정보 도용, 허위 매물 등록, 허위 정보 작성 등',
                        '매크로, 스파이더 등 자동화 프로그램을 이용해 회사의 서버에 부하를 주거나 정보를 무단 수집하는 행위',
                        '욕설, 협박 등으로 임대인, 임차인 또는 회사 임직원의 업무를 방해하거나 명예를 훼손하는 행위',
                      ],
                    },
                  ),
                  _buildArticle(
                    '제8조 (이용요금 및 서비스 수수료)',
                    null,
                    items: [
                      '회사는 플랫폼 제공 및 안전 결제 환경 제공의 대가로 계약 체결 시 양 당사자에게 서비스 수수료를 부과할 수 있습니다.',
                      '구체적인 수수료율 및 부과 기준은 회사의 내부 운영정책에 따르며, 회원이 결제 전 명확히 인지할 수 있도록 서비스 결제 화면 또는 운영정책 공지를 통해 사전에 명시합니다.',
                      '회사는 프로모션 등에 따라 한시적 또는 특정 조건 하에 수수료를 할인 및 면제할 수 있습니다.',
                    ],
                  ),
                  _buildArticle(
                    '제9조 (계약 및 결제)',
                    null,
                    items: [
                      '계약은 임차인이 임대 공간 및 옵션 상품을 선택하고 결제를 완료함과 동시에 성립됩니다.',
                      '회사 시스템을 통하지 않은 외부 직거래(계좌이체, 현금 송금 등)로 인해 발생한 문제에 대해서는 회사가 어떠한 개입 및 책임도 지지 않습니다.',
                    ],
                  ),
                  _buildArticle10(),
                  _buildArticle(
                    '제11조 (보증금 반환 및 분쟁 조정)',
                    null,
                    items: [
                      '보증금은 임차인 퇴실 후 임대인이 \'퇴실 확인\'을 완료하면 즉시 반환됩니다.',
                      '회사가 운영정책으로 정한 기간 내에 임대인의 퇴실 확인 처리가 없을 경우, 시스템에 의해 자동으로 퇴실이 확인되며 보증금은 전액 반환됩니다.',
                      '시설 훼손 등으로 임대인이 \'퇴실 확인 보류\'를 신청할 경우, 회사는 별도의 운영정책에서 정한 최대 보관 기간 동안만 보증금을 예치합니다. 해당 기간이 경과할 때까지 양측 합의가 성립되지 않으면, 회사는 보증금을 임차인에게 우선 자동 반환하며, 이후의 손해배상은 당사자 간 직접 해결하여야 합니다.',
                    ],
                  ),
                  _buildArticle(
                    '제12조 (임대인 정산)',
                    null,
                    items: [
                      '회사는 임차인이 결제한 총 임대료에서 회사의 서비스 수수료를 차감한 금액을 임대인에게 정산합니다.',
                      '정산금은 임차인의 정상적인 입주 후, 회사의 운영정책에서 별도로 정한 정산 주기에 따라 임대인의 계좌로 지급됩니다.',
                      '계약 취소 또는 임대인의 귀책사유로 정상적인 거주가 불가능했던 경우, 회사는 정산금 지급을 보류하거나 기지급된 금액의 환수를 요청할 수 있습니다.',
                    ],
                  ),
                  _buildArticle(
                    '제13조 (회사의 면책 / 통신판매중개자의 지위)',
                    null,
                    items: [
                      '회사는 통신판매중개자로서 회원 간의 편리한 거래를 위한 플랫폼을 제공할 뿐, 임대차 계약의 직접 당사자가 아닙니다. 따라서 공간의 상태, 적법성, 임차인의 신원 등에 대해 회사는 보증하지 않으며 법적 책임을 지지 않습니다.',
                      '회사는 천재지변, 디도스(DDoS) 공격, 기간통신사업자의 회선 장애 등 불가항력적 사유로 서비스가 중단된 경우 그 책임이 면제됩니다.',
                    ],
                  ),
                  _buildArticle(
                    '제14조 (정보의 제공 및 마케팅)',
                    '회사는 서비스 이용에 필수적인 공지, 예약·결제 내역 등을 알림톡, SMS, 이메일로 발송할 수 있으며, 마케팅 수신에 동의한 회원에 한하여 광고성 정보를 전송할 수 있습니다.',
                  ),
                  _buildArticle(
                    '제15조 (준거법 및 관할법원)',
                    '본 약관과 관련된 모든 분쟁은 대한민국 법률을 적용하며, 관할 법원은 민사소송법에 따릅니다.',
                  ),
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
    Map<int, List<String>>? subItems,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (body != null)
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
          if (items != null)
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${idx + 1}.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.7,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.7,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (subItems != null && subItems.containsKey(idx))
                    ...subItems[idx]!.map((sub) => Padding(
                          padding: const EdgeInsets.only(left: 24, top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '- ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  height: 1.7,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  sub,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    height: 1.7,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              );
            }),
        ],
      ),
    );
  }

  /// 제10조 - 구조가 복잡하므로 별도 빌더
  Widget _buildArticle10() {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      color: AppColors.textSecondary,
    );
    final subTitleStyle = AppTextStyles.bodyMedium.copyWith(
      height: 1.7,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제10조 (취소 및 환불 정책)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),

          // 1. 공간 임대료의 취소 및 환불
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('1. 공간 임대료의 취소 및 환불', style: subTitleStyle),
          ),
          _buildSubItem(textStyle, '① 계약 취소 시 환불 기준은 임대인이 해당 공간에 당시 설정한 \'개별 환불 정책\'을 최우선으로 적용합니다.'),
          _buildSubItem(textStyle, '② 임차인은 원칙적으로 입주일 이후에는 임의로 계약을 취소할 수 없습니다. 부득이한 사유로 입주 후 중도 퇴실 및 취소를 원할 경우에는 임대인과 별도로 계약 해지 및 환불 조건을 합의하여 환불 신청을 할 수 있습니다.'),
          _buildSubItem(textStyle, '③ 회사는 공간 임대료 환불 시, 임대인의 환불 규정에 따른 \'취소 위약금\' 및 회사의 \'서비스 수수료\'를 차감한 잔액을 임차인에게 환불 처리합니다. (단, 결제 수단에 따라 실제 환불 완료까지 영업일 기준 일정 시일이 추가 소요될 수 있습니다.)'),

          // 2. 호스트에 의한 계약 취소
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('2. 임대인에 의한 계약 취소 (페널티)', style: subTitleStyle),
          ),
          _buildSubItem(textStyle, '① 임대인의 개인적 사정, 이중 예약 등 부득이한 귀책사유로 계약 취소를 원할 경우, 임대인은 회사에 이를 즉시 통보하여야 합니다. 이 경우 임대인은 회사의 운영정책에 따라 임대인이 설정한 환불 정책에 따라 위약금을 지불할 책임이 있으며, 회사는 임대인에게 서비스 이용 제한 등의 페널티를 부과할 수 있습니다.'),

          // 3. 옵션 상품의 취소 및 환불
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('3. 옵션 상품(배송 상품)의 취소 및 환불', style: subTitleStyle),
          ),
          _buildSubItem(textStyle, '① 상품 배송 시작 전 취소: 결제 대금 전액 100% 환불'),
          _buildSubItem(textStyle, '② 상품 배송 시작 후 취소 (단순 변심): 왕복 배송비를 차감한 잔액 환불'),
          _buildSubItem(textStyle, '③ 상품 하자에 따른 환불: 상품의 불량, 오배송 등 내용이 표시·광고와 다르거나 하자가 있는 경우에는 관련 법령에 따라 사용 전후를 불문하고 전액 환불이 가능합니다.'),
        ],
      ),
    );
  }

  Widget _buildSubItem(TextStyle style, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Text(text, style: style),
    );
  }
}
