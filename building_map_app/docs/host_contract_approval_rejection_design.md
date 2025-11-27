# 호스트 계약 승인/거절 기능 설계

## 개요
호스트가 게스트의 계약 요청을 승인하거나 거절할 수 있는 기능 설계.
React UI를 Flutter로 완전 복제하며, 백엔드 API와 통합.

---

## 1. 기능 요구사항

### 1.1 계약 승인 (Approve)
1. 승인 버튼 클릭
2. 확인 다이얼로그 표시
3. 확인 시 → **게스트 입주 준비 모달** 표시
4. 권장 렌탈 아이템 선택 (선택사항)
5. API 호출: `PATCH /api/contracts/:contractId/approve`
6. 성공 시 → 계약 상태 업데이트 + 페이지 새로고침

### 1.2 계약 거절 (Reject)
1. 거절 버튼 클릭
2. **거절 사유 입력 모달** 표시
3. 거절 사유 입력 (필수)
4. API 호출: `PATCH /api/contracts/:contractId/reject`
5. 성공 시 → 계약 상태 업데이트 + 페이지 새로고침

---

## 2. UI 설계 (React → Flutter)

### 2.1 거절 모달 (Rejection Modal)

#### React 코드 분석 (HostContractManagement.tsx:753-784)
```tsx
<div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
  <div className="bg-white rounded-xl p-6 max-w-md w-full shadow-xl">
    <h3 className="font-bold text-lg text-gray-900 mb-4">계약 거절</h3>
    <p className="text-sm text-gray-600 mb-4">게스트에게 전달할 거절 사유를 입력해주세요.</p>
    <textarea
      value={rejectMessage}
      onChange={(e) => setRejectMessage(e.target.value)}
      placeholder="거절 사유를 입력해주세요"
      className="w-full h-24 px-3 py-2 border border-gray-300 rounded-lg resize-none text-sm mb-4"
    />
    <div className="flex gap-2">
      <button className="flex-1 py-2.5 bg-white border-2 border-gray-300 text-gray-700 rounded-lg">
        취소
      </button>
      <button className="flex-1 py-2.5 bg-red-600 text-white rounded-lg">
        거절하기
      </button>
    </div>
  </div>
</div>
```

#### Flutter 위젯 설계
```dart
// 파일: lib/widgets/modals/host_contract_rejection_modal.dart

class HostContractRejectionModal extends StatefulWidget {
  final int contractId;
  final VoidCallback onClose;
  final Function(String rejectionReason) onConfirm;

  const HostContractRejectionModal({
    required this.contractId,
    required this.onClose,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  State<HostContractRejectionModal> createState() => _HostContractRejectionModalState();
}

class _HostContractRejectionModalState extends State<HostContractRejectionModal> {
  final TextEditingController _rejectionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final reason = _rejectionController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거절 사유를 입력해주세요.')),
      );
      return;
    }

    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md (28rem)
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
                  '계약 거절',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),

                // 설명
                const Text(
                  '게스트에게 전달할 거절 사유를 입력해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),

                // textarea
                TextField(
                  controller: _rejectionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '거절 사유를 입력해주세요',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // 버튼
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : widget.onClose,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 거절하기 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // red-600
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '거절하기',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
```

### 2.2 게스트 입주 준비 모달 (Guest Preparation Modal)

#### React 코드 분석 (HostContractManagement.tsx:857-928)
```tsx
<div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
  <div className="bg-white rounded-xl p-6 max-w-md w-full shadow-xl">
    <h3 className="font-bold text-xl text-gray-900 mb-4">게스트 입주 도와주기</h3>
    <p className="text-[rgb(0,0,0)] mb-4 leading-relaxed text-[16px]">
      이지스테이에서 게스트가 입주에 필요한 상품들을 미리 선택 구매할 수 있도록 안내할 수 있어요.
    </p>

    <div className="mb-6">
      <p className="text-sm text-gray-700 mb-3 font-bold">권장하실 옵션 상품을 선택해주세요:</p>
      <div className="grid grid-cols-2 gap-3">
        {['침구류 대여', '드라이기', '욕실용품', '타올'].map((item) => (
          <label
            key={item}
            className="flex items-center gap-2 p-3 border-2 rounded-lg cursor-pointer transition-all hover:border-blue-300"
            style={{
              borderColor: selectedRentalItems.includes(item) ? '#3B82F6' : '#E5E7EB',
              backgroundColor: selectedRentalItems.includes(item) ? '#EFF6FF' : 'white'
            }}
          >
            <input
              type="checkbox"
              checked={selectedRentalItems.includes(item)}
              className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-bold text-gray-900">{item}</span>
          </label>
        ))}
      </div>
    </div>
    <div className="flex gap-2">
      <button
        disabled={selectedRentalItems.length === 0}
        className={`flex-1 py-2.5 rounded-lg transition-colors font-bold ${
          selectedRentalItems.length === 0
            ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
            : 'bg-blue-600 text-white hover:bg-blue-700'
        }`}
      >
        자동 안내
      </button>
      <button className="flex-1 py-2.5 bg-white border-2 border-gray-300 text-gray-700 rounded-lg">
        취소
      </button>
    </div>
  </div>
</div>
```

