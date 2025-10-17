import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// 디버그용 localStorage 내용 확인
class DebugStorage {
  static void printAllLocalStorage() {
    if (!kIsWeb) {
      debugPrint('⚠️ 웹 환경이 아닙니다');
      return;
    }

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📦 localStorage 전체 내용:');
    debugPrint('═══════════════════════════════════════════════');

    final storage = html.window.localStorage;

    if (storage.isEmpty) {
      debugPrint('❌ localStorage가 비어있습니다!');
    } else {
      storage.keys.forEach((key) {
        final value = storage[key];
        final displayValue = value != null && value.length > 50
            ? '${value.substring(0, 50)}...'
            : value;
        debugPrint('🔑 $key: $displayValue');
      });
    }

    debugPrint('═══════════════════════════════════════════════');
    debugPrint('');
  }

  /// 특정 키로 저장된 모든 항목 찾기
  static void findKeysContaining(String searchTerm) {
    if (!kIsWeb) return;

    debugPrint('🔍 "$searchTerm" 포함 키 검색:');
    final storage = html.window.localStorage;

    final matchingKeys = storage.keys.where((key) =>
      key.toLowerCase().contains(searchTerm.toLowerCase())
    ).toList();

    if (matchingKeys.isEmpty) {
      debugPrint('❌ "$searchTerm"를 포함한 키가 없습니다');
    } else {
      matchingKeys.forEach((key) {
        final value = storage[key];
        final displayValue = value != null && value.length > 50
            ? '${value.substring(0, 50)}...'
            : value;
        debugPrint('✅ $key: $displayValue');
      });
    }
  }
}
