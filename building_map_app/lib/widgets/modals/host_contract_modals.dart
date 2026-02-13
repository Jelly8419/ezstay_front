import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// 호스트 계약 관리 관련 모달 위젯 모음

/// 1. 계약 거절 사유 입력 모달
class RejectContractModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String reason) onConfirm;

  const RejectContractModal({
    super.key,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<RejectContractModal> createState() => _RejectContractModalState();
}

class _RejectContractModalState extends State<RejectContractModal> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('거절 사유를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('거절 사유는 최소 10자 이상 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.modal,
        ),
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '계약 요청 거절',
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // 안내 메시지
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '게스트에게 전달할 거절 사유를 입력해주세요.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '• 정중하고 명확한 사유를 작성해주세요.\n'
                    '• 게스트는 이 메시지를 통해 거절 이유를 확인합니다.\n'
                    '• 최소 10자 이상 입력해주세요.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.red.shade800,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // 거절 사유 입력
            Text(
              '거절 사유',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '예: 해당 기간에 이미 다른 게스트의 계약이 예정되어 있어 승인이 어렵습니다.\n'
                    '다른 날짜로 다시 요청해주시면 감사하겠습니다.',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.primary500, width: 2),
                ),
                contentPadding: AppSpacing.paddingMd,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppSpacing.md),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : widget.onClose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.border, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '거절하기',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
}

/// 2. 취소 요청 모달 (입주일 이후)
class RequestCancellationModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String reason) onConfirm;

  const RequestCancellationModal({
    super.key,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<RequestCancellationModal> createState() =>
      _RequestCancellationModalState();
}

class _RequestCancellationModalState extends State<RequestCancellationModal> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('취소 사유를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('취소 사유는 최소 10자 이상 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.modal,
        ),
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: Colors.orange.shade700, size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '계약 취소 요청',
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // 안내 메시지
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '입주일 이후 계약 취소는 게스트와의 협의가 필요합니다.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '• 취소 요청 사유를 게스트에게 전달합니다.\n'
                    '• 게스트가 동의하면 계약이 취소됩니다.\n'
                    '• 게스트가 거절하면 계약이 유지됩니다.\n'
                    '• 최소 10자 이상 입력해주세요.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // 취소 사유 입력
            Text(
              '취소 요청 사유',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    '예: 긴급한 개인 사정으로 인해 해당 기간 동안 방을 임대할 수 없게 되었습니다.\n'
                    '불편을 끼쳐드려 죄송합니다.',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.primary500, width: 2),
                ),
                contentPadding: AppSpacing.paddingMd,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppSpacing.md),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : widget.onClose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.border, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      '닫기',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '취소 요청',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
}

/// 3. 게스트 입주 준비 안내 모달
class GuestPreparationModal extends StatelessWidget {
  final VoidCallback onClose;
  final String guestName;
  final DateTime checkInDate;
  final String roomAddress;

  const GuestPreparationModal({
    super.key,
    required this.onClose,
    required this.guestName,
    required this.checkInDate,
    required this.roomAddress,
  });

  @override
  Widget build(BuildContext context) {
    final daysDiff = checkInDate.difference(DateTime.now()).inDays;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.modal,
        ),
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              Row(
                children: [
                  Icon(Icons.home_work_outlined,
                      color: AppColors.primary600, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '게스트 입주 준비',
                      style: AppTextStyles.headingMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon:
                        const Icon(Icons.close, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // D-Day 안내
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  border: Border.all(color: AppColors.primary300),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: AppColors.primary700, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '$guestName님의 입주까지 $daysDiff일 남았습니다',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // 준비 사항 체크리스트
              _buildSection(
                title: '📋 입주 전 준비 사항',
                items: [
                  '방 청소 및 정리정돈',
                  '침구류, 수건 등 세탁 및 교체',
                  '가전제품 및 설비 점검',
                  '냉장고, 에어컨 등 미리 작동 확인',
                  '옵션 상품이 있는 경우 배송 준비',
                ],
              ),
              SizedBox(height: AppSpacing.sm),

              _buildSection(
                title: '🔑 입주일 당일',
                items: [
                  '게스트에게 체크인 방법 안내 (비밀번호, 키박스 등)',
                  '게스트 도착 시간 확인',
                  '비상 연락처 공유',
                  '주차 방법 및 쓰레기 배출 방법 안내',
                ],
              ),
              SizedBox(height: AppSpacing.sm),

              _buildSection(
                title: '💡 게스트 소통 팁',
                items: [
                  '입주 전날 리마인드 메시지 전송',
                  '주변 편의시설 정보 제공',
                  '긴급 상황 시 연락처 공유',
                  '체크인 후 불편사항 확인',
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // 주소 정보
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '방 주소',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      roomAddress,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // 닫기 버튼
              ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  '확인',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs / 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.primary500),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodySmall.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
