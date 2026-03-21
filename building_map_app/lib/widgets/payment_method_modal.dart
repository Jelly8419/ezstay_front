import 'package:flutter/material.dart';
import '../models/contract.dart'; // PaymentMethod enum
import '../models/payment_method.dart'; // PaymentMethod extensions
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../utils/format_utils.dart';

/// 결제 수단 선택 모달 (PayTag PG)
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

  /// 신용카드 목록
  static const _creditCards = [
    PaymentMethod.bc,
    PaymentMethod.kb,
    PaymentMethod.sh,
    PaymentMethod.ss,
    PaymentMethod.hd,
    PaymentMethod.lt,
    PaymentMethod.wr,
    PaymentMethod.ka,
    PaymentMethod.nh,
  ];

  /// 간편결제 목록
  static const _easyPays = [
    PaymentMethod.kakaoPay,
    PaymentMethod.naverPay,
    PaymentMethod.payco,
  ];

  // TODO: 오픈 후 가상계좌 추가 예정
  // static const _others = [
  //   PaymentMethod.virtualAccount,
  // ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialSelectedMethod;

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
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 신용카드 섹션
                      _buildSectionTitle('신용카드', Icons.credit_card),
                      const SizedBox(height: 8),
                      _buildCardGrid(_creditCards),

                      const SizedBox(height: 20),

                      // 간편결제 섹션
                      _buildSectionTitle('간편결제', Icons.smartphone),
                      const SizedBox(height: 8),
                      ..._easyPays.map((method) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildPaymentTile(method),
                          )),

                      // TODO: 오픈 후 가상계좌 섹션 추가 예정
                      // const SizedBox(height: 20),
                      // _buildSectionTitle('기타', Icons.more_horiz),
                      // const SizedBox(height: 8),
                      // ..._others.map((method) => Padding(
                      //       padding: const EdgeInsets.only(bottom: 8),
                      //       child: _buildPaymentTile(method),
                      //     )),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 섹션 제목
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 신용카드 그리드 (3열)
  Widget _buildCardGrid(List<PaymentMethod> cards) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards.map((method) {
        final isSelected = _selectedMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _selectedMethod = method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: (MediaQuery.of(context).size.width - 40 - 16) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary500.withValues(alpha: 0.08)
                  : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary500 : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                method.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary500 : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 간편결제/기타 타일
  Widget _buildPaymentTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary500.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary500 : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              method.icon,
              size: 22,
              color: isSelected ? AppColors.primary500 : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary500
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary500, size: 24),
          ],
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
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('결제 수단 선택', style: AppTextStyles.headingMedium),
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

  /// 하단 고정 버튼
  Widget _buildBottomButton() {
    final isEnabled = _selectedMethod != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
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
