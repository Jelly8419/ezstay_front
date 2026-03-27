import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../constants/fee_constants.dart';
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
  final int contractFee; // 계약 수수료 (9.9%)

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

    // 3. 청소비
    // - ez_services에서 cleaningService 신청했으면: 기본 5만원 + 10평 초과시 10평당 2만원 추가
    // - 그렇지 않으면 호스트가 설정한 청소비

    final cleaningFee = (room.ezService?.cleaningService == true)
        ? calculateEzCleaningFee(room.area)
        : room.cleaningFee;


    // 4. 보증금 (고정)
    final deposit = room.deposit;

    // 5. 렌탈 아이템 총 비용 (EZStay 제공)
    int rentalItemsFee = 0;
    if (room.availableRentalItems != null &&
        bookingState.selectedRentalItems.isNotEmpty) {
      final allItems = room.availableRentalItems!.allItems;
      for (final entry in bookingState.selectedRentalItems.entries) {
        final itemId = entry.key;
        final quantity = entry.value;
        final item = allItems.firstWhere(
          (item) => item.id == itemId,
          orElse: () => throw Exception('렌탈 아이템을 찾을 수 없습니다 (ID: $itemId)'),
        );
        rentalItemsFee += item.price * quantity;
      }
    }

    // 6. 빠른 입주 할인 계산 (먼저 적용)
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

    // 7. 장기 계약 할인 계산 (빠른 입주 할인 적용 후 계산)
    int longTermDiscount = 0;
    if (room.longTermWeeks != null &&
        room.longTermDiscount != null &&
        room.longTermDiscount! > 0) {
      final weeks = days / 7;
      if (weeks >= room.longTermWeeks!) {
        // 빠른 입주 할인 적용 후 임대료에 장기계약 할인율 적용
        final adjustedRent = baseRent - quickMoveInDiscount;
        longTermDiscount = (adjustedRent * room.longTermDiscount! / 100).floor();
      }
    }

    // 8. 계약 수수료 (9.9%)
    // 수수료 기준: (임대료 + 관리비 + 청소비 - 할인금액) × 9.9%
    // 할인 적용 후 금액에 수수료 부과
    final isEzCleaningService = room.ezService?.cleaningService == true;
    final totalDiscount = longTermDiscount + quickMoveInDiscount;
    final feeBase = isEzCleaningService
        ? baseRent + maintenanceFee - totalDiscount  // EZ청소 사용시 청소비 제외
        : baseRent + maintenanceFee + cleaningFee - totalDiscount;
    final contractFee = FeeConstants.calculateGuestFee(feeBase);

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

  /// 날짜 차이가 계약 일수 범위(최소~최대)를 만족하는지 검증
  static bool isValidContractDuration({
    required Room room,
    required BookingState bookingState,
  }) {
    final days = bookingState.selectedDays;
    if (days == null) return false;
    return days >= room.minContractDays && days <= room.maxContractDays;
  }

  /// 날짜 선택이 가능한지 검증 (최소/최대 계약 일수 체크)
  static String? validateDateSelection({
    required Room room,
    required BookingState bookingState,
  }) {
    // 초기 상태(날짜 미선택)에서는 validation 에러 표시 안 함
    if (!bookingState.hasSelectedDates) {
      return null;
    }

    final days = bookingState.selectedDays!;
    if (days < room.minContractDays) {
      return '최소 ${room.minContractDays}일 이상 선택해주세요. (현재: ${days}일)';
    }

    if (days > room.maxContractDays) {
      return '최대 ${room.maxContractDays}일까지 선택할 수 있습니다. (현재: ${days}일)';
    }

    return null; // 유효함
  }

  /// 옵션 상품(렌탈 아이템) 선택 가능 여부 판단
  ///
  /// 정책: 입주일 6일 전 날짜의 23:59:59까지 옵션 선택 가능
  /// - 예: 입주일 2/16 → 마감일 = 2/10 → 2/10 23:59:59까지 선택 가능
  /// - 2/11 00:00:00부터 선택 불가
  ///
  /// 시분초를 제거한 날짜(calendar day) 단위로 비교하여,
  /// 하루 중 어느 시간이든 동일한 결과를 보장합니다.
  ///
  /// [checkInDate] - 체크인(입주) 날짜
  /// [currentTime] - 현재 시간 (테스트용으로 주입 가능, 기본값 DateTime.now())
  ///
  /// 반환값: true면 옵션 상품 선택 가능, false면 불가능
  static bool canSelectRentalItems({
    required DateTime? checkInDate,
    DateTime? currentTime,
  }) {
    // 체크인 날짜가 없으면 선택 불가
    if (checkInDate == null) return false;

    final now = currentTime ?? DateTime.now();
    // 시분초를 제거하여 날짜(calendar day) 단위로 비교
    final today = DateTime(now.year, now.month, now.day);
    final checkInDay = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final calendarDaysDiff = checkInDay.difference(today).inDays;

    // 입주일까지 6일 이상 남았으면 선택 가능
    // 예: 입주일 2/16, 오늘 2/10 → diff=6 → 가능 (2/10 23:59:59까지)
    // 예: 입주일 2/16, 오늘 2/11 → diff=5 → 불가
    return calendarDaysDiff >= 6;
  }

  /// 옵션 상품 비활성화 사유 메시지
  ///
  /// [checkInDate] - 체크인(입주) 날짜
  /// [currentTime] - 현재 시간 (테스트용으로 주입 가능)
  ///
  /// 반환값: 비활성화 시 사유 메시지, 선택 가능하면 null
  static String? getRentalItemsDisabledReason({
    required DateTime? checkInDate,
    DateTime? currentTime,
  }) {
    if (checkInDate == null) {
      return '입주일을 먼저 선택해주세요.';
    }

    final now = currentTime ?? DateTime.now();
    // 시분초를 제거하여 날짜(calendar day) 단위로 비교
    final today = DateTime(now.year, now.month, now.day);
    final checkInDay = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final calendarDaysDiff = checkInDay.difference(today).inDays;

    if (calendarDaysDiff < 6) {
      // 마감일 계산하여 안내 (입주일 - 6일)
      final deadline = checkInDay.subtract(const Duration(days: 6));
      final deadlineStr = '${deadline.month}/${deadline.day}';
      return '옵션 상품 선택 기한이 지났습니다. ($deadlineStr 23:59까지 선택 가능)';
    }

    return null; // 선택 가능
  }

  /// EZ서비스 청소비 계산
  /// - 기본금: 5만원
  /// - 10평 초과시: 10평당 2만원 추가 (올림)
  /// - 예: 12평(7만원), 20평(7만원), 21평(9만원), 40평(11만원)
  ///
  /// [areaString] - 전용면적 (평수 문자열, 예: "12", "40")
  static int calculateEzCleaningFee(String areaString) {
    const baseFee = 50000; // 기본 5만원
    const additionalFeePerUnit = 20000; // 10평당 2만원
    const pyeongPerUnit = 10; // 10평 단위

    // 평수 파싱
    final pyeong = double.tryParse(areaString) ?? 0;


    // 10평 이하: 기본 5만원
    if (pyeong <= 10) {
      return baseFee;
    }

    // 10평 초과: 기본 5만원 + 10평당 2만원 추가
    final excessPyeong = pyeong - 10;
    final additionalUnits = (excessPyeong / pyeongPerUnit).ceil();
    final totalFee = baseFee + (additionalUnits * additionalFeePerUnit);

    return totalFee;
  }
}