#### Flutter 위젯 설계
```dart
// 파일: lib/widgets/modals/guest_preparation_modal.dart

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
  // 렌탈 아이템 목록 (실제로는 API에서 가져와야 함)
  final List<RentalItem> _availableItems = [
    RentalItem(id: 1, name: '침구류 대여'),
    RentalItem(id: 2, name: '드라이기'),
    RentalItem(id: 3, name: '욕실용품'),
    RentalItem(id: 4, name: '타올'),
  ];

  final Set<int> _selectedItemIds = {};
  bool _isSubmitting = false;

  void _toggleItem(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _handleSubmit() {
    if (_selectedItemIds.isEmpty) return;
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

                // 2열 그리드
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _availableItems.length,
                  itemBuilder: (context, index) {
                    final item = _availableItems[index];
                    final isSelected = _selectedItemIds.contains(item.id);

                    return GestureDetector(
                      onTap: () => _toggleItem(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
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
                                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
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
                const SizedBox(height: 24),

                // 버튼
                Row(
                  children: [
                    // 자동 안내 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _selectedItemIds.isEmpty) ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedItemIds.isEmpty
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF2563EB),
                          foregroundColor: _selectedItemIds.isEmpty
                              ? const Color(0xFF6B7280)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '자동 안내',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

// 렌탈 아이템 모델
class RentalItem {
  final int id;
  final String name;

  RentalItem({required this.id, required this.name});
}
```

---

## 3. API 통합 설계

### 3.1 ContractService 메서드 추가

```dart
// 파일: lib/services/contract_service.dart

/// 계약 승인 (호스트)
Future<Map<String, dynamic>> approveContract(
  int contractId, {
  List<Map<String, dynamic>>? recommendedItems,
}) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/approve');

    final requestBody = recommendedItems != null
        ? {
            'recommendedItems': {
              'items': recommendedItems,
            },
          }
        : null;

    final response = await _apiClient.patch(
      url,
      headers: await _getAuthHeaders(),
      body: requestBody != null ? jsonEncode(requestBody) : null,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ [CONTRACT_APPROVE] 계약 승인 성공: $contractId');
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? '계약 승인에 실패했습니다.');
    }
  } on SocketException {
    throw Exception('네트워크 연결을 확인해주세요.');
  } on HttpException {
    throw Exception('서버 응답 오류가 발생했습니다.');
  } catch (e) {
    debugPrint('❌ [CONTRACT_APPROVE] 계약 승인 실패: $e');
    rethrow;
  }
}

/// 계약 거절 (호스트)
Future<Map<String, dynamic>> rejectContract(
  int contractId,
  String rejectionReason,
) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/contracts/$contractId/reject');

    final response = await _apiClient.patch(
      url,
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        'hostMessage': rejectionReason,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ [CONTRACT_REJECT] 계약 거절 성공: $contractId');
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? '계약 거절에 실패했습니다.');
    }
  } on SocketException {
    throw Exception('네트워크 연결을 확인해주세요.');
  } on HttpException {
    throw Exception('서버 응답 오류가 발생했습니다.');
  } catch (e) {
    debugPrint('❌ [CONTRACT_REJECT] 계약 거절 실패: $e');
    rethrow;
  }
}

Future<Map<String, String>> _getAuthHeaders() async {
  final token = await _tokenService.getAccessToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
```

---

## 4. 페이지 통합 설계 (host_contracts_page_new.dart)

