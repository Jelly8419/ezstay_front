import 'bed_info.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return <dynamic>[];
}

/// 방 심사 상태 (관리자 승인 워크플로)
enum MoveInRoomReviewStatus {
  pending,
  approved,
  rejected;

  static MoveInRoomReviewStatus fromString(String? raw) {
    switch (raw) {
      case 'APPROVED':
        return MoveInRoomReviewStatus.approved;
      case 'REJECTED':
        return MoveInRoomReviewStatus.rejected;
      case 'PENDING':
      default:
        return MoveInRoomReviewStatus.pending;
    }
  }
}

/// 입주 준비 서비스용 간편 방 정보
///
/// 정식 방 등록(`/api/host/rooms`)과 별개 도메인.
/// PRD 15절 — 같은 화면/플로우로 합치지 말 것.
class MoveInRoom {
  final int id;
  final String? roomName;
  final String address;
  final String detailAddress;
  final num areaPyeong;
  final int livingRoomCount;
  final int roomCount;
  final int bathroomCount;
  final int bedCount;
  final List<BedInfo> beds;
  final String? commonEntrancePassword;
  final String? doorLockPassword;
  final bool cleaningSuppliesAvailable;
  final String? cleaningSuppliesLocation;
  final String? memo;
  final String createdAt;
  final String updatedAt;

  // 심사 (admin review workflow)
  final MoveInRoomReviewStatus reviewStatus;
  final String? submittedAt;
  final String? approvedAt;
  final String? rejectedAt;
  final String? rejectionReason;

  // UI 가드 플래그 (백엔드 계산값)
  final bool isSelectable;
  final bool isEditable;

  const MoveInRoom({
    required this.id,
    this.roomName,
    required this.address,
    required this.detailAddress,
    required this.areaPyeong,
    required this.livingRoomCount,
    required this.roomCount,
    required this.bathroomCount,
    required this.bedCount,
    required this.beds,
    this.commonEntrancePassword,
    this.doorLockPassword,
    required this.cleaningSuppliesAvailable,
    this.cleaningSuppliesLocation,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
    this.reviewStatus = MoveInRoomReviewStatus.pending,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.isSelectable = false,
    this.isEditable = false,
  });

  factory MoveInRoom.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final reviewStatus = MoveInRoomReviewStatus.fromString(json['reviewStatus']?.toString());
    // isSelectable/isEditable: 백엔드가 내려주지 않는 구버전 응답을 위해
    // reviewStatus 기준 fallback 계산 (APPROVED 만 true)
    final approved = reviewStatus == MoveInRoomReviewStatus.approved;
    return MoveInRoom(
      id: (json['id'] ?? 0).toInt(),
      roomName: json['roomName']?.toString(),
      address: (json['address'] ?? '').toString(),
      detailAddress: (json['detailAddress'] ?? '').toString(),
      areaPyeong: (json['areaPyeong'] ?? 0) as num,
      livingRoomCount: (json['livingRoomCount'] ?? 0).toInt(),
      roomCount: (json['roomCount'] ?? 0).toInt(),
      bathroomCount: (json['bathroomCount'] ?? 0).toInt(),
      bedCount: (json['bedCount'] ?? 0).toInt(),
      beds: _asList(json['beds']).map(BedInfo.fromJson).toList(),
      commonEntrancePassword: json['commonEntrancePassword']?.toString(),
      doorLockPassword: json['doorLockPassword']?.toString(),
      cleaningSuppliesAvailable: json['cleaningSuppliesAvailable'] == true,
      cleaningSuppliesLocation: json['cleaningSuppliesLocation']?.toString(),
      memo: json['memo']?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      reviewStatus: reviewStatus,
      submittedAt: json['submittedAt']?.toString(),
      approvedAt: json['approvedAt']?.toString(),
      rejectedAt: json['rejectedAt']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      isSelectable: json['isSelectable'] is bool ? json['isSelectable'] as bool : approved,
      isEditable: json['isEditable'] is bool ? json['isEditable'] as bool : approved,
    );
  }

  /// 표시용 풀 주소 ("서울 강남구 가로수길 9, 101동 1001호")
  String get fullAddress => detailAddress.isEmpty ? address : '$address, $detailAddress';

  /// 카드/목록 표시용 이름 — roomName이 없으면 주소를 fallback
  String get displayName => (roomName?.isNotEmpty ?? false) ? roomName! : address;
}
