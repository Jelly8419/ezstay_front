import 'package:freezed_annotation/freezed_annotation.dart';

part 'convenience_options.freezed.dart';
part 'convenience_options.g.dart';

/// 편의 옵션 (13개 필드)
/// 고급 편의시설 및 생활 편의 용품
@freezed
class ConvenienceOptions with _$ConvenienceOptions {
  const factory ConvenienceOptions({
    @Default(false) bool heatingCooling,    // 냉난방기
    @Default(false) bool heater,            // 히터
    @Default(false) bool airPurifier,       // 공기청정기
    @Default(false) bool dryer,             // 건조기
    @Default(false) bool iron,              // 다리미
    @Default(false) bool waterPurifier,     // 정수기
    @Default(false) bool riceCooker,        // 전기밥솥
    @Default(false) bool electricKettle,    // 전기포트
    @Default(false) bool dishes,            // 식기(그릇,수저)
    @Default(false) bool cookware,          // 조리도구(팬, 냄비)
    @Default(false) bool bathtub,           // 욕조
    @Default(false) bool hairDryer,         // 드라이어
    @Default(false) bool bidet,             // 비데
  }) = _ConvenienceOptions;

  factory ConvenienceOptions.fromJson(Map<String, dynamic> json) =>
      _$ConvenienceOptionsFromJson(json);
}
