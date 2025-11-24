import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../models/refund_policy.dart';
import '../../services/contract_service.dart';
import '../../services/refund_policy_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../core/theme/app_colors.dart';

/// 계약 시작하기 페이지
class ContractStartPage extends StatefulWidget {
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const ContractStartPage({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
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

  // 약관 동의
  bool _serviceTermsAgreed = false;
  bool _cancellationPolicyAgreed = false;
  bool _refundPolicyAgreed = false;

  // 전체 동의
  bool get _allTermsAgreed =>
      _serviceTermsAgreed && _cancellationPolicyAgreed && _refundPolicyAgreed;

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


  /// 총 임대료 계산
  int _calculateRentalTotal() {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final weeks = (days / 7).ceil();
    return widget.room.weeklyRent * weeks;
  }

  /// 총 관리비 계산
  int _calculateMaintenanceTotal() {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final weeks = (days / 7).ceil();
    return widget.room.maintenanceFee * weeks;
  }

  /// 총 옵션 금액 계산 (렌탈 아이템 제거로 항상 0 반환)
  int _calculateOptionsTotal() {
    return 0;
  }

  /// 할인 금액 계산
  int _calculateDiscount() {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final weeks = (days / 7).ceil();

    if (widget.room.longTermDiscount != null &&
        widget.room.longTermDiscount! > 0 &&
        widget.room.longTermWeeks != null &&
        weeks >= widget.room.longTermWeeks!) {
      final rentalTotal = _calculateRentalTotal();
      return (rentalTotal * widget.room.longTermDiscount! / 100).round();
    }
    return 0;
  }

  /// 플랫폼 수수료 계산 (임대료 + 관리비의 10%)
  int _calculatePlatformFee() {
    final rentalTotal = _calculateRentalTotal();
    final maintenanceTotal = _calculateMaintenanceTotal();

    // 계약 수수료: (임대료 + 관리비)의 10%
    final baseForContractFee = rentalTotal + maintenanceTotal;
    return (baseForContractFee * 0.1).round();
  }

  /// 최종 금액 계산 (수수료 포함)
  int _calculateFinalTotal() {
    return _calculateRentalTotal() +
           _calculateMaintenanceTotal() +
           widget.room.cleaningFee +
           _calculateOptionsTotal() +
           _calculatePlatformFee() -
           _calculateDiscount();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('계약 시작하기'),
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
                flex: isWideScreen ? 2 : 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 방 정보 & 호스트 정보 (2열)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 방 정보
                          Expanded(
                            child: _buildRoomInfo(),
                          ),
                          const SizedBox(width: 16),
                          // 호스트 정보
                          Expanded(
                            child: _buildHostInfo(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 임대기간
                      _buildRentalPeriod(days),
                      const SizedBox(height: 24),

                      // 결제 금액
                      _buildPaymentDetails(),
                      const SizedBox(height: 24),

                      // 계약 해지 조항
                      _buildCancellationPolicy(),
                      const SizedBox(height: 24),

                      // 안내사항
                      _buildNotice(),
                      const SizedBox(height: 24),

                      // 약관 동의
                      _buildTermsAgreement(),
                      const SizedBox(height: 100), // 하단 여백
                    ],
                  ),
                ),
              ),

              // 오른쪽: 고정 위젯 (데스크톱에서만 표시)
              if (isWideScreen) ...[
                const SizedBox(width: 20),
                SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
                    child: _buildRightFixedWidget(),
                  ),
                ),
              ],
            ],
          ),
        ),
      // 모바일/태블릿용 하단 고정 버튼
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
              child: _buildSubmitButton(),
            )
          : null,
    );
  }

  /// 오른쪽 고정 위젯
  Widget _buildRightFixedWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
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
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary600.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '계약 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('MM.dd').format(widget.checkInDate)} - ${DateFormat('MM.dd').format(widget.checkOutDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 최종 금액
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최종 결제 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currencyFormat.format(_calculateFinalTotal() + 330000)} 원',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 호스트에게 전할 말
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '호스트에게 전하고 싶은 말을\n남겨주세요',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '입주 시간, 인원 등 호스트에게 알려주시면 미리 방을 준비하는 데 도움이 됩니다. (선택)',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                      borderSide: const BorderSide(color: AppColors.primary600, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  '계약을 승인하면 게스트는 결제 완료 후 계약이 확정됩니다.\n담당자가 있는 물건은 반드시 미리 준비를 해야 합니다.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5),
                ),
              ],
            ),
          ),

          // 계약 승인 요청하기 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  /// 방 정보
  Widget _buildRoomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '방 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('방 이름', widget.room.roomName),
          const SizedBox(height: 8),
          _buildInfoRow('소재지', widget.room.address),
        ],
      ),
    );
  }

  /// 호스트 정보
  Widget _buildHostInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '호스트 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('이름', widget.room.hostName ?? '유저에게 연락'),
          const SizedBox(height: 8),
          _buildInfoRow(
            '연락처',
            '게스트와 확정되면 연락처 공개',
            valueColor: Colors.blue[700],
          ),
        ],
      ),
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 임대기간
  Widget _buildRentalPeriod(int days) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '임대기간',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '체크인',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(widget.checkInDate)} ${widget.room.checkInTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '체크아웃',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(widget.checkOutDate)} ${widget.room.checkOutTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 결제 금액
  Widget _buildPaymentDetails() {
    final rentalTotal = _calculateRentalTotal();
    final maintenanceTotal = _calculateMaintenanceTotal();
    final cleaningFee = widget.room.cleaningFee;
    final platformFee = _calculatePlatformFee();
    final discount = _calculateDiscount();
    final finalTotal = _calculateFinalTotal();
    const deposit = 330000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '결제 금액',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('임대료', rentalTotal),
          const SizedBox(height: 8),
          _buildPriceRow('관리비', maintenanceTotal),
          const SizedBox(height: 8),
          _buildPriceRow('청소비용', cleaningFee),
          const SizedBox(height: 8),
          _buildPriceRow('계약 수수료 (임대료의 10%)', platformFee),
          if (discount > 0) ...[
            const Divider(height: 24),
            _buildPriceRow(
              '할인 금액',
              -discount,
              isDiscount: true,
            ),
          ],
          const Divider(height: 24),
          _buildPriceRow(
            '실이용 금액',
            finalTotal,
            isBold: true,
            fontSize: 16,
          ),
          const Divider(height: 24),
          _buildPriceRow('보증금', deposit, isGrey: true),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '* 보증금은 상상열매에서 보관하며, 퇴실 후 반환됩니다.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Divider(height: 24),
          _buildPriceRow(
            '최종 결제 금액',
            finalTotal + deposit,
            isBold: true,
            fontSize: 18,
            valueColor: AppColors.primary600,
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
    double fontSize = 13,
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
            color: isGrey ? Colors.grey[700] : Colors.black87,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}${_currencyFormat.format(price.abs())} 원',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isDiscount ? Colors.red : (isGrey ? Colors.grey[700] : Colors.black87)),
          ),
        ),
      ],
    );
  }

  /// 계약 해지 조항
  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계약 해지 조항',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

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
        ],
      ),
    );
  }

  /// 환불 규칙을 취소 날짜 텍스트로 변환
  String _calculateCancellationText(RefundRule rule) {
    final description = rule.description;
    final refundRate = rule.refundRate;

    // "결제 당일" 또는 "계약 당일"은 날짜 계산 없이 그대로 표시
    // (결제/계약 시점은 입주일과 다른 날짜이므로 계산 불가)
    if (description.contains('결제') || description.contains('계약')) {
      return '$description : 임대료와 계약 수수료의 $refundRate% 환불';
    }

    // "입주일 20일 이전" 형식 파싱
    final beforeMatch = RegExp(r'입주일\s+(\d+)일\s+이전').firstMatch(description);
    if (beforeMatch != null) {
      final days = int.parse(beforeMatch.group(1)!);
      final deadline = widget.checkInDate.subtract(Duration(days: days));
      final dateStr = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(deadline);
      return '$dateStr까지 취소 시 : 임대료와 계약 수수료의 $refundRate% 환불';
    }

    // "입주일 19일 ~ 10일 이전" 형식 파싱
    final rangeMatch = RegExp(r'입주일\s+(\d+)일\s+~\s+(\d+)일\s+이전').firstMatch(description);
    if (rangeMatch != null) {
      final startDays = int.parse(rangeMatch.group(1)!);
      final endDays = int.parse(rangeMatch.group(2)!);
      final startDate = widget.checkInDate.subtract(Duration(days: startDays));
      final endDate = widget.checkInDate.subtract(Duration(days: endDays));
      final startStr = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(startDate);
      final endStr = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(endDate);
      return '$startStr ~ $endStr 취소 시 : 임대료와 계약 수수료의 $refundRate% 환불';
    }

    // "입주일 당일 이후" 또는 기타 형식
    if (description.contains('입주') && (description.contains('당일') || description.contains('이후'))) {
      final dateStr = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(widget.checkInDate);
      if (refundRate == 0) {
        return '$dateStr 0시 이후 : 환불 불가';
      } else {
        return '$dateStr 이후 취소 시 : 임대료와 계약 수수료의 $refundRate% 환불';
      }
    }

    // 파싱 실패 시 원본 텍스트 표시
    return '$description : 임대료와 계약 수수료의 $refundRate% 환불';
  }

  /// 안내사항
  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[800]),
              const SizedBox(width: 8),
              const Text(
                '안내사항',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletText('결제 당일 취소 시, 환불 규정과 관계 없이 임대료와 계약 수수료를 합계한 10%만 위약금으로 부과됩니다. 단, 무료 취소 기간에 해당하는 경우 전액 환불됩니다.'),

          // API에서 로드한 특별 규칙 표시
          if (_refundPolicy?.specialRules?.alwaysRefund != null)
            _buildBulletText(_refundPolicy!.specialRules!.alwaysRefund!)
          else
            _buildBulletText('관리비, 청소비, 보증금은 전액 환불됩니다.'),

          _buildBulletText('환불 규정은 호스트의 설정에 따라 달라집니다.'),
        ],
      ),
    );
  }

  /// 불릿 텍스트
  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 약관 동의
  Widget _buildTermsAgreement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '약관 동의',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 전체 동의
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary600.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _allTermsAgreed,
                  onChanged: (value) {
                    setState(() {
                      _serviceTermsAgreed = value ?? false;
                      _cancellationPolicyAgreed = value ?? false;
                      _refundPolicyAgreed = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary600,
                ),
                const Text(
                  '전체 동의',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 개별 약관
          _buildTermCheckbox(
            '서비스 이용약관 동의 (필수)',
            _serviceTermsAgreed,
            (value) => setState(() => _serviceTermsAgreed = value ?? false),
          ),
          _buildTermCheckbox(
            '취소 및 환불 규정 동의 (필수)',
            _cancellationPolicyAgreed,
            (value) => setState(() => _cancellationPolicyAgreed = value ?? false),
          ),
          _buildTermCheckbox(
            '환불 정책 동의 (필수)',
            _refundPolicyAgreed,
            (value) => setState(() => _refundPolicyAgreed = value ?? false),
          ),
        ],
      ),
    );
  }

  /// 약관 체크박스
  Widget _buildTermCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary600,
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: 약관 상세 페이지 이동
          },
          child: const Text(
            '보기',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// 계약 승인 요청하기 버튼
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _allTermsAgreed && !_isLoading
            ? () {
                _showContractRequestDialog();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _allTermsAgreed ? AppColors.primary600 : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _allTermsAgreed ? '계약 승인 요청하기' : '약관에 동의해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _allTermsAgreed ? Colors.white : Colors.grey[600],
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
        title: const Text('계약 승인 요청'),
        content: const Text('계약 승인을 요청하시겠습니까?\n호스트가 승인하면 결제가 진행됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestContract();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 계약 승인 요청 API 호출
  Future<void> _requestContract() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rentalTotal = _calculateRentalTotal();
      final maintenanceTotal = _calculateMaintenanceTotal();
      final cleaningFee = widget.room.cleaningFee;
      final platformFee = _calculatePlatformFee();
      final discount = _calculateDiscount();
      final finalTotal = _calculateFinalTotal();
      const deposit = 330000;

      final totalDays = widget.checkOutDate.difference(widget.checkInDate).inDays;
      final totalWeeks = (totalDays / 7).ceil();

      final subtotal = rentalTotal + maintenanceTotal + cleaningFee;

      await _contractService.requestContract(
        roomId: widget.room.id,
        checkInDate: widget.checkInDate,
        checkOutDate: widget.checkOutDate,
        totalDays: totalDays,
        totalWeeks: totalWeeks,
        rentalFee: rentalTotal,
        maintenanceFee: maintenanceTotal,
        cleaningFee: cleaningFee,
        platformFee: platformFee,
        discountAmount: discount,
        subtotal: subtotal,
        totalUsageFee: finalTotal,
        deposit: deposit,
        finalTotalAmount: finalTotal + deposit,
        guestMessage: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        serviceTermsAgreed: _serviceTermsAgreed,
        cancellationPolicyAgreed: _cancellationPolicyAgreed,
        refundPolicyAgreed: _refundPolicyAgreed,
        dailyRentalFee: widget.room.dailyRent.toDouble(),
        dailyMaintenanceFee: widget.room.dailyMaintenanceFee.toDouble(),
        platformFeeRate: 0.1,
        depositRate: 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계약 승인 요청이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
