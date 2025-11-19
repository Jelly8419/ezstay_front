// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_amenity_freezed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomAmenityFreezedImpl _$$RoomAmenityFreezedImplFromJson(
  Map<String, dynamic> json,
) => _$RoomAmenityFreezedImpl(
  roomId: (json['roomId'] as num).toInt(),
  basicOptions: BasicOptions.fromJson(
    json['basicOptions'] as Map<String, dynamic>,
  ),
  additionalOptions: AdditionalOptions.fromJson(
    json['additionalOptions'] as Map<String, dynamic>,
  ),
  convenienceOptions: ConvenienceOptions.fromJson(
    json['convenienceOptions'] as Map<String, dynamic>,
  ),
  petsAllowed: json['petsAllowed'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$RoomAmenityFreezedImplToJson(
  _$RoomAmenityFreezedImpl instance,
) => <String, dynamic>{
  'roomId': instance.roomId,
  'basicOptions': instance.basicOptions,
  'additionalOptions': instance.additionalOptions,
  'convenienceOptions': instance.convenienceOptions,
  'petsAllowed': instance.petsAllowed,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
