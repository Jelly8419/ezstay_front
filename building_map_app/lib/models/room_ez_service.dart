/// 방 이지스테이 관리 서비스 정보 모델 (EZ Service)
///
/// 백엔드 변경사항: free_service → ez_service
/// - 렌탈 관련 필드 제거 (헤어드라이기, 침구류, 타월, 어메니티 키트)
/// - 호스트 방 관리 서비스만 유지 (청소, 도어락 비밀번호 변경)
class RoomEzService {
  final int roomId;
  final bool agreeTerms; // EZ 서비스 이용 약관 동의
  final bool cleaningService; // 청소 서비스
  final String? cleaningToolImageUrl; // 청소도구 이미지 URL
  final bool autoPasswordChange; // 도어락 비밀번호 자동 변경 및 퇴실 점검
  final String? roomPassword; // 방 비밀번호 (게스트 조회 시에는 제외됨)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomEzService({
    required this.roomId,
    required this.agreeTerms,
    required this.cleaningService,
    this.cleaningToolImageUrl,
    required this.autoPasswordChange,
    this.roomPassword,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomEzService.fromJson(Map<String, dynamic> json) {
    return RoomEzService(
      roomId: json['roomId'] as int? ?? 0,
      agreeTerms: json['agreeTerms'] as bool? ?? false,
      cleaningService: json['cleaningService'] as bool? ?? false,
      cleaningToolImageUrl: json['cleaningToolImageUrl'] as String?,
      autoPasswordChange: json['autoPasswordChange'] as bool? ?? false,
      roomPassword: json['roomPassword'] as String?, // 게스트에게는 null
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'agreeTerms': agreeTerms,
      'cleaningService': cleaningService,
      'cleaningToolImageUrl': cleaningToolImageUrl,
      'autoPasswordChange': autoPasswordChange,
      'roomPassword': roomPassword,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 이지스테이 관리 서비스를 평탄화된 리스트로 반환 (UI 표시용)
  List<String> toFlatList() {
    final List<String> services = [];

    if (cleaningService) services.add('청소 서비스');
    if (autoPasswordChange) services.add('도어락 비밀번호 자동 변경 및 퇴실 점검');

    return services;
  }

  RoomEzService copyWith({
    int? roomId,
    bool? agreeTerms,
    bool? cleaningService,
    String? cleaningToolImageUrl,
    bool? autoPasswordChange,
    String? roomPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomEzService(
      roomId: roomId ?? this.roomId,
      agreeTerms: agreeTerms ?? this.agreeTerms,
      cleaningService: cleaningService ?? this.cleaningService,
      cleaningToolImageUrl: cleaningToolImageUrl ?? this.cleaningToolImageUrl,
      autoPasswordChange: autoPasswordChange ?? this.autoPasswordChange,
      roomPassword: roomPassword ?? this.roomPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
