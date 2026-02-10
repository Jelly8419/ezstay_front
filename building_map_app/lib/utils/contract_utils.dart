import '../config/api_config.dart';
import '../models/contract_detail.dart';

/// 계약 관련 공통 유틸리티
///
/// Guest/Host 계약 상세 페이지에서 공통으로 사용하는 유틸리티 메서드를 중앙화합니다.
class ContractUtils {
  ContractUtils._();

  /// 퇴실 확인 위젯 표시 여부 (IN_PROGRESS + 퇴실일 도래)
  static bool shouldShowCheckoutConfirmation(ContractDetail? contract) {
    if (contract == null) return false;
    if (contract.status != 'IN_PROGRESS') return false;
    final checkOutDate = DateTime.tryParse(contract.checkOutDate);
    if (checkOutDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(checkOutDate) ||
        (now.year == checkOutDate.year &&
            now.month == checkOutDate.month &&
            now.day == checkOutDate.day);
  }

  /// 이미지 URL에 baseUrl 추가 (상대경로 → 절대경로)
  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${ApiConfig.baseUrl}$imageUrl';
  }

  /// 전화번호 표시 여부 (결제 완료 이후에만 노출)
  static bool shouldShowPhoneNumber(String status) {
    return status == 'PAYMENT_COMPLETED' ||
        status == 'IN_PROGRESS' ||
        status == 'COMPLETED';
  }

  /// 주소 표시 로직 (정책: 결제 완료 후에만 상세주소 공개)
  ///
  /// - PENDING_APPROVAL, APPROVED: 기본주소 + 층만 표시
  /// - PAYMENT_COMPLETED, IN_PROGRESS, COMPLETED: 상세주소 포함
  static String getAddressDisplay(ContractDetail contract) {
    const paidStatuses = ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED'];
    if (paidStatuses.contains(contract.status)) {
      return '${contract.address} ${contract.detailAddress}';
    }
    return '${contract.address} ${contract.floor}';
  }

  /// 상세주소 비공개 안내 메시지 표시 여부
  static bool shouldShowAddressNotice(String status) {
    return status == 'PENDING_APPROVAL' || status == 'APPROVED';
  }

  /// 날짜 포맷 (문자열 → yyyy-MM-dd 또는 원본 반환)
  static String formatDateString(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
