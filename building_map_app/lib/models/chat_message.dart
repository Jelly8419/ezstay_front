import 'package:cloud_firestore/cloud_firestore.dart';

/// 채팅 메시지 모델
class ChatMessage {
  final String id;
  final int senderId;
  final String? senderName;  // 시스템 메시지용
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? systemMessageType;  // 'contract_approved', 'contract_completed' 등
  final String? imageUrl;  // 이미지 메시지용 (React UI 호환)

  ChatMessage({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.systemMessageType,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // timestamp가 null이거나 Timestamp가 아닌 경우 방어 처리
    DateTime parsedTimestamp;
    if (data['timestamp'] is Timestamp) {
      parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      parsedTimestamp = DateTime.now();
    }
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? 0,
      senderName: data['senderName'],
      text: data['text'] ?? '',
      timestamp: parsedTimestamp,
      isRead: data['isRead'] ?? false,
      type: MessageType.fromString(data['type'] ?? 'text'),
      systemMessageType: data['systemMessageType'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.value,
      if (systemMessageType != null) 'systemMessageType': systemMessageType,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  ChatMessage copyWith({
    String? id,
    int? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? systemMessageType,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      systemMessageType: systemMessageType ?? this.systemMessageType,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// 메시지 시간 포맷팅 (React UI 호환 - HH:mm)
  String getFormattedTime() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// 시스템 메시지인지 확인
  bool get isSystemMessage => type == MessageType.system;

  /// 계약 메시지인지 확인 (systemMessageType이 contract 관련인 경우)
  bool get isContractMessage =>
      type == MessageType.system &&
      (systemMessageType?.contains('contract') ?? false);

  /// 이미지 메시지인지 확인
  bool get isImageMessage => type == MessageType.image || imageUrl != null;
}

/// 메시지 타입
enum MessageType {
  text('text'),
  image('image'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}

/// Firestore 채팅방 메타데이터 모델
class ChatRoomMetadata {
  final int contractId;
  final int hostId;
  final int guestId;
  final bool isActive;
  final String? lastMessageText;
  final int? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;

  ChatRoomMetadata({
    required this.contractId,
    required this.hostId,
    required this.guestId,
    required this.isActive,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatRoomMetadata.fromFirestore(Map<String, dynamic> data) {
    return ChatRoomMetadata(
      contractId: _toInt(data['contractId']),
      hostId: _toInt(data['hostId']),
      guestId: _toInt(data['guestId']),
      isActive: data['isActive'] ?? true,
      lastMessageText: data['lastMessageText'],
      lastMessageSenderId: data['lastMessageSenderId'] != null
          ? _toInt(data['lastMessageSenderId'])
          : null,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  /// Firestore 값이 String("2008") 또는 int(2008) 어느 쪽이어도 int로 변환
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contractId': contractId,
      'hostId': hostId,
      'guestId': guestId,
      'isActive': isActive,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadCount': unreadCount,
    };
  }

  /// 특정 사용자의 읽지 않은 메시지 수
  int getUnreadCountForUser(int userId) {
    return unreadCount[userId.toString()] ?? 0;
  }
}
