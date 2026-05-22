import 'move_in_enums.dart';

/// 침대 1개 정보 (방 등록 시 동적 입력)
class BedInfo {
  final int index;
  final BedSize size;

  const BedInfo({required this.index, required this.size});

  factory BedInfo.fromJson(dynamic raw) {
    final json = (raw is Map) ? raw.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
    return BedInfo(
      index: (json['index'] ?? 0).toInt(),
      size: BedSize.fromCode(json['size']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'size': size.code,
      };

  BedInfo copyWith({int? index, BedSize? size}) =>
      BedInfo(index: index ?? this.index, size: size ?? this.size);
}
