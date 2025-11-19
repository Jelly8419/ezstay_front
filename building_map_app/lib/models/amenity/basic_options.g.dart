// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BasicOptionsImpl _$$BasicOptionsImplFromJson(Map<String, dynamic> json) =>
    _$BasicOptionsImpl(
      refrigerator: json['refrigerator'] as bool? ?? false,
      washingMachine: json['washingMachine'] as bool? ?? false,
      airConditioner: json['airConditioner'] as bool? ?? false,
      sink: json['sink'] as bool? ?? false,
      bed: json['bed'] as bool? ?? false,
      tv: json['tv'] as bool? ?? false,
      internet: json['internet'] as bool? ?? false,
    );

Map<String, dynamic> _$$BasicOptionsImplToJson(_$BasicOptionsImpl instance) =>
    <String, dynamic>{
      'refrigerator': instance.refrigerator,
      'washingMachine': instance.washingMachine,
      'airConditioner': instance.airConditioner,
      'sink': instance.sink,
      'bed': instance.bed,
      'tv': instance.tv,
      'internet': instance.internet,
    };
