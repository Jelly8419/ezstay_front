import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/contract.dart' show DepositStatus;
import '../../models/contract_detail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 계약 상태별 안내 배너 (게스트/호스트 공용)
///
/// 정책:
/// - PENDING_APPROVAL → 호스트 승인 대기 (72시간 기한)
/// - APPROVED → 결제 기한 24시간 카운트다운
/// - PAYMENT_COMPLETED → 결제 완료, 입주일 안내
/// - IN_PROGRESS → 임대 중, 퇴실일 안내
/// - COMPLETED → 계약 정상 종료
/// - 만료/취소 → 기한 만료 또는 취소 안내
class ContractStatusBanner extends StatefulWidget {
  final ContractDetail contract;
  final bool isHost;

  const ContractStatusBanner({
    super.key,
    required this.contract,
    this.isHost = false,
  });

  @override
  State<ContractStatusBanner> createState() => _ContractStatusBannerState();
}

class _ContractStatusBannerState extends State<ContractStatusBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ContractStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contract.status != widget.contract.status) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    final status = widget.contract.status;
    DateTime? deadline;

    if (status == 'APPROVED' && widget.contract.approvedAt != null) {
      // 결제 기한: 기본 승인 시각 + 24시간
      final approvedAt = DateTime.tryParse(widget.contract.approvedAt!);
      if (approvedAt != null) {
        final defaultDeadline = approvedAt.add(const Duration(hours: 24));

        // 정책 3.14.2: 승인 시점이 입주일 또는 다음날 입주일인 경우,
        // 입주일 입실 시간에 자동 마감 처리
        final checkInDate = DateTime.tryParse(widget.contract.checkInDate);
        if (checkInDate != null) {
          final approvedDateOnly = DateTime(approvedAt.year, approvedAt.month, approvedAt.day);
          final checkInDateOnly = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
          final daysDiff = checkInDateOnly.difference(approvedDateOnly).inDays;

          if (daysDiff <= 1 && daysDiff >= 0) {
            // 입주일이 오늘 또는 내일 → 입주일 입실시간이 마감
            final checkInTimeStr = widget.contract.roomCheckInTime ?? '15:00';
            final timeParts = checkInTimeStr.split(':');
            final checkInHour = int.tryParse(timeParts[0]) ?? 15;
            final checkInMinute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
            final checkInDeadline = DateTime(
              checkInDate.year, checkInDate.month, checkInDate.day,
              checkInHour, checkInMinute,
            );
            // 입실시간 마감과 기본 24h 마감 중 더 이른 것 적용
            deadline = checkInDeadline.isBefore(defaultDeadline) ? checkInDeadline : defaultDeadline;
          } else {
            deadline = defaultDeadline;
          }
        } else {
          deadline = defaultDeadline;
        }
      }
    } else if (status == 'PENDING_APPROVAL') {
      // 승인 기한: 요청 시각 + 72시간
      final requestedAt = DateTime.tryParse(
        widget.contract.requestedAt ?? widget.contract.createdAt,
      );
      if (requestedAt != null) {
        deadline = requestedAt.add(const Duration(hours: 72));
      }
    }

    if (deadline != null) {
      _remaining = deadline.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining = deadline!.difference(DateTime.now());
          if (_remaining.isNegative) {
            _remaining = Duration.zero;
            _timer?.cancel();
          }
        });
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final config = _getBannerConfig();
    if (config == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: config.textColor,
                  ),
                ),
                if (config.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: config.subtitleColor ?? config.textColor,
                    ),
                  ),
                ],
                if (config.showTimer) ...[
                  const SizedBox(height: 8),
                  _buildTimer(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final isUrgent = _remaining.inHours < 2;
    final timerColor = isUrgent ? AppColors.error500 : AppColors.primary500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.error500.withValues(alpha: 0.1)
            : AppColors.primary500.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        '남은 시간: ${_formatDuration(_remaining)}',
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: timerColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  _BannerConfig? _getBannerConfig() {
    final status = widget.contract.status;
    final isHost = widget.isHost;

    switch (status) {
      case 'PENDING_APPROVAL':
        return _BannerConfig(
          icon: Icons.schedule,
          title: isHost
              ? '임차인의 계약 요청이 도착했습니다'
              : '임대인의 승인을 기다리고 있습니다',
          subtitle: isHost
              ? '기한 내 승인 또는 거절해주세요'
              : '임대인이 72시간 내 응답하지 않으면 자동 만료됩니다',
          bgColor: const Color(0xFFFFFBEB), // yellow-50
          borderColor: const Color(0xFFFDE68A), // yellow-200
          iconColor: const Color(0xFFD97706), // yellow-600
          textColor: const Color(0xFF92400E), // yellow-800
          showTimer: true,
        );

      case 'APPROVED':
        return _BannerConfig(
          icon: Icons.payment,
          title: isHost
              ? '임차인의 결제를 기다리고 있습니다'
              : '24시간 내 결제를 완료해주세요',
          subtitle: isHost
              ? '임차인이 24시간 내 결제하지 않으면 자동 만료됩니다'
              : '기한 내 결제하지 않으면 계약이 자동 만료됩니다',
          bgColor: const Color(0xFFEFF6FF), // blue-50
          borderColor: const Color(0xFFBFDBFE), // blue-200
          iconColor: const Color(0xFF2563EB), // blue-600
          textColor: const Color(0xFF1E40AF), // blue-800
          showTimer: !isHost,
        );

      case 'PAYMENT_COMPLETED':
        final checkIn = DateTime.parse(widget.contract.checkInDate);
        final isPm = checkIn.hour >= 12;
        final hour12 = checkIn.hour % 12 == 0 ? 12 : checkIn.hour % 12;
        final minute = checkIn.minute.toString().padLeft(2, '0');
        final amPm = isPm ? '오후' : '오전';
        final checkInFormatted =
            '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')} $amPm ${hour12}시${minute}분';
        return _BannerConfig(
          icon: Icons.check_circle,
          title: '결제가 완료되었습니다',
          subtitle: '입주일: $checkInFormatted',
          bgColor: const Color(0xFFF0FDF4), // green-50
          borderColor: const Color(0xFFBBF7D0), // green-200
          iconColor: const Color(0xFF16A34A), // green-600
          textColor: const Color(0xFF166534), // green-800
          showTimer: false,
        );

      case 'IN_PROGRESS':
        final checkOut = widget.contract.checkOutDate;
        // 정책 7.12: 관리자 강제 반환보류 시 경고 표시
        if (widget.contract.depositStatus == DepositStatus.returnHold) {
          return _BannerConfig(
            icon: Icons.warning_amber,
            title: '보증금 반환이 보류 중입니다',
            subtitle: '퇴실일: $checkOut · 관리자 또는 임대인에 의해 보증금 반환이 보류되었습니다',
            bgColor: const Color(0xFFFFF7ED), // orange-50
            borderColor: const Color(0xFFFED7AA), // orange-200
            iconColor: const Color(0xFFF97316), // orange-500
            textColor: const Color(0xFF9A3412), // orange-800
            showTimer: false,
          );
        }
        return _BannerConfig(
          icon: Icons.home,
          title: '현재 임대 중입니다',
          subtitle: '퇴실일: $checkOut',
          bgColor: const Color(0xFFEFF6FF), // blue-50
          borderColor: const Color(0xFFBFDBFE), // blue-200
          iconColor: const Color(0xFF2563EB), // blue-600
          textColor: const Color(0xFF1E40AF), // blue-800
          showTimer: false,
        );

      case 'COMPLETED':
        return _BannerConfig(
          icon: Icons.verified,
          title: '계약이 정상 종료되었습니다',
          subtitle: widget.contract.depositStatus == DepositStatus.returned
              ? '보증금이 반환되었습니다'
              : widget.contract.depositStatus == DepositStatus.returnPending
                  ? '보증금 반환이 진행 중입니다'
                  : widget.contract.depositStatus == DepositStatus.deductionConfirmed
                      ? '보증금 차감이 확정되었습니다'
                      : widget.contract.depositStatus == DepositStatus.returnConfirmed
                          ? '보증금 반환이 확정되었습니다'
                          : widget.contract.depositStatus == DepositStatus.returnHold
                              ? '보증금 반환이 보류 중입니다'
                              : null,
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          iconColor: AppColors.gray600,
          textColor: AppColors.gray900,
          showTimer: false,
        );

      case 'APPROVAL_EXPIRED':
      case 'PAYMENT_EXPIRED':
        return _BannerConfig(
          icon: Icons.timer_off,
          title: '기한 만료로 계약이 취소되었습니다',
          subtitle: status == 'APPROVAL_EXPIRED'
              ? '임대인이 기한 내 응답하지 않았습니다'
              : '결제 기한이 만료되었습니다',
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          iconColor: AppColors.gray600,
          textColor: AppColors.gray900,
          showTimer: false,
        );

      case 'REJECTED':
        return _BannerConfig(
          icon: Icons.cancel,
          title: '임대인이 계약 요청을 거절했습니다',
          subtitle: null,
          bgColor: const Color(0xFFFEF2F2), // red-50
          borderColor: const Color(0xFFFECACA), // red-200
          iconColor: AppColors.error500,
          textColor: const Color(0xFF991B1B), // red-800
          showTimer: false,
        );

      case 'CANCELLED_BY_GUEST':
      case 'CANCELLED_BY_HOST':
        return _BannerConfig(
          icon: Icons.cancel,
          title: status == 'CANCELLED_BY_GUEST'
              ? '임차인이 계약을 취소했습니다'
              : '임대인이 계약을 취소했습니다',
          subtitle: null,
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          iconColor: AppColors.gray600,
          textColor: AppColors.gray900,
          showTimer: false,
        );

      case 'REFUNDED':
        return _BannerConfig(
          icon: Icons.receipt_long,
          title: '환불이 완료되었습니다',
          subtitle: null,
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          iconColor: AppColors.gray600,
          textColor: AppColors.gray900,
          showTimer: false,
        );

      default:
        return null;
    }
  }
}

class _BannerConfig {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color? subtitleColor;
  final bool showTimer;

  const _BannerConfig({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    this.subtitleColor,
    required this.showTimer,
  });
}
