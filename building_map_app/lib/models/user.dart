/// 사용자 모델
class User {
  final String id;
  final String email;
  final String name;
  final String? nickname;
  final String? profileImageUrl;
  final UserMode mode;
  final AuthProvider provider;
  final bool phoneVerified;
  final bool hasBank;
  final AccountStatus accountStatus;
  final String? suspensionReason;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.profileImageUrl,
    required this.mode,
    required this.provider,
    this.phoneVerified = false,
    this.hasBank = false,
    this.accountStatus = AccountStatus.active,
    this.suspensionReason,
  });

  /// 표시용 이름 (닉네임 우선, 없으면 이름)
  String get displayName => (nickname?.isNotEmpty == true) ? nickname! : name;

  /// 계정이 정지 상태인지 확인
  bool get isSuspended => accountStatus == AccountStatus.suspended;

  /// 계정이 활성 상태인지 확인
  bool get isActive => accountStatus == AccountStatus.active;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      mode: UserMode.values.firstWhere(
        (mode) => mode.name == json['userMode'],
        orElse: () => UserMode.guest,
      ),
      provider: AuthProvider.values.firstWhere(
        (provider) => provider.toString() == json['provider'],
        orElse: () => AuthProvider.email,
      ),
      phoneVerified: json['phoneVerified'] ?? false,
      hasBank: json['hasBank'] ?? false,
      accountStatus: AccountStatus.fromString(json['accountStatus']),
      suspensionReason: json['suspensionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'userMode': mode.name,
      'provider': provider.toString(),
      'phoneVerified': phoneVerified,
      'hasBank': hasBank,
      'accountStatus': accountStatus.value,
      'suspensionReason': suspensionReason,
    };
  }
}

/// 사용자 모드 (게스트/호스트)
enum UserMode {
  guest,
  host,
}

/// 인증 제공자
enum AuthProvider {
  email,
  google,
  kakao,
}

/// 계정 상태
enum AccountStatus {
  active('ACTIVE'),
  suspended('SUSPENDED'),
  withdrawn('WITHDRAWN');

  final String value;
  const AccountStatus(this.value);

  static AccountStatus fromString(String? status) {
    if (status == null) return AccountStatus.active;
    return AccountStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => AccountStatus.active,
    );
  }
}