import 'dart:async';
import 'package:flutter/material.dart';
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

  const CheckoutConfirmationWidget({
    super.key,
    required this.contract,
    required this.isHost,
    this.onGuestConfirm,
    this.onHostConfirm,
  });

  @override
  State<CheckoutConfirmationWidget> createState() =>
      _CheckoutConfirmationWidgetState();
}

class _CheckoutConfirmationWidgetState
    extends State<CheckoutConfirmationWidget> {
  Timer? _timer;
  Duration _autoConfirmRemaining = Duration.zero;

  bool get _guestConfirmed =>
      widget.contract.guestCheckoutConfirmedAt != null;

  bool get _hostConfirmed =>
      widget.contract.hostCheckoutConfirmedAt != null;

  @override
  void initState() {
    super.initState();
    _startAutoConfirmTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoConfirmTimer() {
    if (!_guestConfirmed || _hostConfirmed) return;

    // 게스트 확인 시각 + 48시간 = 자동 확정 시각
    final guestConfirmedAt = DateTime.tryParse(
      widget.contract.guestCheckoutConfirmedAt!,
    );
    if (guestConfirmedAt == null) return;

    final autoConfirmDeadline = guestConfirmedAt.add(
      const Duration(hours: 48),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _autoConfirmRemaining = autoConfirmDeadline.difference(DateTime.now());
        if (_autoConfirmRemaining.isNegative) {
          _autoConfirmRemaining = Duration.zero;
          _timer?.cancel();
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
            label: '게스트 퇴실 확인',
            isConfirmed: _guestConfirmed,
            confirmedAt: widget.contract.guestCheckoutConfirmedAt,
            showButton: !widget.isHost && !_guestConfirmed,
            onConfirm: widget.onGuestConfirm,
          ),

          const SizedBox(height: 12),

          // 호스트 퇴실 확인 상태
          _buildCheckRow(
            label: '호스트 퇴실 확인',
            isConfirmed: _hostConfirmed,
            confirmedAt: widget.contract.hostCheckoutConfirmedAt,
            showButton: widget.isHost && _guestConfirmed && !_hostConfirmed,
            onConfirm: widget.onHostConfirm,
          ),

          // 자동 확정 타이머
          if (_guestConfirmed && !_hostConfirmed) ...[
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
                      '호스트 미확인 시 자동 확정까지 ${_formatDuration(_autoConfirmRemaining)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 보증금 안내
          if (_guestConfirmed && _hostConfirmed) ...[
            const SizedBox(height: 12),
            Container(
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
            ),
          ],
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
