import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/contract_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../providers/gnb_provider.dart';
import '../../widgets/chat/chat_list_sidebar.dart';
import '../../widgets/chat/chat_window.dart';
import '../../widgets/chat/contract_info_modal.dart';

/// 채팅 목록 페이지
/// React ChatListPage.tsx를 Flutter로 완전 복제
/// - PC: 왼쪽 사이드바(384px) + 오른쪽 채팅창
/// - Mobile: 채팅 선택 시 전체화면 전환
class ChatListPage extends StatefulWidget {
  final String? initialChatRoomId;
  final int? initialContractId; // 계약 ID로 채팅방 찾기

  const ChatListPage({
    super.key,
    this.initialChatRoomId,
    this.initialContractId,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final ContractService _contractService = ContractService();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  String _statusFilter = 'all';
  String? _selectedChatId;
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _error;

  // Firestore 채팅방 메타데이터 실시간 구독
  final List<StreamSubscription<dynamic>> _metadataSubs = [];
  int _metadataRetryCount = 0;
  static const int _maxMetadataRetries = 3;

  // PC 뷰 heartbeat (채팅창 열려있는 동안 알림톡 차단)
  Timer? _readHeartbeatTimer;

  // 메시지 캐시 (채팅방 변경 시 깜빡임 방지) — 최대 10개 LRU
  static const int _maxCacheSize = 10;
  final Map<String, List<ChatMessage>> _messageCache = {};

  void _updateMessageCache(String chatRoomId, List<ChatMessage> messages) {
    if (_messageCache.length >= _maxCacheSize &&
        !_messageCache.containsKey(chatRoomId)) {
      final oldest = _messageCache.keys
          .where((k) => k != _selectedChatId)
          .firstOrNull;
      if (oldest != null) _messageCache.remove(oldest);
    }
    _messageCache[chatRoomId] = messages;
  }

  @override
  void initState() {
    super.initState();
    _selectedChatId = widget.initialChatRoomId;
    _initializeAndLoadChatRooms();
  }

  @override
  void dispose() {
    _cancelMetadataSubs();
    _readHeartbeatTimer?.cancel();
    super.dispose();
  }

  void _cancelMetadataSubs() {
    for (final sub in _metadataSubs) {
      sub.cancel();
    }
    _metadataSubs.clear();
  }

  /// PC 뷰 heartbeat 시작 (채팅창이 열린 동안 30초마다 서버 읽음 처리)
  /// ChatDetailPage와 동일한 방식으로 알림톡 중복 발송 차단
  void _startReadHeartbeat(String chatRoomId) {
    _readHeartbeatTimer?.cancel();
    _readHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _chatService.markAsReadOnServer(chatRoomId),
    );
  }

  void _stopReadHeartbeat() {
    _readHeartbeatTimer?.cancel();
    _readHeartbeatTimer = null;
  }

  /// REST API 로드 완료 후 Firestore whereIn 쿼리로 실시간 구독
  /// 개별 문서 구독 대신 whereIn 배치 쿼리 사용 → 구독 수 최소화 (SDK assertion 방지)
  /// whereIn 최대 30개 제한으로 청크 분할
  void _subscribeFirestoreMetadata(int currentUserId) {
    _cancelMetadataSubs();
    _metadataRetryCount = 0; // 재구독 시작 시 재시도 카운터 리셋
    if (_chatRooms.isEmpty) return;

    // 종료된 방(isReadOnly) 중 이미 읽음 완료(unreadCount==0)는 구독 불필요.
    // 새 메시지·unreadCount 변화가 없으므로 Firestore reads 낭비만 발생함.
    final roomsToWatch = _chatRooms.where((r) {
      if (!r.isReadOnly) return true;        // 활성 방: 항상 구독
      return (r.unreadCount ?? 0) > 0;       // 종료 방: 미읽음 있을 때만 구독
    }).toList();

    if (roomsToWatch.isEmpty) return;

    const chunkSize = 30;
    final ids = roomsToWatch.map((r) => r.firebaseChatRoomId).toList();

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));

