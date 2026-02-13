import 'package:flutter/material.dart';
import '../models/contract.dart'; // PaymentMethod enum
import '../models/payment_method.dart'; // PaymentMethod extensions
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../utils/format_utils.dart';

/// 결제 수단 선택 모달
class PaymentMethodModal extends StatefulWidget {
  final int totalAmount;
  final PaymentMethod? initialSelectedMethod;

  const PaymentMethodModal({
    super.key,
    required this.totalAmount,
    this.initialSelectedMethod,
  });

  @override
  State<PaymentMethodModal> createState() => _PaymentMethodModalState();
}

class _PaymentMethodModalState extends State<PaymentMethodModal>
    with SingleTickerProviderStateMixin {
  PaymentMethod? _selectedMethod;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialSelectedMethod;

    // 애니메이션 설정
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.modal,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.modal,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.modal,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              _buildHeader(),

              // 결제 수단 리스트
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: PaymentMethod.values.map((method) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPaymentCard(method),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 하단 고정 버튼
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 모달 헤더
  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '결제 수단 선택',
            style: AppTextStyles.headingMedium,
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 28),
            color: Colors.grey.shade600,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 결제 수단 카드
  Widget _buildPaymentCard(PaymentMethod method) {
    final isSelected = _selectedMethod == method;

    return AnimatedContainer(
      duration: AppDurations.listItem,
      curve: AppCurves.listItem,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.primary500.withValues(alpha: 0.08),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.primary500 : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary500.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 16 : 8,
            offset: Offset(0, isSelected ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedMethod = method);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    method.icon,
                    color: AppColors.primary500,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // 제목 + 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.description,
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                    ],
                  ),
                ),

                // 체크 아이콘 (선택 시)
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary500,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 하단 고정 버튼
  Widget _buildBottomButton() {
    final isEnabled = _selectedMethod != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: AnimatedContainer(
            duration: AppDurations.hoverCard,
            curve: AppCurves.hoverCard,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [
                        AppColors.primary500,
                        AppColors.primary500.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEnabled ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary500.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled
                    ? () => Navigator.pop(context, _selectedMethod)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    isEnabled
                        ? '₩${FormatUtils.formatCurrency(widget.totalAmount)} 결제하기'
                        : '결제 수단을 선택해주세요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
