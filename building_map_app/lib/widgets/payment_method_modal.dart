import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../utils/format_utils.dart';

/// 결제 수단 선택 모달을 플랫폼에 맞게 표시합니다.
///
/// 웹: 화면 중앙 다이얼로그
/// 모바일: 하단 시트
Future<PaymentMethod?> showPaymentMethodModal(
  BuildContext context, {
  required int totalAmount,
  PaymentMethod? initialSelectedMethod,
}) {
  if (kIsWeb) {
    return showDialog<PaymentMethod>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PaymentMethodModal(
              totalAmount: totalAmount,
              initialSelectedMethod: initialSelectedMethod,
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<PaymentMethod>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaymentMethodModal(
      totalAmount: totalAmount,
      initialSelectedMethod: initialSelectedMethod,
    ),
  );
}

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

enum _PayCategory { easyPay, card, virtualAccount, transfer }

class _PaymentMethodModalState extends State<PaymentMethodModal>
    with SingleTickerProviderStateMixin {
  _PayCategory? _selectedCategory;
  PaymentMethod? _selectedCard;
  PaymentMethod? _selectedEasyPay;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _creditCards = [
    PaymentMethod.bc,
    PaymentMethod.kb,
    PaymentMethod.sin,
    PaymentMethod.ss,
    PaymentMethod.hd,
    PaymentMethod.lt,
    PaymentMethod.wr,
    PaymentMethod.hn,
    PaymentMethod.ka,
    PaymentMethod.nh,
    PaymentMethod.sh,
  ];

  static const _easyPays = [
    PaymentMethod.kakaoPay,
    PaymentMethod.naverPay,
    PaymentMethod.payco,
  ];

  // 드롭다운 버튼 위치 추적용
  final _cardDropdownKey = GlobalKey();
  final _easyPayDropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final init = widget.initialSelectedMethod;
    if (init != null) {
      if (init.isEasyPay) {
        _selectedCategory = _PayCategory.easyPay;
        _selectedEasyPay = init;
      } else {
        _selectedCategory = _PayCategory.card;
        _selectedCard = init;
      }
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  PaymentMethod? get _resolvedMethod {
    switch (_selectedCategory) {
      case _PayCategory.easyPay:
        return _selectedEasyPay;
      case _PayCategory.card:
        return _selectedCard;
      case _PayCategory.virtualAccount:
      case _PayCategory.transfer:
      case null:
        return null;
    }
  }

  bool get _canProceed => _resolvedMethod != null;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('결제수단', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                _buildOutlinedSection(
                  children: [
                    _buildEasyPayRow(),
                    _buildDivider(),
                    _buildCardRow(),
                    _buildDivider(),
                    _buildDisabledRow('무통장입금(가상계좌)'),
                    _buildDivider(),
                    _buildDisabledRow('계좌이체'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );

    // 웹: Dialog 내부라 슬라이드 애니메이션 불필요, 페이드만
    if (isWeb) {
      return FadeTransition(opacity: _fadeAnimation, child: content);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 60,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
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

  Widget _buildOutlinedSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, color: AppColors.border);

  Widget _buildEasyPayRow() {
    final isSelected = _selectedCategory == _PayCategory.easyPay;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _selectedCategory = _PayCategory.easyPay),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildRadio(isSelected),
                const SizedBox(width: 12),
                Text(
                  '간편결제',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 16, bottom: 14),
            child: _PositionedDropdown<PaymentMethod>(
              key: _easyPayDropdownKey,
              value: _selectedEasyPay,
              items: _easyPays,
              labelOf: (m) => m.label,
              hint: '간편결제 선택',
              onChanged: (m) => setState(() => _selectedEasyPay = m),
            ),
          ),
      ],
    );
  }

  Widget _buildCardRow() {
    final isSelected = _selectedCategory == _PayCategory.card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _selectedCategory = _PayCategory.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildRadio(isSelected),
                const SizedBox(width: 12),
                Text(
                  '신용/체크 카드',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 16, bottom: 14),
            child: _PositionedDropdown<PaymentMethod>(
              key: _cardDropdownKey,
              value: _selectedCard,
              items: _creditCards,
              labelOf: (m) => m.label,
              hint: '카드사 선택',
              onChanged: (m) => setState(() => _selectedCard = m),
            ),
          ),
      ],
    );
  }

  Widget _buildDisabledRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildRadio(false, disabled: true),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '준비중',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(bool isSelected, {bool disabled = false}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: disabled
              ? AppColors.border
              : isSelected
                  ? AppColors.primary500
                  : const Color(0xFFD1D5DB),
          width: isSelected ? 6 : 2,
        ),
        color: isSelected ? AppColors.primary500 : Colors.white,
      ),
      child: isSelected
          ? const Center(
              child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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
          child: ElevatedButton(
            onPressed: _canProceed
                ? () => Navigator.pop(context, _resolvedMethod)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _canProceed ? AppColors.primary500 : Colors.grey.shade300,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _canProceed ? 4 : 0,
              shadowColor: _canProceed
                  ? AppColors.primary500.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            child: Text(
              _canProceed
                  ? '${FormatUtils.formatCurrency(widget.totalAmount)}원 결제하기'
                  : '결제 수단을 선택해주세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _canProceed ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 버튼 바로 아래에 메뉴를 표시하는 커스텀 드롭다운
///
/// Flutter 기본 DropdownButton은 메뉴 위치를 제어할 수 없어
/// showMenu + GlobalKey로 버튼 좌표를 직접 계산합니다.
class _PositionedDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final String hint;
  final ValueChanged<T?> onChanged;

  const _PositionedDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_PositionedDropdown<T>> createState() => _PositionedDropdownState<T>();
}

class _PositionedDropdownState<T> extends State<_PositionedDropdown<T>> {
  final _buttonKey = GlobalKey();

  Future<void> _openMenu() async {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    // 버튼 바로 아래에서 시작, 최대 높이 제한으로 스크롤 가능
    final selected = await showMenu<T>(
      context: context,
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4, // 버튼 하단 + 4px 간격
        offset.dx + size.width,
        0,
      ),
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: 240, // 약 5~6개 표시, 이후 스크롤
      ),
      items: widget.items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              height: 44,
              child: Text(
                widget.labelOf(item),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.value == item
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.value == item
                      ? AppColors.primary500
                      : AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;

    return GestureDetector(
      onTap: _openMenu,
      child: Container(
        key: _buttonKey,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? widget.labelOf(widget.value as T) : widget.hint,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
