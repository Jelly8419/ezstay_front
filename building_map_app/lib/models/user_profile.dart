/// 사용자 프로필 모델
class UserProfile {
  final String name;
  final String? nickname;
  final String email;
  final String phoneNumber;
  final String createdAt;

  UserProfile({
    required this.name,
    this.nickname,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
  });

  /// 표시용 이름 (닉네임 우선, 없으면 이름)
  String get displayName => (nickname?.isNotEmpty == true) ? nickname! : name;

  /// JSON → UserProfile
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  /// UserProfile → JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nickname': nickname,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
    };
  }

  /// 부분 업데이트를 위한 copyWith 메서드
  UserProfile copyWith({
    String? name,
    String? nickname,
    String? email,
    String? phoneNumber,
    String? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 가입일 포맷팅 (YYYY-MM-DD → YYYY년 MM월 DD일)
  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일';
    } catch (e) {
      return createdAt;
    }
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, email: $email, phoneNumber: $phoneNumber, createdAt: $createdAt)';
  }
}
