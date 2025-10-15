/// 방 무료 부가서비스 정보 모델
class RoomFreeService {
  final int roomId;
  final bool agreeTerms;
  final bool cleaningService;
  final String? cleaningToolImageUrl;
  final bool hairDryerRental;
  final bool beddingService;
  final int bedSizeSuperSingle;
  final int bedSizeQueen;
  final int bedSizeKing;
  final bool autoPasswordChange;
  final String? roomPassword; // 게스트 조회 시에는 제외됨
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomFreeService({
    required this.roomId,
    required this.agreeTerms,
    required this.cleaningService,
    this.cleaningToolImageUrl,
    required this.hairDryerRental,
    required this.beddingService,
    required this.bedSizeSuperSingle,
    required this.bedSizeQueen,
    required this.bedSizeKing,
    required this.autoPasswordChange,
    this.roomPassword,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomFreeService.fromJson(Map<String, dynamic> json) {
    return RoomFreeService(
      roomId: json['roomId'] as int,
      agreeTerms: json['agreeTerms'] as bool? ?? false,
      cleaningService: json['cleaningService'] as bool? ?? false,
      cleaningToolImageUrl: json['cleaningToolImageUrl'] as String?,
      hairDryerRental: json['hairDryerRental'] as bool? ?? false,
      beddingService: json['beddingService'] as bool? ?? false,
      bedSizeSuperSingle: json['bedSizeSuperSingle'] as int? ?? 0,
      bedSizeQueen: json['bedSizeQueen'] as int? ?? 0,
      bedSizeKing: json['bedSizeKing'] as int? ?? 0,
      autoPasswordChange: json['autoPasswordChange'] as bool? ?? false,
      roomPassword: json['roomPassword'] as String?, // 게스트에게는 null
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'agreeTerms': agreeTerms,
      'cleaningService': cleaningService,
      'cleaningToolImageUrl': cleaningToolImageUrl,
      'hairDryerRental': hairDryerRental,
      'beddingService': beddingService,
      'bedSizeSuperSingle': bedSizeSuperSingle,
      'bedSizeQueen': bedSizeQueen,
      'bedSizeKing': bedSizeKing,
      'autoPasswordChange': autoPasswordChange,
      'roomPassword': roomPassword,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 무료 서비스를 평탄화된 리스트로 반환 (기존 호환성 유지)
  List<String> toFlatList() {
    final List<String> services = [];

    if (cleaningService) services.add('청소 서비스');
    if (hairDryerRental) services.add('헤어드라이어 대여');
    if (beddingService) services.add('침구 서비스');
    if (autoPasswordChange) services.add('자동 비밀번호 변경');

    return services;
  }

  RoomFreeService copyWith({
    int? roomId,
    bool? agreeTerms,
    bool? cleaningService,
    String? cleaningToolImageUrl,
    bool? hairDryerRental,
    bool? beddingService,
    int? bedSizeSuperSingle,
    int? bedSizeQueen,
    int? bedSizeKing,
    bool? autoPasswordChange,
    String? roomPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomFreeService(
      roomId: roomId ?? this.roomId,
      agreeTerms: agreeTerms ?? this.agreeTerms,
      cleaningService: cleaningService ?? this.cleaningService,
      cleaningToolImageUrl: cleaningToolImageUrl ?? this.cleaningToolImageUrl,
      hairDryerRental: hairDryerRental ?? this.hairDryerRental,
      beddingService: beddingService ?? this.beddingService,
      bedSizeSuperSingle: bedSizeSuperSingle ?? this.bedSizeSuperSingle,
      bedSizeQueen: bedSizeQueen ?? this.bedSizeQueen,
      bedSizeKing: bedSizeKing ?? this.bedSizeKing,
      autoPasswordChange: autoPasswordChange ?? this.autoPasswordChange,
      roomPassword: roomPassword ?? this.roomPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
