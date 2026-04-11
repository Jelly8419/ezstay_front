// ignore_for_file: avoid_dynamic_calls

/// JSON에서 안전하게 Map을 추출 (릴리즈 빌드 타입 캐스트 오류 방지)
Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// JSON에서 안전하게 List를 추출
List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return <dynamic>[];
}

/// 보증금 차감 지급 정보 (목록용)
/// null이면 해당 계약에 보증금 차감 없음
class DepositDeduction {
  final int amount;
  final String status;       // 'PENDING' | 'PAYABLE' | 'COMPLETED'
  final String statusLabel;  // "지급 대기" | "지급 가능" | "지급 완료"
  final String payableAfter; // YYYY-MM-DD

  const DepositDeduction({
    required this.amount,
    required this.status,
    required this.statusLabel,
    required this.payableAfter,
  });

  factory DepositDeduction.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return DepositDeduction(
      amount: (json['amount'] ?? 0).toInt(),
      status: (json['status'] ?? 'PENDING').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      payableAfter: (json['payableAfter'] ?? '').toString(),
    );
  }
}

/// 보증금 차감 지급 정보 (정산 상세 인라인용 — processedAt 포함)
class SettlementDepositDeductionDetail extends DepositDeduction {
  final String? processedAt;

  const SettlementDepositDeductionDetail({
    required super.amount,
    required super.status,
    required super.statusLabel,
    required super.payableAfter,
    this.processedAt,
  });

  factory SettlementDepositDeductionDetail.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementDepositDeductionDetail(
      amount: (json['amount'] ?? 0).toInt(),
      status: (json['status'] ?? 'PENDING').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      payableAfter: (json['payableAfter'] ?? '').toString(),
      processedAt: json['processedAt']?.toString(),
    );
  }
}

/// 정산 목록 아이템 (API 응답)
class Settlement {
  final int contractId;
  final String contractNumber;
  final int roomId;
  final String roomTitle;
  final String? roomThumbnail;
  final String guestName;
  final String checkInDate; // ISO 8601
  final String checkOutDate; // ISO 8601
  final int rentalDays;
  final int settlementAmount;
  final String settlementDate; // YYYY-MM-DD
  final String status; // 'PENDING' | 'READY' | 'PROCESSING' | 'COMPLETED' | 'ON_HOLD' | 'FAILED'
  final String statusLabel;
  final bool hasRefund;
  final int refundAmount;
  final bool hasEzCleaningService;
  final DepositDeduction? depositDeduction;

  const Settlement({
    required this.contractId,
    required this.contractNumber,
    required this.roomId,
    required this.roomTitle,
    this.roomThumbnail,
    required this.guestName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.rentalDays,
    required this.settlementAmount,
    required this.settlementDate,
    required this.status,
    required this.statusLabel,
    required this.hasRefund,
    required this.refundAmount,
    required this.hasEzCleaningService,
    this.depositDeduction,
  });

  factory Settlement.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return Settlement(
      contractId: (json['contractId'] ?? 0).toInt(),
      contractNumber: (json['contractNumber'] ?? '').toString(),
      roomId: (json['roomId'] ?? 0).toInt(),
      roomTitle: (json['roomTitle'] ?? '').toString(),
      roomThumbnail: json['roomThumbnail']?.toString(),
      guestName: (json['guestName'] ?? '').toString(),
      checkInDate: (json['checkInDate'] ?? '').toString(),
      checkOutDate: (json['checkOutDate'] ?? '').toString(),
      rentalDays: (json['rentalDays'] ?? 0).toInt(),
      settlementAmount: (json['settlementAmount'] ?? 0).toInt(),
      settlementDate: (json['settlementDate'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      hasRefund: json['hasRefund'] == true,
      refundAmount: (json['refundAmount'] ?? 0).toInt(),
      hasEzCleaningService: json['hasEzCleaningService'] == true,
      depositDeduction: json['depositDeduction'] != null
          ? DepositDeduction.fromJson(json['depositDeduction'])
          : null,
    );
  }
}

/// 정산 목록 요약
class SettlementSummary {
  final int totalCount;
  final int totalSettlementAmount;
  final int pendingCount;
  final int completedCount;

