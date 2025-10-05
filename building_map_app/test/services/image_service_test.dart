import 'package:flutter_test/flutter_test.dart';
import 'package:building_map_app/services/image_service.dart';

void main() {
  group('ImageService', () {
    test('이미지 포맷 검증 - 유효한 포맷', () {
      expect(ImageService.validateImageFormat('photo.jpg'), isTrue);
      expect(ImageService.validateImageFormat('photo.jpeg'), isTrue);
      expect(ImageService.validateImageFormat('photo.png'), isTrue);
      expect(ImageService.validateImageFormat('photo.webp'), isTrue);
    });

    test('이미지 포맷 검증 - 유효하지 않은 포맷', () {
      expect(ImageService.validateImageFormat('photo.gif'), isFalse);
      expect(ImageService.validateImageFormat('photo.bmp'), isFalse);
      expect(ImageService.validateImageFormat('photo.svg'), isFalse);
      expect(ImageService.validateImageFormat('photo.pdf'), isFalse);
    });

    test('이미지 포맷 검증 - 대소문자 무시', () {
      expect(ImageService.validateImageFormat('photo.JPG'), isTrue);
      expect(ImageService.validateImageFormat('photo.JPEG'), isTrue);
      expect(ImageService.validateImageFormat('photo.PNG'), isTrue);
    });
  });
}
