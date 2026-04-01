import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 게스트 퇴실 확인 다이얼로그
class GuestCheckoutConfirmDialog extends StatelessWidget {
  const GuestCheckoutConfirmDialog({super.key});

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
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '방 도어락 비밀번호를 임의 변경 후 퇴실하셨을 경우, 퇴실 확인 전에 호스트에게 비밀번호를 안내하지 않으면 보증금 환급 절차에 불이익이 발생할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF991B1B),
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

/// 게스트 결제 성공 다이얼로그
class GuestPaymentSuccessDialog extends StatelessWidget {
  final String message;

  const GuestPaymentSuccessDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success500, size: 28),
          const SizedBox(width: 8),
          const Text('결제 완료'),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// 게스트 결제 실패 다이얼로그
class GuestPaymentErrorDialog extends StatelessWidget {
  final String message;

  const GuestPaymentErrorDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: AppColors.error500, size: 28),
          const SizedBox(width: 8),
          const Text('결제 실패'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// 팝업 차단 안내 다이얼로그
class GuestPopupBlockedDialog extends StatelessWidget {
  const GuestPopupBlockedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('팝업 차단 감지'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결제창을 열기 위해 팝업 차단을 해제해주세요.'),
          SizedBox(height: 12),
          Text(
            '해제 방법:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('• 주소창 오른쪽의 팝업 차단 아이콘 클릭'),
          Text('• "팝업 허용" 선택 후 페이지 새로고침'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
