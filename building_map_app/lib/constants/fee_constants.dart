import 'package:flutter_dotenv/flutter_dotenv.dart';

/// EZStay 수수료 및 보증금 상수
///
/// 정책 기준:
/// - 호스트 수수료: 3.3% (부가세 포함, 3% + 0.3%)
/// - 게스트 수수료: 9.9% (부가세 포함, 9% + 0.9%)
/// - 보증금: .env DEPOSIT_AMOUNT (기본 300,000원)
/// - 금액 계산: 원 단위 절삭 (소수점 이하 버림)
class FeeConstants {
  FeeConstants._();

  /// 게스트 수수료율 (9.9%)
  static const double guestFeeRate = 0.099;

  /// 호스트 수수료율 (3.3%)
  static const double hostFeeRate = 0.033;

  /// 보증금 기본값 (원) - .env 미설정 시 폴백
  static const int _defaultDepositAmount = 300000;

  /// 보증금 금액 (원)
  ///
  /// 우선순위: --dart-define > .env > 기본값 (300,000원)
  static int get depositAmount {
    // 1순위: --dart-define으로 주입된 값
    const dartDefineValue = String.fromEnvironment('DEPOSIT_AMOUNT');
    if (dartDefineValue.isNotEmpty) {
      return int.tryParse(dartDefineValue) ?? _defaultDepositAmount;
    }

    // 2순위: .env 파일의 값
    final dotenvValue = dotenv.env['DEPOSIT_AMOUNT'];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return int.tryParse(dotenvValue) ?? _defaultDepositAmount;
    }

    // 3순위: 기본값
    return _defaultDepositAmount;
  }

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