  const SettlementSummary({
    required this.totalCount,
    required this.totalSettlementAmount,
    required this.pendingCount,
    required this.completedCount,
  });

  factory SettlementSummary.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementSummary(
      totalCount: (json['totalCount'] ?? 0).toInt(),
      totalSettlementAmount: (json['totalSettlementAmount'] ?? 0).toInt(),
      pendingCount: (json['pendingCount'] ?? 0).toInt(),
      completedCount: (json['completedCount'] ?? 0).toInt(),
    );
  }
}

/// 정산 목록 페이지네이션
class SettlementPagination {
  final int page;
  final int limit;
  final int totalPages;
  final int totalCount;

  const SettlementPagination({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.totalCount,
  });

  factory SettlementPagination.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementPagination(
      page: (json['page'] ?? 1).toInt(),
      limit: (json['limit'] ?? 20).toInt(),
      totalPages: (json['totalPages'] ?? 1).toInt(),
      totalCount: (json['totalCount'] ?? 0).toInt(),
    );
  }
}

/// 방 필터용 모델
class SettlementRoom {
  final int roomId;
  final String roomTitle;

  const SettlementRoom({
    required this.roomId,
    required this.roomTitle,
  });

  factory SettlementRoom.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementRoom(
      roomId: (json['roomId'] ?? 0).toInt(),
      roomTitle: (json['roomTitle'] ?? '').toString(),
    );
  }
}

/// 정산 목록 API 응답
class SettlementListResponse {
  final List<Settlement> settlements;
  final SettlementSummary summary;
  final SettlementPagination pagination;
  final List<SettlementRoom> rooms;

  const SettlementListResponse({
    required this.settlements,
    required this.summary,
    required this.pagination,
    required this.rooms,
  });

  factory SettlementListResponse.fromJson(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data'] ?? root);
    final filters = _asMap(data['filters']);
    return SettlementListResponse(
      settlements: _asList(data['settlements'])
          .map((e) => Settlement.fromJson(e))
          .toList(),
      summary: SettlementSummary.fromJson(data['summary']),
      pagination: SettlementPagination.fromJson(data['pagination']),
      rooms: _asList(filters['rooms'])
          .map((e) => SettlementRoom.fromJson(e))
          .toList(),
    );
  }
}

/// 정산 상세 - 계약 정보
class SettlementContract {
  final int contractId;
  final String contractNumber;
  final String status;
  final String checkInDate;
  final String checkOutDate;
  final int rentalDays;
  final String? paidAt;

  const SettlementContract({
    required this.contractId,
    required this.contractNumber,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.rentalDays,
    this.paidAt,
  });

  factory SettlementContract.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementContract(
      contractId: (json['contractId'] ?? 0).toInt(),
      contractNumber: (json['contractNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      checkInDate: (json['checkInDate'] ?? '').toString(),
      checkOutDate: (json['checkOutDate'] ?? '').toString(),
      rentalDays: (json['rentalDays'] ?? 0).toInt(),
      paidAt: json['paidAt']?.toString(),
    );
  }
}

/// 정산 상세 - 방 정보
class SettlementRoomInfo {
  final int roomId;
  final String title;
  final String address;
  final String? thumbnail;

  const SettlementRoomInfo({
    required this.roomId,
    required this.title,
    required this.address,
    this.thumbnail,
  });