### 4.1 상태 변수 추가
```dart
class _HostContractsPageNewState extends State<HostContractsPageNew> {
  // 기존 상태 변수...

  // 거절 모달 상태
  bool _showRejectionModal = false;
  int? _selectedContractIdForRejection;

  // 게스트 입주 준비 모달 상태
  bool _showGuestPreparationModal = false;
  int? _selectedContractIdForApproval;

  // ...
}
```

### 4.2 버튼 클릭 핸들러
```dart
/// 승인 버튼 클릭
Future<void> _handleApprove(int contractId) async {
  // 확인 다이얼로그
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('계약 승인'),
      content: const Text('이 계약 요청을 승인하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('승인'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // 게스트 입주 준비 모달 표시
  setState(() {
    _selectedContractIdForApproval = contractId;
    _showGuestPreparationModal = true;
  });
}

/// 거절 버튼 클릭
void _handleReject(int contractId) {
  setState(() {
    _selectedContractIdForRejection = contractId;
    _showRejectionModal = true;
  });
}

/// 승인 API 호출 (권장 아이템 포함)
Future<void> _submitApproval(List<int> selectedItemIds) async {
  if (_selectedContractIdForApproval == null) return;

  setState(() {
    _showGuestPreparationModal = false;
  });

  try {
    // API 호출 (권장 아이템 포함)
    final recommendedItems = selectedItemIds
        .map((itemId) => {'itemId': itemId, 'quantity': 1})
        .toList();

    await _contractService.approveContract(
      _selectedContractIdForApproval!,
      recommendedItems: recommendedItems.isEmpty ? null : recommendedItems,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계약이 승인되었습니다. 게스트가 결제하면 계약이 확정됩니다.')),
    );

    // 계약 목록 새로고침
    await _loadContracts();

    setState(() {
      _selectedContractIdForApproval = null;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('계약 승인 실패: $e')),
    );
  }
}

/// 거절 API 호출
Future<void> _submitRejection(String rejectionReason) async {
  if (_selectedContractIdForRejection == null) return;

  setState(() {
    _showRejectionModal = false;
  });

  try {
    await _contractService.rejectContract(
      _selectedContractIdForRejection!,
      rejectionReason,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계약이 거절되었습니다.')),
    );

    // 계약 목록 새로고침
    await _loadContracts();

    setState(() {
      _selectedContractIdForRejection = null;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('계약 거절 실패: $e')),
    );
  }
}
```

### 4.3 기존 버튼 수정 (onPressed 연결)
```dart
Widget _buildActionButtons() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ElevatedButton.icon(
        onPressed: () => _handleApprove(contract.id), // ✅ 추가
        icon: const Icon(Icons.check, size: 16),
        label: const Text('승인하기', ...),
        // ...
      ),
      const SizedBox(width: 12),
      OutlinedButton.icon(
        onPressed: () => _handleReject(contract.id), // ✅ 추가
        icon: const Icon(Icons.close, size: 16),
        label: const Text('거절하기', ...),
        // ...
      ),
    ],
  );
}
```

