import 'package:flutter/material.dart';

/// 취소 요청 모달
///
/// 입주일 이후에 계약을 취소하려는 경우 표시되는 모달입니다.
/// 호스트와의 직접 합의 및 관리자 승인이 필요합니다.
///
/// **사용 시나리오:**
/// - 입주일(checkInDate) 이후
/// - 게스트가 계약 취소를 원하는 경우
/// - 결제 취소는 불가, 호스트 합의 + 관리자 승인 필요
///
/// **프로세스:**
/// 1. 게스트가 취소 사유 입력
/// 2. 관리자에게 취소 요청 전송
/// 3. 호스트와 게스트 간 합의 확인
/// 4. 관리자 승인 후 해당 기간 다시 임대 가능 상태로 변경
/// 5. 결제는 정상 정산됨 (취소 불가)
///
/// **사용 예시:**
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => CancelRequestModal(
///     onSubmit: (reason) {
///       // API 호출: 취소 요청 전송
///     },
///     onClose: () {
///       Navigator.of(context).pop();
///     },
///   ),
/// );
/// ```
class CancelRequestModal extends StatefulWidget {
  /// 취소 요청 제출 콜백 (사유를 파라미터로 전달)
  final Function(String reason) onSubmit;

  /// 닫기 버튼 콜백
  final VoidCallback onClose;

  const CancelRequestModal({
    super.key,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  State<CancelRequestModal> createState() => _CancelRequestModalState();
}

class _CancelRequestModalState extends State<CancelRequestModal> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// 제출 버튼 핸들러
  void _handleSubmit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      // 사유 미입력 경고
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('취소 사유를 입력해주세요.'),
          backgroundColor: Color(0xFFDC2626), // red-600
        ),
      );
      return;
    }
    widget.onSubmit(reason);
  }

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
            // 헤더 (아이콘 + 제목 + 설명)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEA580C), // orange-600
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
                        '취소 요청',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            _buildInfoItem('입주일 이후 취소 요청 시, 관리자의 승인이 필요합니다.'),
                            const SizedBox(height: 8),
                            _buildInfoItem('임대인과 임차인의 합의된 내용으로 계약 취소가 진행될 수 있습니다.'),
                            const SizedBox(height: 8),
                            _buildInfoItem('계약 취소 시, 수수료는 환불이 불가능할 수 있습니다.'),
                            const SizedBox(height: 8),
                            _buildInfoItem('귀책 사유 제공자는 서비스 이용에 불이익을 받을 수 있습니다.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 취소 사유 입력
                      const Text(
                        '취소 요청 사유',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151), // gray-700
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '취소 사유를 입력해주세요',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF), // gray-400
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1D5DB), // gray-300
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1D5DB), // gray-300
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB), // blue-600
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827), // gray-900
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
                // 닫기 버튼
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
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
                      '닫기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151), // gray-700
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 요청하기 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // blue-600
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '관리자에게 요청하기',
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
