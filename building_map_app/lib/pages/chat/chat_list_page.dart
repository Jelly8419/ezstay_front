import 'package:building_map_app/core/utils/app_logger.dart';
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
import '../../widgets/chat/chat_list_item.dart';
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

  // 메시지 캐시 (채팅방 변경 시 깜빡임 방지)
  final Map<String, List<ChatMessage>> _messageCache = {};

  @override
  void initState() {
    super.initState();
    _selectedChatId = widget.initialChatRoomId;
    _initializeAndLoadChatRooms();
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

      setState(() {
        _chatRooms = updatedRooms;
        _isLoading = false;
      });

      // 초기 선택된 채팅방의 읽음 처리 (fire-and-forget)
      if (initialId != null) {
        final currentUserId =
            int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
        if (currentUserId != 0) {
          _chatService.markAsRead(
            chatRoomId: initialId,
            userId: currentUserId,
          );
        }
        _chatService.markAsReadOnServer(initialId);

        // GNB 채팅 레드닷 업데이트
        final totalUnread = updatedRooms.fold(
            0, (sum, chat) => sum + (chat.unreadCount ?? 0));
        if (totalUnread == 0 && mounted) {
          context.read<GNBProvider>().markChatsAsRead();
        }
      }

      // 3. 계약 ID로 채팅방 찾아서 선택 및 URL 업데이트
      for (var room in chatRooms) {
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

  int get _totalUnreadCount {
    return _chatRooms.fold(0, (sum, chat) => sum + (chat.unreadCount ?? 0));
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
    final totalUnreadAfter = updatedRooms.fold(0, (sum, chat) => sum + (chat.unreadCount ?? 0));

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

    // React: h-full flex flex-col lg:flex-row bg-white
    return Container(
        color: AppColors.neutral0, // bg-white
        child: Row(
          children: [
            // 채팅 목록 사이드바
            // React: 모바일에서 채팅 선택 시 숨김, 웹에서 항상 표시
            // hidden lg:flex → ${selectedChatId ? 'hidden lg:flex' : 'flex'}
            if (isDesktop || _selectedChatId == null)
              isDesktop
                  ? SizedBox(
                      width: 384, // lg:w-96 (384px)
                      child: _buildChatListSidebar(isDesktop, isHostMode),
                    )
                  : Expanded(
                      child: _buildChatListSidebar(isDesktop, isHostMode),
                    ),

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
  Widget _buildChatListSidebar(bool isDesktop, bool isHostMode) {
    // React: flex flex-col w-full lg:w-96 border-r border-gray-200 h-full
    return Column(
      children: [
        // Mobile Header (React: lg:hidden)
        if (!isDesktop) _buildMobileHeader(),

        // Filter Section (React: p-4 sm:p-6 lg:p-4 border-b border-gray-200)
        _buildFilterSection(isHostMode),

        // Chat List (React: flex-1 overflow-y-auto pb-16 lg:pb-0)
        Expanded(
          child: _buildChatList(),
        ),
      ],
    );
  }

  /// 모바일 헤더 (React: lg:hidden bg-white border-b border-gray-200 px-4 py-4)
  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // px-4 py-4
      decoration: const BoxDecoration(
        color: AppColors.neutral0, // bg-white
        border: Border(
          bottom: BorderSide(color: AppColors.gray200), // border-b border-gray-200
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '채팅',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.neutral900, // text-gray-900
              fontWeight: FontWeight.bold, // font-bold
              fontSize: 18, // text-[18px]
            ),
          ),
        ],
      ),
    );
  }

  /// 필터 섹션 (React: p-4 sm:p-6 lg:p-4 border-b border-gray-200)
  Widget _buildFilterSection(bool isHostMode) {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Row(
        children: [
          // Status Filter Dropdown (React: relative flex-1)
          Expanded(
            child: _buildStatusDropdown(),
          ),
          const SizedBox(width: 8), // gap-2

          // 자동메시지 버튼 (호스트 모드에서만)
          // React: userMode === 'host' && (...)
          if (isHostMode) _buildAutoMessageButton(),
        ],
      ),
    );
  }

  /// 상태 필터 드롭다운
  /// React: w-full pl-4 pr-9 py-2 bg-gray-100 rounded-lg appearance-none cursor-pointer
  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // pl-4 pr-9
      decoration: BoxDecoration(
        color: AppColors.neutral100, // bg-gray-100
        borderRadius: BorderRadius.circular(8), // rounded-lg
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more, // ChevronDown
            size: 16, // w-4 h-4
            color: AppColors.neutral400, // text-gray-400
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral900,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('계약 상태')),
            DropdownMenuItem(value: 'PENDING_APPROVAL', child: Text('승인 대기')),
            DropdownMenuItem(value: 'APPROVED', child: Text('결제 대기')),
            DropdownMenuItem(value: 'PAYMENT_COMPLETED', child: Text('결제 완료')),
            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('임대 중')),
            DropdownMenuItem(value: 'COMPLETED', child: Text('계약 종료')),
            DropdownMenuItem(value: 'CANCELLED_BY_GUEST', child: Text('게스트 취소')),
            DropdownMenuItem(value: 'CANCELLED_BY_HOST', child: Text('호스트 취소')),
            DropdownMenuItem(value: 'REJECTED', child: Text('거절됨')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _statusFilter = value);
            }
          },
        ),
      ),
    );
  }

  /// 자동메시지 버튼
  /// React: flex items-center gap-2 px-3 sm:px-4 py-2 bg-blue-600 text-white rounded-lg
  Widget _buildAutoMessageButton() {
    return InkWell(
      onTap: () {
        context.push('/host/chat/auto-message');
      },
      borderRadius: BorderRadius.circular(8), // rounded-lg
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, // px-3
          vertical: 8, // py-2
        ),
        decoration: BoxDecoration(
          color: AppColors.blue600, // bg-blue-600
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add, // Plus
              size: 16, // w-4 h-4
              color: AppColors.neutral0, // text-white
            ),
            const SizedBox(width: 8), // gap-2
            Text(
              '자동메시지',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral0, // text-white
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 채팅 목록
  /// React: flex-1 overflow-y-auto pb-16 lg:pb-0
  Widget _buildChatList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error500,
            ),
            const SizedBox(height: 16),
            Text(
              '채팅방 목록을 불러올 수 없습니다',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeAndLoadChatRooms,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_filteredChatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: 16),
            Text(
              '채팅 내역이 없습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      );
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;

    return RefreshIndicator(
      onRefresh: _initializeAndLoadChatRooms,
      child: ListView.builder(
        itemCount: _filteredChatRooms.length,
        itemBuilder: (context, index) {
          final chat = _filteredChatRooms[index];
          // firebaseChatRoomId로 비교 및 선택
          final isSelected = _selectedChatId == chat.firebaseChatRoomId;

          return ChatListItem(
            chatRoom: chat,
            currentUserId: currentUserId,
            isSelected: isSelected,
            onTap: () => _handleSelectChat(chat.firebaseChatRoomId),
          );
        },
      ),
    );
  }

  /// 채팅 창
  Widget _buildChatWindow(bool isDesktop) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
    final firebaseChatRoomId = _selectedChat!.firebaseChatRoomId;


    // Firebase에서 실시간 메시지 로드
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getMessages(firebaseChatRoomId),
      builder: (context, snapshot) {

        if (snapshot.hasError) {
          AppLogger.e('❌ [CHAT_WINDOW] 메시지 스트림 에러: ${snapshot.error}');
        }

        // 새 데이터가 오면 캐시 업데이트
        if (snapshot.hasData) {
          _messageCache[firebaseChatRoomId] = snapshot.data!;
        }

        // 캐시된 메시지 사용 (깜빡임 방지)
        final messages = _messageCache[firebaseChatRoomId] ?? snapshot.data ?? [];

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
      final chatRoomId = _selectedChat!.firebaseChatRoomId;

      if (images.isNotEmpty) {
        // 이미지가 있으면 이미지 메시지 전송 (텍스트 포함)
        await _chatService.sendImageMessages(
          chatRoomId: chatRoomId,
          senderId: senderId,
          images: images,
          text: text.trim().isNotEmpty ? text : null,
        );
      } else {
        // 텍스트만 전송
        await _chatService.sendMessage(
          chatRoomId: chatRoomId,
          senderId: senderId,
          text: text,
        );
      }

      // 알림톡 요청 (fire-and-forget)
      _chatService.notifyChatMessage(chatRoomId);
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
}
