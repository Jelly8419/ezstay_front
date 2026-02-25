import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/notice_texts.dart';
import '../../models/room.dart';
import '../../models/refund_policy.dart';
import '../../models/calculated_pricing.dart';
import '../../services/contract_service.dart';
import '../../services/refund_policy_service.dart';
import '../../utils/price_calculator.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/common/app_footer.dart';
import '../../widgets/modals/required_info_gate_modal.dart';

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

  // 임대 기간이 유효 범위(최소~최대) 내인지 확인
  bool get _isValidContractPeriod {
    if (!_hasValidDates) return false;
    final days = widget.checkOutDate!.difference(widget.checkInDate!).inDays;
    return days >= widget.room.minContractDays && days <= widget.room.maxContractDays;
  }

  // 계약 요청 가능 여부
  bool get _canSubmit => _hasValidDates && _isValidContractPeriod && widget.calculatedPricing.isValid;

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
    return FormatUtils.formatDateWithDay(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1024;

    return ColoredBox(
      color: const Color(0xFFF9FAFB), // bg-gray-50
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 컨텐츠 최대 너비 1400px 기준으로 여백 계산
                const maxContentWidth = 1400.0;
                final contentWidth = constraints.maxWidth < maxContentWidth
                    ? constraints.maxWidth
                    : maxContentWidth;
                final horizontalMargin =
                    (constraints.maxWidth - contentWidth) / 2;

                return Stack(
                  children: [
                    // 전체 영역 스크롤 가능 (좌우 여백 포함)
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 24,
                                  right: isWideScreen
                                      ? 424
                                      : 24, // 데스크톱: 오른쪽 카드 공간 확보
                                  top: 24,
                                  bottom: isWideScreen ? 24 : 100,
                                ),
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const AppFooter(),
                        ],
                      ),
                    ),

                    // 오른쪽: 결제 금액 카드 고정 (데스크톱에서만 표시)
                    if (isWideScreen)
                      Positioned(
                        top: 0,
                        right: horizontalMargin, // 화면 중앙 기준으로 위치 계산
                        bottom: 0,
                        child: SizedBox(
                          width: 400,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: _buildPaymentSummaryCard(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          // 모바일/태블릿용 하단 고정 버튼 (버튼만, 금액은 위에 표시)
          if (!isWideScreen)
            Container(
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
            ),
        ],
      ),
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
                Text(
                  '날짜를 선택해주세요',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF8B6914),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '체크인/체크아웃 날짜를 선택해야 계약을 요청할 수 있습니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
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
        ? ContractUtils.getFullImageUrl(widget.room.photos.first.url)
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
          Text('기본 정보', style: AppTextStyles.headingSmall),
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
          style: AppTextStyles.headingMedium.copyWith(
            color: const Color(0xFF111827), // gray-900
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${widget.room.address}, ${widget.room.floor}층',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF111827),
                ),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: _hasValidDates
                  ? RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF111827),
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_formatDate(widget.checkInDate!)} - ${_formatDate(widget.checkOutDate!)} ',
                          ),
                          TextSpan(
                            text: '(${widget.calculatedPricing.totalDays}일)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '날짜가 선택되지 않았습니다',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[500],
                      ),
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
          Text('호스트', style: AppTextStyles.headingSmall),
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
                      style: AppTextStyles.labelLarge.copyWith(
                        color: const Color(0xFF111827), // gray-900
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
                Expanded(
                  child: Text(
                    '호스트의 연락처는 계약이 확정된 후 공개됩니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF1E40AF), // blue-800
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
  /// 6일 정책: 입주일 6일 전까지만 옵션 상품 선택 가능
  Widget _buildRentalItemsSection() {
    final hasItems = widget.selectedRentalItems.isNotEmpty;

    // 6일 정책 체크: 입주일 6일 전까지만 선택 가능
    final canSelectRental = PriceCalculator.canSelectRentalItems(
      checkInDate: widget.checkInDate,
    );
    final disabledReason = PriceCalculator.getRentalItemsDisabledReason(
      checkInDate: widget.checkInDate,
    );

    // 정책 위반 시 옵션 상품 포함 불가
    final isRentalDisabled = !canSelectRental && hasItems;

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
              Text('옵션 상품', style: AppTextStyles.headingSmall),
              const SizedBox(width: 8),
              Text(
                '(${widget.selectedRentalItems.length}개 선택)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6일 정책 위반 경고 메시지 (옵션 상품이 있는데 정책 위반인 경우)
          if (isRentalDisabled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error50,
                border: Border.all(color: AppColors.error500),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.error500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disabledReason ?? '옵션 상품을 선택할 수 없습니다.',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '선택하신 옵션 상품은 계약에 포함되지 않습니다.',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.error600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // React: 빈 상태 UI (옵션 없을 때)
          if (!hasItems)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    '선택한 옵션 상품이 없습니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '방 상세페이지에서 옵션 상품을 선택해주세요.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          else
            // 옵션 상품 목록 (정책 위반 시 반투명 처리)
            Opacity(
              opacity: isRentalDisabled ? 0.5 : 1.0,
              child: Column(
                children: widget.selectedRentalItems
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[100]!,
                              width: 1,
                            ),
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
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  if (item.description != null &&
                                      item.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.description!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${FormatUtils.formatCurrency(item.price)}원 x ${item.quantity}개',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        color: const Color(
                                          0xFF2563EB,
                                        ), // blue-600
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${FormatUtils.formatCurrency(item.totalPrice)}원',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
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
                Expanded(
                  child: Text(
                    '옵션 상품은 계약 승인 후에도 입주 5일 전까지 추가로 구매할 수 있습니다.(각 최대 4개)',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF1E40AF), // blue-800
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
          Text('임대 목적 (선택사항)', style: AppTextStyles.headingSmall),
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
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
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
                style: AppTextStyles.bodyMedium,
              ),
              // Character count (React: bottom-right inside textarea)
              Positioned(
                bottom: 12,
                right: 12,
                child: Text(
                  '${_messageController.text.length}/500',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // React: helper text with asterisk
          Text(
            '임대 목적을 호스트에게 미리 전달해주세요.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 결제 금액 카드 (오른쪽 고정)
  /// 6일 정책: 입주일 6일 전까지만 옵션 상품 포함 가능
  Widget _buildPaymentSummaryCard() {
    final pricing = widget.calculatedPricing;
    final hasDiscount = pricing.discount > 0;

    // 6일 정책 체크
    final canIncludeRentalItems = PriceCalculator.canSelectRentalItems(
      checkInDate: widget.checkInDate,
    );

    // 6일 정책 위반 시 렌탈 아이템 비용 제외
    final actualRentalItemsFee = canIncludeRentalItems
        ? pricing.rentalItemsFee
        : 0;
    final adjustedTotalUsageFee =
        pricing.totalUsageFee - (pricing.rentalItemsFee - actualRentalItemsFee);
    final adjustedFinalTotalAmount =
        pricing.finalTotalAmount -
        (pricing.rentalItemsFee - actualRentalItemsFee);

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
              children: [Text('결제 금액', style: AppTextStyles.headingSmall)],
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
                // 옵션 상품 (6일 정책 적용)
                if (actualRentalItemsFee > 0) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow('옵션 상품', actualRentalItemsFee),
                ],
                const SizedBox(height: 10),
                // React: "계약 수수료" (not "플랫폼 수수료")
                _buildPriceRow('계약 수수료', pricing.platformFee),

                const Divider(height: 32),

                // React: "실이용 금액" with blue value (text-blue-600)
                _buildPriceRow(
                  '실이용 금액',
                  adjustedTotalUsageFee,
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
                Text(
                  '* 보증금은 3자 예치기관에 보관되며, 퇴실 완료 후 2일 내 자동 환급됩니다.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                _buildPriceRow(
                  '최종 예상 금액',
                  adjustedFinalTotalAmount,
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
                Text(
                  '방 입주 매너',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF111827), // gray-900
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
              style: AppTextStyles.bodySmall.copyWith(
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
  /// 6일 정책: 입주일 6일 전까지만 옵션 상품 포함 가능
  Widget _buildMobilePaymentSummaryCard() {
    final pricing = widget.calculatedPricing;
    final hasDiscount = pricing.discount > 0;

    // 6일 정책 체크
    final canIncludeRentalItems = PriceCalculator.canSelectRentalItems(
      checkInDate: widget.checkInDate,
    );

    // 6일 정책 위반 시 렌탈 아이템 비용 제외
    final actualRentalItemsFee = canIncludeRentalItems
        ? pricing.rentalItemsFee
        : 0;
    final adjustedTotalUsageFee =
        pricing.totalUsageFee - (pricing.rentalItemsFee - actualRentalItemsFee);
    final adjustedFinalTotalAmount =
        pricing.finalTotalAmount -
        (pricing.rentalItemsFee - actualRentalItemsFee);

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
          Text('예상 금액', style: AppTextStyles.headingSmall),
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
          // 옵션 상품 (6일 정책 적용)
          if (actualRentalItemsFee > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow('옵션 상품', actualRentalItemsFee),
          ],
          const SizedBox(height: 10),
          _buildPriceRow('계약 수수료', pricing.platformFee),

          const Divider(height: 32),

          // 실이용 금액 (React: text-blue-600)
          _buildPriceRow(
            '실이용 금액',
            adjustedTotalUsageFee,
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
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          _buildPriceRow(
            '최종 예상 금액',
            adjustedFinalTotalAmount,
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
              Text('계약 해지 조항', style: AppTextStyles.headingSmall),
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
                  style: AppTextStyles.labelSmall.copyWith(
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
              return _buildBulletText(NoticeTexts.cancellationText(rule.description, rule.refundRate));
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
                    Text(
                      '안내사항',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFF1E40AF), // blue-800
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNoticeBulletText(NoticeTexts.sameDayCancelPenalty),

                // API에서 로드한 특별 규칙 표시
                if (_refundPolicy?.specialRules?.alwaysRefund != null)
                  _buildNoticeBulletText(
                    _refundPolicy!.specialRules!.alwaysRefund!,
                  )
                else
                  _buildNoticeBulletText(NoticeTexts.alwaysRefundDefault),

                _buildNoticeBulletText(NoticeTexts.rentRefundByHost),
                _buildNoticeBulletText(NoticeTexts.optionRefundWithin7Days),
                _buildNoticeBulletText(NoticeTexts.optionRefundRestrictions),
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
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: const Color(0xFF1E40AF), // blue-800
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
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isGrey ? Colors.grey[600] : Colors.black87,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}${FormatUtils.formatCurrency(price.abs())}원',
          style: AppTextStyles.bodyMedium.copyWith(
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
              style: AppTextStyles.bodySmall.copyWith(
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
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 15,
                  color: _canSubmit ? Colors.white : Colors.grey[500],
                ),
              ),
      ),
    );
  }

  /// 계약 요청 성공 안내 표시 (중앙 모달)
  Future<void> _showContractSuccessMessage() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('요청 완료'),
          ],
        ),
        content: const Text('계약 요청이 완료되었습니다.\n호스트가 승인하면 결제를 진행할 수 있습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/guest');
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

  /// 계약 요청 실패 안내 표시 (중앙 모달)
  Future<void> _showContractErrorMessage(String errorMessage) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('요청 실패'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${FormatUtils.formatCurrency(widget.calculatedPricing.finalTotalAmount)}원',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.primary600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '호스트가 승인하면 결제가 진행됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: Colors.grey[600],
              ),
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
  /// 6일 정책: 입주일 6일 전까지만 옵션 상품 포함 가능
  Future<void> _requestContract() async {
    if (_isLoading || !_canSubmit) return;

    // 세션 방어: 제출 시점에 옵션 선택 기한 재검증
    // 예약 창을 오래 열어둔 채 날짜가 넘어간 경우를 방어
    final canIncludeRentalItems = PriceCalculator.canSelectRentalItems(
      checkInDate: widget.checkInDate,
    );

    // 옵션을 선택했는데 기한이 지난 경우 → 사용자에게 안내
    if (!canIncludeRentalItems && widget.selectedRentalItems.isNotEmpty) {
      final shouldContinue = await _showOptionDeadlineExpiredDialog();
      if (!shouldContinue) return; // 사용자가 취소 선택
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pricing = widget.calculatedPricing;

      // 렌탈 아이템 API 형식으로 변환 (6일 정책 위반 시 빈 리스트)
      final rentalItemsPayload = canIncludeRentalItems
          ? widget.selectedRentalItems.map((item) => item.toApiJson()).toList()
          : <Map<String, dynamic>>[];

      // 6일 정책 위반 시 렌탈 아이템 비용 제외하여 금액 재계산
      final actualRentalItemsFee = canIncludeRentalItems
          ? pricing.rentalItemsFee
          : 0;
      final adjustedTotalUsageFee =
          pricing.totalUsageFee -
          (pricing.rentalItemsFee - actualRentalItemsFee);
      final adjustedFinalTotalAmount =
          pricing.finalTotalAmount -
          (pricing.rentalItemsFee - actualRentalItemsFee);

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
        totalUsageFee: adjustedTotalUsageFee,
        deposit: pricing.deposit,
        finalTotalAmount: adjustedFinalTotalAmount,
        rentalItemsFee: actualRentalItemsFee,
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
        // 로딩 상태 먼저 해제
        setState(() {
          _isLoading = false;
        });

        // 환경별 성공 안내 표시
        await _showContractSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 에러코드 4010: 필수 정보 누락 → 게이트 모달 표시
        final errorStr = e.toString();
        if (errorStr.contains('4010') || errorStr.contains('missingFields')) {
          final missingFields = _parseMissingFields(errorStr);
          if (missingFields.isNotEmpty) {
            final result = await RequiredInfoGateModal.show(
              context,
              missingFields: missingFields,
            );
            if (result != null && result.isNotEmpty) {
              // 사용자가 필수 정보를 입력한 경우 재시도
              _requestContract();
            }
            return;
          }
        }

        // 에러 메시지 파싱 (백엔드 에러 메시지 추출)
        String errorMessage = errorStr;
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
        }
        await _showContractErrorMessage(errorMessage);
      }
    }
  }

  /// 옵션 선택 기한 만료 안내 다이얼로그 (세션 방어)
  /// 예약 창을 열어둔 채 기한이 지난 경우 표시
  /// 반환값: true면 옵션 제외 후 계속 진행, false면 취소
  Future<bool> _showOptionDeadlineExpiredDialog() async {
    final checkInDay = widget.checkInDate != null
        ? DateTime(widget.checkInDate!.year, widget.checkInDate!.month, widget.checkInDate!.day)
        : null;
    final deadline = checkInDay?.subtract(const Duration(days: 6));
    final deadlineStr = deadline != null
        ? '${deadline.month}/${deadline.day}'
        : '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.schedule, color: AppColors.warning500, size: 24),
            const SizedBox(width: 8),
            const Text('옵션 선택 기한 만료'),
          ],
        ),
        content: Text(
          '옵션 상품 선택 가능 기한이 지났습니다.\n'
          '($deadlineStr 23:59까지 선택 가능)\n\n'
          '선택하신 옵션 상품을 제외하고 계약 요청을 진행할까요?\n'
          '옵션 상품은 계약 승인 후에도 기한 내 추가할 수 있습니다.',
          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('옵션 제외 후 진행', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 에러 메시지에서 missingFields 배열 파싱
  List<String> _parseMissingFields(String errorStr) {
    // missingFields: [phoneNumber, name] 패턴 파싱
    final regex = RegExp(r'missingFields.*?\[([^\]]+)\]');
    final match = regex.firstMatch(errorStr);
    if (match != null) {
      return match.group(1)!.split(',').map((s) => s.trim()).toList();
    }
    // 개별 필드명 매칭
    final fields = <String>[];
    if (errorStr.contains('phoneNumber')) fields.add('phoneNumber');
    if (errorStr.contains('name') && !errorStr.contains('roomName'))
      fields.add('name');
    if (errorStr.contains('bankAccount')) fields.add('bankAccount');
    if (errorStr.contains('verification')) fields.add('verification');
    return fields;
  }
}
