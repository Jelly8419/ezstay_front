import 'package:freezed_annotation/freezed_annotation.dart';

part 'additional_options.freezed.dart';
part 'additional_options.g.dart';

/// 추가 옵션 (16개 필드)
/// 안전, 보안, 추가 가전제품 및 가구
@freezed
class AdditionalOptions with _$AdditionalOptions {
  const factory AdditionalOptions({
    @Default(false) bool doorLock,          // 도어락
    @Default(false) bool cctv,              // CCTV
    @Default(false) bool managementOffice,  // 관리실
    @Default(false) bool gasRange,          // 가스레인지
    @Default(false) bool induction,         // 인덕션
    @Default(false) bool microwave,         // 전자레인지
    @Default(false) bool diningTable,       // 식탁
    @Default(false) bool shoeRack,          // 신발장
    @Default(false) bool wardrobe,          // 옷장
    @Default(false) bool dressRoom,         // 드레스룸
    @Default(false) bool vanity,            // 화장대
    @Default(false) bool cableTv,           // 케이블 TV
    @Default(false) bool sofa,              // 소파
    @Default(false) bool desk,              // 책상
    @Default(false) bool curtain,           // 커튼
    @Default(false) bool balcony,           // 발코니/베란다
  }) = _AdditionalOptions;

  factory AdditionalOptions.fromJson(Map<String, dynamic> json) =>
      _$AdditionalOptionsFromJson(json);
}