      final sub = FirebaseFirestore.instance
          .collection('chatRooms')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((querySnapshot) {
        if (!mounted) return;

        bool changed = false;
        final updatedRooms = List<ChatRoom>.from(_chatRooms);
        // 순서 재배치가 필요한 방 ID 추적 (lastMessageAt 변경된 경우만)
        final reorderIds = <String>{};

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final chatRoomId = doc.id;

          final lastMessageText = data['lastMessageText'] as String?;
          final lastMessageAt = data['lastMessageAt'] != null
              ? (data['lastMessageAt'] as Timestamp).toDate()
              : null;
          final unreadMap =
              Map<String, dynamic>.from(data['unreadCount'] ?? {});
          final rawUnread = unreadMap[currentUserId.toString()] ?? 0;
          final unreadCount =
              rawUnread is int ? rawUnread : (rawUnread as num).toInt();

          final idx = updatedRooms.indexWhere(
            (r) => r.firebaseChatRoomId == chatRoomId,
          );
          if (idx == -1) continue;

          final current = updatedRooms[idx];
          final newLastMessage = lastMessageText ?? current.lastMessage;
          final newLastMessageAt = lastMessageAt ?? current.lastMessageAt;

          // 현재 열려있는 채팅방은 unreadCount를 0으로 강제 처리
          // B가 채팅방을 보고 있는 동안 A가 메시지를 보내면 increment가 발생하지만
          // B 측 UI에서는 0으로 표시하고 즉시 읽음 처리해 배지가 뜨지 않게 함
          final effectiveUnreadCount =
              chatRoomId == _selectedChatId ? 0 : unreadCount;
          if (chatRoomId == _selectedChatId && unreadCount > 0) {
            // Firestore에도 즉시 0으로 리셋 (fire-and-forget)
            _chatService.markAsRead(
              chatRoomId: chatRoomId,
              userId: currentUserId,
            );
          }

          // 각 필드를 독립적으로 비교 (OR 조건)
          // 기존 AND 조건은 markAsRead(unread=0) + serverTimestamp pending(at=null) 상황에서
          // lastMessage가 같으면 수신자 UI가 갱신되지 않는 버그를 유발함
          final lastMessageChanged = lastMessageText != null &&
              lastMessageText != current.lastMessage;
          final lastMessageAtChanged = lastMessageAt != null &&
              lastMessageAt != current.lastMessageAt;
          final unreadChanged = effectiveUnreadCount != current.unreadCount;

          if (!lastMessageChanged && !lastMessageAtChanged && !unreadChanged) {
            continue;
          }

          updatedRooms[idx] = current.copyWith(
            lastMessage: newLastMessage,
            lastMessageAt: newLastMessageAt,
            unreadCount: effectiveUnreadCount,
          );
          changed = true;
          // lastMessageAt이 바뀐 방만 순서 재배치 대상
          if (lastMessageAtChanged) reorderIds.add(chatRoomId);
        }

        if (!changed) return;

        // 정렬 최적화: lastMessageAt이 변경된 방이 소수(≤2)이면
        // 전체 sort(O(n log n)) 대신 해당 방만 올바른 위치에 재삽입(O(n))
        if (reorderIds.isEmpty) {
          // unreadCount만 바뀐 경우 — 순서 변경 없음
        } else if (reorderIds.length <= 2) {
          for (final id in reorderIds) {
            final roomIdx = updatedRooms.indexWhere((r) => r.firebaseChatRoomId == id);
            if (roomIdx == -1) continue;
            final room = updatedRooms.removeAt(roomIdx);
            final roomTime = room.lastMessageAt ?? DateTime(2000);
            // 내림차순 정렬이므로 roomTime보다 작은 첫 번째 위치에 삽입
            final insertIdx = updatedRooms.indexWhere(
              (r) => (r.lastMessageAt ?? DateTime(2000)).isBefore(roomTime),
            );
            updatedRooms.insert(insertIdx == -1 ? updatedRooms.length : insertIdx, room);
          }
        } else {
          // 다수 변경 시 전체 정렬 (드문 케이스)
          updatedRooms.sort((a, b) {
            final aTime = a.lastMessageAt ?? DateTime(2000);
            final bTime = b.lastMessageAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
        }
        setState(() => _chatRooms = updatedRooms);
      }, onError: (e) {
        if (e is FirebaseException && e.code == 'permission-denied' &&
            _metadataRetryCount < _maxMetadataRetries) {
          _metadataRetryCount++;
          AppLogger.w('⚠️ [CHAT_LIST] 메타데이터 권한 없음 — 재인증 시도 $_metadataRetryCount/$_maxMetadataRetries');
          Future.delayed(Duration(seconds: _metadataRetryCount), () {
            _firebaseAuth.signInWithCustomToken().then((_) {
              if (mounted) _subscribeFirestoreMetadata(currentUserId);
            }).catchError((err) {
              AppLogger.e('❌ [CHAT_LIST] 재인증 실패: $err');
            });
          });
          return;
        }
        AppLogger.w('⚠️ [CHAT_LIST] 메타데이터 구독 에러: $e');
      });

      _metadataSubs.add(sub);
    }
  }

  /// Firebase 인증 후 채팅방 목록 로드
  Future<void> _initializeAndLoadChatRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 1. async 전에 context 의존 값 추출
      final authService = Provider.of<AuthService>(context, listen: false);
      final userMode = authService.currentUser?.mode == UserMode.host ? 'host' : 'guest';

      // 2. Firebase 인증 확인
      await _firebaseAuth.ensureAuthenticated();

      // 3. 채팅방 목록 로드 (유저 모드 분기)
      final chatRooms = await _chatService.getChatRooms(userMode: userMode);

      // 초기 선택된 채팅방이 있으면 unreadCount를 0으로 설정
      final initialId = _selectedChatId ?? widget.initialChatRoomId;
      final updatedRooms = initialId != null
          ? chatRooms.map((chat) {
              if (chat.firebaseChatRoomId == initialId) {
                return chat.copyWith(unreadCount: 0);
              }
              return chat;
            }).toList()
          : chatRooms;

      final currentUserId =
          int.tryParse(authService.currentUser?.id ?? '0') ?? 0;

      setState(() {
        _chatRooms = updatedRooms;
        _isLoading = false;
      });

      // 채팅방 목록 로드 완료 후 Firestore 실시간 구독 시작
      _subscribeFirestoreMetadata(currentUserId);

      // 초기 선택된 채팅방의 읽음 처리 (fire-and-forget)
      if (initialId != null) {
        if (currentUserId != 0) {
          _chatService.markAsRead(
            chatRoomId: initialId,
            userId: currentUserId,
          );
        }
        _chatService.markAsReadOnServer(initialId);

        // PC 뷰 heartbeat 시작 (URL로 직접 진입한 경우)
        _startReadHeartbeat(initialId);

        // GNB 채팅 레드닷 업데이트
        final totalUnread = updatedRooms.fold(
            0, (acc, chat) => acc + (chat.unreadCount ?? 0));
        if (totalUnread == 0 && mounted) {
          context.read<GNBProvider>().markChatsAsRead();
        }
      }

      if (widget.initialContractId != null && _selectedChatId == null) {
        final matchingRoom = chatRooms.where(
          (room) => room.contractId == widget.initialContractId,
        ).toList();

        if (matchingRoom.isNotEmpty) {
          final chatRoomId = matchingRoom.first.firebaseChatRoomId;
          setState(() {
            _selectedChatId = chatRoomId;
          });

          // URL을 /chat-list/{chatRoomId} 형태로 업데이트 (replace로 히스토리 교체)
          if (mounted) {
            context.replace('/chat-list/$chatRoomId');
          }
        } else {
          AppLogger.w('⚠️ [CHAT_LIST] 계약 ID ${widget.initialContractId}에 해당하는 채팅방을 찾을 수 없습니다.');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.e('❌ [CHAT_LIST] 초기화 실패: $e');
    }
  }

  /// 현재 사용자 모드에 따른 채팅방 필터링
  List<ChatRoom> get _filteredChatRooms {
    // 상태 필터 적용
    if (_statusFilter == 'all') {
      return _chatRooms;
    }

    return _chatRooms.where((chat) {
      return chat.contract?.status == _statusFilter;
    }).toList();
  }

  ChatRoom? get _selectedChat {
    if (_selectedChatId == null) return null;
    try {
      // firebaseChatRoomId로 비교 (URL에서 사용되는 ID)
      return _chatRooms.firstWhere(
        (chat) => chat.firebaseChatRoomId == _selectedChatId,
      );
    } catch (e) {
      return null;
    }
  }

  void _handleSelectChat(String firebaseChatRoomId) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;

    // setState 전에 새 리스트와 합계를 미리 계산
    final updatedRooms = _chatRooms.map((chat) {
      if (chat.firebaseChatRoomId == firebaseChatRoomId) {
        return chat.copyWith(unreadCount: 0);
      }
      return chat;
    }).toList();
    final totalUnreadAfter = updatedRooms.fold(0, (acc, chat) => acc + (chat.unreadCount ?? 0));

    setState(() {
      _selectedChatId = firebaseChatRoomId;
      _chatRooms = updatedRooms;
    });

    // 전체 미읽음 합이 0이면 GNB 채팅 레드닷 제거
    if (totalUnreadAfter == 0) {
      context.read<GNBProvider>().markChatsAsRead();
    }

    // Firestore unreadCount 리셋 (fire-and-forget)
    if (currentUserId != 0) {
      _chatService.markAsRead(
        chatRoomId: firebaseChatRoomId,
        userId: currentUserId,
      );
    }
    // Redis 읽음 처리 (알림톡 차단용, fire-and-forget)
    _chatService.markAsReadOnServer(firebaseChatRoomId);

    // PC 뷰 heartbeat 시작 (채팅창 열린 동안 30초마다 서버 읽음 처리)
    _startReadHeartbeat(firebaseChatRoomId);

    // URL 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/chat-list/$firebaseChatRoomId');
      }
    });
  }

  void _handleBack() {
    setState(() {
      _selectedChatId = null;
    });
    // 채팅창 닫힐 때 heartbeat 중단
    _stopReadHeartbeat();
    // URL 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/chat-list');
      }
    });
  }

  Future<void> _handleOpenContractInfo() async {
    final selectedChat = _selectedChat;
    if (selectedChat == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userMode = authService.currentUser?.mode == UserMode.host ? 'host' : 'guest';

    try {
      final detail = await _contractService.getGuestContractDetail(
        selectedChat.contractId,
      );

      if (detail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('계약 정보를 찾을 수 없습니다.')),
          );
        }
        return;
      }

      if (mounted) {
        showContractInfoModal(
          context,
          contract: detail,
          userMode: userMode,
        );
      }
    } catch (e) {
      AppLogger.e('❌ [CHAT_LIST] 계약 상세 조회 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계약 정보 조회 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024; // lg breakpoint
    final authService = Provider.of<AuthService>(context);
    final isHostMode = authService.currentUser?.mode == UserMode.host;
    final currentUserId =
        int.tryParse(authService.currentUser?.id ?? '0') ?? 0;

    final sidebar = ChatListSidebar(
      isDesktop: isDesktop,
      isHostMode: isHostMode,
      statusFilter: _statusFilter,
      onStatusFilterChanged: (v) => setState(() => _statusFilter = v),
      isLoading: _isLoading,
      error: _error,
      filteredChatRooms: _filteredChatRooms,
      currentUserId: currentUserId,
      selectedChatId: _selectedChatId,
      onSelectChat: _handleSelectChat,
      onRetry: _initializeAndLoadChatRooms,
    );

    // React: h-full flex flex-col lg:flex-row bg-white
    return Container(
        color: AppColors.neutral0, // bg-white
        child: Row(
          children: [
            // 채팅 목록 사이드바
            // React: 모바일에서 채팅 선택 시 숨김, 웹에서 항상 표시
            if (isDesktop || _selectedChatId == null)
              isDesktop
                  ? SizedBox(width: 384, child: sidebar)
                  : Expanded(child: sidebar),

            // 구분선 (웹에서만)
            if (isDesktop)
              Container(
                width: 1,
                color: AppColors.gray200, // border-r border-gray-200
              ),

            // 채팅 창
            // React: 웹에서만 표시 / 모바일에서는 선택 시 전체 화면
            if (_selectedChat != null && (isDesktop || _selectedChatId != null))
              Expanded(
                child: _buildChatWindow(isDesktop),
              ),

            // 웹에서 채팅 미선택 시 안내 메시지
            // React: hidden lg:flex flex-1 items-center justify-center bg-gray-50
            if (_selectedChat == null && isDesktop)
              Expanded(
                child: Container(
                  color: AppColors.gray50, // bg-gray-50
                  child: Center(
                    child: Text(
                      '채팅방을 선택해주세요',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.neutral400, // text-gray-400
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  /// 채팅 목록 사이드바
  /// 채팅 창
  Widget _buildChatWindow(bool isDesktop) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
    final firebaseChatRoomId = _selectedChat!.firebaseChatRoomId;


    // Firebase에서 실시간 메시지 로드
    // initialData: 캐시된 메시지로 초기화 → 스트림 교체 시 빈 화면 깜빡임 방지
    return StreamBuilder<List<ChatMessage>>(
      key: ValueKey(firebaseChatRoomId),
      stream: _chatService.getMessages(firebaseChatRoomId),
      initialData: _messageCache[firebaseChatRoomId],
      builder: (context, snapshot) {

        if (snapshot.hasError) {
          AppLogger.e('❌ [CHAT_WINDOW] 메시지 스트림 에러: ${snapshot.error}');
        }

        // 새 데이터가 오면 캐시 업데이트 (LRU 10개 제한)
        if (snapshot.hasData) {
          _updateMessageCache(firebaseChatRoomId, snapshot.data!);
        }

        // 캐시된 메시지 사용 (깜빡임 방지)
        final messages = snapshot.data ?? _messageCache[firebaseChatRoomId] ?? [];

        return ChatWindow(
          chatRoom: _selectedChat!,
          messages: messages,
          currentUserId: currentUserId,
          onOpenContractInfo: _handleOpenContractInfo,
          onBack: isDesktop ? null : _handleBack,
          onSendMessage: (text, images) async => _handleSendMessage(text, images, currentUserId),
        );
      },
    );
  }

  /// 메시지 전송 핸들러
  Future<void> _handleSendMessage(String text, List<XFile> images, int senderId) async {
    if (_selectedChat == null) return;

    try {
      await _chatService.sendMessageWithNotification(
        chatRoomId: _selectedChat!.firebaseChatRoomId,
        senderId: senderId,
        text: text,
        images: images,
      );
    } on ChatPermissionDeniedException {
      AppLogger.w('⚠️ [CHAT_LIST] 권한 거부: 종료된 계약 채팅방');
      if (mounted) _showPermissionDeniedDialog();
    } catch (e) {
      AppLogger.e('❌ [CHAT_LIST] 메시지 전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 전송 불가'),
        content: const Text('종료된 계약의 채팅방에는 메시지를 보낼 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
