/// 방 상태 상수 정의
enum RoomStatus {
  draft('draft', '등록중'),
  pendingReview('pending_review', '심사중'),
  approved('approved', '승인됨'),
  rejected('rejected', '등록 반려'),
  published('published', '게시중'),
  hiddenByAdmin('hidden_by_admin', '관리자 숨김');

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
