import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/guest_move_in/guest_move_in.dart';

/// 비로그인 미리보기에서 선택한 옵션을 로그인 복귀 후 복원하기 위한 저장소.
///
/// PRD 10.1: "비로그인 상태에서 선택한 옵션은 로그인 후 복귀해도 유지되어야 한다"
///
/// 키: `pending_move_in_options_<token>` — token 단위로 격리
/// 값: `[{"optionId": 1, "quantity": 2}, ...]`
///
/// 웹 전용. 모바일은 추후 SharedPreferences 등으로 확장 가능.
class GuestMoveInSessionStorage {
  static String _key(String token) => 'pending_move_in_options_$token';

  static void save(String token, List<GuestSelectedItem> items) {
    if (!kIsWeb) return;
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    html.window.sessionStorage[_key(token)] = encoded;
  }

  static List<GuestSelectedItem> load(String token) {
    if (!kIsWeb) return const [];
    final raw = html.window.sessionStorage[_key(token)];
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GuestSelectedItem(
                optionId: (e['optionId'] as num).toInt(),
                quantity: (e['quantity'] as num).toInt(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static void clear(String token) {
    if (!kIsWeb) return;
    html.window.sessionStorage.remove(_key(token));
  }
}