### 4.4 모달 표시 (Scaffold의 Stack)
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppGnb(currentRoute: '/host/contracts'),
    body: Stack(
      children: [
        // 기존 페이지 콘텐츠
        _buildPageContent(),

        // 거절 모달
        if (_showRejectionModal && _selectedContractIdForRejection != null)
          HostContractRejectionModal(
            contractId: _selectedContractIdForRejection!,
            onClose: () {
              setState(() {
                _showRejectionModal = false;
                _selectedContractIdForRejection = null;
              });
            },
            onConfirm: _submitRejection,
          ),

        // 게스트 입주 준비 모달
        if (_showGuestPreparationModal && _selectedContractIdForApproval != null)
          GuestPreparationModal(
            contractId: _selectedContractIdForApproval!,
            onClose: () {
              setState(() {
                _showGuestPreparationModal = false;
                _selectedContractIdForApproval = null;
              });
            },
            onConfirm: _submitApproval,
          ),
      ],
    ),
  );
}
```

---

## 5. 에러 핸들링

### 5.1 API 에러 처리
- **400 Bad Request (이미 처리된 계약)**: "이미 처리된 계약입니다."
- **401 Unauthorized**: "로그인이 필요합니다."
- **403 Forbidden**: "권한이 없습니다."
- **404 Not Found**: "계약을 찾을 수 없습니다."
- **네트워크 에러**: "네트워크 연결을 확인해주세요."
- **기타 에러**: "요청 처리 중 오류가 발생했습니다."

### 5.2 사용자 입력 검증
- **거절 사유**: 필수, 빈 문자열 불가
- **권장 아이템**: 선택사항, 빈 목록 허용

---

## 6. 테스트 시나리오

### 6.1 계약 승인 플로우
1. ✅ 승인 버튼 클릭 → 확인 다이얼로그 표시
2. ✅ 확인 → 게스트 입주 준비 모달 표시
3. ✅ 권장 아이템 선택 (0~4개)
4. ✅ "자동 안내" 버튼 클릭 → API 호출
5. ✅ 성공 → SnackBar 표시 + 목록 새로고침
6. ✅ 실패 → 에러 SnackBar 표시

### 6.2 계약 거절 플로우
1. ✅ 거절 버튼 클릭 → 거절 모달 표시
2. ✅ 거절 사유 입력
3. ✅ "거절하기" 버튼 클릭 → API 호출
4. ✅ 성공 → SnackBar 표시 + 목록 새로고침
5. ✅ 실패 → 에러 SnackBar 표시
6. ✅ 빈 사유 입력 → 검증 에러 표시

---

## 7. 구현 체크리스트

### Phase 1: 모달 위젯 생성
- [ ] `lib/widgets/modals/host_contract_rejection_modal.dart` 생성
- [ ] `lib/widgets/modals/guest_preparation_modal.dart` 생성
- [ ] React UI와 스타일 완전 일치 확인

### Phase 2: ContractService API 메서드 추가
- [ ] `approveContract()` 메서드 추가
- [ ] `rejectContract()` 메서드 추가
- [ ] 에러 핸들링 구현

### Phase 3: 페이지 통합
- [ ] `host_contracts_page_new.dart`에 상태 변수 추가
- [ ] 버튼 onPressed 핸들러 연결
- [ ] 모달 표시 로직 추가 (Stack)
- [ ] API 호출 및 에러 핸들링

### Phase 4: 테스트
- [ ] 승인 플로우 테스트 (권장 아이템 0개)
- [ ] 승인 플로우 테스트 (권장 아이템 1~4개)
- [ ] 거절 플로우 테스트 (정상)
- [ ] 거절 플로우 테스트 (빈 사유)
- [ ] 에러 시나리오 테스트 (네트워크, 권한, 등)

---

## 8. 주의사항

1. **React UI 완전 복제**: 색상, 간격, 폰트 크기, 애니메이션 모두 동일하게
2. **버튼 상태 관리**: 로딩 중 버튼 비활성화, CircularProgressIndicator 표시
3. **모달 배경**: `Colors.black.withOpacity(0.5)` 반투명 검은색
4. **토큰 자동 갱신**: ApiClient에서 401 에러 시 자동 갱신 처리
5. **권장 아이템 ID 매핑**: 실제 백엔드 렌탈 아이템 ID와 일치하도록 설정

---

## 9. API 명세 (재정리)

### 9.1 계약 승인
- **Method**: `PATCH`
- **URL**: `/api/contracts/:contractId/approve`
- **Headers**: `Authorization: Bearer {accessToken}`
- **Request Body** (선택):
  ```json
  {
    "recommendedItems": {
      "items": [
        { "itemId": 1, "quantity": 1 },
        { "itemId": 3, "quantity": 2 }
      ]
    }
  }
  ```
- **Response** (200):
  ```json
  {
    "success": true,
    "message": "계약이 승인되었습니다.",
    "data": {
      "contractId": 1,
      "status": "APPROVED",
      "statusLabel": "승인됨",
      "approvedAt": "2025-01-27T10:30:00Z"
    }
  }
  ```

### 9.2 계약 거절
- **Method**: `PATCH`
- **URL**: `/api/contracts/:contractId/reject`
- **Headers**: `Authorization: Bearer {accessToken}`
- **Request Body** (필수):
  ```json
  {
    "hostMessage": "죄송합니다. 해당 기간에는 다른 예약이 있습니다."
  }
  ```
- **Response** (200):
  ```json
  {
    "success": true,
    "message": "계약이 거절되었습니다.",
    "data": {
      "contractId": 1,
      "status": "REJECTED"
    }
  }
  ```
