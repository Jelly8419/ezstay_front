import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 방 편의시설 정보 모델
class RoomAmenity {
  final int roomId;
  final Map<String, bool> basicOptions; // wifi, tv, airConditioner, heater
  final Map<String, bool> additionalOptions; // washer, dryer, iron
  final Map<String, bool> convenienceOptions; // microwave, refrigerator, dishwasher
  final bool petsAllowed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomAmenity({
    required this.roomId,
    required this.basicOptions,
    required this.additionalOptions,
    required this.convenienceOptions,
    required this.petsAllowed,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomAmenity.fromJson(Map<String, dynamic> json) {
    // 🔍 디버그: 원본 JSON 데이터 확인

    // additionalOptions에서 petsAllowed 추출 (백엔드가 잘못된 위치에 넣음)
    bool petsAllowed = false;
    if (json['additionalOptions'] != null) {
      final additionalOpts = json['additionalOptions'];
      if (additionalOpts is Map && additionalOpts.containsKey('petsAllowed')) {
        final value = additionalOpts['petsAllowed'];
        petsAllowed = value is int ? value == 1 : (value as bool? ?? false);
      }
    }
    // JSON 최상위 레벨에서도 확인
    if (json['petsAllowed'] != null) {
      final value = json['petsAllowed'];
      petsAllowed = value is int ? value == 1 : (value as bool? ?? false);
    }

    return RoomAmenity(
      roomId: json['roomId'] as int,
      basicOptions: _parseOptions(json['basicOptions']),
      additionalOptions: _parseOptions(json['additionalOptions']),
      convenienceOptions: _parseOptions(json['convenienceOptions']),
      petsAllowed: petsAllowed,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  /// JSON 문자열을 Map<String, bool>로 파싱
  static Map<String, bool> _parseOptions(dynamic options) {
    if (options == null) return {};

    Map<String, dynamic> source;

    if (options is String) {
      final decoded = jsonDecode(options);
      source = Map<String, dynamic>.from(decoded as Map);
    } else if (options is Map) {
      source = Map<String, dynamic>.from(options);
    } else {
      return {};
    }

    // petsAllowed 키 제거 (별도 필드로 처리)
    source.remove('petsAllowed');

    // int 값을 bool로 변환 (1 → true, 0 → false)
    final result = source.map((key, value) {
      if (value is int) {
        return MapEntry(key, value == 1);
      } else if (value is bool) {
        return MapEntry(key, value);
      }
      return MapEntry(key, false);
    });

    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'basicOptions': jsonEncode(basicOptions),
      'additionalOptions': jsonEncode(additionalOptions),
      'convenienceOptions': jsonEncode(convenienceOptions),
      'petsAllowed': petsAllowed,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 모든 편의시설을 평탄화된 리스트로 반환 (기존 호환성 유지)
  List<String> toFlatList() {
    final List<String> amenities = [];

    // 기본 옵션
    if (basicOptions['wifi'] == true) amenities.add('WiFi');
    if (basicOptions['tv'] == true) amenities.add('TV');
    if (basicOptions['airConditioner'] == true) amenities.add('에어컨');
    if (basicOptions['heater'] == true) amenities.add('난방');

    // 추가 옵션
    if (additionalOptions['washer'] == true) amenities.add('세탁기');
    if (additionalOptions['dryer'] == true) amenities.add('건조기');
    if (additionalOptions['iron'] == true) amenities.add('다리미');

    // 편의 옵션
    if (convenienceOptions['microwave'] == true) amenities.add('전자레인지');
    if (convenienceOptions['refrigerator'] == true) amenities.add('냉장고');
    if (convenienceOptions['dishwasher'] == true) amenities.add('식기세척기');

    // 반려동물
    if (petsAllowed) amenities.add('반려동물 동반 가능');

    return amenities;
  }

  RoomAmenity copyWith({
    int? roomId,
    Map<String, bool>? basicOptions,
    Map<String, bool>? additionalOptions,
    Map<String, bool>? convenienceOptions,
    bool? petsAllowed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomAmenity(
      roomId: roomId ?? this.roomId,
      basicOptions: basicOptions ?? this.basicOptions,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      convenienceOptions: convenienceOptions ?? this.convenienceOptions,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
