import 'package:flutter/material.dart';
import '../models/chat_room.dart';

/// 채팅 UI 상태 관리 Provider
class ChatProvider with ChangeNotifier {
  bool _isOpen = false;
  ChatRoom? _selectedChatRoom;
  bool _isListView = true; // true: 목록, false: 상세

  bool get isOpen => _isOpen;
  ChatRoom? get selectedChatRoom => _selectedChatRoom;
  bool get isListView => _isListView;

  /// 채팅 위젯 열기 (목록 표시)
  void openChatList() {
    _isOpen = true;
    _isListView = true;
    _selectedChatRoom = null;
    notifyListeners();
  }

  /// 채팅 상세 열기
  void openChatDetail(ChatRoom chatRoom) {
    _isOpen = true;
    _isListView = false;
    _selectedChatRoom = chatRoom;
    notifyListeners();
  }

  /// 채팅 목록으로 돌아가기
  void backToList() {
    _isListView = true;
    _selectedChatRoom = null;
    notifyListeners();
  }

  /// 채팅 위젯 닫기
  void closeChat() {
    _isOpen = false;
    _isListView = true;
    _selectedChatRoom = null;
    notifyListeners();
  }
}
