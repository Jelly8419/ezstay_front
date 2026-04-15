import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_util.dart';

/// 방 정보 섹션 (사진 + 계약 정보, 모바일 반응형)
class ContractRoomInfoSection extends StatelessWidget {
  final ContractListItem contract;
  final bool showChatButton;

  const ContractRoomInfoSection({
    super.key,
    required this.contract,
    required this.showChatButton,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomImage(width: double.infinity, height: 192),
          const SizedBox(height: 16),
          _ContractInfoColumn(
            contract: contract,
            showChatButton: showChatButton,
            isMobile: true,
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomImage(width: 140, height: 140),
          const SizedBox(width: 16),
          Expanded(
            child: _ContractInfoColumn(
              contract: contract,
              showChatButton: showChatButton,
              isMobile: false,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRoomImage({required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: contract.roomThumbnail != null
          ? Image.network(
              ContractUtils.getFullImageUrl(contract.roomThumbnail),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.home, size: 40),
                );
              },
            )
          : Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.home, size: 40),
            ),
    );
  }
}

/// 계약 정보 컬럼 (내부 위젯)
class _ContractInfoColumn extends StatelessWidget {
  final ContractListItem contract;
  final bool showChatButton;
  final bool isMobile;

  const _ContractInfoColumn({
    required this.contract,
    required this.showChatButton,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contract.roomName,
          style: AppTextStyles.headingMedium.copyWith(
            color: const Color(0xFF111827),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 8),
        _InfoRow(label: '주소', value: contract.roomAddress, isMobile: isMobile),
        SizedBox(height: isMobile ? 12 : 4),
        _InfoRow(
          label: '계약 기간',
          value:
              '${FormatUtils.formatDate(contract.checkInDate)} - ${FormatUtils.formatDate(contract.checkOutDate)} (${contract.totalDays}일)',
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 4),
        _InfoRow(
          label: '결제 금액',
          value: '₩${FormatUtils.formatCurrency(contract.finalTotalAmount)}',
          isMobile: isMobile,
          valueStyle: AppTextStyles.labelLarge.copyWith(
            color: const Color(0xFF111827),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 4),
        _HostRow(
          contract: contract,
          showChatButton: showChatButton,
          isMobile: isMobile,
        ),
      ],
    );
  }
}

/// 호스트 행 (채팅 버튼 포함)
class _HostRow extends StatelessWidget {
  final ContractListItem contract;
  final bool showChatButton;
  final bool isMobile;

  const _HostRow({
    required this.contract,
    required this.showChatButton,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      '임대인',
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
      ),
    );

    final valueWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          contract.partnerDisplayName,
          style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF111827)),
        ),
        if (showChatButton) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              context.go('/chat-list?contractId=${contract.id}');
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary600,
              size: 18,
            ),
          ),
        ],
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [labelWidget, const SizedBox(height: 4), valueWidget],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: labelWidget),
          Flexible(child: valueWidget),
        ],
      );
    }
  }
}

/// 정보 행 (모바일 반응형)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool isMobile;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
      ),
    );

    final valueWidget = Text(
      value,
      style: valueStyle ?? AppTextStyles.labelLarge.copyWith(color: const Color(0xFF000000)),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [labelWidget, const SizedBox(height: 4), valueWidget],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: labelWidget),
          Expanded(child: valueWidget),
        ],
      );
    }
  }
}
