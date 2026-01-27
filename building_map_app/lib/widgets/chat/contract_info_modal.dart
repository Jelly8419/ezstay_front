import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';

/// 계약 정보 모달 위젯
/// React ContractInfoModal.tsx를 Flutter로 완전 복제
class ContractInfoModal extends StatelessWidget {
  final ContractDetail contract;
  final String userMode; // 'host' | 'guest'
  final VoidCallback onClose;

  const ContractInfoModal({
    super.key,
    required this.contract,
    required this.userMode,
    required this.onClose,
  });

  /// 금액 포맷팅
  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }

  /// 날짜 포맷팅 (YYYY.MM.DD(요일))
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
      final weekday = weekdays[date.weekday % 7];
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}($weekday)';
    } catch (e) {
      return dateStr;
    }
  }

  /// 날짜+시간 포맷팅 (DateTime 객체)
  String _formatDateTimeFromDateTime(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 호스트 수수료 계산 (3.3%)
  int _getHostCommissionFee() {
    final baseAmount = contract.isEzCleaning
        ? contract.rentalFee + contract.maintenanceFee
        : contract.rentalFee + contract.maintenanceFee + contract.cleaningFee;
    return (baseAmount * 0.033).floor();
  }

  /// 호스트 정산 예정 금액
  int _getActualSettlementAmount() {
    final baseAmount = contract.isEzCleaning
        ? contract.rentalFee + contract.maintenanceFee
        : contract.rentalFee + contract.maintenanceFee + contract.cleaningFee;
    return baseAmount - _getHostCommissionFee();
  }

  /// 상태 뱃지 색상
  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return const Color(0xFFFEF3C7); // bg-yellow-100
      case 'APPROVED':
        return const Color(0xFFDBEAFE); // bg-blue-100
      case 'PAYMENT_COMPLETED':
        return const Color(0xFFD1FAE5); // bg-green-100
      case 'IN_PROGRESS':
        return const Color(0xFFF3E8FF); // bg-purple-100
      case 'COMPLETED':
        return AppColors.neutral100; // bg-gray-100
      case 'REJECTED':
      case 'CANCELLED_BY_GUEST':
      case 'CANCELLED_BY_HOST':
        return const Color(0xFFFEE2E2); // bg-red-100
      default:
        return AppColors.neutral100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return const Color(0xFFA16207); // text-yellow-700
      case 'APPROVED':
        return const Color(0xFF1D4ED8); // text-blue-700
      case 'PAYMENT_COMPLETED':
        return const Color(0xFF047857); // text-green-700
      case 'IN_PROGRESS':
        return const Color(0xFF7E22CE); // text-purple-700
      case 'COMPLETED':
        return AppColors.neutral700; // text-gray-700
      case 'REJECTED':
      case 'CANCELLED_BY_GUEST':
      case 'CANCELLED_BY_HOST':
        return const Color(0xFFB91C1C); // text-red-700
      default:
        return AppColors.neutral700;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return '승인 대기';
      case 'APPROVED':
        return '결제 대기';
      case 'PAYMENT_COMPLETED':
        return '결제 완료';
      case 'IN_PROGRESS':
        return '임대 중';
      case 'COMPLETED':
        return '계약 종료';
      case 'REJECTED':
        return '계약 거절';
      case 'CANCELLED_BY_GUEST':
        return userMode == 'guest' ? '계약 취소' : '게스트 취소';
      case 'CANCELLED_BY_HOST':
        return '호스트 취소';
      default:
        return '알 수 없음';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return Icons.access_time;
      case 'APPROVED':
        return Icons.info_outline;
      case 'PAYMENT_COMPLETED':
        return Icons.check_circle;
      case 'IN_PROGRESS':
        return Icons.home;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REJECTED':
      case 'CANCELLED_BY_GUEST':
      case 'CANCELLED_BY_HOST':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// 결제 완료 이후 상태인지 확인
  bool _isPaymentConfirmed() {
    return ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED'].contains(contract.status);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16), // p-4
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl (42rem = 672px)
        decoration: BoxDecoration(
          color: AppColors.neutral0, // bg-white
          borderRadius: BorderRadius.circular(12), // rounded-xl
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Content (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24), // p-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 정보
                    _buildBasicInfo(),
                    const SizedBox(height: 24), // space-y-6

                    // 호스트/게스트 정보
                    _buildPartyInfo(),
                    const SizedBox(height: 24),

                    // 계약 금액
                    if (userMode == 'host')
                      _buildHostPriceSection()
                    else
                      _buildGuestPriceSection(),
                    const SizedBox(height: 24),

                    // 옵션 상품 (게스트만)
                    if (userMode == 'guest' && contract.rentalItems.isNotEmpty) ...[
                      _buildRentalItemsSection(),
                      const SizedBox(height: 24),
                    ],

                    // 결제 내역 (게스트만)
                    if (userMode == 'guest' && contract.paymentHistory.isNotEmpty) ...[
                      _buildPaymentHistorySection(),
                      const SizedBox(height: 24),
                    ],

                    // 환불 규정
                    if (contract.refundPolicyDetail.isNotEmpty) ...[
                      _buildRefundPolicySection(),
                      const SizedBox(height: 24),
                    ],

                    // 안내사항
                    _buildNoticeSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 헤더
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 1),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '계약 상세 정보',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.gray900,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              hoverColor: AppColors.neutral100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 기본 정보 섹션
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (타이틀 + 상태 뱃지)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기본 정보',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                if (contract.orderId != null) ...[
                  const SizedBox(height: 8), // mt-2
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall,
                      children: [
                        TextSpan(
                          text: '계약번호: ',
                          style: TextStyle(color: AppColors.gray600),
                        ),
                        TextSpan(
                          text: contract.orderId,
                          style: TextStyle(
                            color: AppColors.blue600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 16), // mb-4

        // 방 정보
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 방 사진
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // rounded-lg
              child: contract.roomPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: contract.roomPhoto,
                      width: 128, // w-32
                      height: 128, // h-32
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => _buildImagePlaceholder(),
                      errorWidget: (ctx, url, error) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 16), // gap-4

            // 방 정보 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contract.roomName,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 12), // mb-3

                  // 주소
                  _buildInfoRow(
                    '주소',
                    _buildAddressText(),
                  ),
                  const SizedBox(height: 8), // space-y-2

                  // 계약 기간
                  _buildInfoRow(
                    '계약 기간',
                    '${_formatDate(contract.checkInDate)} - ${_formatDate(contract.checkOutDate)} (${contract.totalDays}일)',
                  ),

                  // 계약 확정일 (결제 완료 이후만)
                  if (contract.paidAt != null && _isPaymentConfirmed()) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '계약 확정',
                      _formatDate(contract.paidAt!),
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 128,
      height: 128,
      color: AppColors.neutral200,
      child: const Icon(Icons.home, size: 40, color: AppColors.neutral400),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(contract.status),
        borderRadius: BorderRadius.circular(9999), // rounded-full
      ),
      child: Text(
        _getStatusLabel(contract.status),
        style: AppTextStyles.bodySmall.copyWith(
          color: _getStatusTextColor(contract.status),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildAddressText() {
    final address = contract.address;
    // 게스트이고 결제 전이면 층수만 표시
    if (userMode == 'guest' &&
        (contract.status == 'PENDING_APPROVAL' || contract.status == 'APPROVED')) {
      return '$address ${contract.floor}';
    }
    return '$address ${contract.detailAddress}';
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80, // w-20
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray900,
                ),
          ),
        ),
      ],
    );
  }

  /// 호스트/게스트 정보 섹션
  Widget _buildPartyInfo() {
    return Row(
      children: [
        // 호스트 정보
        Expanded(
          child: _buildPartyCard(
            title: '호스트',
            name: contract.hostName,
            phone: _isPaymentConfirmed() ? contract.hostPhoneNumber : null,
            profileImage: contract.hostProfileImage,
            iconColor: AppColors.blue600,
            iconBgColor: const Color(0xFFDBEAFE), // bg-blue-100
          ),
        ),
        const SizedBox(width: 16), // gap-4

        // 게스트 정보
        Expanded(
          child: _buildGuestCard(),
        ),
      ],
    );
  }

  Widget _buildPartyCard({
    required String title,
    required String name,
    String? phone,
    String? profileImage,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: AppColors.gray50, // bg-gray-50
        borderRadius: BorderRadius.circular(8), // rounded-lg
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12), // mb-3
          Row(
            children: [
              // 아바타
              if (profileImage != null && profileImage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: CachedNetworkImage(
                    imageUrl: profileImage,
                    width: 48, // w-12
                    height: 48, // h-12
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _buildAvatarPlaceholder(iconColor, iconBgColor),
                    errorWidget: (ctx, url, error) => _buildAvatarPlaceholder(iconColor, iconBgColor),
                  ),
                )
              else
                _buildAvatarPlaceholder(iconColor, iconBgColor),
              const SizedBox(width: 12), // gap-3

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 4), // mt-1
                      Text(
                        phone,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gray600,
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

  Widget _buildGuestCard() {
    final showPhone = userMode == 'host'
        ? (_isPaymentConfirmed() ? contract.guestPhone : '결제 완료 후 확인 가능')
        : contract.guestPhone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '게스트',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAvatarPlaceholder(
                AppColors.green600,
                const Color(0xFFD1FAE5), // bg-green-100
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.guestName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showPhone,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 게스트 메시지 (호스트만)
          if (userMode == 'host' && contract.guestMessage != null && contract.guestMessage!.isNotEmpty) ...[
            const SizedBox(height: 12), // mt-3
            Container(
              padding: const EdgeInsets.all(12), // p-3
              decoration: BoxDecoration(
                color: AppColors.neutral0, // bg-white
                border: Border.all(color: AppColors.gray200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.message,
                      size: 16, // w-4 h-4
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '게스트 메시지',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutral700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4), // mb-1
                        Text(
                          contract.guestMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral800,
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
    );
  }

  Widget _buildAvatarPlaceholder(Color iconColor, Color bgColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Icon(
        Icons.person,
        size: 24, // w-6 h-6
        color: iconColor,
      ),
    );
  }

  /// 호스트용 금액 섹션
  Widget _buildHostPriceSection() {
    final totalContractAmount = contract.rentalFee +
        contract.maintenanceFee +
        contract.cleaningFee +
        contract.deposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '계약 금액',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 16), // mb-4

        Container(
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            color: AppColors.gray50,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이용 금액
              Text(
                '이용 금액',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8), // mb-2
              Padding(
                padding: const EdgeInsets.only(left: 12), // pl-3
                child: Column(
                  children: [
                    _buildPriceRow('임대료', contract.rentalFee),
                    const SizedBox(height: 8),
                    _buildPriceRow('관리비', contract.maintenanceFee),
                    const SizedBox(height: 8),
                    _buildCleaningFeeRow(),
                  ],
                ),
              ),

              // 보증금
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.gray200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '보증금 ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '(게스트 퇴실 후 환급)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(contract.deposit),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 총 계약 금액
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.gray300, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '총 계약 금액',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatCurrency(totalContractAmount),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 호스트 계약수수료
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '호스트 계약수수료',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      '- ${_formatCurrency(_getHostCommissionFee())}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // 정산 예정 금액
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.gray200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '정산 예정금액',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatCurrency(_getActualSettlementAmount()),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.blue600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 게스트용 금액 섹션
  Widget _buildGuestPriceSection() {
    final totalRentalAmount = contract.rentalFee +
        contract.maintenanceFee +
        contract.cleaningFee +
        contract.platformFee +
        contract.deposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '임대 계약 금액',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 16),

        _buildPriceRow('임대료', contract.rentalFee),
        const SizedBox(height: 12),
        _buildPriceRow('관리비', contract.maintenanceFee),
        const SizedBox(height: 12),
        _buildCleaningFeeRow(),
        const SizedBox(height: 12),
        _buildPriceRow('계약 수수료', contract.platformFee),
        const SizedBox(height: 12),

        // 보증금
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '보증금 ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
                Text(
                  '(퇴실 후 반환 예정)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
            Text(
              _formatCurrency(contract.deposit),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        // 총 임대 계약 금액
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 임대 계약 금액',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatCurrency(totalRentalAmount),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral700,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCleaningFeeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '청소비',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral700,
              ),
            ),
            if (contract.isEzCleaning) ...[
              const SizedBox(width: 6), // gap-1.5
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // px-2 py-0.5
                decoration: BoxDecoration(
                  color: AppColors.blue600, // bg-blue-600
                  borderRadius: BorderRadius.circular(4), // rounded
                ),
                child: Text(
                  'EZ서비스',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral0, // text-white
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          _formatCurrency(contract.cleaningFee),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// 옵션 상품 섹션 (게스트만)
  Widget _buildRentalItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, size: 20, color: AppColors.neutral700), // Package icon
            const SizedBox(width: 8), // gap-2
            Text(
              '옵션 상품 (EZstay에서 제공)',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // mb-4

        // 아이템 목록
        ...contract.rentalItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12), // space-y-3
              child: Container(
                padding: const EdgeInsets.all(16), // p-4
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(8),
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
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.description != null && item.description!.isNotEmpty) ...[
                            const SizedBox(height: 4), // mb-1
                            Text(
                              item.description!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4), // mt-1
                          Text(
                            '수량: ${item.quantity}개',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(item.totalPrice),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )),

        // 옵션 상품 합계
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.gray200, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '옵션 상품 합계',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatCurrency(contract.rentalItemsFee),
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 결제 내역 섹션 (게스트만)
  Widget _buildPaymentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.credit_card, size: 20, color: AppColors.neutral700), // CreditCard icon
            const SizedBox(width: 8),
            Text(
              '결제 내역',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...contract.paymentHistory.map((history) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getPaymentTypeLabel(history.transactionType),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8), // gap-2
                              _buildPaymentStatusBadge(history.status),
                            ],
                          ),
                          const SizedBox(height: 4), // mb-1
                          if (history.description != null)
                            Text(
                              history.description!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                          const SizedBox(height: 4), // mt-1
                          Text(
                            _formatDateTimeFromDateTime(history.transactionDate),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${history.isPayment ? '+' : '-'}${_formatCurrency(history.amount)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: history.isPayment
                            ? AppColors.gray900
                            : const Color(0xFFDC2626), // text-red-600
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  String _getPaymentTypeLabel(String type) {
    switch (type) {
      case 'PAYMENT':
        return '결제';
      case 'PARTIAL_REFUND':
        return '부분 환불';
      case 'FULL_REFUND':
        return '전체 환불';
      default:
        return type;
    }
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'COMPLETED':
        bgColor = const Color(0xFFD1FAE5); // bg-green-100
        textColor = const Color(0xFF047857); // text-green-700
        label = '완료';
        break;
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7); // bg-yellow-100
        textColor = const Color(0xFFA16207); // text-yellow-700
        label = '대기';
        break;
      case 'FAILED':
        bgColor = const Color(0xFFFEE2E2); // bg-red-100
        textColor = const Color(0xFFB91C1C); // text-red-700
        label = '실패';
        break;
      default:
        bgColor = AppColors.neutral100;
        textColor = AppColors.neutral700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // px-2 py-0.5
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4), // rounded
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// 환불 규정 섹션
  Widget _buildRefundPolicySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '환불 규정',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 12), // mb-3
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            color: AppColors.gray50, // bg-gray-50
            borderRadius: BorderRadius.circular(8), // rounded-lg
          ),
          child: Text(
            contract.refundPolicyDetail,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral700, // text-gray-700
              height: 1.6, // leading-relaxed
            ),
          ),
        ),
      ],
    );
  }

  /// 안내사항 섹션
  Widget _buildNoticeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안내사항',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 12), // mb-3
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCE8), // bg-yellow-50
            border: Border.all(color: const Color(0xFFFDE68A)), // border-yellow-200
            borderRadius: BorderRadius.circular(8), // rounded-lg
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNoticeItem('옵션 상품(침구류, 어메니티 키트, 헤어드라이기 등)은 호스트 계약 정보에 표시되지 않습니다.'),
              _buildNoticeItem('보증금은 제3자 예치기관에 보관되며, 정산 금액에 포함되지 않습니다.'),
              _buildNoticeItem('정산은 입주 후 영업일 기준 1~2일 내에 진행됩니다.'),
              _buildNoticeItem('보증금 환급은 계약 종료 후 영업일 기준 1~2일 내에 진행됩니다.'),
              _buildNoticeItem('게스트는 계약을 위반하거나 시설을 손상한 경우 보증금에서 차감될 수 있습니다.'),
              _buildNoticeItem('계약 취소 시 취소 정책에 따라 위약금이 부과될 수 있습니다.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // space-y-1
      child: Text(
        '• $text',
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF854D0E), // text-yellow-800
          height: 1.6, // leading-relaxed
        ),
      ),
    );
  }
}

/// ContractInfoModal을 표시하는 헬퍼 함수
void showContractInfoModal(
  BuildContext context, {
  required ContractDetail contract,
  required String userMode,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5), // bg-black bg-opacity-50
    builder: (context) => ContractInfoModal(
      contract: contract,
      userMode: userMode,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
