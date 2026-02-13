/// 방 상태 상수 정의
enum RoomStatus {
  draft('draft', '등록중'),
  pendingReview('pending_review', '심사중'),
  approved('approved', '게시중'),
  rejected('rejected', '등록 반려');

  final String value;
  final String label;

  const RoomStatus(this.value, this.label);

  /// API 응답 값으로부터 RoomStatus 생성
  static RoomStatus fromValue(String value) {
    return RoomStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RoomStatus.draft,
    );
  }
}

/// 게시 상태 (승인된 방의 isActive 여부)
enum PublishStatus {
  active('active', '게시중'),
  inactive('inactive', '게시중단');

  final String value;
  final String label;

  const PublishStatus(this.value, this.label);
}
