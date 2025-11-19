import 'package:freezed_annotation/freezed_annotation.dart';

part 'basic_options.freezed.dart';
part 'basic_options.g.dart';

/// 기본 옵션 (7개 필드)
/// 숙박에 필수적인 기본 생활 시설 및 가전제품
@freezed
class BasicOptions with _$BasicOptions {
  const factory BasicOptions({
    @Default(false) bool refrigerator,      // 냉장고
    @Default(false) bool washingMachine,    // 세탁기
    @Default(false) bool airConditioner,    // 에어컨
    @Default(false) bool sink,              // 싱크대
    @Default(false) bool bed,               // 침대
    @Default(false) bool tv,                // TV
    @Default(false) bool internet,          // 인터넷 (Wi-Fi)
  }) = _BasicOptions;

  factory BasicOptions.fromJson(Map<String, dynamic> json) =>
      _$BasicOptionsFromJson(json);
}
