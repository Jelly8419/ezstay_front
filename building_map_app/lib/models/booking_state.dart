/// 예약/가격 계산 상태 (날짜 및 렌탈 아이템 관리)
class BookingState {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final Map<int, int> selectedRentalItems; // 아이템 ID → 수량

  const BookingState({
    this.checkInDate,
    this.checkOutDate,
    this.selectedRentalItems = const {},
  });

  /// 선택된 날짜 일수 (checkOut - checkIn)
  int? get selectedDays {
    if (checkInDate == null || checkOutDate == null) return null;
    return checkOutDate!.difference(checkInDate!).inDays;
  }

  /// 날짜가 선택되었는지 여부
  bool get hasSelectedDates => checkInDate != null && checkOutDate != null;

  BookingState copyWith({
    DateTime? checkInDate,
    DateTime? checkOutDate,
    Map<int, int>? selectedRentalItems,
  }) {
    return BookingState(
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      selectedRentalItems: selectedRentalItems ?? this.selectedRentalItems,
    );
  }

  /// 날짜 초기화
  BookingState clearDates() {
    return BookingState(
      checkInDate: null,
      checkOutDate: null,
      selectedRentalItems: selectedRentalItems,
    );
  }

  /// 렌탈 아이템 추가/수량 변경
  BookingState addRentalItem(int itemId, int quantity) {
    final updatedItems = Map<int, int>.from(selectedRentalItems);
    if (quantity > 0) {
      updatedItems[itemId] = quantity;
    } else {
      updatedItems.remove(itemId);
    }
    return copyWith(selectedRentalItems: updatedItems);
  }

  /// 렌탈 아이템 제거
  BookingState removeRentalItem(int itemId) {
    final updatedItems = Map<int, int>.from(selectedRentalItems);
    updatedItems.remove(itemId);
    return copyWith(selectedRentalItems: updatedItems);
  }

  /// 렌탈 아이템 수량 조회
  int getRentalItemQuantity(int itemId) {
    return selectedRentalItems[itemId] ?? 0;
  }

  /// 렌탈 아이템 초기화
  BookingState clearRentalItems() {
    return copyWith(selectedRentalItems: {});
  }

  /// 렌탈 아이템이 선택되었는지 여부
  bool get hasRentalItems => selectedRentalItems.isNotEmpty;
}
