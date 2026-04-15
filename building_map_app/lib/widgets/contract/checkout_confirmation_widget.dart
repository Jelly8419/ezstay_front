import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/contract.dart' show DepositStatus;
import '../../models/contract_detail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 퇴실 확인 위젯
///
/// 정책:
/// - 퇴실일 이후 + IN_PROGRESS 상태에서 표시
/// - 게스트 퇴실 확인 → 호스트 퇴실 확인 → 계약 완료
/// - 호스트 미확인 시 48시간 후 자동 확정
class CheckoutConfirmationWidget extends StatefulWidget {
  final ContractDetail contract;
  final bool isHost;
  final VoidCallback? onGuestConfirm;
  final VoidCallback? onHostConfirm;
  final VoidCallback? onHostHold; // 정책 7.6.2: 호스트 퇴실확인 보류 신청

  const CheckoutConfirmationWidget({
    super.key,
    required this.contract,
    required this.isHost,
    this.onGuestConfirm,
    this.onHostConfirm,
    this.onHostHold,
  });

  @override
  State<CheckoutConfirmationWidget> createState() =>
      _CheckoutConfirmationWidgetState();
}

class _CheckoutConfirmationWidgetState
    extends State<CheckoutConfirmationWidget> {
  Timer? _guestAutoCheckoutTimer;
  Timer? _hostAutoConfirmTimer;
  Duration _guestAutoCheckoutRemaining = Duration.zero;
  Duration _hostAutoConfirmRemaining = Duration.zero;

  bool get _guestConfirmed =>
      widget.contract.guestCheckoutConfirmedAt != null;

  bool get _hostConfirmed =>
      widget.contract.hostCheckoutConfirmedAt != null;

  @override
  void initState() {
    super.initState();
    _startGuestAutoCheckoutTimer();
    _startHostAutoConfirmTimer();
  }

  @override
  void dispose() {
    _guestAutoCheckoutTimer?.cancel();
    _hostAutoConfirmTimer?.cancel();
    super.dispose();
  }

  /// 정책 7.6.1: 게스트 자동 퇴실완료 타이머 (퇴실시간 + 48h)
  void _startGuestAutoCheckoutTimer() {
    if (_guestConfirmed) return;

    // 퇴실일 + 퇴실시간 계산
    final checkOutDate = DateTime.tryParse(widget.contract.checkOutDate);
    if (checkOutDate == null) return;

    DateTime checkoutDateTime = checkOutDate;
    final checkoutTime = widget.contract.roomCheckoutTime;
    if (checkoutTime != null && checkoutTime.contains(':')) {
      final parts = checkoutTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      checkoutDateTime = DateTime(
        checkOutDate.year, checkOutDate.month, checkOutDate.day,
        hour, minute,
      );
    }

    final autoCheckoutDeadline = checkoutDateTime.add(
      const Duration(hours: 48),
    );

    _guestAutoCheckoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _guestAutoCheckoutRemaining = autoCheckoutDeadline.difference(DateTime.now());
        if (_guestAutoCheckoutRemaining.isNegative) {
          _guestAutoCheckoutRemaining = Duration.zero;
          _guestAutoCheckoutTimer?.cancel();
        }
      });
    });
  }

  /// 보류 신청 여부 (정책 7.7.2: 카운트다운 정지)
  bool get _isHostPending =>
      widget.contract.checkoutStatus == 'HOST_PENDING';

  /// 정책 7.6.2: 호스트 자동 퇴실확인 타이머 (게스트 퇴실완료 + 48h)
  void _startHostAutoConfirmTimer() {
    if (!_guestConfirmed || _hostConfirmed || _isHostPending) return;

    final guestConfirmedAt = DateTime.tryParse(
      widget.contract.guestCheckoutConfirmedAt!,
    );
    if (guestConfirmedAt == null) return;

    final autoConfirmDeadline = guestConfirmedAt.add(
      const Duration(hours: 48),
    );

    _hostAutoConfirmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _hostAutoConfirmRemaining = autoConfirmDeadline.difference(DateTime.now());
        if (_hostAutoConfirmRemaining.isNegative) {
          _hostAutoConfirmRemaining = Duration.zero;
          _hostAutoConfirmTimer?.cancel();
        }
      });
    });
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            '퇴실 확인',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),

          // 게스트 퇴실 확인 상태
          _buildCheckRow(
            label: '임차인 퇴실 확인',
            isConfirmed: _guestConfirmed,
            confirmedAt: widget.contract.guestCheckoutConfirmedAt,
            showButton: !widget.isHost && !_guestConfirmed,
            onConfirm: widget.onGuestConfirm,
          ),

          const SizedBox(height: 12),

          // 호스트 퇴실 확인 상태
          _buildCheckRow(
            label: '임대인 퇴실 확인',
            isConfirmed: _hostConfirmed,
            confirmedAt: widget.contract.hostCheckoutConfirmedAt,
            showButton: widget.isHost && _guestConfirmed && !_hostConfirmed,
            onConfirm: widget.onHostConfirm,
          ),

          // 정책 7.6.2: 호스트 퇴실확인 보류 신청 버튼 (보류 미신청 상태에서만)
          if (widget.isHost &&
              _guestConfirmed &&
              !_hostConfirmed &&
              !_isHostPending &&
              widget.onHostHold != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onHostHold,
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: Text(
                  '퇴실 확인 보류 신청',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  foregroundColor: const Color(0xFFF97316),
                  side: const BorderSide(color: Color(0xFFFED7AA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSm,
                  ),
                ),
              ),
            ),
          ],

          // 정책 7.6.1: 게스트 자동 퇴실완료 타이머
          if (!_guestConfirmed) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '임차인 미처리 시 자동 퇴실완료까지 ${_formatDuration(_guestAutoCheckoutRemaining)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 정책 7.6.2 / 7.7.2: 호스트 자동 퇴실확인 타이머 또는 보류 상태
          if (_guestConfirmed && !_hostConfirmed) ...[
            const SizedBox(height: 12),
            if (_isHostPending)
              // 정책 7.7.2: 보류 신청 시 카운트다운 정지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pause_circle, size: 18, color: Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '퇴실 확인 보류 신청됨 — 자동 확정 타이머가 정지되었습니다.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '임대인 미확인 시 자동 확정까지 ${_formatDuration(_hostAutoConfirmRemaining)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // 보증금 상태 안내 (정책 7.4, 7.10)
          if (_guestConfirmed && _hostConfirmed) ...[
            const SizedBox(height: 12),
            _buildDepositStatusBanner(),
          ],
        ],
      ),
    );
  }

  /// 보증금 상태별 배너 (정책 7.4, 7.10)
  Widget _buildDepositStatusBanner() {
    final status = widget.contract.depositStatus;

    // 차감확정: 합의에 따라 차감 금액 확정
    if (status == DepositStatus.deductionConfirmed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: AppRadius.radiusSm,
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 18, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '보증금 차감이 확정되었습니다. 잔여 금액이 반환됩니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 반환확정: 반환 금액 확정 (환불 실행 대기)
    if (status == DepositStatus.returnConfirmed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: AppRadius.radiusSm,
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments, size: 18, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '보증금 반환이 확정되었습니다. 환불이 진행됩니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 반환보류: 합의 프로세스 진행 중
    if (status == DepositStatus.returnHold) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: AppRadius.radiusSm,
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.pause_circle, size: 18, color: Color(0xFFF97316)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '보증금 반환이 보류 중입니다. 합의 절차가 진행됩니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF9A3412),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 반환완료
    if (status == DepositStatus.returned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: AppRadius.radiusSm,
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '보증금이 반환 완료되었습니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 기본: 퇴실 확인 완료 → 반환 진행 예정
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '퇴실 확인이 완료되었습니다. 보증금 반환이 진행됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow({
    required String label,
    required bool isConfirmed,
    String? confirmedAt,
    required bool showButton,
    VoidCallback? onConfirm,
  }) {
    return Row(
      children: [
        // 상태 아이콘
        Icon(
          isConfirmed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 22,
          color: isConfirmed ? const Color(0xFF16A34A) : AppColors.gray300,
        ),
        const SizedBox(width: 10),

        // 라벨 + 확인 시각
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isConfirmed ? AppColors.gray900 : AppColors.gray600,
                ),
              ),
              if (isConfirmed && confirmedAt != null)
                Text(
                  _formatDateTime(confirmedAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray600,
                    fontSize: 12,
                  ),
                ),
              if (!isConfirmed && !showButton)
                Text(
                  '대기 중',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),

        // 확인 버튼
        if (showButton)
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSm,
              ),
            ),
            child: const Text('퇴실 확인'),
          ),
      ],
    );
  }
}
