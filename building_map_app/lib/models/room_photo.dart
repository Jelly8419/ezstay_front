/// 방 사진 정보 모델
class RoomPhoto {
  final int id;
  final String url;
  final int order;

  const RoomPhoto({
    required this.id,
    required this.url,
    required this.order,
  });

  factory RoomPhoto.fromJson(Map<String, dynamic> json) {
    return RoomPhoto(
      id: json['id'] as int,
      url: json['url'] as String,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
