import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/room.dart';
import '../../models/refund_policy.dart';
import '../../models/calculated_pricing.dart';
import '../../services/contract_service.dart';
import '../../services/refund_policy_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 계약 요청하기 페이지
/// PRD: 반드시 상세페이지에서 전달받은 calculatedPricing 값을 그대로 사용하고 재계산 금지
class ContractStartPage extends StatefulWidget {
  final Room room;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final CalculatedPricing calculatedPricing;
  final List<SelectedRentalItem> selectedRentalItems;

  const ContractStartPage({
    super.key,
    required this.room,
    this.checkInDate,
    this.checkOutDate,
    required this.calculatedPricing,
    this.selectedRentalItems = const [],
  });

  @override
  State<ContractStartPage> createState() => _ContractStartPageState();
}

class _ContractStartPageState extends State<ContractStartPage> {
  final _currencyFormat = NumberFormat('#,###');
  final _messageController = TextEditingController();
  late final ContractService _contractService;
  final RefundPolicyService _refundPolicyService = RefundPolicyService();
  bool _isLoading = false;

  // 환불 정책
  RefundPolicy? _refundPolicy;
  bool _isLoadingPolicy = false;

  // 날짜 선택 여부 확인
  bool get _hasValidDates =>
      widget.checkInDate != null && widget.checkOutDate != null;

  // 계약 요청 가능 여부
  bool get _canSubmit => _hasValidDates && widget.calculatedPricing.isValid;

  @override
  void initState() {
    super.initState();
    _contractService = ContractService();
    _loadRefundPolicy();
  }

