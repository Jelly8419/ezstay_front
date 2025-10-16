import 'package:flutter/material.dart';
import '../models/room.dart';
import '../constants/app_constants.dart';
import 'package:intl/intl.dart';

/// 계약 시작하기 페이지
class ContractStartPage extends StatefulWidget {
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int? selectedHairDryerId;
  final int? selectedBeddingSetId;
  final int? selectedAmenityKitId;
  final int? selectedTowelSetId;
  final int beddingSetQuantity;
  final int amenityKitQuantity;
  final int towelSetQuantity;

  const ContractStartPage({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    this.selectedHairDryerId,
    this.selectedBeddingSetId,
    this.selectedAmenityKitId,
    this.selectedTowelSetId,
    this.beddingSetQuantity = 1,
    this.amenityKitQuantity = 1,
    this.towelSetQuantity = 1,
  });

  @override
  State<ContractStartPage> createState() => _ContractStartPageState();
}

class _ContractStartPageState extends State<ContractStartPage> {
  final _currencyFormat = NumberFormat('#,###');
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// 렌탈 아이템 가격 조회
  int _getRentalItemPrice(int? itemId, List items) {
    if (itemId == null || items.isEmpty) return 0;
    try {
      final item = items.firstWhere((item) => item.id == itemId);
      return item.price;
    } catch (e) {
      return 0;
    }
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

  /// 총 옵션 금액 계산
  int _calculateOptionsTotal() {
    final rentalItems = widget.room.availableRentalItems;
    if (rentalItems == null) return 0;

    int hairDryerPrice = _getRentalItemPrice(widget.selectedHairDryerId, rentalItems.hairDryers);
    int beddingPrice = _getRentalItemPrice(widget.selectedBeddingSetId, rentalItems.beddingSets) * widget.beddingSetQuantity;
    int amenityKitPrice = _getRentalItemPrice(widget.selectedAmenityKitId, rentalItems.amenityKits) * widget.amenityKitQuantity;
    int towelSetPrice = _getRentalItemPrice(widget.selectedTowelSetId, rentalItems.towelSets) * widget.towelSetQuantity;

    return hairDryerPrice + beddingPrice + amenityKitPrice + towelSetPrice;
  }

  /// 할인 금액 계산
  int _calculateDiscount() {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final weeks = (days / 7).ceil();

    if (widget.room.longTermDiscount > 0 && weeks >= widget.room.longTermWeeks) {
      final rentalTotal = _calculateRentalTotal();
      return (rentalTotal * widget.room.longTermDiscount / 100).round();
    }
    return 0;
  }

  /// 최종 금액 계산
  int _calculateFinalTotal() {
    return _calculateRentalTotal() +
           _calculateMaintenanceTotal() +
           widget.room.cleaningFee +
           _calculateOptionsTotal() -
           _calculateDiscount();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('계약 시작하기'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
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
              color: AppColors.primary.withValues(alpha: 0.05),
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
                    color: AppColors.primary,
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
          Text(
            '${DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(widget.checkInDate)} - ${DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(widget.checkOutDate)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
    final optionsTotal = _calculateOptionsTotal();
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
          if (optionsTotal > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('계약 수수료', optionsTotal),
          ],
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
            valueColor: AppColors.primary,
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
          _buildBulletText('2025년 12월 03일까지 취소 시 : 임대료와 계약 수수료의 90% 환불'),
          _buildBulletText('2025년 12월 10일까지 취소 시 : 임대료와 계약 수수료의 70% 환불'),
          _buildBulletText('2025년 12월 17일까지 취소 시 : 임대료와 계약 수수료의 50% 환불'),
          _buildBulletText('2025년 12월 18일 0시 뒤터 : 환불 불가'),
        ],
      ),
    );
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
          _buildBulletText('결제 당일 취소 시, 환불 규정과 관계 없이 입대료와 계약 수수료를 합계한 10%만 위약금으로 부과됩니다. 단, 무료 취소 기간에 해당하는 경우 전액 환불됩니다.'),
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


  /// 계약 승인 요청하기 버튼
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // TODO: 계약 승인 요청 API 호출
          _showContractRequestDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          '계약 승인 요청하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              // TODO: 계약 승인 요청 API 호출
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('계약 승인 요청이 완료되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
              // 이전 페이지로 이동
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
