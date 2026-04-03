import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';

/// 계약 정보 모달 — 기본 정보 섹션 (방 사진 + 계약번호 + 계약 기간)
class ContractInfoBasicSection extends StatelessWidget {
  final ContractDetail contract;
  final String userMode;

  const ContractInfoBasicSection({
    super.key,
    required this.contract,
    required this.userMode,
  });

  bool get _isPaymentConfirmed =>
      ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED'].contains(contract.status);

  String get _addressText {
    final address = contract.address;
    if (userMode == 'guest' &&
        (contract.status == 'PENDING_APPROVAL' || contract.status == 'APPROVED')) {
      return '$address ${contract.floor}';
    }
    return '$address ${contract.detailAddress}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기본 정보',
                  style: AppTextStyles.headingSmall.copyWith(color: AppColors.gray900),
                ),
                if (contract.orderId != null) ...[
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall,
                      children: [
                        TextSpan(
                          text: '계약번호: ',
                          style: TextStyle(color: AppColors.gray600),
                        ),
                        TextSpan(
                          text: contract.orderId,
                          style: TextStyle(
                            color: AppColors.blue600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            _ContractStatusBadge(status: contract.status, userMode: userMode),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: contract.roomPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ContractUtils.getFullImageUrl(contract.roomPhoto),
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => _imagePlaceholder(),
                      errorWidget: (ctx, url, error) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contract.roomName,
                    style: AppTextStyles.headingSmall.copyWith(color: AppColors.gray900),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: '주소', value: _addressText),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: '계약 기간',
                    value:
                        '${FormatUtils.formatDateWithDayString(contract.checkInDate)} - ${FormatUtils.formatDateWithDayString(contract.checkOutDate)} (${contract.totalDays}일)',
                  ),
                  if (contract.paidAt != null && _isPaymentConfirmed) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: '계약 확정',
                      value: FormatUtils.formatDateWithDayString(contract.paidAt!),
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 128,
        height: 128,
        color: AppColors.neutral200,
        child: const Icon(Icons.home, size: 40, color: AppColors.neutral400),
      );
}

/// 계약 상태 뱃지
class _ContractStatusBadge extends StatelessWidget {
  final String status;
  final String userMode;

  const _ContractStatusBadge({required this.status, required this.userMode});

  Color get _bgColor {
    switch (status) {
      case 'PENDING_APPROVAL':
        return const Color(0xFFFEF3C7);
      case 'APPROVED':
        return const Color(0xFFDBEAFE);
      case 'PAYMENT_COMPLETED':
        return const Color(0xFFD1FAE5);
      case 'IN_PROGRESS':
        return const Color(0xFFF3E8FF);
      case 'COMPLETED':
      case 'APPROVAL_EXPIRED':
      case 'PAYMENT_EXPIRED':
        return AppColors.neutral100;
      case 'REJECTED':
      case 'CANCELLED_BY_GUEST':
      case 'CANCELLED_BY_HOST':
      case 'CANCELLED_BY_ADMIN_WITH_REFUND':
      case 'CANCELLED_BY_ADMIN_NO_REFUND':
        return const Color(0xFFFEE2E2);
      case 'REFUNDED':
        return const Color(0xFFF3E8FF);
      case 'CANCEL_REQUESTED':
        return const Color(0xFFFFF7ED);
      default:
        return AppColors.neutral100;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'PENDING_APPROVAL':
        return const Color(0xFFA16207);
      case 'APPROVED':
        return const Color(0xFF1D4ED8);
      case 'PAYMENT_COMPLETED':
        return const Color(0xFF047857);
      case 'IN_PROGRESS':
        return const Color(0xFF7E22CE);
      case 'COMPLETED':
      case 'APPROVAL_EXPIRED':
      case 'PAYMENT_EXPIRED':
        return AppColors.neutral700;
      case 'REJECTED':
      case 'CANCELLED_BY_GUEST':
      case 'CANCELLED_BY_HOST':
      case 'CANCELLED_BY_ADMIN_WITH_REFUND':
      case 'CANCELLED_BY_ADMIN_NO_REFUND':
        return const Color(0xFFB91C1C);
      case 'REFUNDED':
        return const Color(0xFF7E22CE);
      case 'CANCEL_REQUESTED':
        return const Color(0xFFEA580C);
      default:
        return AppColors.neutral700;
    }
  }

  String get _label {
    switch (status) {
      case 'PENDING_APPROVAL':
        return '승인 대기';
      case 'APPROVED':
        return '결제 대기';
      case 'PAYMENT_COMPLETED':
        return '결제 완료';
      case 'IN_PROGRESS':
        return '임대 중';
      case 'COMPLETED':
        return '계약 종료';
      case 'REJECTED':
        return '거절됨';
      case 'CANCELLED_BY_GUEST':
        return userMode == 'guest' ? '계약 취소' : '게스트 취소';
      case 'CANCELLED_BY_HOST':
        return '호스트 취소';
      case 'CANCELLED_BY_ADMIN_WITH_REFUND':
        return '관리자 취소 (환불)';
      case 'CANCELLED_BY_ADMIN_NO_REFUND':
        return '관리자 취소';
      case 'REFUNDED':
        return '환불 완료';
      case 'APPROVAL_EXPIRED':
        return '미승인 만료';
      case 'PAYMENT_EXPIRED':
        return '미결제 만료';
      case 'CANCEL_REQUESTED':
        return '취소 요청';
      default:
        return '알 수 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        _label,
        style: AppTextStyles.bodySmall.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 레이블 + 값 행 (모달 내부 공용)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                AppTextStyles.bodySmall.copyWith(color: AppColors.gray900),
          ),
        ),
      ],
    );
  }
}
