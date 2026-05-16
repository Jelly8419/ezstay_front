// 입주 준비 서비스 (임차인) 도메인 에러 코드.
//
// 백엔드 API 명세 §7 (478x 대역) 기준.

/// 게스트 입주 준비 서비스에서 발생할 수 있는 도메인 에러 코드
enum GuestMoveInErrorCode {
  // 공통
  unauthorized(1001, '로그인이 필요합니다.'),
  forbidden(2001, '권한이 없습니다.'),
  validationError(4001, '입력값을 확인해주세요.'),

  // 결제 공통
  paymentConfirmationFailed(4605, '결제 승인에 실패했습니다. 다시 시도해주세요.'),

  // 게스트 입주준비 도메인 (478x)
  tokenInvalid(4780, '잘못된 링크입니다.'),
  tokenExpired(4781, '해당 입주 준비 서비스 링크가 만료되었거나 사용할 수 없습니다.'),
  phoneMismatch(4782,
      '임대인이 등록한 임차인 연락처와 현재 계정의 본인확인 연락처가 일치하지 않습니다.'),
  caseNotFound(4783, '해당 입주 준비 요청을 찾을 수 없습니다.'),
  paymentDeadlinePassed(4784, '입주일 5일 전까지만 결제할 수 있습니다.'),
  optionRequired(4785, '결제할 입주 준비 옵션을 선택해주세요.'),
  optionUnavailable(4786, '선택한 옵션을 현재 사용할 수 없습니다.'),
  optionNotFound(4787, '선택한 옵션을 찾을 수 없습니다.'),
  stockInsufficient(4788, '선택한 옵션의 재고가 부족합니다.'),
  amountMismatch(4789, '결제 금액이 변경되었습니다. 다시 시도해주세요.'),
  orderNotFound(4790, '주문을 찾을 수 없습니다.'),
  orderNotPayable(4791, '결제 가능한 상태가 아닙니다.'),
  orderNotCancellable(4792,
      '결제 완료된 주문은 취소할 수 없습니다. 고객센터로 문의해주세요.'),
  pendingOrderExists(4793,
      '결제 대기 중인 주문이 있습니다. 기존 주문을 결제하거나 취소해주세요.'),
  paymentNotFound(4794, '결제를 찾을 수 없습니다.'),

  // 환불/취소/반품 (2026-05-16)
  refundNotAllowed(4799, '현재 시점 또는 배송 상태에서는 취소/반품할 수 없습니다.'),
  returnAlreadyRequested(4810, '이미 처리 중인 반품 요청이 있습니다.'),
  cleaningRefundNotAllowed(
      4813, '청소 희망 시간 1시간 전부터는 환불할 수 없습니다.'),
  pgCancelFailed(4900, 'PG 결제 취소에 실패했습니다. 잠시 후 다시 시도해주세요.'),
  pgAlreadyCancelled(4901, '이미 취소 완료된 결제입니다.'),

  unknown(0, '알 수 없는 오류가 발생했습니다.');

  final int code;
  final String defaultMessage;
  const GuestMoveInErrorCode(this.code, this.defaultMessage);

  static GuestMoveInErrorCode fromCode(int? code) {
    if (code == null) return GuestMoveInErrorCode.unknown;
    return GuestMoveInErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => GuestMoveInErrorCode.unknown,
    );
  }
}

/// 게스트 입주 준비 서비스 도메인 예외
class GuestMoveInException implements Exception {
  final GuestMoveInErrorCode errorCode;
  final String message;
  final int? httpStatus;
  final dynamic details;

  const GuestMoveInException({
    required this.errorCode,
    required this.message,
    this.httpStatus,
    this.details,
  });

  /// API 응답 body에서 예외 생성
  factory GuestMoveInException.fromResponse({
    required int httpStatus,
    required Map<String, dynamic> body,
  }) {
    final code = (body['code'] as num?)?.toInt();
    final errorCode = GuestMoveInErrorCode.fromCode(code);
    final message = (body['message'] as String?) ?? errorCode.defaultMessage;
    return GuestMoveInException(
      errorCode: errorCode,
      message: message,
      httpStatus: httpStatus,
      details: body['details'],
    );
  }

  /// 네트워크/파싱 등 응답 외 에러
  factory GuestMoveInException.network(Object error) {
    return GuestMoveInException(
      errorCode: GuestMoveInErrorCode.unknown,
      message: '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      details: error.toString(),
    );
  }

  bool get isTokenInvalid => errorCode == GuestMoveInErrorCode.tokenInvalid;
  bool get isTokenExpired => errorCode == GuestMoveInErrorCode.tokenExpired;
  bool get isPhoneMismatch => errorCode == GuestMoveInErrorCode.phoneMismatch;
  bool get isDeadlinePassed =>
      errorCode == GuestMoveInErrorCode.paymentDeadlinePassed;
  bool get isPendingOrderExists =>
      errorCode == GuestMoveInErrorCode.pendingOrderExists;
  bool get isStockInsufficient =>
      errorCode == GuestMoveInErrorCode.stockInsufficient;
  bool get isAmountMismatch => errorCode == GuestMoveInErrorCode.amountMismatch;
  bool get isRefundNotAllowed =>
      errorCode == GuestMoveInErrorCode.refundNotAllowed;
  bool get isReturnAlreadyRequested =>
      errorCode == GuestMoveInErrorCode.returnAlreadyRequested;
  bool get isPgCancelFailed =>
      errorCode == GuestMoveInErrorCode.pgCancelFailed;
  bool get isPgAlreadyCancelled =>
      errorCode == GuestMoveInErrorCode.pgAlreadyCancelled;

  @override
  String toString() =>
      'GuestMoveInException($errorCode, http=$httpStatus): $message';
}
