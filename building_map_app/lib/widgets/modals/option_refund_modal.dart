import 'package:flutter/material.dart';
import '../../utils/format_utils.dart';

/// 옵션 환불 확인 모달
///
/// 결제 완료 후 옵션 수량을 감소시켜 환불이 발생하는 경우 표시되는 확인 모달입니다.
///
/// **사용 시나리오:**
/// - 게스트가 결제 완료 후 옵션 상품 수량을 감소시킴
/// - 감소로 인해 환불이 발생하는 경우
/// - 환불 금액과 처리 안내를 표시
///
/// **기능:**
/// - 환불 금액 표시
/// - 환불 처리 안내 (영업일 기준 3-5일)
/// - 확인/취소 버튼
///
/// **사용 예시:**
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => OptionRefundModal(
///     refundAmount: 15000,
///     onConfirm: () {
///       // API 호출 및 상태 업데이트
///     },
///     onClose: () {
///       Navigator.of(context).pop();
///     },
///   ),
/// );
/// ```
class OptionRefundModal extends StatelessWidget {
  /// 환불 금액
  final int refundAmount;

  /// 확인 버튼 콜백
  final VoidCallback onConfirm;

  /// 취소/닫기 버튼 콜백
  final VoidCallback onClose;

  const OptionRefundModal({
    super.key,
    required this.refundAmount,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                            const TextSpan(text: '옵션 수량을 변경하고 '),
                            TextSpan(
                              text: FormatUtils.formatKRW(refundAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626), // red-600
                              ),
                            ),
                            const TextSpan(text: '을 환불받으시겠습니까?'),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoItem('환불 금액은 영업일 기준 3-5일 내 입금됩니다.'),
                            const SizedBox(height: 8),
                            _buildInfoItem('옵션 수량 변경은 즉시 적용됩니다.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFFD1D5DB), // gray-300
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151), // gray-700
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 확인 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // blue-600
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '환불 확인',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
