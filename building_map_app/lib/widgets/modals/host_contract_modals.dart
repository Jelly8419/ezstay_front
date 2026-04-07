import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/format_utils.dart';

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

/// 4. 보증금 합의 내용 제출 모달
class DepositAgreementModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(int deductAmount, String agreementText) onConfirm;
  final int depositAmount; // 보증금 총액
  final DateTime checkOutDate; // 퇴실일
  final String? roomCheckoutTime; // 퇴실 시간 (HH:mm)
  final DateTime? agreementDeadline; // 합의 데드라인 (정책 7.9.1: 관리자 승인 시점 + 10일)
  final int? initialDeductAmount; // 수정 모드: 기존 차감 금액
  final String? initialAgreementText; // 수정 모드: 기존 합의 내용

  const DepositAgreementModal({
    super.key,
    required this.onClose,
    required this.onConfirm,
    required this.depositAmount,
    required this.checkOutDate,
    this.roomCheckoutTime,
    this.agreementDeadline,
    this.initialDeductAmount,
    this.initialAgreementText,
  });

  @override
  State<DepositAgreementModal> createState() => _DepositAgreementModalState();
}

class _DepositAgreementModalState extends State<DepositAgreementModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _agreementTextController =
      TextEditingController();
  bool _isSubmitting = false;
  String? _amountError;

  /// 데드라인 (정책 7.9.1): 관리자 승인 시점 + 10일
  /// agreementDeadline이 없으면 퇴실시간 + 10일로 폴백 (서버 미지원 시)
  DateTime get _deadline {
    if (widget.agreementDeadline != null) {
      return widget.agreementDeadline!;
    }
    // 폴백: 퇴실시간 + 10일
    final checkoutTime = widget.roomCheckoutTime ?? '11:00';
    final parts = checkoutTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 11;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(
      widget.checkOutDate.year,
      widget.checkOutDate.month,
      widget.checkOutDate.day,
      hour,
      minute,
    ).add(const Duration(days: 10));
  }

  bool get _isDeadlinePassed => DateTime.now().isAfter(_deadline);

  String get _remainingTimeText {
    final remaining = _deadline.difference(DateTime.now());
    if (remaining.isNegative) return '기한 초과';
    if (remaining.inDays > 0) return '${remaining.inDays}일 ${remaining.inHours % 24}시간 남음';
    if (remaining.inHours > 0) return '${remaining.inHours}시간 ${remaining.inMinutes % 60}분 남음';
    return '${remaining.inMinutes}분 남음';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDeductAmount != null) {
      _amountController.text = widget.initialDeductAmount.toString();
    }
    if (widget.initialAgreementText != null) {
      _agreementTextController.text = widget.initialAgreementText!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _agreementTextController.dispose();
    super.dispose();
  }

  void _setFullDeduction() {
    _amountController.text = widget.depositAmount.toString();
    _validateAmount(widget.depositAmount.toString());
  }

  void _setNoDeduction() {
    _amountController.text = '0';
    _validateAmount('0');
  }

  void _validateAmount(String value) {
    setState(() {
      if (value.isEmpty) {
        _amountError = null;
        return;
      }
      final amount = int.tryParse(value);
      if (amount == null) {
        _amountError = '숫자를 입력해주세요.';
      } else if (amount < 0) {
        _amountError = '0 이상의 금액을 입력해주세요.';
      } else if (amount > widget.depositAmount) {
        _amountError = '보증금(${FormatUtils.formatCurrency(widget.depositAmount)}원)을 초과할 수 없습니다.';
      } else {
        _amountError = null;
      }
    });
  }

  void _handleConfirm() {
    final amountText = _amountController.text.trim();
    final agreementText = _agreementTextController.text.trim();

    if (amountText.isEmpty) {
      setState(() => _amountError = '차감 금액을 입력해주세요.');
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount < 0 || amount > widget.depositAmount) {
      setState(() => _amountError = '올바른 금액을 입력해주세요.');
      return;
    }

    if (agreementText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('합의 내용을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (agreementText.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('합의 내용은 최소 10자 이상 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isDeadlinePassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제출 기한이 초과되었습니다. 보증금이 게스트에게 자동 반환됩니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    widget.onConfirm(amount, agreementText);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
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
                  Icon(Icons.handshake_outlined,
                      color: const Color(0xFFF97316), size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.initialDeductAmount != null ? '보증금 합의 내용 수정' : '보증금 합의 내용 제출',
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

              // 데드라인 안내
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: _isDeadlinePassed
                      ? Colors.red.shade50
                      : const Color(0xFFFFF7ED),
                  border: Border.all(
                    color: _isDeadlinePassed
                        ? Colors.red.shade300
                        : const Color(0xFFFED7AA),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isDeadlinePassed
                              ? Icons.error_outline
                              : Icons.timer_outlined,
                          size: 18,
                          color: _isDeadlinePassed
                              ? Colors.red.shade700
                              : const Color(0xFFF97316),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _isDeadlinePassed
                                ? '제출 기한이 초과되었습니다'
                                : '제출 기한: $_remainingTimeText',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isDeadlinePassed
                                  ? Colors.red.shade700
                                  : const Color(0xFFC2410C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      _isDeadlinePassed
                          ? '합의 기한이 경과하여 보증금이 게스트에게 전액 자동 반환됩니다.'
                          : '• 관리자 승인일로부터 10일 이내에 합의 내용을 제출해야 합니다.\n'
                              '• 기한 내 미제출 시 보증금이 게스트에게 전액 자동 반환됩니다.\n'
                              '• 게스트가 합의에 동의하면 차감 금액이 정산됩니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isDeadlinePassed
                            ? Colors.red.shade600
                            : const Color(0xFF9A3412),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // 보증금 정보
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '보증금 총액',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatCurrency(widget.depositAmount)}원',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // 차감 금액 입력
              Text(
                '차감 금액',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _validateAmount,
                      decoration: InputDecoration(
                        hintText: '차감할 금액을 입력하세요',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        suffixText: '원',
                        errorText: _amountError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              BorderSide(color: AppColors.primary500, width: 2),
                        ),
                        contentPadding: AppSpacing.paddingMd,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),

              // 퀵 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDeadlinePassed ? null : _setFullDeduction,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: const Color(0xFFFED7AA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        '전액 차감',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDeadlinePassed ? null : _setNoDeduction,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        '차감 없음',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // 합의 내용 입력
              Text(
                '합의 내용',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _agreementTextController,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      '게스트와 합의한 내용을 상세히 작성해주세요.\n'
                      '예: 벽지 파손으로 인한 복구 비용 50,000원 차감에 합의하였습니다.',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        BorderSide(color: AppColors.primary500, width: 2),
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
                      onPressed:
                          (_isSubmitting || _isDeadlinePassed) ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.initialDeductAmount != null ? '합의 내용 수정' : '합의 내용 제출',
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
      ),
    );
  }
}

/// 보류 신청 / 재신청 모달
///
/// 호스트가 퇴실 확인 보류 신청 시 사유를 입력하는 모달.
/// [isReapply]가 true이면 재신청 모드 (반려 후).
class HoldRequestModal extends StatefulWidget {
  final bool isReapply;
  final VoidCallback onClose;
  final Future<void> Function(String reason) onConfirm;

  const HoldRequestModal({
    super.key,
    this.isReapply = false,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<HoldRequestModal> createState() => _HoldRequestModalState();
}

class _HoldRequestModalState extends State<HoldRequestModal> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보류 사유를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(reason);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReapply ? '보류 재신청' : '퇴실 확인 보류 신청';

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.headingSmall),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보류 신청 안내',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '• 관리자가 검토 후 승인 또는 반려합니다.\n'
                  '• 사진 등 구체적인 증빙 내용을 포함하면 승인에 도움이 됩니다.\n'
                  '• 승인 후 10일 내에 합의 내용을 제출해야 합니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '보류 사유 *',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: '예) 벽면 훼손 및 청소 불량 — 퇴실 후 벽에 큰 구멍이 있으며 바닥이 심하게 오염되어 있습니다.',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.gray300),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary500),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '취소',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.warning500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.gray300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isReapply ? '재신청' : '신청',
                          style: AppTextStyles.bodyMedium.copyWith(
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
    );
  }
}
