/// EZStay 수수료 및 보증금 상수
///
/// 정책 기준:
/// - 호스트 수수료: 3.3% (부가세 포함, 3% + 0.3%)
/// - 게스트 수수료: 9.9% (부가세 포함, 9% + 0.9%)
/// - 보증금: 300,000원 고정
/// - 금액 계산: 원 단위 절삭 (소수점 이하 버림)
class FeeConstants {
  FeeConstants._();

  /// 게스트 수수료율 (9.9%)
  static const double guestFeeRate = 0.099;

  /// 호스트 수수료율 (3.3%)
  static const double hostFeeRate = 0.033;

  /// 보증금 고정 금액 (원)
  static const int depositAmount = 300000;

  /// 게스트 수수료 계산 (원 단위 절삭)
  ///
  /// [baseAmount] = 임대료 + 관리비 + 청소비 - 할인금액
  /// EZ청소 사용 시 청소비는 수수료 기준에서 제외
  static int calculateGuestFee(int baseAmount) {
    return (baseAmount * guestFeeRate).floor();
  }

  /// 호스트 수수료 계산 (원 단위 절삭)
  ///
  /// [baseAmount] = 임대료 + 관리비 + 청소비
  /// EZ청소 사용 시 청소비는 수수료 기준에서 제외
  static int calculateHostFee(int baseAmount) {
    return (baseAmount * hostFeeRate).floor();
  }
}
