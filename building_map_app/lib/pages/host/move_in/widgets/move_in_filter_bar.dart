import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';

/// 입주 준비 서비스 홈 — 검색 + 필터 chip 그룹
///
/// 필터 (PRD 11.1, 이미지 ①):
/// - 전체
/// - 임차인 요청 발송 전
/// - 임차인 요청 발송 완료
/// - 청소 결제 대기
/// - 청소 결제 완료
class MoveInFilterBar extends StatefulWidget {
  final String search;
  final PaymentRequestStatus? requestStatus;
  final CleaningStatus? cleaningStatus;
  final void Function({
    PaymentRequestStatus? requestStatus,
    CleaningStatus? cleaningStatus,
    String? search,
  }) onChanged;

  const MoveInFilterBar({
    super.key,
    required this.search,
    required this.requestStatus,
    required this.cleaningStatus,
    required this.onChanged,
  });

  @override
  State<MoveInFilterBar> createState() => _MoveInFilterBarState();
}

class _MoveInFilterBarState extends State<MoveInFilterBar> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.search);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(
        requestStatus: widget.requestStatus,
        cleaningStatus: widget.cleaningStatus,
        search: value,
      );
    });
  }

  bool get _isAllSelected =>
      widget.requestStatus == null && widget.cleaningStatus == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '방 이름, 주소, 임차인 이름 검색',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.primary500, width: 1.5),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _filterChip(
              label: '전체',
              selected: _isAllSelected,
              onSelected: () => widget.onChanged(
                requestStatus: null,
                cleaningStatus: null,
                search: widget.search,
              ),
            ),
            _filterChip(
              label: '임차인 요청 발송 전',
              selected: widget.requestStatus == PaymentRequestStatus.notSent,
              onSelected: () => widget.onChanged(
                requestStatus: widget.requestStatus == PaymentRequestStatus.notSent
                    ? null
                    : PaymentRequestStatus.notSent,
                cleaningStatus: null,
                search: widget.search,
              ),
            ),
            _filterChip(
              label: '임차인 요청 발송 완료',
              selected: widget.requestStatus == PaymentRequestStatus.sent,
              onSelected: () => widget.onChanged(
                requestStatus: widget.requestStatus == PaymentRequestStatus.sent
                    ? null
                    : PaymentRequestStatus.sent,
                cleaningStatus: null,
                search: widget.search,
              ),
            ),
            _filterChip(
              label: '청소 결제 대기',
              selected: widget.cleaningStatus == CleaningStatus.paymentPending,
              onSelected: () => widget.onChanged(
                requestStatus: null,
                cleaningStatus: widget.cleaningStatus == CleaningStatus.paymentPending
                    ? null
                    : CleaningStatus.paymentPending,
                search: widget.search,
              ),
            ),
            _filterChip(
              label: '청소 결제 완료',
              selected: widget.cleaningStatus == CleaningStatus.paid,
              onSelected: () => widget.onChanged(
                requestStatus: null,
                cleaningStatus: widget.cleaningStatus == CleaningStatus.paid
                    ? null
                    : CleaningStatus.paid,
                search: widget.search,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: selected ? AppColors.primary700 : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      selectedColor: AppColors.primary50,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary500 : AppColors.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