  factory SettlementRoomInfo.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementRoomInfo(
      roomId: (json['roomId'] ?? 0).toInt(),
      title: (json['title'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }
}

/// 정산 상세 - 게스트 정보
class SettlementGuest {
  final String name;
  final String phone;

  const SettlementGuest({
    required this.name,
    required this.phone,
  });

  factory SettlementGuest.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementGuest(
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

/// 정산 상세 - 금액 상세
class SettlementBreakdown {
  final int rentalFee;
  final int maintenanceFee;
  final int cleaningFee;
  final int originalCleaningFee;
  final bool hasEzCleaningService;
  final int subtotal;
  final int platformFee;
  final double platformFeeRate;
  final int grossSettlement;

  const SettlementBreakdown({
    required this.rentalFee,
    required this.maintenanceFee,
    required this.cleaningFee,
    required this.originalCleaningFee,
    required this.hasEzCleaningService,
    required this.subtotal,
    required this.platformFee,
    required this.platformFeeRate,
    required this.grossSettlement,
  });

  factory SettlementBreakdown.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementBreakdown(
      rentalFee: (json['rentalFee'] ?? 0).toInt(),
      maintenanceFee: (json['maintenanceFee'] ?? 0).toInt(),
      cleaningFee: (json['cleaningFee'] ?? 0).toInt(),
      originalCleaningFee: (json['originalCleaningFee'] ?? 0).toInt(),
      hasEzCleaningService: json['hasEzCleaningService'] == true,
      subtotal: (json['subtotal'] ?? 0).toInt(),
      platformFee: (json['platformFee'] ?? 0).toInt(),
      platformFeeRate: (json['platformFeeRate'] ?? 3.3).toDouble(),
      grossSettlement: (json['grossSettlement'] ?? 0).toInt(),
    );
  }
}

/// 정산 상세 - 환불 상세
class RefundDetails {
  final int rentalFeeRefund;
  final int maintenanceFeeRefund;
  final int cleaningFeeRefund;
  final int totalRefund;

  const RefundDetails({
    required this.rentalFeeRefund,
    required this.maintenanceFeeRefund,
    required this.cleaningFeeRefund,
    required this.totalRefund,
  });

  factory RefundDetails.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return RefundDetails(
      rentalFeeRefund: (json['rentalFeeRefund'] ?? 0).toInt(),
      maintenanceFeeRefund: (json['maintenanceFeeRefund'] ?? 0).toInt(),
      cleaningFeeRefund: (json['cleaningFeeRefund'] ?? 0).toInt(),
      totalRefund: (json['totalRefund'] ?? 0).toInt(),
    );
  }
}

/// 정산 상세 - 환불 정보
class SettlementRefund {
  final bool hasRefund;
  final String? refundDate;
  final String? refundReason;
  final String? refundType;
  final RefundDetails? refundDetails;

  const SettlementRefund({
    required this.hasRefund,
    this.refundDate,
    this.refundReason,
    this.refundType,
    this.refundDetails,
  });

  factory SettlementRefund.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementRefund(
      hasRefund: json['hasRefund'] == true,
      refundDate: json['refundDate']?.toString(),
      refundReason: json['refundReason']?.toString(),
      refundType: json['refundType']?.toString(),
      refundDetails: json['refundDetails'] != null
          ? RefundDetails.fromJson(json['refundDetails'])
          : null,
    );
  }
}

/// 정산 상세 - 계좌 정보
class BankInfo {
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  const BankInfo({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  factory BankInfo.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return BankInfo(
      bankName: (json['bankName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      accountHolder: (json['accountHolder'] ?? '').toString(),
    );
  }
}

/// 정산 상세 - 정산 정보
class SettlementInfo {
  final int finalAmount;
  final String settlementDate;
  final String status;
  final String statusLabel;
  final BankInfo? bankInfo;

  const SettlementInfo({
    required this.finalAmount,
    required this.settlementDate,
    required this.status,
    required this.statusLabel,
    this.bankInfo,
  });

  factory SettlementInfo.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return SettlementInfo(
      finalAmount: (json['finalAmount'] ?? 0).toInt(),
      settlementDate: (json['settlementDate'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      bankInfo: json['bankInfo'] != null
          ? BankInfo.fromJson(json['bankInfo'])
          : null,
    );
  }
}

/// 정산 상세 API 응답
class SettlementDetail {
  final SettlementContract contract;
  final SettlementRoomInfo room;
  final SettlementGuest guest;
  final SettlementBreakdown breakdown;
  final SettlementRefund refund;
  final SettlementInfo settlement;
  final SettlementDepositDeductionDetail? depositDeduction;

  const SettlementDetail({
    required this.contract,
    required this.room,
    required this.guest,
    required this.breakdown,
    required this.refund,
    required this.settlement,
    this.depositDeduction,
  });

  factory SettlementDetail.fromJson(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data'] ?? root);
    return SettlementDetail(
      contract: SettlementContract.fromJson(data['contract']),
      room: SettlementRoomInfo.fromJson(data['room']),
      guest: SettlementGuest.fromJson(data['guest']),
      breakdown: SettlementBreakdown.fromJson(data['breakdown']),
      refund: SettlementRefund.fromJson(data['refund']),
      settlement: SettlementInfo.fromJson(data['settlement']),
      depositDeduction: data['depositDeduction'] != null
          ? SettlementDepositDeductionDetail.fromJson(data['depositDeduction'])
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 보증금 차감 상세 페이지 전용 모델
// GET /api/host/settlements/:contractId/deposit-deduction
// ─────────────────────────────────────────────────────────────

/// 합의 이력 아이템
class DeductionAgreementHistory {
  final int id;
  final String status;
  final String statusLabel;
  final String holdReason;
  final int? deductAmount;
  final String? agreementText;
  final String? requestedAt;
  final String? adminApprovedAt;
  final String? submittedAt;
  final String? acceptedAt;
  final String? rejectedAt;
  final String? rejectedReason;

  const DeductionAgreementHistory({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.holdReason,
    this.deductAmount,
    this.agreementText,
    this.requestedAt,
    this.adminApprovedAt,
    this.submittedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectedReason,
  });

  factory DeductionAgreementHistory.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return DeductionAgreementHistory(
      id: (json['id'] ?? 0).toInt(),
      status: (json['status'] ?? '').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      holdReason: (json['holdReason'] ?? '').toString(),
      deductAmount: json['deductAmount'] != null
          ? (json['deductAmount']).toInt()
          : null,
      agreementText: json['agreementText']?.toString(),
      requestedAt: json['requestedAt']?.toString(),
      adminApprovedAt: json['adminApprovedAt']?.toString(),
      submittedAt: json['submittedAt']?.toString(),
      acceptedAt: json['acceptedAt']?.toString(),
      rejectedAt: json['rejectedAt']?.toString(),
      rejectedReason: json['rejectedReason']?.toString(),
    );
  }
}

/// 차감 지급(payout) 정보
class DeductionPayout {
  final int id;
  final int amount;
  final String status;       // 'PENDING' | 'PAYABLE' | 'COMPLETED'
  final String statusLabel;
  final String payableAfter; // YYYY-MM-DD
  final String? processedAt;

  const DeductionPayout({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusLabel,
    required this.payableAfter,
    this.processedAt,
  });

  factory DeductionPayout.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return DeductionPayout(
      id: (json['id'] ?? 0).toInt(),
      amount: (json['amount'] ?? 0).toInt(),
      status: (json['status'] ?? 'PENDING').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      payableAfter: (json['payableAfter'] ?? '').toString(),
      processedAt: json['processedAt']?.toString(),
    );
  }
}

/// GET /api/host/settlements/:contractId/deposit-deduction 응답
class DepositDeductionDetailResponse {
  final int contractId;
  final String contractNumber;
  final int deposit;
  final int depositDeduction;
  final String deductionReason;
  final int refundableDeposit;
  final String depositStatus;
  final String depositStatusLabel;
  final DeductionPayout payout;
  final List<DeductionAgreementHistory> history;

  const DepositDeductionDetailResponse({
    required this.contractId,
    required this.contractNumber,
    required this.deposit,
    required this.depositDeduction,
    required this.deductionReason,
    required this.refundableDeposit,
    required this.depositStatus,
    required this.depositStatusLabel,
    required this.payout,
    required this.history,
  });

  factory DepositDeductionDetailResponse.fromJson(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data'] ?? root);
    return DepositDeductionDetailResponse(
      contractId: (data['contractId'] ?? 0).toInt(),
      contractNumber: (data['contractNumber'] ?? '').toString(),
      deposit: (data['deposit'] ?? 0).toInt(),
      depositDeduction: (data['depositDeduction'] ?? 0).toInt(),
      deductionReason: (data['deductionReason'] ?? '').toString(),
      refundableDeposit: (data['refundableDeposit'] ?? 0).toInt(),
      depositStatus: (data['depositStatus'] ?? '').toString(),
      depositStatusLabel: (data['depositStatusLabel'] ?? '').toString(),
      payout: DeductionPayout.fromJson(data['payout']),
      history: _asList(data['history'])
          .map((e) => DeductionAgreementHistory.fromJson(e))
          .toList(),
    );
  }
}
