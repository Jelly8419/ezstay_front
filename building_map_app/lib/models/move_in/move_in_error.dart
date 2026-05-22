// 입주 준비 서비스 도메인 에러 코드.
//
// 백엔드 responseHelper.js의 표준 코드 중 이 도메인에서 의미를 갖는 것만 모음.
// HTTP 상태 코드와 별개로 응답 body의 `code` 필드로 식별.

/// 입주 준비 서비스에서 발생할 수 있는 도메인 에러 코드
enum MoveInErrorCode {
  unauthorized(1001, '로그인이 필요합니다.'),
  forbidden(2001, '권한이 없습니다.'),
  caseNotFound(3001, '케이스를 찾을 수 없습니다.'),
  roomNotFound(3002, '방을 찾을 수 없습니다.'),
  validationError(4001, '입력값을 확인해주세요.'),
  roomHasContracts(4230, '연결된 케이스가 있어 삭제할 수 없습니다.'),
  conflictWithContract(4300, '해당 기간에 이미 등록된 입주 준비가 있습니다.'),
  paymentNotAvailable(4602, '지금은 결제할 수 없는 상태입니다.'),
  paymentConfirmationFailed(4605, '결제 승인에 실패했습니다. 다시 시도해주세요.'),
  moveInRoomNotApproved(4795, '심사 승인된 방만 사용할 수 있습니다.'),
  // 청소 결제 환불 (2026-05-16)
  cleaningRefundNotAllowed(
      4813, '청소 희망 시간 1시간 전부터는 환불할 수 없습니다.'),
  pgCancelFailed(4900, 'PG 결제 취소에 실패했습니다. 잠시 후 다시 시도해주세요.'),
  pgAlreadyCancelled(4901, '이미 취소 완료된 결제입니다.'),
  pgManualCancelRequired(4903,
      '자동 취소가 불가능한 결제입니다. 고객센터로 문의해 수동 취소를 요청해주세요.'),
  unknown(0, '알 수 없는 오류가 발생했습니다.');

  final int code;
  final String defaultMessage;
  const MoveInErrorCode(this.code, this.defaultMessage);

  static MoveInErrorCode fromCode(int? code) {
    if (code == null) return MoveInErrorCode.unknown;
    return MoveInErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => MoveInErrorCode.unknown,
    );
  }
}

/// 입주 준비 서비스 도메인 예외
///
/// 서비스 레이어에서 응답의 `code`를 보고 throw, UI 레이어에서 catch해
/// `errorCode`별로 분기 처리(409 CONFLICT 모달 등) 가능하도록 분리.
class MoveInException implements Exception {
  final MoveInErrorCode errorCode;
  final String message;
  final int? httpStatus;
  final dynamic details;

  const MoveInException({
    required this.errorCode,
    required this.message,
    this.httpStatus,
    this.details,
  });

  /// API 응답 body에서 예외 생성
  factory MoveInException.fromResponse({
    required int httpStatus,
    required Map<String, dynamic> body,
  }) {
    final code = (body['code'] as num?)?.toInt();
    final errorCode = MoveInErrorCode.fromCode(code);
    final message = (body['message'] as String?) ?? errorCode.defaultMessage;
    return MoveInException(
      errorCode: errorCode,
      message: message,
      httpStatus: httpStatus,
      details: body['details'],
    );
  }

  /// 네트워크/파싱 등 응답 외 에러
  factory MoveInException.network(Object error) {
    return MoveInException(
      errorCode: MoveInErrorCode.unknown,
      message: '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      details: error.toString(),
    );
  }

  bool get isConflict => errorCode == MoveInErrorCode.conflictWithContract;
  bool get isUnauthorized => errorCode == MoveInErrorCode.unauthorized;
  bool get isValidation => errorCode == MoveInErrorCode.validationError;
  bool get isCleaningRefundNotAllowed =>
      errorCode == MoveInErrorCode.cleaningRefundNotAllowed;
  bool get isPgCancelFailed => errorCode == MoveInErrorCode.pgCancelFailed;
  bool get isPgAlreadyCancelled =>
      errorCode == MoveInErrorCode.pgAlreadyCancelled;
  bool get isPgManualCancelRequired =>
      errorCode == MoveInErrorCode.pgManualCancelRequired;

  @override
  String toString() => 'MoveInException($errorCode, http=$httpStatus): $message';
}
