/// 채팅방 모델
class ChatRoom {
  final int id;
  final int contractId;
  final String firebaseChatRoomId;
  final int hostId;
  final int guestId;
  final int roomId;
  final bool isActive;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 추가 정보 (API 응답에 포함됨)
  final Contract? contract;
  final Room? room;
  final User? host;
  final User? guest;
  final String? lastMessage;
  final int? unreadCount;

  ChatRoom({
    required this.id,
    required this.contractId,
    required this.firebaseChatRoomId,
    required this.hostId,
    required this.guestId,
    required this.roomId,
    required this.isActive,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.contract,
    this.room,
    this.host,
    this.guest,
    this.lastMessage,
    this.unreadCount,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      contractId: json['contractId'],
      firebaseChatRoomId: json['firebaseChatRoomId'],
      hostId: json['hostId'],
      guestId: json['guestId'],
      roomId: json['roomId'],
      isActive: json['isActive'] ?? true,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      contract: json['contract'] != null
          ? Contract.fromJson(json['contract'])
          : null,
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
      host: json['host'] != null ? User.fromJson(json['host']) : null,
      guest: json['guest'] != null ? User.fromJson(json['guest']) : null,
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'firebaseChatRoomId': firebaseChatRoomId,
      'hostId': hostId,
      'guestId': guestId,
      'roomId': roomId,
      'isActive': isActive,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 상대방 정보 가져오기 (현재 사용자 기준)
  User? getOtherUser(int currentUserId) {
    if (currentUserId == hostId) {
      return guest;
    } else if (currentUserId == guestId) {
      return host;
    }
    return null;
  }

  /// 상대방 이름 가져오기
  String getOtherUserName(int currentUserId) {
    final otherUser = getOtherUser(currentUserId);
    return otherUser?.name ?? '알 수 없음';
  }

  /// 방 이름 또는 주소
  String getRoomDisplayName() {
    return room?.name ?? room?.roadAddress ?? '알 수 없음';
  }
}

/// Contract 모델 (간소화 버전 - 채팅방 목록용)
class Contract {
  final int id;
  final String status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int? totalUsageFee;

  Contract({
    required this.id,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    this.totalUsageFee,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'],
      status: json['status'],
      checkInDate: DateTime.parse(json['checkInDate']),
      checkOutDate: DateTime.parse(json['checkOutDate']),
      totalUsageFee: json['totalUsageFee'],
    );
  }
}

/// Room 모델 (간소화 버전 - 채팅방 목록용)
class Room {
  final int id;
  final String? name;
  final String? roadAddress;
  final String? detailAddress;

  Room({
    required this.id,
    this.name,
    this.roadAddress,
    this.detailAddress,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      roadAddress: json['roadAddress'],
      detailAddress: json['detailAddress'],
    );
  }
}

/// User 모델 (간소화 버전 - 채팅방 목록용)
class User {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
