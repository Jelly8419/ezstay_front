import '../models/room.dart';
import '../models/booking_state.dart';

/// 가격 계산 결과 (React UI의 가격 분석과 동일)
class PriceBreakdown {
  final int baseRent; // 기본 임대료 (일 임대료 × 일수)
  final int maintenanceFee; // 관리비 (일 관리비 × 일수)
  final int cleaningFee; // 청소비
  final int deposit; // 보증금
  final int rentalItemsFee; // 렌탈 아이템 총 비용
  final int longTermDiscount; // 장기 계약 할인
  final int quickMoveInDiscount; // 빠른 입주 할인
  final int contractFee; // 계약 수수료 (총액의 10%)

  const PriceBreakdown({
    required this.baseRent,
    required this.maintenanceFee,
    required this.cleaningFee,
    required this.deposit,
    required this.rentalItemsFee,
    required this.longTermDiscount,
    required this.quickMoveInDiscount,
    required this.contractFee,
  });

  /// 총 할인 금액
  int get totalDiscount => longTermDiscount + quickMoveInDiscount;

  /// 소계 (임대료 + 관리비 + 청소비 + 렌탈 아이템 - 할인)
  int get subtotal => baseRent + maintenanceFee + cleaningFee + rentalItemsFee - totalDiscount;

  /// 최종 총액 (소계 + 보증금 + 계약 수수료)
  int get total => subtotal + deposit + contractFee;
}

/// 가격 계산기 (React UI의 calculateTotalPrice 로직과 동일)
class PriceCalculator {
  /// 가격 분석 계산
  static PriceBreakdown calculate({
    required Room room,
    required BookingState bookingState,
  }) {
    // 날짜가 선택되지 않은 경우 0 반환
    final days = bookingState.selectedDays;
    if (days == null || days <= 0) {
      return const PriceBreakdown(
        baseRent: 0,
        maintenanceFee: 0,
        cleaningFee: 0,
        deposit: 0,
        rentalItemsFee: 0,
        longTermDiscount: 0,
        quickMoveInDiscount: 0,
        contractFee: 0,
      );
    }

    // 1. 기본 임대료 (일 임대료 × 일수)
    final baseRent = room.dailyRent * days;

    // 2. 관리비 (일 관리비 × 일수)
    final maintenanceFee = room.dailyMaintenanceFee * days;

    // 3. 청소비 (고정)
    final cleaningFee = room.cleaningFee;

    // 4. 보증금 (고정)
    final deposit = room.deposit;

    // 5. 렌탈 아이템 총 비용
    final rentalItemsFee = bookingState.rentalItemsTotalPrice;

    // 6. 장기 계약 할인 계산
    int longTermDiscount = 0;
    if (room.longTermWeeks != null &&
        room.longTermDiscount != null &&
        room.longTermDiscount! > 0) {
      final weeks = days / 7;
      if (weeks >= room.longTermWeeks!) {
        // 할인율을 기본 임대료에 적용
        longTermDiscount = (baseRent * room.longTermDiscount! / 100).round();
      }
    }

    // 7. 빠른 입주 할인 계산
    int quickMoveInDiscount = 0;
    if (room.quickMoveIn != null &&
        room.quickMoveInDiscount != null &&
        room.quickMoveInDiscount! > 0 &&
        bookingState.checkInDate != null) {
      final now = DateTime.now();
      final daysUntilCheckIn = bookingState.checkInDate!.difference(now).inDays;

      // 빠른 입주 기준 일수 이내면 할인 적용
      if (daysUntilCheckIn <= room.quickMoveIn!) {
        quickMoveInDiscount = room.quickMoveInDiscount!;
      }
    }

    // 8. 소계 계산 (임대료 + 관리비 + 청소비 + 렌탈 아이템 - 할인)
    final subtotal = baseRent + maintenanceFee + cleaningFee + rentalItemsFee -
                     longTermDiscount - quickMoveInDiscount;

    // 9. 계약 수수료 (소계의 10%)
    final contractFee = (subtotal * 0.10).round();

    return PriceBreakdown(
      baseRent: baseRent,
      maintenanceFee: maintenanceFee,
      cleaningFee: cleaningFee,
      deposit: deposit,
      rentalItemsFee: rentalItemsFee,
      longTermDiscount: longTermDiscount,
      quickMoveInDiscount: quickMoveInDiscount,
      contractFee: contractFee,
    );
  }

  /// 숫자를 한국 통화 형식으로 포맷 (예: 1000000 -> "1,000,000원")
  static String formatKRW(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted원';
  }

  /// 일 단위를 주/월 단위로 변환하여 표시 (예: 14일 -> "2주", 30일 -> "1개월")
  static String formatDuration(int days) {
    if (days < 7) {
      return '$days일';
    } else if (days % 7 == 0) {
      final weeks = days ~/ 7;
      return '$weeks주';
    } else if (days >= 28 && days % 7 < 3) {
      // 4주 이상이고 나머지가 3일 미만이면 월 단위로 표시
      final months = days ~/ 28;
      final remainingDays = days % 28;
      if (remainingDays == 0) {
        return '$months개월';
      } else {
        return '$months개월 $remainingDays일';
      }
    } else {
      final weeks = days ~/ 7;
      final remainingDays = days % 7;
      if (remainingDays == 0) {
        return '$weeks주';
      } else {
        return '$weeks주 $remainingDays일';
      }
    }
  }

  /// 날짜 차이가 최소 계약 일수를 만족하는지 검증
  static bool isValidContractDuration({
    required Room room,
    required BookingState bookingState,
  }) {
    final days = bookingState.selectedDays;
    if (days == null) return false;
    return days >= room.minContractDays;
  }

  /// 날짜 선택이 가능한지 검증 (최소 계약 일수 체크)
  static String? validateDateSelection({
    required Room room,
    required BookingState bookingState,
  }) {
    if (!bookingState.hasSelectedDates) {
      return '체크인/체크아웃 날짜를 선택해주세요.';
    }

    final days = bookingState.selectedDays!;
    if (days < room.minContractDays) {
      return '최소 ${room.minContractDays}일 이상 선택해주세요. (현재: ${days}일)';
    }

    return null; // 유효함
  }
}
