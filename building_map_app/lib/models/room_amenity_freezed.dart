import 'package:freezed_annotation/freezed_annotation.dart';
import 'amenity/basic_options.dart';
import 'amenity/additional_options.dart';
import 'amenity/convenience_options.dart';

part 'room_amenity_freezed.freezed.dart';
part 'room_amenity_freezed.g.dart';

/// 방 편의시설 정보 모델 (Freezed 버전)
@freezed
class RoomAmenityFreezed with _$RoomAmenityFreezed {
  const RoomAmenityFreezed._();

  const factory RoomAmenityFreezed({
    required int roomId,
    required BasicOptions basicOptions,
    required AdditionalOptions additionalOptions,
    required ConvenienceOptions convenienceOptions,
    @Default(false) bool petsAllowed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoomAmenityFreezed;

  factory RoomAmenityFreezed.fromJson(Map<String, dynamic> json) =>
      _$RoomAmenityFreezedFromJson(json);

  /// 모든 편의시설을 평탄화된 리스트로 반환 (기존 호환성 유지)
  List<String> toFlatList() {
    final List<String> amenities = [];

    // 기본 옵션
    if (basicOptions.refrigerator) amenities.add('냉장고');
    if (basicOptions.washingMachine) amenities.add('세탁기');
    if (basicOptions.airConditioner) amenities.add('에어컨');
    if (basicOptions.sink) amenities.add('싱크대');
    if (basicOptions.bed) amenities.add('침대');
    if (basicOptions.tv) amenities.add('TV');
    if (basicOptions.internet) amenities.add('인터넷 (Wi-Fi)');

    // 추가 옵션
    if (additionalOptions.doorLock) amenities.add('도어락');
    if (additionalOptions.cctv) amenities.add('CCTV');
    if (additionalOptions.managementOffice) amenities.add('관리실');
    if (additionalOptions.gasRange) amenities.add('가스레인지');
    if (additionalOptions.induction) amenities.add('인덕션');
    if (additionalOptions.microwave) amenities.add('전자레인지');
    if (additionalOptions.diningTable) amenities.add('식탁');
    if (additionalOptions.shoeRack) amenities.add('신발장');
    if (additionalOptions.wardrobe) amenities.add('옷장');
    if (additionalOptions.dressRoom) amenities.add('드레스룸');
    if (additionalOptions.vanity) amenities.add('화장대');
    if (additionalOptions.cableTv) amenities.add('케이블 TV');
    if (additionalOptions.sofa) amenities.add('소파');
    if (additionalOptions.desk) amenities.add('책상');
    if (additionalOptions.curtain) amenities.add('커튼');
    if (additionalOptions.balcony) amenities.add('발코니/베란다');

    // 편의 옵션
    if (convenienceOptions.heatingCooling) amenities.add('냉난방기');
    if (convenienceOptions.heater) amenities.add('히터');
    if (convenienceOptions.airPurifier) amenities.add('공기청정기');
    if (convenienceOptions.dryer) amenities.add('건조기');
    if (convenienceOptions.iron) amenities.add('다리미');
    if (convenienceOptions.waterPurifier) amenities.add('정수기');
    if (convenienceOptions.riceCooker) amenities.add('전기밥솥');
    if (convenienceOptions.electricKettle) amenities.add('전기포트');
    if (convenienceOptions.dishes) amenities.add('식기(그릇,수저)');
    if (convenienceOptions.cookware) amenities.add('조리도구(팬, 냄비)');
    if (convenienceOptions.bathtub) amenities.add('욕조');
    if (convenienceOptions.hairDryer) amenities.add('드라이어');
    if (convenienceOptions.bidet) amenities.add('비데');

    // 반려동물
    if (petsAllowed) amenities.add('반려동물 동반 가능');

    return amenities;
  }
}
