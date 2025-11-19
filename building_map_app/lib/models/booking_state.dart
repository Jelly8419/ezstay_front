import 'selected_rental_item.dart';

/// 예약/가격 계산 상태 (React UI의 상태와 동일)
class BookingState {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final List<SelectedRentalItem> selectedRentalItems;

  const BookingState({
    this.checkInDate,
    this.checkOutDate,
    this.selectedRentalItems = const [],
  });

  /// 선택된 날짜 일수 (checkOut - checkIn)
  int? get selectedDays {
    if (checkInDate == null || checkOutDate == null) return null;
    return checkOutDate!.difference(checkInDate!).inDays;
  }

  /// 날짜가 선택되었는지 여부
  bool get hasSelectedDates => checkInDate != null && checkOutDate != null;

  /// 렌탈 아이템 총 가격
  int get rentalItemsTotalPrice {
    return selectedRentalItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// 특정 렌탈 아이템의 수량 가져오기
  int getQuantity(int itemId) {
    final item = selectedRentalItems.where((i) => i.id == itemId).firstOrNull;
    return item?.quantity ?? 0;
  }

  /// 렌탈 아이템이 선택되어 있는지 확인
  bool hasRentalItem(int itemId) {
    return selectedRentalItems.any((i) => i.id == itemId && i.quantity > 0);
  }

  BookingState copyWith({
    DateTime? checkInDate,
    DateTime? checkOutDate,
    List<SelectedRentalItem>? selectedRentalItems,
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

  /// 렌탈 아이템 추가/업데이트
  BookingState updateRentalItem(SelectedRentalItem item) {
    final List<SelectedRentalItem> updated = [...selectedRentalItems];
    final index = updated.indexWhere((i) => i.id == item.id);

    if (index >= 0) {
      // 수량이 0이면 제거, 아니면 업데이트
      if (item.quantity <= 0) {
        updated.removeAt(index);
      } else {
        updated[index] = item;
      }
    } else if (item.quantity > 0) {
      // 새 아이템 추가
      updated.add(item);
    }

    return BookingState(
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      selectedRentalItems: updated,
    );
  }

  /// 렌탈 아이템 제거
  BookingState removeRentalItem(int itemId) {
    return BookingState(
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      selectedRentalItems: selectedRentalItems.where((i) => i.id != itemId).toList(),
    );
  }

  /// 모든 렌탈 아이템 제거
  BookingState clearRentalItems() {
    return BookingState(
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      selectedRentalItems: [],
    );
  }
}
