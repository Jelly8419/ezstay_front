import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';

/// 이미지 최적화 서비스
class ImageService {
  /// 이미지 압축 (최대 5MB로 제한)
  static Future<Uint8List?> compressImage(
    XFile image, {
    int maxSizeInBytes = AppConstants.maxImageSize,
    int quality = 85,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('🖼️ [IMAGE] 이미지 압축 시작: ${image.name}');
      }

      // 원본 파일 크기 확인
      final originalBytes = await image.readAsBytes();
      final originalSize = originalBytes.length;

      if (!ApiConfig.isProduction) {
        debugPrint('📊 [IMAGE] 원본 크기: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      // 이미 충분히 작으면 압축 스킵
      if (originalSize <= maxSizeInBytes) {
        if (!ApiConfig.isProduction) {
          debugPrint('✅ [IMAGE] 압축 불필요 (이미 ${(maxSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB 이하)');
        }
        return originalBytes;
      }

      // 이미지 압축
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: quality,
        minWidth: 1920, // 최대 width
        minHeight: 1080, // 최대 height
      );

      if (compressedBytes == null) {
        if (!ApiConfig.isProduction) {
          debugPrint('❌ [IMAGE] 압축 실패');
        }
        return originalBytes;
      }

      final compressedSize = compressedBytes.length;

      if (!ApiConfig.isProduction) {
        debugPrint('📊 [IMAGE] 압축 후 크기: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB');
        debugPrint('📊 [IMAGE] 압축률: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');
      }

      // 여전히 너무 크면 품질을 낮춰서 재시도
      if (compressedSize > maxSizeInBytes && quality > 50) {
        if (!ApiConfig.isProduction) {
          debugPrint('⚠️ [IMAGE] 파일이 여전히 큼. 품질을 낮춰서 재압축...');
        }
        return await compressImage(image, maxSizeInBytes: maxSizeInBytes, quality: quality - 20);
      }

      return compressedBytes;
    } catch (e) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [IMAGE] 압축 에러: $e');
      }
      // 에러 발생 시 원본 반환
      return await image.readAsBytes();
    }
  }

  /// 여러 이미지 압축
  static Future<List<Uint8List>> compressImages(List<XFile> images) async {
    final List<Uint8List> compressedImages = [];

    for (final image in images) {
      final compressed = await compressImage(image);
      if (compressed != null) {
        compressedImages.add(compressed);
      }
    }

    return compressedImages;
  }

  /// 이미지 크기 검증
  static Future<bool> validateImageSize(XFile image) async {
    final bytes = await image.readAsBytes();
    final sizeInMB = bytes.length / 1024 / 1024;

    if (sizeInMB > 10) {
      // 10MB 초과
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [IMAGE] 이미지 파일이 너무 큽니다: ${sizeInMB.toStringAsFixed(2)}MB');
      }
      return false;
    }

    return true;
  }

  /// 이미지 포맷 검증
  static bool validateImageFormat(String fileName) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();

    return allowedExtensions.contains(extension);
  }

  /// 썸네일 생성
  static Future<Uint8List?> createThumbnail(
    XFile image, {
    int maxWidth = 300,
    int maxHeight = 300,
    int quality = 80,
  }) async {
    try {
      final thumbnail = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      return thumbnail;
    } catch (e) {
      if (!ApiConfig.isProduction) {
        debugPrint('❌ [IMAGE] 썸네일 생성 에러: $e');
      }
      return null;
    }
  }
}
