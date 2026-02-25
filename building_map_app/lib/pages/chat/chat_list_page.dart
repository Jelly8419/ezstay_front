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
import '../../services/firebase_auth_service.dart';
import '../../widgets/chat/chat_list_item.dart';
import '../../widgets/chat/chat_window.dart';

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
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  String _statusFilter = 'all';
  String? _selectedChatId;
  bool _isContractInfoOpen = false;
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

      // 1. Firebase 인증 확인
      await _firebaseAuth.ensureAuthenticated();

      // 2. 채팅방 목록 로드
      final chatRooms = await _chatService.getChatRooms();

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });

      // 3. 계약 ID로 채팅방 찾아서 선택 및 URL 업데이트
      debugPrint('📱 [CHAT_LIST] initialContractId: ${widget.initialContractId}, _selectedChatId: $_selectedChatId');
      debugPrint('📱 [CHAT_LIST] 로드된 채팅방 수: ${chatRooms.length}');
      for (var room in chatRooms) {
        debugPrint('📱 [CHAT_LIST] 채팅방 - contractId: ${room.contractId}, firebaseChatRoomId: ${room.firebaseChatRoomId}');
      }

      if (widget.initialContractId != null && _selectedChatId == null) {
        final matchingRoom = chatRooms.where(
          (room) => room.contractId == widget.initialContractId,
        ).toList();
        debugPrint('📱 [CHAT_LIST] 매칭된 채팅방 수: ${matchingRoom.length}');

        if (matchingRoom.isNotEmpty) {
          final chatRoomId = matchingRoom.first.firebaseChatRoomId;
          setState(() {
            _selectedChatId = chatRoomId;
          });
          debugPrint('📱 [CHAT_LIST] 계약 ID ${widget.initialContractId}에 해당하는 채팅방 선택: $chatRoomId');

          // URL을 /chat-list/{chatRoomId} 형태로 업데이트 (replace로 히스토리 교체)
          if (mounted) {
            context.replace('/chat-list/$chatRoomId');
          }
        } else {
          debugPrint('⚠️ [CHAT_LIST] 계약 ID ${widget.initialContractId}에 해당하는 채팅방을 찾을 수 없습니다.');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('❌ [CHAT_LIST] 초기화 실패: $e');
    }
  }

  /// 현재 사용자 모드에 따른 채팅방 필터링
  List<ChatRoom> get _filteredChatRooms {
    // 상태 필터 적용
    if (_statusFilter == 'all') {
      return _chatRooms;
    }

    return _chatRooms.where((chat) {
      return chat.contractStatus.value == _statusFilter;
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
    setState(() {
      _selectedChatId = firebaseChatRoomId;
    });
    // URL 업데이트 (go 사용 - 페이지 재빌드 없이 URL만 변경)
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

  void _handleOpenContractInfo() {
    setState(() {
      _isContractInfoOpen = true;
    });
  }

  void _handleCloseContractInfo() {
    setState(() {
      _isContractInfoOpen = false;
    });
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
              SizedBox(
                width: isDesktop ? 384 : double.infinity, // lg:w-96 (384px)
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
            DropdownMenuItem(value: 'payment_pending', child: Text('결제 대기')),
            DropdownMenuItem(value: 'payment_completed', child: Text('결제 완료')),
            DropdownMenuItem(value: 'ongoing', child: Text('임대 중')),
            DropdownMenuItem(value: 'terminated', child: Text('계약 종료')),
            DropdownMenuItem(value: 'cancelled', child: Text('계약 취소')),
            DropdownMenuItem(value: 'rejected', child: Text('승인 거절')),
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

    debugPrint('💬 [CHAT_WINDOW] firebaseChatRoomId: $firebaseChatRoomId, currentUserId: $currentUserId');

    // Firebase에서 실시간 메시지 로드
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getMessages(firebaseChatRoomId),
      builder: (context, snapshot) {
        debugPrint('💬 [CHAT_WINDOW] StreamBuilder - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');

        if (snapshot.hasError) {
          debugPrint('❌ [CHAT_WINDOW] 메시지 스트림 에러: ${snapshot.error}');
        }

        // 새 데이터가 오면 캐시 업데이트
        if (snapshot.hasData) {
          _messageCache[firebaseChatRoomId] = snapshot.data!;
          debugPrint('💬 [CHAT_WINDOW] 메시지 ${snapshot.data!.length}개 수신');
        }

        // 캐시된 메시지 사용 (깜빡임 방지)
        final messages = _messageCache[firebaseChatRoomId] ?? snapshot.data ?? [];

        return ChatWindow(
          chatRoom: _selectedChat!,
          messages: messages,
          currentUserId: currentUserId,
          onOpenContractInfo: _handleOpenContractInfo,
          onBack: isDesktop ? null : _handleBack,
          onSendMessage: (text, images) => _handleSendMessage(text, images, currentUserId),
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
    } catch (e) {
      debugPrint('❌ [CHAT_LIST] 메시지 전송 실패: $e');
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
