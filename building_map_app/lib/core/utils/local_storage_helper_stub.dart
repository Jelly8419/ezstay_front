/// Non-web 빌드용 no-op stub
class LocalStorageHelper {
  LocalStorageHelper._();

  static String? getItem(String key) => null;
  static void setItem(String key, String value) {}
  static void removeItem(String key) {}
}
