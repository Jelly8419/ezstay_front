import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/format_utils.dart';

/// 날짜 범위(체크인~체크아웃) 입력 필드.
///
/// 값 선택은 외부에 위임하며, 탭 시 [onTap] 콜백을 호출해 호출자가
/// `showDialog(... GuestDateRangePickerDialog ...)` 등을 열도록 한다.
///
/// 사용 예시:
/// ```dart
/// DateRangeInput(
///   checkIn: _checkInDate,
///   checkOut: _checkOutDate,
///   onTap: _showDateDialog,
/// )
/// ```
class DateRangeInput extends StatelessWidget {
  const DateRangeInput({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onTap,
    this.placeholder = '날짜를 선택하세요',
    this.height = 56,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoidCallback onTap;
  final String placeholder;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasDate = checkIn != null && checkOut != null;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: hasDate ? AppColors.primary600 : AppColors.border,
            width: hasDate ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use_from_same_package
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: hasDate ? AppColors.primary600 : AppColors.textSecondary,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hasDate
                    ? '${FormatUtils.formatDateShort(checkIn!)} - ${FormatUtils.formatDateShort(checkOut!)}'
                    : placeholder,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasDate
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}
