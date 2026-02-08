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
  final String status; // 'pending' | 'completed'
  final String statusLabel;
  final bool hasRefund;
  final int refundAmount;
  final bool hasEzCleaningService;

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
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      contractId: json['contractId'] ?? 0,
      contractNumber: json['contractNumber'] ?? '',
      roomId: json['roomId'] ?? 0,
      roomTitle: json['roomTitle'] ?? '',
      roomThumbnail: json['roomThumbnail'],
      guestName: json['guestName'] ?? '',
      checkInDate: json['checkInDate'] ?? '',
      checkOutDate: json['checkOutDate'] ?? '',
      rentalDays: json['rentalDays'] ?? 0,
      settlementAmount: json['settlementAmount'] ?? 0,
      settlementDate: json['settlementDate'] ?? '',
      status: json['status'] ?? 'pending',
      statusLabel: json['statusLabel'] ?? '',
      hasRefund: json['hasRefund'] ?? false,
      refundAmount: json['refundAmount'] ?? 0,
      hasEzCleaningService: json['hasEzCleaningService'] ?? false,
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

  factory SettlementSummary.fromJson(Map<String, dynamic> json) {
    return SettlementSummary(
      totalCount: json['totalCount'] ?? 0,
      totalSettlementAmount: json['totalSettlementAmount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
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

  factory SettlementPagination.fromJson(Map<String, dynamic> json) {
    return SettlementPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
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

  factory SettlementRoom.fromJson(Map<String, dynamic> json) {
    return SettlementRoom(
      roomId: json['roomId'] ?? 0,
      roomTitle: json['roomTitle'] ?? '',
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

  factory SettlementListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return SettlementListResponse(
      settlements: (data['settlements'] as List<dynamic>?)
              ?.map((e) => Settlement.fromJson(e))
              .toList() ??
          [],
      summary: SettlementSummary.fromJson(data['summary'] ?? {}),
      pagination: SettlementPagination.fromJson(data['pagination'] ?? {}),
      rooms: (data['filters']?['rooms'] as List<dynamic>?)
              ?.map((e) => SettlementRoom.fromJson(e))
              .toList() ??
          [],
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

  factory SettlementContract.fromJson(Map<String, dynamic> json) {
    return SettlementContract(
      contractId: json['contractId'] ?? 0,
      contractNumber: json['contractNumber'] ?? '',
      status: json['status'] ?? '',
      checkInDate: json['checkInDate'] ?? '',
      checkOutDate: json['checkOutDate'] ?? '',
      rentalDays: json['rentalDays'] ?? 0,
      paidAt: json['paidAt'],
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

  factory SettlementRoomInfo.fromJson(Map<String, dynamic> json) {
    return SettlementRoomInfo(
      roomId: json['roomId'] ?? 0,
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      thumbnail: json['thumbnail'],
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

  factory SettlementGuest.fromJson(Map<String, dynamic> json) {
    return SettlementGuest(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
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

  factory SettlementBreakdown.fromJson(Map<String, dynamic> json) {
    return SettlementBreakdown(
      rentalFee: json['rentalFee'] ?? 0,
      maintenanceFee: json['maintenanceFee'] ?? 0,
      cleaningFee: json['cleaningFee'] ?? 0,
      originalCleaningFee: json['originalCleaningFee'] ?? 0,
      hasEzCleaningService: json['hasEzCleaningService'] ?? false,
      subtotal: json['subtotal'] ?? 0,
      platformFee: json['platformFee'] ?? 0,
      platformFeeRate: (json['platformFeeRate'] ?? 3.3).toDouble(),
      grossSettlement: json['grossSettlement'] ?? 0,
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

  factory RefundDetails.fromJson(Map<String, dynamic> json) {
    return RefundDetails(
      rentalFeeRefund: json['rentalFeeRefund'] ?? 0,
      maintenanceFeeRefund: json['maintenanceFeeRefund'] ?? 0,
      cleaningFeeRefund: json['cleaningFeeRefund'] ?? 0,
      totalRefund: json['totalRefund'] ?? 0,
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

  factory SettlementRefund.fromJson(Map<String, dynamic> json) {
    return SettlementRefund(
      hasRefund: json['hasRefund'] ?? false,
      refundDate: json['refundDate'],
      refundReason: json['refundReason'],
      refundType: json['refundType'],
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

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountHolder: json['accountHolder'] ?? '',
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

  factory SettlementInfo.fromJson(Map<String, dynamic> json) {
    return SettlementInfo(
      finalAmount: json['finalAmount'] ?? 0,
      settlementDate: json['settlementDate'] ?? '',
      status: json['status'] ?? 'pending',
      statusLabel: json['statusLabel'] ?? '',
      bankInfo:
          json['bankInfo'] != null ? BankInfo.fromJson(json['bankInfo']) : null,
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

  const SettlementDetail({
    required this.contract,
    required this.room,
    required this.guest,
    required this.breakdown,
    required this.refund,
    required this.settlement,
  });

  factory SettlementDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return SettlementDetail(
      contract: SettlementContract.fromJson(data['contract'] ?? {}),
      room: SettlementRoomInfo.fromJson(data['room'] ?? {}),
      guest: SettlementGuest.fromJson(data['guest'] ?? {}),
      breakdown: SettlementBreakdown.fromJson(data['breakdown'] ?? {}),
      refund: SettlementRefund.fromJson(data['refund'] ?? {}),
      settlement: SettlementInfo.fromJson(data['settlement'] ?? {}),
    );
  }
}
