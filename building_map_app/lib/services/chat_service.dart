import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'firebase_auth_service.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../config/api_config.dart';

/// 채팅 서비스
/// - Firestore: 실시간 메시지 전송/수신
/// - 백엔드 API: 채팅방 메타데이터 관리
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final ApiClient _apiClient = ApiClient();

  /// Authorization 헤더 생성
  Future<Map<String, String>> _getAuthHeaders() async {
    final accessToken = await TokenService.getValidAccessToken(autoRefresh: true);
    if (accessToken == null) {
      throw Exception('액세스 토큰이 없습니다. 먼저 로그인하세요.');
    }
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  // ============================================
  // 1. 백엔드 API - 채팅방 관리
  // ============================================

  /// 채팅방 목록 조회 (백엔드 API)
  /// [status] - 계약 상태 필터 (선택사항)
  ///   - IN_PROGRESS: 진행중
  ///   - PAYMENT_PENDING: 결제대기
  ///   - PAYMENT_COMPLETED: 결제완료
  ///   - ACTIVE: 임대중
  ///   - COMPLETED: 계약종료
  ///   - CANCELLED: 계약취소
  ///   - REJECTED: 승인거절
  Future<List<ChatRoom>> getChatRooms({String? status}) async {
    try {
      debugPrint('📋 [CHAT] 채팅방 목록 조회 시작 (status: $status)');

      final headers = await _getAuthHeaders();

      // 상태 필터가 있으면 쿼리 파라미터 추가
      String urlString = '${ApiConfig.baseUrl}/api/chats/rooms';
      if (status != null && status.isNotEmpty && status != 'all') {
        urlString += '?status=$status';
      }

      final url = Uri.parse(urlString);
      final response = await _apiClient.get(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '채팅방 목록 조회 실패');
      }

      final List<dynamic> roomsJson = data['data']['chatRooms'];
      final chatRooms = roomsJson.map((json) => ChatRoom.fromJson(json)).toList();

      debugPrint('✅ [CHAT] 채팅방 ${chatRooms.length}개 조회 완료');
      return chatRooms;
    } catch (e) {
      debugPrint('❌ [CHAT] 채팅방 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 채팅방 상세 정보 조회 (백엔드 API)
  Future<ChatRoom> getChatRoomDetail(String firebaseChatRoomId) async {
    try {
      debugPrint('📋 [CHAT] 채팅방 상세 조회: $firebaseChatRoomId');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/chats/rooms/$firebaseChatRoomId');
      final response = await _apiClient.get(url, headers: headers);

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '채팅방 조회 실패');
      }

      final chatRoom = ChatRoom.fromJson(data['data']['chatRoom']);
      debugPrint('✅ [CHAT] 채팅방 상세 조회 완료');
      return chatRoom;
    } catch (e) {
      debugPrint('❌ [CHAT] 채팅방 상세 조회 실패: $e');
      rethrow;
    }
  }

  /// 채팅방 생성 (백엔드 API) - 수동 생성
  Future<ChatRoom> createChatRoom(int contractId) async {
    try {
      debugPrint('🆕 [CHAT] 채팅방 생성: contractId=$contractId');

      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/chats/rooms');
      final response = await _apiClient.post(
        url,
        headers: headers,
        body: jsonEncode({'contractId': contractId}),
      );

      if (response == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final data = jsonDecode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? '채팅방 생성 실패');
      }

      final chatRoom = ChatRoom.fromJson(data['data']['chatRoom']);
      debugPrint('✅ [CHAT] 채팅방 생성 완료: ${chatRoom.firebaseChatRoomId}');
      return chatRoom;
    } catch (e) {
      debugPrint('❌ [CHAT] 채팅방 생성 실패: $e');
      rethrow;
    }
  }

  // ============================================
  // 2. Firestore - 실시간 메시지
  // ============================================

  /// 메시지 전송 (Firestore)
  Future<void> sendMessage({
    required String chatRoomId,
    required int senderId,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    try {
      // Firebase 인증 확인
      await _firebaseAuth.ensureAuthenticated();

      debugPrint('💬 [CHAT] 메시지 전송: $chatRoomId');

      final message = ChatMessage(
        id: '', // Firestore가 자동 생성
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        isRead: false,
        type: type,
      );

      // Firestore에 메시지 추가
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toFirestore());

      // 채팅방 메타데이터 업데이트
      await _updateChatRoomMetadata(
        chatRoomId: chatRoomId,
        lastMessage: text,
        lastMessageSenderId: senderId,
      );

      debugPrint('✅ [CHAT] 메시지 전송 완료');
    } catch (e) {
      debugPrint('❌ [CHAT] 메시지 전송 실패: $e');
      rethrow;
    }
  }

  /// 메시지 수신 (Firestore - 실시간 스트림)
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  /// 읽음 처리 (Firestore)
  Future<void> markAsRead({
    required String chatRoomId,
    required int userId,
  }) async {
    try {
      await _firebaseAuth.ensureAuthenticated();

      debugPrint('✅ [CHAT] 읽음 처리: $chatRoomId, user=$userId');

      // 채팅방 메타데이터에서 unreadCount 초기화
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      debugPrint('❌ [CHAT] 읽음 처리 실패: $e');
      rethrow;
    }
  }

  /// 안읽은 메시지 카운트 (Firestore)
  Stream<int> getUnreadCount(String chatRoomId, int userId) {
    try {
      return _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return 0;

        final data = snapshot.data() as Map<String, dynamic>;
        final metadata = ChatRoomMetadata.fromFirestore(data);
        return metadata.getUnreadCountForUser(userId);
      });
    } catch (e) {
      debugPrint('❌ [CHAT] 안읽은 메시지 카운트 에러: $e');
      return Stream.value(0);
    }
  }

  /// 채팅방 메타데이터 업데이트 (내부 헬퍼)
  Future<void> _updateChatRoomMetadata({
    required String chatRoomId,
    required String lastMessage,
    required int lastMessageSenderId,
  }) async {
    try {
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      final snapshot = await chatRoomRef.get();

      if (!snapshot.exists) {
        debugPrint('⚠️ [CHAT] 채팅방 메타데이터 없음: $chatRoomId');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final metadata = ChatRoomMetadata.fromFirestore(data);

      // 상대방의 unreadCount 증가
      final otherUserId = lastMessageSenderId == metadata.hostId
          ? metadata.guestId
          : metadata.hostId;

      final newUnreadCount = Map<String, int>.from(metadata.unreadCount);
      newUnreadCount[otherUserId.toString()] =
          (newUnreadCount[otherUserId.toString()] ?? 0) + 1;

      // 메타데이터 업데이트
      await chatRoomRef.update({
        'lastMessageText': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': newUnreadCount,
      });

      debugPrint('✅ [CHAT] 메타데이터 업데이트 완료');
    } catch (e) {
      debugPrint('❌ [CHAT] 메타데이터 업데이트 실패: $e');
    }
  }

  /// 채팅방 메타데이터 스트림 (Firestore)
  Stream<ChatRoomMetadata?> getChatRoomMetadata(String chatRoomId) {
    try {
      return _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return null;

        final data = snapshot.data() as Map<String, dynamic>;
        return ChatRoomMetadata.fromFirestore(data);
      });
    } catch (e) {
      debugPrint('❌ [CHAT] 메타데이터 스트림 에러: $e');
      return Stream.value(null);
    }
  }
}
