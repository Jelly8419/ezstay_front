import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// 호스트 계약 거절 모달
/// React UI: HostContractManagement.tsx (lines 753-784)
class HostContractRejectionModal extends StatefulWidget {
  final int contractId;
  final VoidCallback onClose;
  final Function(String rejectionReason) onConfirm;

  const HostContractRejectionModal({
    required this.contractId,
    required this.onClose,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  State<HostContractRejectionModal> createState() =>
      _HostContractRejectionModalState();
}

class _HostContractRejectionModalState
    extends State<HostContractRejectionModal> {
  final TextEditingController _rejectionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final reason = _rejectionController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거절 사유를 입력해주세요.')),
      );
      return;
    }

    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md (28rem)
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
                const Text(
                  '계약 거절',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),

                // 설명
                const Text(
                  '게스트에게 전달할 거절 사유를 입력해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),

                // textarea
                TextField(
                  controller: _rejectionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '거절 사유를 입력해주세요',
                    hintStyle:
                        AppTextStyles.bodySmall.copyWith(color: const Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),

                // 버튼
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : widget.onClose,
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
                    // 거절하기 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // red-600
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                '거절하기',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
