Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// 게스트 응답에 포함되는 룸 요약 정보
///
/// - 비로그인/phone 불일치: address 4토큰 마스킹 + detailAddress null
/// - 로그인 + phone 일치: 풀 정보
class GuestMoveInRoom {
  final String? displayName;
  final String? address;
  final String? detailAddress;

  const GuestMoveInRoom({
    this.displayName,
    this.address,
    this.detailAddress,
  });

  factory GuestMoveInRoom.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return GuestMoveInRoom(
      displayName: json['displayName']?.toString(),
      address: json['address']?.toString(),
      detailAddress: json['detailAddress']?.toString(),
    );
  }

  /// 마스킹된 주소인지 ('…'으로 끝나면 마스킹된 상태)
  bool get isMasked => (address ?? '').endsWith('…');

  /// 표시용 풀 주소 (상세주소 결합)
  String get fullAddress {
    final base = address ?? '';
    final detail = detailAddress;
    if (detail == null || detail.isEmpty) return base;
    return '$base $detail';
  }
}
