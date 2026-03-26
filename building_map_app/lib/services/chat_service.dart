import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
  Future<List<ChatRoom>> getChatRooms({String? status, String? userMode}) async {
    try {
      debugPrint('📋 [CHAT] 채팅방 목록 조회 시작 (status: $status, userMode: $userMode)');

      final headers = await _getAuthHeaders();

      // 쿼리 파라미터 조합
      final params = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'all') {
        params['status'] = status;
      }
      if (userMode != null && userMode.isNotEmpty) {
        params['userMode'] = userMode;
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/api/chats/rooms')
          .replace(queryParameters: params.isEmpty ? null : params);
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
      for (final room in chatRooms) {
        debugPrint('🔢 [CHAT] ${room.firebaseChatRoomId} unreadCount=${room.unreadCount}');
      }
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
  // 1-1. 백엔드 API - 채팅 알림톡 (ALIGO)
  // ============================================

  /// 채팅 메시지 알림 요청 (fire-and-forget)
  /// 메시지 전송 직후 호출 → 백엔드가 상대방 읽음 여부/5분 중복 체크 후 알림톡 발송
  Future<void> notifyChatMessage(String chatRoomId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse(ApiConfig.chatNotifyUrl(chatRoomId));
      await _apiClient.post(url, headers: headers);
      debugPrint('🔔 [CHAT] 알림 요청 완료: $chatRoomId');
    } catch (e) {
      // fire-and-forget: 실패해도 무시
      debugPrint('⚠️ [CHAT] 알림 요청 실패 (무시): $e');
    }
  }

  /// 채팅방 읽음 처리 (백엔드 API)
  /// 채팅방 진입 시 / 포그라운드 복귀 시 / heartbeat로 호출
  /// 백엔드에서 Redis에 읽음 시간 기록 → 상대방 알림 차단 판단에 사용
  Future<void> markAsReadOnServer(String chatRoomId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse(ApiConfig.chatReadUrl(chatRoomId));
      await _apiClient.post(url, headers: headers);
      debugPrint('👁️ [CHAT] 서버 읽음 처리 완료: $chatRoomId');
    } catch (e) {
      // 실패해도 무시 (최악의 경우 알림이 한 번 더 갈 뿐)
      debugPrint('⚠️ [CHAT] 서버 읽음 처리 실패 (무시): $e');
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
    String? imageUrl,
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
        imageUrl: imageUrl,
      );

      // Firestore에 메시지 추가
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toFirestore());

      // 채팅방 메타데이터 업데이트
      final lastMessageText = type == MessageType.image ? '사진' : text;
      await _updateChatRoomMetadata(
        chatRoomId: chatRoomId,
        lastMessage: lastMessageText,
        lastMessageSenderId: senderId,
      );

      debugPrint('✅ [CHAT] 메시지 전송 완료');
    } catch (e) {
      debugPrint('❌ [CHAT] 메시지 전송 실패: $e');
      rethrow;
    }
  }

  /// 이미지를 Firebase Storage에 업로드하고 다운로드 URL 반환
  Future<String> uploadChatImage({
    required String chatRoomId,
    required XFile imageFile,
  }) async {
    try {
      await _firebaseAuth.ensureAuthenticated();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.name.split('.').last.toLowerCase();
      final fileName = '${timestamp}_${imageFile.name}';
      final storagePath = 'chat_images/$chatRoomId/$fileName';

      debugPrint('📤 [CHAT] 이미지 업로드 시작: $storagePath');

      // 1. 바이트 읽기
      final bytes = await imageFile.readAsBytes();
      debugPrint('📤 [CHAT] 바이트 읽기 완료: ${bytes.length} bytes');

      // 2. Storage ref 생성
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      debugPrint('📤 [CHAT] Storage ref 생성 완료, bucket: ${FirebaseStorage.instance.bucket}');

      // 3. contentType 결정
      final contentType = switch (extension) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final metadata = SettableMetadata(contentType: contentType);
      debugPrint('📤 [CHAT] 업로드 시작 (contentType: $contentType)...');

      // 4. 업로드
      final uploadTask = ref.putData(bytes, metadata);

      // 진행 상태 로깅
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('📤 [CHAT] 업로드 진행: ${(progress * 100).toStringAsFixed(1)}% (${snapshot.state})');
        },
        onError: (e) {
          debugPrint('❌ [CHAT] 업로드 스냅샷 에러: $e');
        },
      );

      await uploadTask;
      debugPrint('📤 [CHAT] putData 완료, URL 가져오는 중...');

      // 5. 다운로드 URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ [CHAT] 이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ [CHAT] 이미지 업로드 실패: $e');
      debugPrint('❌ [CHAT] 에러 타입: ${e.runtimeType}');
      rethrow;
    }
  }

  /// 이미지 메시지 전송 (업로드 + Firestore 메시지 생성)
  Future<void> sendImageMessages({
    required String chatRoomId,
    required int senderId,
    required List<XFile> images,
    String? text,
  }) async {
    // 텍스트가 있으면 먼저 텍스트 메시지 전송
    if (text != null && text.trim().isNotEmpty) {
      await sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        text: text,
      );
    }

    // 각 이미지를 업로드 후 이미지 메시지 전송
    for (final image in images) {
      final imageUrl = await uploadChatImage(
        chatRoomId: chatRoomId,
        imageFile: image,
      );

      await sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        text: '',
        type: MessageType.image,
        imageUrl: imageUrl,
      );
    }
  }

  /// 메시지 수신 (Firestore - 실시간 스트림)
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    debugPrint('📨 [CHAT] getMessages 스트림 시작: chatRoomId=$chatRoomId');
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint('📨 [CHAT] 메시지 스냅샷 수신: ${snapshot.docs.length}개 문서');
      final messages = <ChatMessage>[];
      for (final doc in snapshot.docs) {
        try {
          messages.add(ChatMessage.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ [CHAT] 메시지 파싱 실패 (docId: ${doc.id}): $e');
        }
      }
      return messages;
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
