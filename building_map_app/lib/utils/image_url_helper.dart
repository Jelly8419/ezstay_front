import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/api_config.dart';

/// 이미지 URL 처리 유틸리티
///
/// 백엔드에서 반환된 상대경로를 환경에 맞게 절대경로로 변환합니다.
class ImageUrlHelper {
  /// 사진 URL에 경로 prefix 추가
  ///
  /// - 웹 환경: `http://localhost:8080/uploads/...` 형식
  /// - 모바일/데스크톱: `C:\study\uploads\...` 형식 (개발 환경)
  ///
  /// [url] 백엔드에서 반환된 이미지 경로 (예: `/uploads/rooms/...`)
  ///
  /// Returns: 절대경로 URL
  static String getPhotoUrl(String url) {
    // 이미 절대경로인 경우 그대로 반환
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // 개발 환경: 모든 플랫폼에서 로컬 파일 경로 사용 시도
    // 주의: 웹에서는 file:// 프로토콜이 CORS로 차단될 수 있음
    // 차선책: Python 간이 서버 (python -m http.server 8080)를 C:\study\uploads에서 실행

    if (kIsWeb) {
      // 웹 환경: file:// 프로토콜 시도 (작동 안 할 가능성 높음)
      // 대안: 백엔드 또는 Python 서버를 통해 파일 서빙
      if (url.startsWith('/uploads/')) {
        // file:// 프로토콜 시도 (브라우저가 차단할 수 있음)
        // return 'file:///C:/study$url';

        // 백엔드 서버 URL 사용 (권장)
        return '${ApiConfig.baseUrl}$url';
      }
      if (url.startsWith('/')) {
        return '${ApiConfig.baseUrl}$url';
      }
      return url;
    }

    // 모바일/데스크톱: 로컬 파일시스템 직접 접근
    if (url.startsWith('/uploads/')) {
      return 'C:\\study$url';
    }

    if (url.startsWith('/')) {
      return 'C:\\study$url';
    }

    return url;
  }

  /// 썸네일 URL 리스트를 변환
  ///
  /// [thumbnails] 썸네일 URL 리스트
  ///
  /// Returns: 절대경로로 변환된 URL 리스트
  static List<String> convertThumbnails(List<dynamic>? thumbnails) {
    if (thumbnails == null || thumbnails.isEmpty) {
      return [];
    }

    return thumbnails
        .map((url) => url.toString())
        .where((url) => url.isNotEmpty)
        .map((url) => getPhotoUrl(url))
        .toList();
  }

  /// Map 형식의 photos 데이터를 변환
  ///
  /// [photos] 사진 정보 Map 리스트 (예: [{'id': 1, 'url': '/uploads/...'}])
  ///
  /// Returns: 절대경로로 변환된 photos 리스트
  static List<Map<String, dynamic>> convertPhotosMap(List<dynamic>? photos) {
    if (photos == null || photos.isEmpty) {
      return [];
    }

    return photos.map((photo) {
      if (photo is Map<String, dynamic>) {
        final photoMap = Map<String, dynamic>.from(photo);
        if (photoMap.containsKey('url')) {
          photoMap['url'] = getPhotoUrl(photoMap['url'].toString());
        }
        return photoMap;
      }
      return photo as Map<String, dynamic>;
    }).toList();
  }
}
