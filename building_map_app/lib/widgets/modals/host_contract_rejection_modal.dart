import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// 호스트 계약 거절 모달
///
/// [isWithdrawal] true이면 '승인 철회' 문구 사용 (APPROVED 상태에서 호출)
class HostContractRejectionModal extends StatelessWidget {
  final int contractId;
  final VoidCallback onClose;
  final Function(String rejectionReason) onConfirm;
  final bool isWithdrawal;

  const HostContractRejectionModal({
    required this.contractId,
    required this.onClose,
    required this.onConfirm,
    this.isWithdrawal = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 448),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  isWithdrawal ? '승인 철회' : '계약 거절',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),

                // 설명
                Text(
                  isWithdrawal
                      ? '해당 승인 계약을 철회하시겠습니까?'
                      : '해당 계약 승인 요청을 거절하시겠습니까?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                              color: Color(0xFFD1D5DB), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 확인 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onConfirm(''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isWithdrawal ? '철회하기' : '거절하기',
                          style: AppTextStyles.labelLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
