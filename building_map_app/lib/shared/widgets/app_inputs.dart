import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Search Bar - 검색 바
///
/// 사용 예시:
/// ```dart
/// AppSearchBar(
///   hintText: '지역, 역 이름으로 검색',
///   onSearch: (query) {
///     print('검색: $query');
///   },
///   onFilterTap: () {
///     // 필터 모달 열기
///   },
/// )
/// ```
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hintText = '검색',
    this.onSearch,
    this.onFilterTap,
    this.showFilter = true,
  });

  final String hintText;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onFilterTap;
  final bool showFilter;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.shadowSm,
      ),
      child: Row(
        children: [
          // 검색 아이콘
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.md),
            child: Icon(
              Icons.search,
              color: AppColors.neutral600,
              size: AppSizes.iconMd,
            ),
          ),

          // 입력 필드
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSearch,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.neutral500,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
            ),
          ),

          // Clear 버튼 (텍스트 있을 때)
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(Icons.close, size: AppSizes.iconSm),
                color: AppColors.neutral600,
                onPressed: () {
                  _controller.clear();
                },
              );
            },
          ),

          // 필터 버튼
          if (widget.showFilter) ...[
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
            IconButton(
              icon: Icon(Icons.tune, size: AppSizes.iconMd),
              color: AppColors.neutral700,
              onPressed: widget.onFilterTap,
            ),
          ] else
            SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// Text Field - 일반 입력 필드
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium,
          ),
          SizedBox(height: AppSpacing.sm),
        ],

        // 입력 필드
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.neutral500,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.neutral600)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? AppColors.neutral0 : AppColors.neutral100,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.primary500,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.error500,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.error500,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.neutral200,
                width: 1,
              ),
            ),
          ),
        ),

        // 에러 또는 헬퍼 텍스트
        if (errorText != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTextStyles.bodySmallError,
          ),
        ] else if (helperText != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            helperText!,
            style: AppTextStyles.bodySmallSecondary,
          ),
        ],
      ],
    );
  }
}

/// Password Field - 비밀번호 입력 필드
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.errorText,
    this.helperText,
    this.onChanged,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: widget.hintText,
      controller: widget.controller,
      errorText: widget.errorText,
      helperText: widget.helperText,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.neutral600,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Date Range Picker - 날짜 범위 선택
class AppDateRangePicker extends StatelessWidget {
  const AppDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onTap,
    this.label,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTap;
  final String? label;

  String _formatDate(DateTime? date) {
    if (date == null) return '날짜 선택';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium,
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMd,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.neutral0,
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(
              children: [
                // 체크인
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '체크인',
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(startDate),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: startDate != null
                              ? AppColors.textPrimary
                              : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 구분선
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),

                // 체크아웃
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '체크아웃',
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(endDate),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: endDate != null
                              ? AppColors.textPrimary
                              : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 달력 아이콘
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.neutral600,
                  size: AppSizes.iconMd,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
