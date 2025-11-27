import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/contract_detail.dart';
import '../../services/contract_service.dart';
import '../../config/api_config.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../widgets/common/app_gnb.dart';

/// 카드 그림자 (기본)
const List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
];

/// 호스트 계약 상세 페이지
class HostContractDetailPage extends StatefulWidget {
  final int contractId;

  const HostContractDetailPage({
    super.key,
    required this.contractId,
  });

  @override
  State<HostContractDetailPage> createState() =>
      _HostContractDetailPageState();
}

class _HostContractDetailPageState extends State<HostContractDetailPage> {
  final ContractService _contractService = ContractService();

  ContractDetail? _contract;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContractDetail();
  }

  /// 계약 상세 정보 로드
  Future<void> _loadContractDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final contract =
          await _contractService.getGuestContractDetail(widget.contractId);

      if (contract != null) {
        setState(() {
          _contract = contract;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '계약 정보를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '계약 정보를 불러오는데 실패했습니다: $e';
      });
    }
  }

  /// 호스트 수수료 계산 (3.3%)
  int _getHostCommissionFee() {
    if (_contract == null) return 0;
    final baseAmount = _contract!.isEzCleaning
        ? _contract!.rentalFee + _contract!.maintenanceFee
        : _contract!.rentalFee +
            _contract!.maintenanceFee +
            _contract!.cleaningFee;
    return (baseAmount * 0.033).floor();
  }

  /// 실 정산 금액 계산
  int _getActualSettlementAmount() {
    if (_contract == null) return 0;
    final baseAmount = _contract!.isEzCleaning
        ? _contract!.rentalFee + _contract!.maintenanceFee
        : _contract!.rentalFee +
            _contract!.maintenanceFee +
            _contract!.cleaningFee;
    return baseAmount - _getHostCommissionFee();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      appBar: const AppGNB(),
      body: ResponsivePageLayout(
        useCardStyle: false, // 배경색 유지 (각 섹션이 이미 카드)
        maxWidth: 896, // max-w-4xl (React 기준)
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContractDetail,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_contract == null) {
      return const Center(
        child: Text('계약 정보가 없습니다.'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 제목
          Padding(
            padding: const EdgeInsets.only(bottom: 24), // mb-6
            child: Text(
              '계약 상세 정보',
              style: const TextStyle(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700, // font-bold
                color: Color(0xFF111827), // gray-900
              ),
            ),
          ),
          _buildBasicInfoSection(),
          const SizedBox(height: 24), // mb-6
          _buildPartyInfoSection(),
          const SizedBox(height: 24), // mb-6
          _buildContractAmountSection(),
          const SizedBox(height: 24), // mb-6
          _buildNoticeSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 기본 정보 섹션
  Widget _buildBasicInfoSection() {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리 추가
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목 + 상태 배지 (flex justify-between)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "기본 정보" 제목 (text-lg = 18px)
                  const Text(
                    '기본 정보',
                    style: TextStyle(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.w700, // font-bold
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                  // 계약 번호 (승인된 경우만 표시)
                  if (_contract!.orderId != null) ...[
                    const SizedBox(height: 8), // mt-2
                    Row(
                      children: [
                        const Text(
                          '계약번호: ',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        Text(
                          _contract!.orderId!,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w700, // font-bold
                            color: Color(0xFF2563EB), // blue-600
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              // 상태 배지
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),

          // 방 정보 (반응형 레이아웃)
          if (isMobile) ...[
            // 모바일: 세로 레이아웃
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 방 이미지 (전체 너비)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  child: _contract!.roomPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _getFullImageUrl(_contract!.roomPhoto),
                          width: double.infinity,
                          height: 192, // h-48
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: double.infinity,
                            height: 192,
                            color: AppColors.grey50,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 192,
                            color: AppColors.grey50,
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 192,
                          color: AppColors.grey50,
                          child: Icon(Icons.home,
                              size: 40, color: AppColors.textHint),
                        ),
                ),
                const SizedBox(height: 12),
                // 방 정보 텍스트
                _buildRoomInfo(),
              ],
            ),
          ] else ...[
            // 데스크톱: 가로 레이아웃
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 방 이미지 (고정 크기)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  child: _contract!.roomPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _getFullImageUrl(_contract!.roomPhoto),
                          width: 128, // lg:w-32
                          height: 128, // lg:h-32
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 128,
                            height: 128,
                            color: AppColors.grey50,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 128,
                            height: 128,
                            color: AppColors.grey50,
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          width: 128,
                          height: 128,
                          color: AppColors.grey50,
                          child: Icon(Icons.home,
                              size: 40, color: AppColors.textHint),
                        ),
                ),
                const SizedBox(width: 16),
                // 방 정보 텍스트
                Expanded(child: _buildRoomInfo()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 당사자 정보 섹션
  Widget _buildPartyInfoSection() {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildHostCard(),
          const SizedBox(height: 16),
          _buildGuestCard(),
        ],
      );
    } else {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildHostCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildGuestCard()),
          ],
        ),
      );
    }
  }

  /// 호스트 카드
  Widget _buildHostCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '호스트 정보',
            style: TextStyle(
              fontSize: 16, // text-base
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 16), // mb-4

          // space-y-3
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타 + 이름
              Row(
                children: [
                  // 아바타 (w-12 h-12)
                  Container(
                    width: 48, // w-12
                    height: 48, // h-12
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE), // blue-100
                      shape: BoxShape.circle,
                    ),
                    child: _contract!.hostProfileImage != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _getFullImageUrl(_contract!.hostProfileImage!),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, color: Color(0xFF2563EB)), // blue-600
                            ),
                          )
                        : const Icon(Icons.person, color: Color(0xFF2563EB)), // blue-600
                  ),
                  const SizedBox(width: 12), // gap-3
                  // 이름 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        Text(
                          _contract!.hostName,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w700, // font-bold
                            color: Color(0xFF111827), // gray-900
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // space-y-3

              // 연락처 (pl-15)
              Padding(
                padding: const EdgeInsets.only(left: 60), // pl-15 (15 * 4 = 60px)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '연락처',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF4B5563), // gray-600
                      ),
                    ),
                    // 호스트는 자신의 전화번호를 항상 볼 수 있음
                    if (_contract!.hostPhoneNumber != null)
                      Text(
                        _contract!.hostPhoneNumber!,
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
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

  /// 게스트 카드
  Widget _buildGuestCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '게스트 정보',
            style: TextStyle(
              fontSize: 16, // text-base
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 16), // mb-4

          // space-y-3
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타 + 이름
              Row(
                children: [
                  // 아바타 (w-12 h-12)
                  Container(
                    width: 48, // w-12
                    height: 48, // h-12
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7), // green-100
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF16A34A)), // green-600
                  ),
                  const SizedBox(width: 12), // gap-3
                  // 이름 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        Text(
                          _contract!.guestName,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w700, // font-bold
                            color: Color(0xFF111827), // gray-900
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // space-y-3

              // 연락처 (pl-15)
              Padding(
                padding: const EdgeInsets.only(left: 60), // pl-15 (15 * 4 = 60px)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '연락처',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF4B5563), // gray-600
                      ),
                    ),
                    // 전화번호는 결제 완료 후 상태에서만 표시
                    Text(
                      _shouldShowGuestPhone()
                          ? _contract!.guestPhone
                          : '결제 완료 후 확인 가능',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        fontWeight: FontWeight.w700, // font-bold
                        color: _shouldShowGuestPhone()
                            ? const Color(0xFF111827) // gray-900
                            : const Color(0xFF111827), // gray-900
                      ),
                    ),
                  ],
                ),
              ),

              // 게스트 메시지 (있을 경우 회색 박스로 표시)
              if (_contract!.guestMessage != null &&
                  _contract!.guestMessage!.isNotEmpty) ...[
                const SizedBox(height: 12), // mt-3
                Container(
                  padding: const EdgeInsets.all(12), // p-3 = 12px
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB), // gray-50
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                    border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.message_outlined,
                          size: 16, color: Color(0xFF4B5563)), // gray-600, w-4 h-4
                      const SizedBox(width: 8), // gap-2
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '게스트 메시지',
                              style: TextStyle(
                                fontSize: 12, // text-xs
                                fontWeight: FontWeight.w700, // font-bold
                                color: Color(0xFF374151), // gray-700
                              ),
                            ),
                            const SizedBox(height: 4), // mb-1
                            Text(
                              _contract!.guestMessage!,
                              style: const TextStyle(
                                fontSize: 14, // text-sm
                                color: Color(0xFF1F2937), // gray-800
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 계약 금액 섹션 (호스트 특화)
  Widget _buildContractAmountSection() {
    final commissionFee = _getHostCommissionFee();
    final settlementAmount = _getActualSettlementAmount();
    final totalContractAmount = _contract!.rentalFee +
        _contract!.maintenanceFee +
        _contract!.cleaningFee +
        _contract!.deposit;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 (text-lg = 18px)
          Text(
            '계약 금액',
            style: const TextStyle(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 16),

          // Gray-50 배경 박스로 모든 금액 정보 감싸기
          Container(
            padding: const EdgeInsets.all(16), // p-4
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), // gray-50
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이용 금액 서브타이틀
                const Text(
                  '이용 금액',
                  style: TextStyle(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w700, // font-bold
                    color: Color(0xFF111827), // gray-900
                  ),
                ),
                const SizedBox(height: 8), // mb-2

                // 세부 금액들 (pl-3 indented)
                Padding(
                  padding: const EdgeInsets.only(left: 12), // pl-3
                  child: Column(
                    children: [
                      // 렌탈료
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '임대료',
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              color: Color(0xFF374151), // gray-700
                            ),
                          ),
                          Text(
                            _formatCurrency(_contract!.rentalFee),
                            style: const TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 관리비
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '관리비',
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              color: Color(0xFF374151), // gray-700
                            ),
                          ),
                          Text(
                            _formatCurrency(_contract!.maintenanceFee),
                            style: const TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 청소비 또는 EZ 청소 서비스 배지
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '청소비',
                                style: TextStyle(
                                  fontSize: 14, // text-sm
                                  color: Color(0xFF374151), // gray-700
                                ),
                              ),
                              if (_contract!.isEzCleaning) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB), // blue-600
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'EZ서비스',
                                    style: TextStyle(
                                      fontSize: 12, // text-xs
                                      fontWeight: FontWeight.w700, // font-bold
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatCurrency(_contract!.cleaningFee),
                            style: const TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 보증금 (게스트 퇴실 후 환급)
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            '보증금 ',
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                          Text(
                            '(게스트 퇴실 후 환급)',
                            style: TextStyle(
                              fontSize: 12, // text-xs
                              fontWeight: FontWeight.w400, // font-normal
                              color: Color(0xFF6B7280), // gray-500
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(_contract!.deposit),
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                    ],
                  ),
                ),

                // 총 계약 금액
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFD1D5DB), width: 2), // border-t-2 gray-300
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총 계약 금액',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                      Text(
                        _formatCurrency(totalContractAmount),
                        style: const TextStyle(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                    ],
                  ),
                ),

                // 호스트 계약수수료
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '호스트 계약수수료',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          color: Color(0xFF000000), // rgb(0,0,0)
                        ),
                      ),
                      Text(
                        '- ${_formatCurrency(commissionFee)}',
                        style: const TextStyle(
                          fontSize: 16, // text-[16px]
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF000000), // rgb(0,0,0)
                        ),
                      ),
                    ],
                  ),
                ),

                // 정산 예정금액 (no space!)
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '정산 예정금액',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF2563EB), // blue-600
                        ),
                      ),
                      Text(
                        _formatCurrency(settlementAmount),
                        style: const TextStyle(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF2563EB), // blue-600
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// 안내사항 섹션 (노란 박스)
  Widget _buildNoticeSection() {
    return Container(
      padding: AppSpacing.paddingLg, // p-6
      decoration: BoxDecoration(
        color: Colors.white, // bg-white
        borderRadius: BorderRadius.circular(AppRadius.radiusLg), // rounded-xl
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
        boxShadow: _cardShadow, // shadow-sm
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목: "계약 안내사항" (text-lg = 18px)
          const Text(
            '계약 안내사항',
            style: TextStyle(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 12), // mb-3

          // Yellow-50 안내 박스
          Container(
            padding: const EdgeInsets.all(16), // p-4
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8), // yellow-50
              borderRadius: BorderRadius.circular(AppRadius.radiusMd), // rounded-lg
              border: Border.all(color: const Color(0xFFFEF08A)), // yellow-200
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNoticeBullet('옵션 상품(침구류, 어메니티 키트, 헤어드라이기 등)은 호스트 계약 정보에 표시되지 않습니다.'),
                _buildNoticeBullet('보증금은 제3자 예치기관에 보관며, 정산 금액에 포함되지 않습니다'),
                _buildNoticeBullet('정산은 계약 종료 후 영업일 기준 1~2일 내에 진행됩니다'),
                _buildNoticeBullet('게스트가 계약을 위반하거나 시설을 손상한 경우 보증금에서 차감될 수 있습니다'),
                _buildNoticeBullet('계약 취소 시 취소 정책에 따라 위약금이 부과될 수 있습니다'),
                _buildNoticeBullet('문의사항이 있으시면 고객센터로 연락 주시기 바랍니다'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 안내사항 불릿 포인트
  Widget _buildNoticeBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // space-y-1
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 12, // text-xs
              color: Color(0xFF854D0E), // yellow-800
              height: 1.6, // leading-relaxed
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12, // text-xs
                color: Color(0xFF854D0E), // yellow-800
                height: 1.6, // leading-relaxed
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 배지 빌더
  Widget _buildStatusBadge() {
    String statusText;
    Color backgroundColor;
    Color textColor;

    switch (_contract!.status) {
      case 'PENDING_APPROVAL':
        statusText = '승인 대기';
        backgroundColor = const Color(0xFFFEF3C7); // yellow-100
        textColor = const Color(0xFFF59E0B); // yellow-500
        break;
      case 'APPROVED':
        statusText = '승인 완료';
        backgroundColor = const Color(0xFFDCFCE7); // green-100
        textColor = const Color(0xFF16A34A); // green-600
        break;
      case 'PAYMENT_COMPLETED':
        statusText = '결제 완료';
        backgroundColor = const Color(0xFFDBEAFE); // blue-100
        textColor = const Color(0xFF2563EB); // blue-600
        break;
      case 'IN_PROGRESS':
        statusText = '진행 중';
        backgroundColor = const Color(0xFFE0E7FF); // indigo-100
        textColor = const Color(0xFF6366F1); // indigo-500
        break;
      case 'COMPLETED':
        statusText = '완료';
        backgroundColor = const Color(0xFFF3F4F6); // gray-100
        textColor = const Color(0xFF6B7280); // gray-500
        break;
      case 'CANCELLED':
        statusText = '취소됨';
        backgroundColor = const Color(0xFFFEE2E2); // red-100
        textColor = const Color(0xFFDC2626); // red-600
        break;
      default:
        statusText = '알 수 없음';
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // py-1 = 4px
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999), // rounded-full
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 14, // text-sm
          fontWeight: FontWeight.w700, // font-bold
          color: textColor,
        ),
      ),
    );
  }

  /// 방 정보 (이름, 주소, 계약 기간, 계약 확정)
  Widget _buildRoomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방 이름 (text-lg font-bold text-gray-900)
        Text(
          _contract!.roomName,
          style: const TextStyle(
            fontSize: 18, // text-lg
            fontWeight: FontWeight.w700, // font-bold
            color: Color(0xFF111827), // gray-900
          ),
        ),
        const SizedBox(height: 12), // mb-3

        // space-y-2 text-sm 섹션
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주소 (라벨 포함)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주소 : ',
                  style: TextStyle(
                    fontSize: 14, // text-sm
                    color: Color(0xFF374151), // gray-700
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF000000), // rgb(0,0,0)
                      ),
                      children: [
                        TextSpan(text: _contract!.address),
                        const TextSpan(text: ' '),
                        TextSpan(text: _contract!.detailAddress),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // space-y-2

            // 계약 기간 (inline 텍스트)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14, // text-sm
                  color: Color(0xFF374151), // gray-700
                ),
                children: [
                  const TextSpan(text: '계약 기간: '),
                  TextSpan(
                    text: '${_formatDate(_contract!.checkInDate)} - ${_formatDate(_contract!.checkOutDate)} (${_contract!.totalDays}일)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, // font-bold
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                ],
              ),
            ),

            // 계약 확정 (결제 완료 후 상태에서만 표시)
            if (_contract!.paidAt != null &&
                ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED']
                    .contains(_contract!.status)) ...[
              const SizedBox(height: 8), // space-y-2
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14, // text-sm
                    color: Color(0xFF374151), // gray-700
                  ),
                  children: [
                    const TextSpan(text: '계약 확정: '),
                    TextSpan(
                      text: _formatDate(_contract!.paidAt!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, // font-bold
                        color: Color(0xFF374151), // gray-700
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 게스트 전화번호 표시 여부
  bool _shouldShowGuestPhone() {
    return _contract!.status == 'PAYMENT_COMPLETED' ||
        _contract!.status == 'IN_PROGRESS' ||
        _contract!.status == 'COMPLETED';
  }

  /// 이미지 URL 가져오기
  String _getFullImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.baseUrl}$path';
  }

  /// 금액 포맷팅
  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}원';
  }

  /// 날짜 포맷팅
  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
