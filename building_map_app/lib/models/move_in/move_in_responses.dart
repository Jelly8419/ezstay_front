import 'move_in_case.dart';
import 'move_in_enums.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return <dynamic>[];
}

/// POST /cases 응답 — 케이스 + 자동 발송 결과 동봉
class MoveInCaseCreateResponse {
  final MoveInCase moveInCase;
  final AutoSendResult? autoSend;

  const MoveInCaseCreateResponse({required this.moveInCase, this.autoSend});

  factory MoveInCaseCreateResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final autoSendRaw = json['autoSend'];
    return MoveInCaseCreateResponse(
      moveInCase: MoveInCase.fromJson(json),
      autoSend: autoSendRaw == null ? null : AutoSendResult.fromJson(autoSendRaw),
    );
  }
}

/// 자동 발송 결과 (응답의 autoSend 필드)
class AutoSendResult {
  final bool sent;
  final bool mock;
  final String? error;

  const AutoSendResult({required this.sent, this.mock = false, this.error});

  factory AutoSendResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return AutoSendResult(
      sent: json['sent'] == true,
      mock: json['mock'] == true,
      error: json['error']?.toString(),
    );
  }
}

/// 케이스 목록 응답 (GET /cases)
class MoveInCaseListResponse {
  final List<MoveInCase> cases;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  /// PRD 5.1 / 이미지 ① 상단 요약 카드 4개용 카운트
  /// — 백엔드가 응답에 포함시키지 않으면 null. 그때는 클라이언트 집계로 대체.
  final MoveInCaseCounts? counts;

  const MoveInCaseListResponse({
    required this.cases,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.counts,
  });

  factory MoveInCaseListResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final pagination = _asMap(json['pagination']);
    final countsRaw = json['counts'];
    return MoveInCaseListResponse(
      cases: _asList(json['cases'] ?? json['items']).map(MoveInCase.fromJson).toList(),
      page: (pagination['page'] ?? json['page'] ?? 1).toInt(),
      limit: (pagination['limit'] ?? json['limit'] ?? 20).toInt(),
      total: (pagination['total'] ?? json['total'] ?? 0).toInt(),
      totalPages: (pagination['totalPages'] ?? json['totalPages'] ?? 0).toInt(),
      counts: countsRaw == null ? null : MoveInCaseCounts.fromJson(countsRaw),
    );
  }
}

/// 입주 준비 서비스 홈 상단 요약 카드 카운트
class MoveInCaseCounts {
  final int total;
  final int cleaningPending;
  final int paymentRequestPending;
  final int inProgress;

  const MoveInCaseCounts({
    required this.total,
    required this.cleaningPending,
    required this.paymentRequestPending,
    required this.inProgress,
  });

  factory MoveInCaseCounts.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return MoveInCaseCounts(
      total: (json['total'] ?? 0).toInt(),
      cleaningPending: (json['cleaningPending'] ?? 0).toInt(),
      paymentRequestPending: (json['paymentRequestPending'] ?? 0).toInt(),
      inProgress: (json['inProgress'] ?? 0).toInt(),
    );
  }

  /// 백엔드가 카운트를 안 주면 클라이언트에서 집계 (목록 응답 cases로부터)
  factory MoveInCaseCounts.fromCases(List<MoveInCase> cases) {
    return MoveInCaseCounts(
      total: cases.length,
      cleaningPending: cases.where((c) => c.cleaningStatus == CleaningStatus.paymentPending).length,
      paymentRequestPending: cases.where((c) => !c.isPaymentRequestSent).length,
      inProgress: cases.where((c) => c.cleaningStatus == CleaningStatus.paid || c.isPaymentRequestSent).length,
    );
  }
}

/// 청소 견적 응답 (POST /cleaning/quote)
class CleaningQuoteResponse {
  final num areaPyeong;
  final int cleaningFee;
  final String formula;

  const CleaningQuoteResponse({
    required this.areaPyeong,
    required this.cleaningFee,
    required this.formula,
  });

  factory CleaningQuoteResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return CleaningQuoteResponse(
      areaPyeong: (json['areaPyeong'] ?? 0) as num,
      cleaningFee: (json['cleaningFee'] ?? 0).toInt(),
      formula: (json['formula'] ?? '').toString(),
    );
  }
}

/// 청소 PG 결제 시작 응답 (POST /cleaning/payment/init)
class CleaningPaymentInitResponse {
  final int paymentId;
  final String orderId;
  final int amount;
  final int caseId;
  final Map<String, dynamic> pgPayload;

  const CleaningPaymentInitResponse({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.caseId,
    required this.pgPayload,
  });

  factory CleaningPaymentInitResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return CleaningPaymentInitResponse(
      paymentId: (json['paymentId'] ?? 0).toInt(),
      orderId: (json['orderId'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toInt(),
      caseId: (json['caseId'] ?? 0).toInt(),
      pgPayload: _asMap(json['pgPayload']),
    );
  }

  bool get isMock => pgPayload['mock'] == true;
}

/// 청소 PG 결제 승인 응답 (POST /cleaning/payment/confirm)
class CleaningPaymentConfirmResponse {
  final int paymentId;
  final String orderId;
  final int caseId;
  final CleaningStatus cleaningStatus;
  final String paidAt;
  final String? pgTid;
  final bool mock;

  const CleaningPaymentConfirmResponse({
    required this.paymentId,
    required this.orderId,
    required this.caseId,
    required this.cleaningStatus,
    required this.paidAt,
    this.pgTid,
    required this.mock,
  });

  factory CleaningPaymentConfirmResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return CleaningPaymentConfirmResponse(
      paymentId: (json['paymentId'] ?? 0).toInt(),
      orderId: (json['orderId'] ?? '').toString(),
      caseId: (json['caseId'] ?? 0).toInt(),
      cleaningStatus: CleaningStatus.fromCode(json['cleaningStatus']?.toString()),
      paidAt: (json['paidAt'] ?? '').toString(),
      pgTid: json['pgTid']?.toString(),
      mock: json['mock'] == true,
    );
  }
}

/// 임차인 결제 요청 발송 응답 (send / resend / link)
class PaymentRequestSendResponse {
  final int caseId;
  final PaymentRequestStatus status;
  final String? sentAt;
  final String paymentLink;
  final String? note; // _note — 알림톡 미연동 안내 (운영 후 사라짐)

  const PaymentRequestSendResponse({
    required this.caseId,
    required this.status,
    this.sentAt,
    required this.paymentLink,
    this.note,
  });

  factory PaymentRequestSendResponse.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return PaymentRequestSendResponse(
      caseId: (json['caseId'] ?? 0).toInt(),
      status: PaymentRequestStatus.fromCode(json['status']?.toString()),
      sentAt: json['sentAt']?.toString(),
      paymentLink: (json['paymentLink'] ?? '').toString(),
      note: json['_note']?.toString(),
    );
  }
}
