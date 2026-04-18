import 'package:web/web.dart' as web;

/// Flutter Web 전용 localStorage 헬퍼
class LocalStorageHelper {
  LocalStorageHelper._();

  static String? getItem(String key) =>
      web.window.localStorage.getItem(key);

  static void setItem(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  static void removeItem(String key) =>
      web.window.localStorage.removeItem(key);
}
