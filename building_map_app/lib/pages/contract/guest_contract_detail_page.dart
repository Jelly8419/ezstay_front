import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../config/payment_config.dart';
import '../../models/contract_detail.dart';
import '../../models/payment_history.dart';
import '../../services/contract_service.dart';
import '../../services/payment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/payment_webview.dart';
import '../../widgets/common/app_gnb.dart';

/// 게스트 계약 상세 페이지 (React UI 기반)
class GuestContractDetailPage extends StatefulWidget {
  final int contractId;

  const GuestContractDetailPage({super.key, required this.contractId});

  @override
  State<GuestContractDetailPage> createState() =>
      _GuestContractDetailPageState();
}

class _GuestContractDetailPageState extends State<GuestContractDetailPage> {
  final ContractService _contractService = ContractService();
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = true;
  String? _errorMessage;
  ContractDetail? _contractDetail;

  // 결제 관련
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadContractDetail();
  }

  /// 계약 상세 정보 로드
  Future<void> _loadContractDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 계약 상세 조회 (rentalItems에 itemId, quantity만 있음)
      final detail = await _contractService.getGuestContractDetail(
        widget.contractId,
      );

      if (detail == null) {
        setState(() {
          _errorMessage = '계약 정보를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      // 2. 렌탈 아이템이 있으면 전체 목록 조회하여 매칭
      if (detail.rentalItems.isNotEmpty) {
        try {
          final allRentalItems = await _contractService.getAllRentalItems(
            inStock: false, // 재고 여부 무관하게 전체 조회
          );

          if (allRentalItems != null && allRentalItems.isNotEmpty) {
            // itemId로 매칭하여 완전한 정보로 교체
            final enrichedRentalItems = detail.rentalItems.map((contractItem) {
              // 전체 목록에서 itemId가 일치하는 아이템 찾기
              final fullItemData = allRentalItems.firstWhere(
                (fullItem) => fullItem['id'] == contractItem.id,
                orElse: () => <String, dynamic>{},
              );

              // 완전한 정보가 있으면 병합
              if (fullItemData.isNotEmpty) {
                // fullItemData에 계약의 quantity와 deliveryStatus 추가
                final mergedData = Map<String, dynamic>.from(fullItemData);
                mergedData['quantity'] = contractItem.quantity;
                mergedData['deliveryStatus'] = contractItem.deliveryStatus;

                // ContractRentalItem.fromJson()으로 안전하게 파싱 (price 타입 변환 포함)
                return ContractRentalItem.fromJson(mergedData);
              }

              // 매칭 실패 시 기존 데이터 유지
              return contractItem;
            }).toList();

            // 매칭된 데이터로 ContractDetail 재생성
            final enrichedDetail = ContractDetail(
              id: detail.id,
              orderId: detail.orderId,
              roomId: detail.roomId,
              roomName: detail.roomName,
              roomPhoto: detail.roomPhoto,
              address: detail.address,
              detailAddress: detail.detailAddress,
              floor: detail.floor,
              checkInDate: detail.checkInDate,
              checkOutDate: detail.checkOutDate,
              totalDays: detail.totalDays,
              rentalFee: detail.rentalFee,
              maintenanceFee: detail.maintenanceFee,
              cleaningFee: detail.cleaningFee,
              deposit: detail.deposit,
              rentalItemsFee: detail.rentalItemsFee,
              platformFee: detail.platformFee,
              finalTotalAmount: detail.finalTotalAmount,
              status: detail.status,
              paidAt: detail.paidAt,
              refundPolicy: detail.refundPolicy,
              refundPolicyDetail: detail.refundPolicyDetail,
              refundPolicySnapshot: detail.refundPolicySnapshot,
              rentalItems: enrichedRentalItems, // 완전한 정보로 교체
              paymentHistory: detail.paymentHistory,
              hostName: detail.hostName,
              hostProfileImage: detail.hostProfileImage,
              hostPhoneNumber: detail.hostPhoneNumber,
              guestName: detail.guestName,
              guestPhone: detail.guestPhone,
              guestMessage: detail.guestMessage,
              isEzCleaning: detail.isEzCleaning,
            );

            setState(() {
              _contractDetail = enrichedDetail;
              _isLoading = false;
            });
          } else {
            // 렌탈 아이템 목록 조회 실패 시 원본 데이터 사용
            setState(() {
              _contractDetail = detail;
              _isLoading = false;
            });
          }
        } catch (rentalItemsError) {
          // 렌탈 아이템 매칭 실패해도 계약 정보는 표시
          debugPrint('⚠️ 렌탈 아이템 매칭 실패: $rentalItemsError');
          setState(() {
            _contractDetail = detail;
            _isLoading = false;
          });
        }
      } else {
        // 렌탈 아이템이 없으면 바로 표시
        setState(() {
          _contractDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // React: bg-gray-50
      backgroundColor: AppColors.gray50,
      appBar: const AppGNB(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _contractDetail != null
          ? _buildDetailView()
          : const Center(child: Text('데이터를 불러올 수 없습니다.')),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 에러 뷰
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error500),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '오류가 발생했습니다.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadContractDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 상세 정보 뷰 (React: max-w-4xl mx-auto px-4 py-6)
  Widget _buildDetailView() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 896,
          ), // max-w-4xl = 56rem = 896px
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // React: h2 className="font-bold text-xl text-gray-900 mb-6"
              Text(
                '계약 상세 정보',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900, // text-gray-900
                ),
              ),
              const SizedBox(height: 24),

              _buildBasicInfoSection(),
              const SizedBox(height: 24),

              _buildPartyInfoSection(),
              const SizedBox(height: 24),

              _buildRentalAmountSection(),

              // 옵션 상품 섹션 (React: 항상 표시, 없으면 "선택한 옵션이 없습니다")
              const SizedBox(height: 24),
              _buildOptionProductsSection(),

              const SizedBox(height: 24),
              _buildCancellationPolicySection(),

              const SizedBox(height: 24),
              _buildNoticeSection(),

              if (_contractDetail!.paymentHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildPaymentHistorySection(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 기본 정보 섹션 (React 구조와 일치)
  Widget _buildBasicInfoSection() {
    final contract = _contractDetail!;

    // React: bg-white rounded-xl p-6 shadow-sm border border-gray-200 mb-6
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: AppColors.gray200), // border-gray-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // shadow-sm
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24), // p-6 = 24px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: 헤더 - 제목 + 계약번호 (왼쪽), 상태 배지 (오른쪽)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // React: h3 className="font-bold text-lg text-gray-900 text-[18px]"
                    Text(
                      '기본 정보',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),

                    // React: 계약주문번호 (있을 경우에만 표시)
                    if (contract.orderId != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '계약번호: ',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 14, // React: text-sm = 14px
                              color: AppColors.gray600, // text-gray-600
                            ),
                          ),
                          Text(
                            contract.orderId!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 14, // React: text-sm = 14px
                              fontWeight: FontWeight.bold, // 값 강조
                              color: AppColors.blue600, // text-blue-600
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 상태 배지 (오른쪽)
              _buildStatusBadge(contract.status),
            ],
          ),

          const SizedBox(height: 16),

          // React: 방 정보 - 사진(128x128) + 텍스트 (가로 배치)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // React: w-32 h-32 rounded-lg (128x128px)
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), // rounded-lg
                  color: AppColors.gray50, // bg-gray-100
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: _getFullImageUrl(contract.roomPhoto),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.gray50,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.gray50,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16), // gap-4
              // React: flex-1 (방 정보 텍스트)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // React: h4 className="font-bold text-lg text-gray-900 mb-3 text-[20px]"
                    Text(
                      contract.roomName,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // React: 주소 (상태에 따라 floor 또는 detailAddress)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80, // React: w-20 = 80px
                          child: Text(
                            '주소',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray600, // text-gray-600
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _getAddressDisplay(contract),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray900, // text-gray-900
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // React: 체크인/체크아웃
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80, // React: w-20 = 80px
                          child: Text(
                            '계약 기간',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_formatDate(contract.checkInDate)} ~ ${_formatDate(contract.checkOutDate)} (${contract.totalDays}일)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 결제 금액
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80, // React: w-20 = 80px
                          child: Text(
                            '결제 금액',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_formatCurrency(contract.finalTotalAmount)}원',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray900,
                              fontWeight: FontWeight.normal, // React: font-normal
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 호스트/게스트 정보 섹션 (React: grid grid-cols-1 md:grid-cols-2 gap-6)
  Widget _buildPartyInfoSection() {
    final contract = _contractDetail!;
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildHostCard(contract),
          const SizedBox(height: 24),
          _buildGuestCard(contract),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildHostCard(contract)),
          const SizedBox(width: 24), // gap-6 = 24px
          Expanded(child: _buildGuestCard(contract)),
        ],
      );
    }
  }

  /// 호스트 정보 카드
  Widget _buildHostCard(ContractDetail contract) {
    final showPhone = _shouldShowHostPhone(contract);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: h3 className="font-bold text-lg text-gray-900 mb-4"
          Text(
            '호스트',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 16),

          // React: flex items-center gap-3
          Row(
            children: [
              // React: w-12 h-12 rounded-full (48x48px)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray50,
                ),
                clipBehavior: Clip.antiAlias,
                child: contract.hostProfileImage != null
                    ? CachedNetworkImage(
                        imageUrl: _getFullImageUrl(contract.hostProfileImage),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.person, size: 28),
                      )
                    : Icon(Icons.person, size: 28, color: AppColors.gray600),
              ),

              const SizedBox(width: 12), // gap-3

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // React: font-bold text-gray-900
                    Text(
                      contract.hostDisplayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),

                    // React: 결제 완료/진행 중/완료 상태에서만 전화번호 표시
                    if (showPhone && contract.hostPhoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        contract.hostPhoneNumber!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 14,
                          color: AppColors.gray600, // text-gray-600
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 게스트 정보 카드
  Widget _buildGuestCard(ContractDetail contract) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '게스트',
                style: AppTextStyles.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),

              // EZ청소 배지
              if (contract.isEzCleaning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green100, // bg-green-100
                    borderRadius: BorderRadius.circular(999), // rounded-full
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cleaning_services,
                        size: 14,
                        color: AppColors.green600, // text-green-600
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EZ청소',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // React: flex items-center gap-3
          Row(
            children: [
              // React: w-12 h-12 rounded-full bg-gray-200 flex items-center justify-center
              Container(
                width: 48, // w-12
                height: 48, // h-12
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E7EB), // bg-gray-200
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    // 이름 첫 글자
                    contract.guestDisplayName.isNotEmpty
                        ? contract.guestDisplayName.substring(0, 1)
                        : '?',
                    style: const TextStyle(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.bold, // font-bold
                      color: Color(0xFF4B5563), // text-gray-600
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12), // gap-3
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // React: font-bold text-gray-900
                  Text(
                    contract.guestDisplayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827), // text-gray-900
                    ),
                  ),
                  const SizedBox(height: 4), // mt-1
                  // React: text-sm text-gray-600
                  Text(
                    contract.guestPhone,
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      color: Color(0xFF4B5563), // text-gray-600
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 임대 금액 섹션
  Widget _buildRentalAmountSection() {
    final contract = _contractDetail!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '임대 계약 금액',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 16),

          _buildAmountRow('임대료', contract.rentalFee),
          _buildAmountRow('관리비', contract.maintenanceFee),
          _buildAmountRowWithBadge(
            '청소비',
            contract.cleaningFee,
            showEzBadge: contract.isEzCleaning,
          ),
          _buildAmountRow('계약 수수료', contract.platformFee),

          // React: 보증금 위에 구분선
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.gray200),
          ),

          // React: 보증금 (퇴실 후 반환 예정) - 괄호 안에 작은 글씨
          _buildAmountRowWithSubtext(
            '보증금',
            '(퇴실 후 반환 예정)',
            contract.deposit,
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 2, thickness: 2, color: AppColors.gray200),
          ),

          _buildAmountRow(
            '총 임대 계약 금액',
            contract.finalTotalAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// 금액 행 (React: text-sm = 14px, text-gray-700)
  Widget _buildAmountRow(
    String label,
    int amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14, // React: text-sm = 14px, total은 text-[16px]
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? const Color(0xFF111827) // text-gray-900
                  : const Color(0xFF374151), // text-gray-700
            ),
          ),
          Text(
            '${_formatCurrency(amount)}원',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14, // React: text-sm, total은 text-lg text-[16px]
              fontWeight: FontWeight.bold, // font-bold
              color: const Color(0xFF111827), // text-gray-900
            ),
          ),
        ],
      ),
    );
  }

  /// 금액 행 (EZ서비스 배지 포함) - React: 청소비 옆 EZ서비스 배지
  Widget _buildAmountRowWithBadge(
    String label,
    int amount, {
    bool showEzBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14, // React: text-sm
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF374151), // text-gray-700
                ),
              ),
              // React: EZ서비스 배지 (isEzCleaning일 때만)
              if (showEzBadge) ...[
                const SizedBox(width: 6), // gap-1.5
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB), // bg-blue-600
                    borderRadius: BorderRadius.circular(4), // rounded
                  ),
                  child: const Text(
                    'EZ서비스',
                    style: TextStyle(
                      fontSize: 12, // text-xs
                      fontWeight: FontWeight.bold, // font-bold
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            '${_formatCurrency(amount)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  /// 금액 행 (부제목 포함) - React: 보증금 (퇴실 후 반환 예정)
  Widget _buildAmountRowWithSubtext(
    String label,
    String subtext,
    int amount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14, // React: text-sm
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF374151), // text-gray-700
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 12, // React: text-xs
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6B7280), // text-gray-500
                ),
              ),
            ],
          ),
          Text(
            '${_formatCurrency(amount)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  /// 옵션 상품 섹션 (React UI 기반)
  Widget _buildOptionProductsSection() {
    final contract = _contractDetail!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: const Color(0xFFE5E7EB)), // border-gray-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // shadow-sm
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24), // p-6
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 제목 + 전체 배송 상태 뱃지 + 옵션 추가 버튼
          Row(
            children: [
              // Package 아이콘 (w-5 h-5 text-gray-700)
              const Icon(
                Icons.inventory_2_outlined,
                size: 20, // w-5 h-5
                color: Color(0xFF374151), // text-gray-700
              ),
              const SizedBox(width: 8), // gap-2

              // 제목
              const Text(
                '옵션 상품 (EZstay에서 제공)',
                style: TextStyle(
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.w700, // font-bold
                  color: Color(0xFF111827), // text-gray-900
                ),
              ),

              // 전체 배송 상태 뱃지 (옵션 상품이 있을 때만)
              if (contract.rentalItems.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildOverallDeliveryStatusBadge(contract.rentalItems),
              ],
            ],
          ),

          const SizedBox(height: 16), // mb-4

          // 옵션 상품이 없으면 "선택한 옵션이 없습니다" 표시
          if (contract.rentalItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '선택한 옵션이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280), // text-gray-500
                  ),
                ),
              ),
            )
          else ...[
            // space-y-3: 아이템 간 12px 간격
            ...contract.rentalItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: index > 0 ? 12 : 0), // space-y-3
                child: _buildRentalItemCard(item),
              );
            }),

            // 합계
            Container(
              padding: const EdgeInsets.only(top: 12), // pt-3
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE5E7EB), // border-gray-200
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '옵션 상품 합계',
                    style: TextStyle(
                      fontSize: 16, // font-bold text-gray-900
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    '${_formatCurrency(contract.rentalItemsFee)}원',
                    style: const TextStyle(
                      fontSize: 16, // text-lg text-[16px]
                      fontWeight: FontWeight.w700, // font-bold
                      color: Color(0xFF111827), // text-gray-900
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 전체 배송 상태 뱃지 (React UI 로직 복제)
  Widget _buildOverallDeliveryStatusBadge(List<ContractRentalItem> items) {
    // hasShipping: 배송 중인 아이템이 하나라도 있는지
    final hasShipping = items.any((item) => item.deliveryStatus == 'SHIPPING');
    // allDelivered: 모든 아이템이 배송 완료인지
    final allDelivered = items.every((item) => item.deliveryStatus == 'DELIVERED');

    final String status;
    if (hasShipping) {
      status = 'SHIPPING';
    } else if (allDelivered) {
      status = 'DELIVERED';
    } else {
      status = 'PENDING';
    }

    // 상태별 설정
    final Map<String, dynamic> config = {
      'PENDING': {
        'text': '배송 대기',
        'bgColor': const Color(0xFFF3F4F6), // bg-gray-100
        'textColor': const Color(0xFF374151), // text-gray-700
      },
      'SHIPPING': {
        'text': '배송 중',
        'bgColor': const Color(0xFFDBEAFE), // bg-blue-100
        'textColor': const Color(0xFF1D4ED8), // text-blue-700
      },
      'DELIVERED': {
        'text': '배송 완료',
        'bgColor': const Color(0xFFD1FAE5), // bg-green-100
        'textColor': const Color(0xFF047857), // text-green-700
      },
    }[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // px-2 py-0.5
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(4), // rounded
      ),
      child: Text(
        config['text'],
        style: TextStyle(
          fontSize: 12, // text-xs
          fontWeight: FontWeight.w700, // font-bold
          color: config['textColor'],
        ),
      ),
    );
  }

  /// 렌탈 아이템 카드 (React UI 기반)
  Widget _buildRentalItemCard(ContractRentalItem item) {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE5E7EB), // border-gray-200
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8), // rounded-lg
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // justify-between
        children: [
          // 왼쪽: 아이템 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이템명 (font-bold text-gray-900 mb-1)
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700, // font-bold
                    color: Color(0xFF111827), // text-gray-900
                  ),
                ),

                const SizedBox(height: 4), // mb-1

                // 설명 (text-sm text-gray-600)
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      color: Color(0xFF4B5563), // text-gray-600
                    ),
                  ),

                const SizedBox(height: 4), // mt-1

                // 수량 (text-sm text-gray-600 mt-1)
                Text(
                  '수량: ${item.quantity}개',
                  style: const TextStyle(
                    fontSize: 14, // text-sm
                    color: Color(0xFF4B5563), // text-gray-600
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 오른쪽: 가격 (font-bold text-gray-900)
          Text(
            '${_formatCurrency(item.price * item.quantity)}원',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // text-gray-900
            ),
          ),
        ],
      ),
    );
  }

  /// 취소 정책 섹션 (계약 요청 페이지와 동일한 UI)
  Widget _buildCancellationPolicySection() {
    final contract = _contractDetail!;
    final snapshot = contract.refundPolicySnapshot;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: 제목 = "환불 규정"
          Text(
            '환불 규정',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827), // text-gray-900
            ),
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 12),

          // React: 환불 규정 상세 내용 (whitespace-pre-wrap)
          // 환불 정책 규칙 표시
          if (snapshot != null && snapshot.rules.isNotEmpty) ...[
            ...snapshot.rules.map((rule) {
              final text = _calculateCancellationText(rule);
              return _buildBulletText(text);
            }),
          ] else ...[
            // Fallback: 기존 상세 설명
            Text(
              contract.refundPolicyDetail.isNotEmpty
                  ? contract.refundPolicyDetail
                  : '환불 정책 정보를 불러올 수 없습니다.',
              style: const TextStyle(
                fontSize: 14, // text-sm
                color: Color(0xFF374151), // text-gray-700
                height: 1.5, // leading-relaxed
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 안내사항 섹션 (React와 동일 - yellow 스타일)
  Widget _buildNoticeSection() {
    // React: bg-yellow-50 border border-yellow-200 rounded-lg p-4
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8), // bg-yellow-50
        borderRadius: BorderRadius.circular(8), // rounded-lg
        border: Border.all(
          color: const Color(0xFFFDE68A), // border-yellow-200
        ),
      ),
      padding: const EdgeInsets.all(16), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: text-xs text-yellow-800 space-y-1 leading-relaxed
          _buildNoticeBulletText(
              '옵션 상품(침구류, 어메니티 키트, 헤어드라이기 등)은 호스트 계약 정보에 표시되지 않습니다.'),
          _buildNoticeBulletText(
              '옵션 상품, 계약 변경사항에 대한 문의는 EZStay 고객센터로 연락 바랍니다.'),
          _buildNoticeBulletText(
              '입주일 기준 7일 이내 계약 변경은 불가하며, 이후 변경 시 추가 수수료가 발생할 수 있습니다.'),
        ],
      ),
    );
  }

  /// 환불 규칙을 텍스트로 변환
  String _calculateCancellationText(RefundPolicyRule rule) {
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

  /// 안내사항 불릿 텍스트 (yellow 스타일 - React와 동일)
  Widget _buildNoticeBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // space-y-1
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 12, // text-xs
          color: Color(0xFF92400E), // text-yellow-800
          height: 1.625, // leading-relaxed
        ),
      ),
    );
  }

  /// 결제 내역 섹션
  Widget _buildPaymentHistorySection() {
    final contract = _contractDetail!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: flex items-center gap-2 mb-4
          Row(
            children: [
              // React: CreditCard className="w-5 h-5 text-gray-700"
              const Icon(
                Icons.credit_card,
                size: 20, // w-5 h-5
                color: Color(0xFF374151), // text-gray-700
              ),
              const SizedBox(width: 8), // gap-2
              Text(
                '결제 내역',
                style: AppTextStyles.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...contract.paymentHistory.map(
            (payment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentHistoryTile(payment),
            ),
          ),
        ],
      ),
    );
  }

  /// 결제 내역 타일
  Widget _buildPaymentHistoryTile(PaymentHistory payment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: payment.isPayment
                ? AppColors
                      .blue100 // bg-blue-100
                : AppColors.error50, // bg-red-100
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.isPayment ? Icons.payment : Icons.replay,
            color: payment.isPayment ? AppColors.blue600 : AppColors.error600,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        // 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.isPayment ? '결제' : '환불',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(payment.transactionDate),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
              if (payment.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  payment.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              _buildPaymentStatusBadge(payment.status),
            ],
          ),
        ),

        // 금액
        Text(
          '${payment.isPayment ? '' : '-'}${_formatCurrency(payment.amount)}원',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: payment.isPayment ? AppColors.gray900 : AppColors.error600,
          ),
        ),
      ],
    );
  }

  /// 결제 상태 배지
  Widget _buildPaymentStatusBadge(String status) {
    final config = _getPaymentStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config['text'] as String,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 12,
          color: config['color'] as Color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 상태 배지 (React 색상과 일치)
  Widget _buildStatusBadge(String status) {
    final config = _getStatusConfig(status);

    // React: inline-block px-3 py-1 rounded-full text-sm font-bold
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['color'] as Color,
        borderRadius: BorderRadius.circular(999), // rounded-full
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 16,
            color: config['textColor'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            config['text'] as String,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 14,
              color: config['textColor'] as Color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========== 유틸리티 메서드 ==========

  /// 이미지 URL에 baseUrl 추가 (상대경로 → 절대경로)
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    // 이미 절대 경로인 경우 그대로 반환
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // 상대 경로인 경우 baseUrl 추가
    return '${ApiConfig.baseUrl}$imageUrl';
  }

  /// 주소 표시 로직 (React와 일치)
  String _getAddressDisplay(ContractDetail contract) {
    // React: PENDING_APPROVAL 또는 APPROVED 상태에서는 floor 표시
    if (contract.status == 'PENDING_APPROVAL' ||
        contract.status == 'APPROVED') {
      return '${contract.address} ${contract.floor}';
    } else {
      // 그 외 상태에서는 detailAddress 표시
      return '${contract.address} ${contract.detailAddress}';
    }
  }

  /// 호스트 전화번호 표시 여부 (React와 일치)
  bool _shouldShowHostPhone(ContractDetail contract) {
    return [
      'PAYMENT_COMPLETED',
      'IN_PROGRESS',
      'COMPLETED',
    ].contains(contract.status);
  }

  /// 상태 설정 가져오기 (React 색상 스킴과 일치)
  Map<String, dynamic> _getStatusConfig(String status) {
    final statusMap = {
      'PENDING_APPROVAL': {
        'text': '승인 대기',
        'color': AppColors.warning50, // bg-yellow-100
        'textColor': AppColors.secondary700, // text-yellow-700
        'icon': Icons.schedule,
      },
      'APPROVED': {
        'text': '결제 대기',
        'color': AppColors.blue100, // bg-blue-100
        'textColor': AppColors.blue700, // text-blue-700
        'icon': Icons.payment,
      },
      'PAYMENT_COMPLETED': {
        'text': '결제 완료',
        'color': AppColors.green100, // bg-green-100
        'textColor': AppColors.success700, // text-green-700
        'icon': Icons.check_circle,
      },
      'IN_PROGRESS': {
        'text': '임대 중',
        'color': AppColors.purple50, // bg-purple-100
        'textColor': AppColors.purple600, // text-purple-700
        'icon': Icons.home,
      },
      'COMPLETED': {
        'text': '계약 종료',
        'color': AppColors.gray50, // bg-gray-100
        'textColor': AppColors.neutral700, // text-gray-700
        'icon': Icons.check_circle_outline,
      },
      'CANCELLED_BY_GUEST': {
        'text': '계약 취소',
        'color': AppColors.error50, // bg-red-100
        'textColor': AppColors.error700, // text-red-700
        'icon': Icons.cancel,
      },
      'CANCELLED_BY_HOST': {
        'text': '계약 취소',
        'color': AppColors.error50, // bg-red-100
        'textColor': AppColors.error700, // text-red-700
        'icon': Icons.cancel,
      },
    };

    return statusMap[status] ?? statusMap['PENDING_APPROVAL']!;
  }

  /// 결제 상태 설정 가져오기
  Map<String, dynamic> _getPaymentStatusConfig(String status) {
    final statusMap = {
      'COMPLETED': {
        'text': '완료',
        'color': AppColors.success500, // green-500
      },
      'PENDING': {
        'text': '대기',
        'color': AppColors.warning500, // yellow-500
      },
      'FAILED': {
        'text': '실패',
        'color': AppColors.error500, // red-500
      },
    };

    return statusMap[status] ?? statusMap['PENDING']!;
  }

  /// 날짜 포맷 (yyyy-MM-dd)
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// 날짜/시간 포맷 (yyyy-MM-dd HH:mm)
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// 금액 포맷 (천 단위 콤마)
  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  /// 하단 고정 바 (게스트 전용 - APPROVED 상태 시 결제 버튼)
  Widget _buildBottomBar() {
    if (_contractDetail == null) return const SizedBox.shrink();

    final contract = _contractDetail!;

    // APPROVED 상태일 때만 결제 버튼 표시
    if (contract.status == 'APPROVED') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
              onPressed: _isPaymentProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isPaymentProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '₩${_formatCurrency(contract.finalTotalAmount)} 결제하기',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// 결제 처리
  Future<void> _processPayment() async {
    if (_contractDetail == null) return;

    setState(() => _isPaymentProcessing = true);

    try {
      // Mock 모드일 경우 백엔드 Mock API 호출
      if (PaymentConfig.useMockMode) {
        await _processPaymentWithMock();
        return;
      }

      // 1. 백엔드에서 결제 정보 조회
      final paymentInfo = await _paymentService.getPaymentInfo(widget.contractId);

      // 2. 토스 결제창 URL 생성
      final paymentUrl = _buildTossPaymentUrl(
        clientKey: PaymentConfig.clientKey,
        amount: paymentInfo['amount'] as int,
        orderId: paymentInfo['orderId'] as String,
        orderName: paymentInfo['orderName'] as String,
        customerEmail: paymentInfo['customerEmail'] as String?,
        customerName: paymentInfo['customerName'] as String?,
        successUrl: PaymentConfig.successUrl,
        failUrl: PaymentConfig.failUrl,
      );

      // 3. 웹/모바일 구분 처리
      if (kIsWeb) {
        // 웹: 새 탭으로 토스 결제 페이지 열기
        await _processPaymentWeb(paymentUrl);
      } else {
        // 모바일: WebView로 토스 결제창 열기
        await _processPaymentMobile(paymentUrl);
      }
    } catch (e) {
      debugPrint('❌ [GuestContractDetail] 결제 오류: $e');
      _showErrorDialog('결제 중 오류가 발생했습니다.\n${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }
  }

  /// 웹에서 결제 처리
  Future<void> _processPaymentWeb(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);

      // 새 탭으로 토스 결제 페이지 열기 (웹에서는 canLaunchUrl 체크 불필요)
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // 사용자 안내 다이얼로그
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('결제 진행 중'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('새 탭에서 토스 결제창이 열렸습니다.'),
                SizedBox(height: 16),
                Text('결제를 완료하신 후, 이 페이지로 돌아와서 "확인" 버튼을 눌러주세요.'),
                SizedBox(height: 16),
                Text(
                  '⚠️ 결제를 취소하셨다면 "취소" 버튼을 눌러주세요.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // 취소
                },
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // 완료
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                ),
                child: const Text('결제 완료'),
              ),
            ],
          ),
        );

        // 결제 완료 시 페이지 새로고침
        if (result == true) {
          await _loadContractDetail();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 페이지 열기 실패: ${e.toString()}');
      }
    }
  }

  /// 모바일에서 결제 처리
  Future<void> _processPaymentMobile(String paymentUrl) async {
    try {
      // WebView로 토스 결제창 열기
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            paymentUrl: paymentUrl,
            contractId: widget.contractId,
          ),
          fullscreenDialog: true,
        ),
      );

      // 결제 결과 처리
      if (result != null && result['success'] == true) {
        // 결제 성공 - 백엔드 승인 API 호출
        await _confirmPayment(
          paymentKey: result['paymentKey'] as String,
          orderId: result['orderId'] as String,
          amount: result['amount'] as int,
        );
      } else {
        // 결제 실패 또는 취소
        final errorMessage = result?['errorMessage'] as String? ?? '결제가 취소되었습니다.';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 처리 실패: ${e.toString()}');
      }
    }
  }

  /// Mock 결제 처리
  Future<void> _processPaymentWithMock() async {
    try {
      final paymentInfo = await _paymentService.getPaymentInfo(widget.contractId);

      // Mock 결제 승인
      await _paymentService.confirmPaymentMock(
        contractId: widget.contractId,
        orderId: paymentInfo['orderId'] as String,
        amount: paymentInfo['amount'] as int,
      );

      if (mounted) {
        _showSuccessDialog('[Mock] 결제가 완료되었습니다!');
        // 계약 상세 다시 로드
        await _loadContractDetail();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('[Mock] 결제 실패: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }
  }

  /// 토스 결제창 URL 생성
  String _buildTossPaymentUrl({
    required String clientKey,
    required int amount,
    required String orderId,
    required String orderName,
    String? customerEmail,
    String? customerName,
    required String successUrl,
    required String failUrl,
  }) {
    final params = {
      'clientKey': clientKey,
      'amount': amount.toString(),
      'orderId': orderId,
      'orderName': orderName,
      'successUrl': successUrl,
      'failUrl': failUrl,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (customerName != null) 'customerName': customerName,
    };

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    debugPrint('🔗 [TossPayment] URL 생성: https://pay.toss.im/web/v2?$queryString');

    // 토스 결제창 URL (웹용 결제 위젯 v2)
    return 'https://pay.toss.im/web/v2?$queryString';
  }

  /// 결제 승인
  Future<void> _confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      await _paymentService.confirmPayment(
        contractId: widget.contractId,
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

      if (mounted) {
        _showSuccessDialog('결제가 완료되었습니다!');
        // 계약 상세 다시 로드
        await _loadContractDetail();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 승인 실패: ${e.toString()}');
      }
    }
  }

  /// 성공 다이얼로그
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success500, size: 28),
            const SizedBox(width: 8),
            const Text('결제 완료'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error500, size: 28),
            const SizedBox(width: 8),
            const Text('결제 실패'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
