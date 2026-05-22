// 입주 준비 서비스 — 도메인 enum 모음
//
// 백엔드 응답 문자열 ↔ 한글 라벨 ↔ enum 변환을 한 곳에서 관리.
// 신규 enum 값 추가 시 라벨/색상 매핑(UI 위젯)도 함께 갱신.

/// 침대 사이즈
enum BedSize {
  single('SINGLE', '싱글'),
  superSingle('SUPER_SINGLE', '슈퍼싱글'),
  double('DOUBLE', '더블'),
  queen('QUEEN', '퀸'),
  king('KING', '킹');

  final String code;
  final String label;
  const BedSize(this.code, this.label);

  static BedSize fromCode(String? code) {
    return BedSize.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BedSize.single,
    );
  }
}

/// 청소 서비스 상태
enum CleaningStatus {
  notRequested('NOT_REQUESTED', '신청 안 함'),
  paymentPending('PAYMENT_PENDING', '결제 대기'),
  paid('PAID', '결제 완료'),
  cancelled('CANCELLED', '취소됨');

  final String code;
  final String label;
  const CleaningStatus(this.code, this.label);

  static CleaningStatus fromCode(String? code) {
    return CleaningStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => CleaningStatus.notRequested,
    );
  }
}

/// 임차인 결제 요청 발송 상태
///
/// MVP: 임대인에게 임차인의 결제 완료 여부는 노출하지 않음 (PRD 10.1).
/// 두 값만 사용한다.
enum PaymentRequestStatus {
  notSent('NOT_SENT', '발송 전'),
  sent('SENT', '발송 완료');

  final String code;
  final String label;
  const PaymentRequestStatus(this.code, this.label);

  static PaymentRequestStatus fromCode(String? code) {
    return PaymentRequestStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PaymentRequestStatus.notSent,
    );
  }
}

/// 청소용품 구비 여부 — 드롭다운 표시용
enum CleaningSuppliesAvailability {
  available(true, '구비함'),
  notAvailable(false, '구비 안 함');

  final bool value;
  final String label;
  const CleaningSuppliesAvailability(this.value, this.label);

  static CleaningSuppliesAvailability fromBool(bool? value) {
    return value == true ? available : notAvailable;
  }
}
