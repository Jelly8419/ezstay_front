import '../config/api_config.dart';
import '../models/contract.dart';
import '../models/contract_detail.dart';

/// 계약 관련 공통 유틸리티
///
/// Guest/Host 계약 상세 페이지에서 공통으로 사용하는 유틸리티 메서드를 중앙화합니다.
class ContractUtils {
  ContractUtils._();

  /// 퇴실 확인 위젯 표시 여부
  ///
  /// 정책: IN_PROGRESS 상태이고 퇴실일 당일 00:00 이후면 노출.
  /// 일찍 퇴실하는 경우를 위해 퇴실 시간(roomCheckoutTime) 조건 없이 당일부터 표시.
  static bool shouldShowCheckoutConfirmation(ContractDetail? contract) {
    if (contract == null) return false;
    if (ContractStatus.fromString(contract.status) != ContractStatus.inProgress) return false;
    final checkOutDate = DateTime.tryParse(contract.checkOutDate);
    if (checkOutDate == null) return false;
    final checkOutDay = DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return !todayDay.isBefore(checkOutDay); // 당일 포함, 이후 모두 노출
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
    final s = ContractStatus.fromString(status);
    return s == ContractStatus.paymentCompleted ||
        s == ContractStatus.inProgress ||
        s == ContractStatus.completed;
  }

  /// 주소 표시 로직 (정책: 결제 완료 후에만 상세주소 공개)
  ///
  /// - PENDING_APPROVAL, APPROVED: 기본주소 + 층만 표시
  /// - PAYMENT_COMPLETED, IN_PROGRESS, COMPLETED: 상세주소 포함
  static String getAddressDisplay(ContractDetail contract) {
    const paidStatuses = [
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
      ContractStatus.completed,
    ];
    if (paidStatuses.contains(ContractStatus.fromString(contract.status))) {
      return '${contract.address} ${contract.detailAddress}';
    }
    return '${contract.address} ${contract.floor}';
  }

  /// 상세주소 비공개 안내 메시지 표시 여부
  static bool shouldShowAddressNotice(String status) {
    final s = ContractStatus.fromString(status);
    return s == ContractStatus.pendingApproval || s == ContractStatus.approved;
  }

  /// 퇴실 시간 도래 여부 (ContractListItem 기준)
  ///
  /// checkOutDate + roomCheckoutTime(기본 11:00)을 합산해 현재 시각과 비교.
  static bool isCheckoutTimeReached(ContractListItem contract) {
    final checkOutDate = contract.checkOutDate;
    final checkoutTimeStr = contract.roomCheckoutTime ?? '11:00';
    final timeParts = checkoutTimeStr.split(':');
    final checkoutHour = int.tryParse(timeParts[0]) ?? 11;
    final checkoutMinute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final checkoutDateTime = DateTime(
      checkOutDate.year, checkOutDate.month, checkOutDate.day,
      checkoutHour, checkoutMinute,
    );
    return DateTime.now().isAfter(checkoutDateTime);
  }

  /// 퇴실 시간 도래 여부 (ContractDetail 기준)
  ///
  /// checkOutDate(String) + roomCheckoutTime(기본 11:00)을 합산해 현재 시각과 비교.
  static bool isCheckoutTimeReachedFromDetail(ContractDetail contract) {
    final checkOutDate = DateTime.tryParse(contract.checkOutDate);
    if (checkOutDate == null) return false;
    final checkoutTimeStr = contract.roomCheckoutTime ?? '11:00';
    final timeParts = checkoutTimeStr.split(':');
    final checkoutHour = int.tryParse(timeParts[0]) ?? 11;
    final checkoutMinute =
        timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final checkoutDateTime = DateTime(
      checkOutDate.year, checkOutDate.month, checkOutDate.day,
      checkoutHour, checkoutMinute,
    );
    return DateTime.now().isAfter(checkoutDateTime);
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
