import '../core/exceptions.dart';
import '../services/contract_service.dart';

/// 게스트 퇴실 처리 서비스
class GuestCheckoutService {
  final ContractService _contractService;

  GuestCheckoutService({ContractService? contractService})
      : _contractService = contractService ?? ContractService();

  /// 퇴실 완료 API 호출
  /// 성공 시 [onSuccess], 실패 시 [onError], 인증 만료 시 [onUnauthorized] 콜백
  Future<void> requestCheckout({
    required int contractId,
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
    required void Function() onUnauthorized,
  }) async {
    try {
      await _contractService.requestCheckout(contractId);
      onSuccess();
    } on UnauthorizedException {
      onUnauthorized();
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
