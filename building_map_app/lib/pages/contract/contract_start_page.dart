import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import '../../models/room.dart';
import '../../models/refund_policy.dart';
import '../../models/calculated_pricing.dart';
import '../../services/contract_service.dart';
import '../../services/refund_policy_service.dart';
import '../../utils/price_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_footer.dart';
import '../../widgets/modals/required_info_gate_modal.dart';
import '../../widgets/contract/contract_start_dialogs.dart';
import '../../widgets/contract/contract_rental_items_section.dart';
import '../../widgets/contract/contract_payment_summary_card.dart';
import '../../widgets/contract/contract_cancellation_section.dart';
import '../../widgets/contract/contract_start_room_section.dart';
import '../../widgets/contract/contract_host_info_section.dart';

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
    return days >= widget.room.minContractDays &&
        days <= widget.room.maxContractDays;
  }

  // 계약 요청 가능 여부
  bool get _canSubmit =>
      _hasValidDates &&
      _isValidContractPeriod &&
      widget.calculatedPricing.isValid;

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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [CONTRACT_START] 환불 정책 로드 실패: $e');
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
                                    ContractStartRoomSection(
                                      room: widget.room,
                                      checkInDate: widget.checkInDate,
                                      checkOutDate: widget.checkOutDate,
                                      calculatedPricing:
                                          widget.calculatedPricing,
                                      isWideScreen: isWideScreen,
                                    ),
                                    const SizedBox(height: 24),

                                    // 호스트 정보 섹션 (아바타 포함)
                                    ContractHostInfoSection(
                                      hostName: widget.room.hostName,
                                    ),
                                    const SizedBox(height: 24),

                                    // 옵션 상품 섹션 (항상 표시, 빈 상태 UI 포함)
                                    _buildRentalItemsSection(),
                                    const SizedBox(height: 24),

                                    // 호스트에게 전할 메시지
                                    _buildHostMessageSection(),
                                    const SizedBox(height: 24),

                                    // 모바일: 예상 금액 카드 (React와 동일한 위치)
                                    if (!isWideScreen) ...[
                                      ContractPaymentSummaryCard(
                                        pricing: widget.calculatedPricing,
                                        checkInDate: widget.checkInDate,
                                        isMobile: true,
                                      ),
                                      const SizedBox(height: 24),
                                    ],

                                    // 계약 해지 조항 (안내사항 포함)
                                    ContractCancellationSection(
                                      refundPolicy: widget.room.refundPolicy,
                                      refundPolicyData: _refundPolicy,
                                      isLoadingPolicy: _isLoadingPolicy,
                                    ),
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
                        right: horizontalMargin,
                        bottom: 0,
                        child: SizedBox(
                          width: 400,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ContractPaymentSummaryCard(
                              pricing: widget.calculatedPricing,
                              checkInDate: widget.checkInDate,
                              isMobile: false,
                              onSubmit: _showContractRequestDialog,
                              isLoading: _isLoading,
                              canSubmit: _canSubmit,
                            ),
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
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF8B6914),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '입주/퇴실 날짜를 선택해야 계약을 요청할 수 있습니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 옵션 상품 섹션
  Widget _buildRentalItemsSection() {
    return ContractRentalItemsSection(
      selectedRentalItems: widget.selectedRentalItems,
      checkInDate: widget.checkInDate,
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
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.textPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.textPrimary),
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // React: helper text with asterisk
          Text(
            '임대 목적을 임대인에게 미리 전달해주세요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
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
    } else if (widget.calculatedPricing.finalTotalAmount <= 0) {
      buttonText = '결제 금액을 확인해주세요';
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
    await ContractStartDialogs.showSuccessMessage(context);
  }

  /// 계약 요청 실패 안내 표시 (중앙 모달)
  Future<void> _showContractErrorMessage(String errorMessage) async {
    await ContractStartDialogs.showErrorMessage(context, errorMessage);
  }

  /// 계약 요청 확인 다이얼로그
  void _showContractRequestDialog() {
    ContractStartDialogs.showRequestDialog(
      context,
      finalTotalAmount: widget.calculatedPricing.finalTotalAmount,
      onConfirm: _requestContract,
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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

        // 에러코드 4308: 프로모션 혜택 변경 (선착순 소진/기간 만료/자격 재평가 등)
        // → 방 상세 페이지로 돌아가 최신 eligiblePromotions를 다시 불러오도록 유도
        if (errorStr.contains('4308') ||
            errorStr.contains('혜택 적용 상태가 변경되었습니다')) {
          await _showPromotionChangedDialog();
          if (mounted) {
            context.go('/room/${widget.room.id}');
          }
          return;
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
  Future<bool> _showOptionDeadlineExpiredDialog() async {
    return ContractStartDialogs.showOptionDeadlineExpiredDialog(
      context,
      checkInDate: widget.checkInDate,
    );
  }

  /// 프로모션 혜택 변경 안내 다이얼로그 (4308)
  /// 선착순 소진/기간 만료/자격 재평가 등으로 프리뷰 ↔ 실제 적용 상태가 달라진 경우
  Future<void> _showPromotionChangedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('혜택이 변경되었습니다'),
        content: const Text(
          '프로모션 혜택 적용 상태가 변경되었습니다.\n'
          '방 상세 페이지에서 최신 혜택과 금액을 다시 확인한 뒤 요청해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
    if (errorStr.contains('name') && !errorStr.contains('roomName')) {
      fields.add('name');
    }
    if (errorStr.contains('bankAccount')) fields.add('bankAccount');
    if (errorStr.contains('verification')) fields.add('verification');
    return fields;
  }
}
