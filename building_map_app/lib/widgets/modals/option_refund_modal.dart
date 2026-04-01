import 'package:flutter/material.dart';
import '../../utils/format_utils.dart';

/// 옵션 결제 취소 완료 모달
///
/// 옵션 결제 취소 후 환불 금액과 처리 소요일 안내를 표시합니다.
class OptionRefundModal extends StatelessWidget {
  /// 환불 금액
  final int refundAmount;

  /// 확인 버튼 콜백
  final VoidCallback onClose;

  const OptionRefundModal({
    super.key,
    required this.refundAmount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (아이콘 + 제목)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  child: const Icon(
                    Icons.attach_money,
                    color: Color(0xFF2563EB), // blue-600
                    size: 24,
                  ),
                ),
                // 제목 및 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      const Text(
                        '옵션 환불 안내',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 메시지
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563), // gray-600
                          ),
                          children: [
                            TextSpan(
                              text: FormatUtils.formatKRW(refundAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626), // red-600
                              ),
                            ),
                            const TextSpan(text: ' 환불이 완료되었습니다.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 안내사항 박스
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB), // gray-50
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildInfoItem('결제수단에 따라 5영업일까지 소요될 수 있습니다.'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // blue-600
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 안내사항 아이템 위젯
  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151), // gray-700
            ),
          ),
        ),
      ],
    );
  }
}
