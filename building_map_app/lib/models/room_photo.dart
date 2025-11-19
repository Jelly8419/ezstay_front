/// 방 사진 정보 모델
class RoomPhoto {
  final int? id; // 백엔드가 id를 제공하지 않으므로 optional
  final String url;
  final int order;

  const RoomPhoto({
    this.id,
    required this.url,
    required this.order,
  });

  factory RoomPhoto.fromJson(Map<String, dynamic> json) {
    return RoomPhoto(
      id: json['id'] as int?,
      url: json['url'] as String? ?? '',  // ✅ null 안전 처리
      order: json['order'] as int? ?? 0,  // ✅ null 안전 처리 + 기본값
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'order': order,
    };
  }

  RoomPhoto copyWith({
    int? id,
    String? url,
    int? order,
  }) {
    return RoomPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      order: order ?? this.order,
    );
  }
}
