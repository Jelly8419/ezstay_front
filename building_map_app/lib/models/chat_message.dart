import 'package:cloud_firestore/cloud_firestore.dart';

/// 채팅 메시지 모델
class ChatMessage {
  final String id;
  final int senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'],
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: MessageType.fromString(data['type'] ?? 'text'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.value,
    };
  }

  ChatMessage copyWith({
    String? id,
    int? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
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
      contractId: data['contractId'],
      hostId: data['hostId'],
      guestId: data['guestId'],
      isActive: data['isActive'] ?? true,
      lastMessageText: data['lastMessageText'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
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
