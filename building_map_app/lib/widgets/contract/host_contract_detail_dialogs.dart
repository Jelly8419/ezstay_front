import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../utils/format_utils.dart';

/// 호스트 퇴실 확인 다이얼로그 (도어락 경고 포함)
///
/// [roomId] null이면 "변경 요청" 링크 미표시
/// [onChangePassword] 변경 요청 탭 시 호출 (다이얼로그 닫고 이동)
class HostCheckoutConfirmDialog extends StatelessWidget {
  final int? roomId;
  final VoidCallback? onChangePassword;

  const HostCheckoutConfirmDialog({
    super.key,
    this.roomId,
    this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text('퇴실 확인'),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('퇴실을 확인하시겠습니까?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              border: Border.all(color: const Color(0xFFFED7AA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 20, color: Color(0xFFF97316)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '청소 서비스 진행을 위해 방 도어락 비밀번호가 맞는지 반드시 확인해주세요. ',
                        ),
                        if (roomId != null)
                          TextSpan(
                            text: '(현재 비밀번호 확인 및 변경 요청)',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).pop(false);
                                onChangePassword?.call();
                              },
                          ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A3412),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('확인', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// IN_PROGRESS 퇴실 확인 다이얼로그 (단순 확인)
class HostRequestCheckoutDialog extends StatelessWidget {
  const HostRequestCheckoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('퇴실 확인'),
      content: const Text(
        '퇴실을 확인하시겠습니까?\n계약이 종료되며 보증금 환급 절차가 진행됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// 호스트 위약금 결제 확인 다이얼로그
class HostPenaltyPaymentConfirmDialog extends StatelessWidget {
  final int penaltyAmount;

  const HostPenaltyPaymentConfirmDialog({
    super.key,
    required this.penaltyAmount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('위약금 결제'),
      content: Text(
        '호스트 귀책 취소를 위해 위약금을 결제해야 합니다.\n\n'
        '위약금: ${FormatUtils.formatCurrency(penaltyAmount)}원\n'
        '(임대료 위약금 + 게스트 서비스 수수료)\n\n'
        '결제 후 게스트에게 전액 환불 및 보전 지급이 처리됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
          child: const Text('결제하기'),
        ),
      ],
    );
  }
}
