import '../constants/fee_constants.dart';
import '../models/contract.dart';

/// 정산/수수료 계산 유틸리티
class FeeCalculator {
  FeeCalculator._();

  /// 호스트 정산 예정금액 계산
  ///
  /// EZ청소 사용 시 청소비는 수수료 기준에서 제외.
  /// [contract.hostEarnings]가 이미 있으면 그 값을 우선 사용.
  static int calculateHostSettlement(ContractListItem contract) {
    final rentalFee = contract.rentalFee ?? 0;
    final maintenanceFee = contract.maintenanceFee ?? 0;
    final cleaningFee = contract.cleaningFee ?? 0;
    final isEzCleaning = contract.isEzCleaning == true;

    final usageFee = isEzCleaning
        ? rentalFee + maintenanceFee
        : rentalFee + maintenanceFee + cleaningFee;

    return usageFee - FeeConstants.calculateHostFee(usageFee);
  }
}