  /// 환불 정책 로드
  Future<void> _loadRefundPolicy() async {
    if (widget.room.refundPolicy.isEmpty) return;

    setState(() {
      _isLoadingPolicy = true;
    });

    try {
      final policy = await _refundPolicyService.getRefundPolicyByType(
        widget.room.refundPolicy,
      );
      if (mounted) {
        setState(() {
          _refundPolicy = policy;
          _isLoadingPolicy = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CONTRACT_START] 환불 정책 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingPolicy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// 날짜 포맷: YYYY.MM.DD(요일)
  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${DateFormat('yyyy.MM.dd').format(date)}($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      appBar: AppBar(
        title: const Text('계약 요청하기'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ResponsivePageLayout(
        maxWidth: 1400,
        scrollable: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 메인 컨텐츠
            Expanded(
              flex: isWideScreen ? 3 : 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 미선택 경고
                    if (!_hasValidDates) _buildDateWarning(),

                    // 방 정보 섹션 (이미지 포함)
                    _buildRoomInfoSection(isWideScreen),
                    const SizedBox(height: 24),

                    // 호스트 정보 섹션 (아바타 포함)
                    _buildHostInfoSection(),
                    const SizedBox(height: 24),

                    // 옵션 상품 섹션 (항상 표시, 빈 상태 UI 포함)
                    _buildRentalItemsSection(),
                    const SizedBox(height: 24),

                    // 호스트에게 전할 메시지
                    _buildHostMessageSection(),
                    const SizedBox(height: 24),

                    // 모바일: 예상 금액 카드 (React와 동일한 위치)
                    if (!isWideScreen) ...[
                      _buildMobilePaymentSummaryCard(),
                      const SizedBox(height: 24),
                    ],

                    // 계약 해지 조항 (안내사항 포함)
                    _buildCancellationPolicyWithNotice(),

                    // 모바일용 여백
                    if (!isWideScreen) const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // 오른쪽: 결제 금액 (데스크톱에서만 표시)
            if (isWideScreen) ...[
              const SizedBox(width: 24),
              SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: _buildPaymentSummaryCard(),
                ),
              ),
            ],
          ],
        ),
      ),
      // 모바일/태블릿용 하단 고정 버튼 (버튼만, 금액은 위에 표시)
      bottomNavigationBar: !isWideScreen
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(top: false, child: _buildSubmitButton()),
            )
          : null,
    );
  }

  /// 날짜 미선택 경고 박스
  Widget _buildDateWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        border: Border.all(color: const Color(0xFFFFE066)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD4A000),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '날짜를 선택해주세요',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B6914),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '체크인/체크아웃 날짜를 선택해야 계약을 요청할 수 있습니다.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 방 정보 섹션 (이미지 포함)
  /// React: 모바일에서 세로 배열, 데스크톱에서 가로 배열
  Widget _buildRoomInfoSection(bool isWideScreen) {
    final thumbnailUrl = widget.room.photos.isNotEmpty
        ? widget.room.photos.first.url
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기본 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 방 이미지 + 정보 (모바일: 세로, 데스크톱: 가로)
          if (isWideScreen)
            // 데스크톱: 가로 배열
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 데스크톱: 고정 너비 (Row 내에서는 width 지정 필수)
                SizedBox(
                  width: 180,
                  height: 180,
                  child: _buildRoomImageContent(thumbnailUrl),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildRoomDetails()),
              ],
            )
          else
            // 모바일: 세로 배열 (React와 동일)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomImage(thumbnailUrl, 192), // h-48 = 192px
                const SizedBox(height: 16),
                _buildRoomDetails(),
              ],
            ),
        ],
      ),
    );
  }

  /// 방 이미지 위젯 (모바일용 - width: infinity)
  Widget _buildRoomImage(String? thumbnailUrl, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _buildRoomImageContent(thumbnailUrl),
      ),
    );
  }

  /// 방 이미지 컨텐츠 (공통)
  Widget _buildRoomImageContent(String? thumbnailUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.home, color: Colors.grey),
              ),
            )
          : Container(
              color: Colors.grey[200],
              child: const Icon(Icons.home, size: 40, color: Colors.grey),
            ),
    );
  }

  /// 방 상세 정보 위젯
  Widget _buildRoomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방 이름 (React: text-[20px] font-bold)
        Text(
          widget.room.roomName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827), // gray-900
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        // 주소 (React: "주소    {주소값}, {층}")
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '주소',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              child: Text(
                '${widget.room.address}, ${widget.room.floor}층',
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 계약기간 (React: "계약 기간    날짜 - 날짜 (X일)")
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '계약 기간',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              child: _hasValidDates
                  ? RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_formatDate(widget.checkInDate!)} - ${_formatDate(widget.checkOutDate!)} ',
                          ),
                          TextSpan(
                            text: '(${widget.calculatedPricing.totalDays}일)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '날짜가 선택되지 않았습니다',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// 호스트 정보 섹션 (아바타 + 소개문 포함)
  /// React: title="호스트", avatar w-12 h-12 (48px), introduction text
  Widget _buildHostInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: "호스트"
          const Text(
            '호스트',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 호스트 아바타 (React: w-12 h-12 = 48px)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE), // blue-100
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFF2563EB), // blue-600
                ),
              ),
              const SizedBox(width: 12),
              // 호스트 정보 (React: name)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.hostName ?? '호스트',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    // TODO: Room 모델에 hostIntroduction 추가 후 소개문 표시
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 호스트 연락처 안내 (React: bg-blue-50 border-blue-100)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF2563EB), // blue-600
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '호스트의 연락처는 계약이 확정된 후 공개됩니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E40AF), // blue-800
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 옵션 상품 섹션 (빈 상태 UI 포함)
  /// React: title "옵션 상품 (X개 선택)" format, 빈 상태 메시지 표시
  Widget _buildRentalItemsSection() {
    final hasItems = widget.selectedRentalItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: "옵션 상품" + "(X개 선택)" in gray
          Row(
            children: [
              const Text(
                '옵션 상품',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.selectedRentalItems.length}개 선택)',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // React: 빈 상태 UI (옵션 없을 때)
          if (!hasItems)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    '선택한 옵션 상품이 없습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '방 상세페이지에서 옵션 상품을 선택해주세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            // 옵션 상품 목록
            ...widget.selectedRentalItems.map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (item.description != null &&
                              item.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_currencyFormat.format(item.price)}원 x ${item.quantity}개',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2563EB), // blue-600
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_currencyFormat.format(item.totalPrice)}원',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // React: 옵션 상품 안내 (파란색 박스)
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF2563EB), // blue-600
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '옵션 상품은 계약 승인 후에도 입주 5일 전까지 추가로 구매할 수 있습니다.(각 최대 4개)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E40AF), // blue-800
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 호스트에게 전할 메시지 섹션
  /// React: title "호스트에게 하고싶은 말이나 방문 목적"
  Widget _buildHostMessageSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '임대 목적 (선택사항)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // React: textarea with multi-line placeholder
          Stack(
            children: [
              TextField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 500,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      '예) 오후 3시쯤 입주 예정입니다. 짐이 많아 차량으로 이동할 예정입니다.\n예) 출장 목적으로 1개월간 머물 예정입니다.\n예) 가족 2명이 함께 이용할 예정입니다.',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ), // blue-500
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 14),
              ),
              // Character count (React: bottom-right inside textarea)
              Positioned(
                bottom: 12,
                right: 12,
                child: Text(
                  '${_messageController.text.length}/500',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // React: helper text with asterisk
          Text(
            '임대 목적을 호스트에게 미리 전달해주세요.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 결제 금액 카드 (오른쪽 고정)
  Widget _buildPaymentSummaryCard() {
    final pricing = widget.calculatedPricing;
    final hasDiscount = pricing.discount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '결제 금액',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 금액 상세
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPriceRow(
                  '임대료 (${pricing.totalDays}일)',
                  pricing.rentalFee,
                ),
                // 할인
                if (hasDiscount) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow(
                    pricing.discountType == 'long_term'
                        ? '장기계약 할인'
                        : pricing.discountType == 'quick_move_in'
                        ? '빠른 입주 할인'
                        : '할인',
                    -pricing.discount,
                    isDiscount: true,
                  ),
                ],
                const SizedBox(height: 10),
                _buildPriceRow(
                  '관리비 (${pricing.totalDays}일)',
                  pricing.maintenanceFee,
                ),
                const SizedBox(height: 10),
                _buildPriceRow('청소비', pricing.cleaningFee),
                if (pricing.rentalItemsFee > 0) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow('옵션 상품', pricing.rentalItemsFee),
                ],
                const SizedBox(height: 10),
                // React: "계약 수수료" (not "플랫폼 수수료")
                _buildPriceRow('계약 수수료', pricing.platformFee),

                const Divider(height: 32),

                // React: "실이용 금액" with blue value (text-blue-600)
                _buildPriceRow(
                  '실이용 금액',
                  pricing.totalUsageFee,
                  isBold: true,
                  fontSize: 15,
                  valueColor: const Color(0xFF2563EB), // blue-600
                ),

                const SizedBox(height: 16),
                const Divider(height: 32),

                _buildPriceRow('보증금(퇴실 후 환급)', pricing.deposit, isGrey: true),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(left: 4)),

                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '* 보증금은 3자 예치기관에 보관되며, 퇴실 완료 후 2일 내 자동 환급\n됩니다.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPriceRow(
                  '최종 예상 금액',
                  pricing.finalTotalAmount,
                  isBold: true,
                  fontSize: 18,
                  valueColor: const Color(0xFFDC2626), // red-600
                ),

                const SizedBox(height: 20),

                // 입주 매너 안내 (결제 카드 내부로 이동)
                _buildMoveInEtiquetteCompact(),
              ],
            ),
          ),

          // 계약 요청 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  /// 입주 매너 안내 (결제 카드 내부용 - 컴팩트 버전)
  Widget _buildMoveInEtiquetteCompact() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // gray-50
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: AlertCircle icon w-5 h-5 text-gray-600
          Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '방 입주 매너',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // gray-900
                  ),
                ),
                const SizedBox(height: 8),
                // React bullet items
                _buildBulletTextCompact('실내에서는 슬리퍼나 양말을 착용해주세요.'),
                _buildBulletTextCompact(
                  '쓰레기는 반드시 날짜 혹은 요일을 준수해서 손쉽게 버려주셔야 합니다.',
                ),
                _buildBulletTextCompact('입주 전 반려동물 동반 및 흡연은 금지입니다.'),
                _buildBulletTextCompact('입주 48시간 이내 방문은 언제든지 방문해주세요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 불릿 텍스트 (컴팩트 버전)
  Widget _buildBulletTextCompact(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 모바일용 결제 금액 카드 (React와 동일한 위치 - 컨텐츠 중간)
  Widget _buildMobilePaymentSummaryCard() {
    final pricing = widget.calculatedPricing;
    final hasDiscount = pricing.discount > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예상 금액',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 금액 상세
          _buildPriceRow('임대료 (${pricing.totalDays}일)', pricing.rentalFee),
          // 할인
          if (hasDiscount) ...[
            const SizedBox(height: 10),
            _buildPriceRow(
              pricing.discountType == 'long_term'
                  ? '장기계약 할인'
                  : pricing.discountType == 'quick_move_in'
                  ? '빠른 입주 할인'
                  : '할인',
              -pricing.discount,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 10),
          _buildPriceRow('관리비 (${pricing.totalDays}일)', pricing.maintenanceFee),
          const SizedBox(height: 10),
          _buildPriceRow('청소비', pricing.cleaningFee),
          if (pricing.rentalItemsFee > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow('옵션 상품', pricing.rentalItemsFee),
          ],
          const SizedBox(height: 10),
          _buildPriceRow('계약 수수료', pricing.platformFee),

          const Divider(height: 32),

          // 실이용 금액 (React: text-blue-600)
          _buildPriceRow(
            '실이용 금액',
            pricing.totalUsageFee,
            isBold: true,
            fontSize: 15,
            valueColor: const Color(0xFF2563EB), // blue-600
          ),

          const SizedBox(height: 16),
          const Divider(height: 32),

          _buildPriceRow('보증금(퇴실 후 환급)', pricing.deposit, isGrey: true),
          const SizedBox(height: 8),

          const Divider(height: 32),
          Text(
            '* 보증금은 3자 예치기관에 보관되며, 퇴실 완료 후 2일 내 자동 환급\n됩니다.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          _buildPriceRow(
            '최종 예상 금액',
            pricing.finalTotalAmount,
            isBold: true,
            fontSize: 18,
            valueColor: const Color(0xFFDC2626), // red-600
          ),

          const SizedBox(height: 20),

          // 입주 매너 안내 (모바일에서도 표시 - React와 동일)
          _buildMoveInEtiquetteCompact(),
        ],
      ),
    );
  }

  /// 계약 해지 조항 + 안내사항 통합 (React: 안내사항이 해지 조항 내부에 위치)
  Widget _buildCancellationPolicyWithNotice() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '계약 해지 조항',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              // 환불 정책 라벨
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRefundPolicyColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getRefundPolicyLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getRefundPolicyColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 로딩 중
          if (_isLoadingPolicy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          // API에서 로드한 환불 정책 표시
          else if (_refundPolicy != null) ...[
            ..._refundPolicy!.rules.map((rule) {
              final cancellationText = _calculateCancellationText(rule);
              return _buildBulletText(cancellationText);
            }),
          ]
          // Fallback: 하드코딩된 기본값 (API 실패 시)
          else ...[
            _buildBulletText('환불 정책을 불러오는데 실패했습니다.'),
            _buildBulletText('자세한 환불 규정은 호스트에게 문의해주세요.'),
          ],

          const SizedBox(height: 20),

          // 안내사항 (React: 계약 해지 조항 내부에 위치)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF2563EB), // blue-600
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '안내사항',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF), // blue-800
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNoticeBulletText(
                  '결제 당일 취소 시, 환불 규정과 관계 없이 임대료와 계약 수수료를 합계한 10%만 위약금으로 부과됩니다.',
                ),

                // API에서 로드한 특별 규칙 표시
                if (_refundPolicy?.specialRules?.alwaysRefund != null)
                  _buildNoticeBulletText(
                    _refundPolicy!.specialRules!.alwaysRefund!,
                  )
                else
                  _buildNoticeBulletText('관리비, 청소비, 보증금은 전액 환불됩니다.'),

                _buildNoticeBulletText('환불 규정은 호스트의 설정에 따라 달라집니다.'),
                _buildNoticeBulletText(
                  '계약 승인 요청 후 호스트가 24시간 내에 응답하지 않으면 자동 취소됩니다.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 안내사항 불릿 텍스트 (blue 스타일)
  Widget _buildNoticeBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB), // blue-600
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E40AF), // blue-800
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 가격 행
  Widget _buildPriceRow(
    String label,
    int price, {
    bool isBold = false,
    bool isGrey = false,
    bool isDiscount = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isGrey ? Colors.grey[600] : Colors.black87,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}${_currencyFormat.format(price.abs())}원',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color:
                valueColor ??
                (isDiscount
                    ? const Color(0xFF2563EB)
                    : (isGrey ? Colors.grey[600] : Colors.black87)),
          ),
        ),
      ],
    );
  }

  /// 환불 정책 라벨
  String _getRefundPolicyLabel() {
    switch (widget.room.refundPolicy.toLowerCase()) {
      case 'flexible':
        return '유연';
      case 'moderate':
        return '보통';
      case 'strict':
        return '엄격';
      default:
        return '기본';
    }
  }

  /// 환불 정책 색상
  Color _getRefundPolicyColor() {
    switch (widget.room.refundPolicy.toLowerCase()) {
      case 'flexible':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'strict':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 환불 규칙을 텍스트로 변환 (원본 그대로 표시)
  String _calculateCancellationText(RefundRule rule) {
    final description = rule.description;
    final refundRate = rule.refundRate;

    // 환불 불가인 경우
    if (refundRate == 0) {
      return '$description : 환불 불가';
    }

    // 일반적인 경우: 원본 텍스트 + 환불율
    return '$description : 임대료의 $refundRate% 환불';
  }

  /// 불릿 텍스트
  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 계약 요청하기 버튼 (React: "계약 요청하기")
  Widget _buildSubmitButton() {
    String buttonText;
    if (!_hasValidDates) {
      buttonText = '날짜를 선택해주세요';
    } else {
      buttonText = '계약 요청하기'; // React와 동일
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _canSubmit && !_isLoading
            ? _showContractRequestDialog
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canSubmit ? AppColors.primary600 : Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                buttonText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _canSubmit ? Colors.white : Colors.grey[500],
                ),
              ),
      ),
    );
  }

  /// 계약 요청 확인 다이얼로그
  void _showContractRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('계약 승인 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('계약 승인을 요청하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최종 결제 금액',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currencyFormat.format(widget.calculatedPricing.finalTotalAmount)}원',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '호스트가 승인하면 결제가 진행됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestContract();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 계약 승인 요청 API 호출
  /// PRD: calculatedPricing에서 전달받은 값 그대로 사용 (재계산 금지)
  Future<void> _requestContract() async {
    if (_isLoading || !_canSubmit) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pricing = widget.calculatedPricing;

      // 렌탈 아이템 API 형식으로 변환
      final rentalItemsPayload = widget.selectedRentalItems
          .map((item) => item.toApiJson())
          .toList();

      await _contractService.requestContract(
        roomId: widget.room.id,
        checkInDate: widget.checkInDate!,
        checkOutDate: widget.checkOutDate!,
        totalDays: pricing.totalDays,
        totalWeeks: pricing.totalWeeks,
        rentalFee: pricing.rentalFee,
        maintenanceFee: pricing.maintenanceFee,
        cleaningFee: pricing.cleaningFee,
        platformFee: pricing.platformFee,
        discountAmount: pricing.discount,
        discountType: pricing.discountType,
        subtotal: pricing.subtotal,
        totalUsageFee: pricing.totalUsageFee,
        deposit: pricing.deposit,
        finalTotalAmount: pricing.finalTotalAmount,
        rentalItemsFee: pricing.rentalItemsFee,
        rentalItems: rentalItemsPayload.isNotEmpty ? rentalItemsPayload : null,
        guestMessage: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        serviceTermsAgreed: true, // 계약 요청 시 자동 동의
        cancellationPolicyAgreed: true, // 계약 요청 시 자동 동의
        refundPolicyAgreed: true, // 환불 정책은 취소 규정에 포함
        dailyRentalFee: widget.room.dailyRent.toDouble(),
        dailyMaintenanceFee: widget.room.dailyMaintenanceFee.toDouble(),
        platformFeeRate: 0.099,
        depositRate: 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계약 승인 요청이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 게스트 계약 관리 페이지로 이동
        context.go('/guest/contracts');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계약 요청 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
