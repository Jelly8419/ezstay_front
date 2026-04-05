import 'package:flutter/material.dart';
import '../../services/contract_service.dart';

/// 게스트 입주 준비 모달 (렌탈 아이템 권장)
/// React UI: HostContractManagement.tsx (lines 857-928)
class GuestPreparationModal extends StatefulWidget {
  final int contractId;
  final VoidCallback onClose;
  final Function(List<int> selectedItemIds) onConfirm;

  const GuestPreparationModal({
    required this.contractId,
    required this.onClose,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  State<GuestPreparationModal> createState() => _GuestPreparationModalState();
}

class _GuestPreparationModalState extends State<GuestPreparationModal> {
  final ContractService _contractService = ContractService();

  List<RentalItem> _availableItems = [];
  final Set<int> _selectedItemIds = {};
  bool _noneOption = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRentalItems();
  }

  /// API에서 렌탈 아이템 목록 조회
  Future<void> _loadRentalItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final items = await _contractService.getAllRentalItems();

      if (items != null && items.isNotEmpty) {
        setState(() {
          _availableItems = items
              .map((item) => RentalItem(
                    id: item['id'] as int,
                    name: item['name'] as String,
                  ))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '옵션 상품 목록이 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '옵션 상품을 불러오는데 실패했습니다: $e';
      });
    }
  }

  void _toggleNone() {
    setState(() {
      _noneOption = !_noneOption;
      if (_noneOption) _selectedItemIds.clear();
    });
  }

  void _toggleItem(int itemId) {
    setState(() {
      _noneOption = false;
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  bool get _canSubmit => _noneOption || _selectedItemIds.isNotEmpty;

  void _handleSubmit() {
    if (!_canSubmit) return;
    widget.onConfirm(_selectedItemIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                const Text(
                  '게스트 입주 도와주기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),

                // 설명
                const Text(
                  '이지스테이에서 게스트가 입주에 필요한 상품들을 미리 선택 구매할 수 있도록 안내할 수 있어요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // 옵션 상품 선택
                const Text(
                  '권장하실 옵션 상품을 선택해주세요:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),

                // 로딩/에러/데이터 표시
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFDC2626), size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFDC2626),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // 2열 그리드 + 없음 옵션
                  Column(
                    children: [
                      if (_availableItems.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: _availableItems.length,
                          itemBuilder: (context, index) {
                            final item = _availableItems[index];
                            final isSelected =
                                _selectedItemIds.contains(item.id);

                            return GestureDetector(
                              onTap: () => _toggleItem(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    // 체크박스
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFFD1D5DB),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              size: 12, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    // 아이템 이름
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      // 없음 옵션
                      GestureDetector(
                        onTap: _toggleNone,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _noneOption
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            border: Border.all(
                              color: _noneOption
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _noneOption
                                      ? const Color(0xFF2563EB)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _noneOption
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFD1D5DB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _noneOption
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '없음',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // 버튼
                Row(
                  children: [
                    // 확인 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _isLoading || !_canSubmit)
                            ? null
                            : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSubmit
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD1D5DB),
                          foregroundColor: _canSubmit
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                '확인',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : widget.onClose,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                              color: Color(0xFFD1D5DB), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 렌탈 아이템 모델
class RentalItem {
  final int id;
  final String name;

  RentalItem({required this.id, required this.name});
}
