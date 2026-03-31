import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/exceptions.dart';
import '../services/receipt_service.dart';
import '../utils/receipt_validator.dart';

/// 호스트 영수증 비즈니스 로직 서비스
///
/// 영수증 CRUD, 필드 유효성 검증, 타입명 변환을
/// [HostMyPage]에서 분리합니다.
class HostReceiptService {
  final ReceiptService _receiptService = ReceiptService();

  // ──────────────────────────────────────────────
  // 유틸
  // ──────────────────────────────────────────────

  /// 영수증 종류 코드 → 표시 이름
  String getReceiptTypeName(String? type) {
    switch (type) {
      case 'personal':
        return '개인소득공제용 현금영수증';
      case 'business':
        return '사업자증빙용 현금영수증';
      case 'tax_invoice':
        return '전자세금계산서';
      default:
        return '-';
    }
  }

  /// 영수증 필드 유효성 검증
  ///
  /// 에러가 있는 필드만 [errors]에 저장합니다.
  /// null 항목은 에러 없음을 의미하며 최종 결과에서 제거됩니다.
  /// 반환값: 에러가 없으면 true
  bool validateFields({
    required String receiptType,
    required String receiptNumberInputType,
    required String number,
    required String businessName,
    required String repName,
    required String email,
    required Map<String, String?> errors,
  }) {
    errors.clear();

    if (receiptType.isEmpty) {
      errors['type'] = '영수증 종류를 선택해주세요.';
    }

    if (receiptType == 'personal') {
      if (number.isEmpty) {
        errors['number'] = receiptNumberInputType == 'phone'
            ? '휴대폰 번호를 입력해주세요.'
            : '현금영수증 카드 번호를 입력해주세요.';
      } else if (receiptNumberInputType == 'phone') {
        errors['number'] = ReceiptValidator.validatePhone(number);
      } else {
        errors['number'] = ReceiptValidator.validateCardNumber(number);
      }
    } else if (receiptType == 'business') {
      if (number.isEmpty) {
        errors['number'] = receiptNumberInputType == 'phone'
            ? '휴대폰 번호를 입력해주세요.'
            : '사업자 등록번호를 입력해주세요.';
      } else if (receiptNumberInputType == 'phone') {
        errors['number'] = ReceiptValidator.validatePhone(number);
      } else {
        errors['number'] = ReceiptValidator.validateBusinessNumber(number);
      }
    } else if (receiptType == 'tax_invoice') {
      if (number.isEmpty) {
        errors['number'] = '사업자 등록번호를 입력해주세요.';
      } else {
        errors['number'] = ReceiptValidator.validateBusinessNumber(number);
      }

      if (businessName.trim().isEmpty) {
        errors['businessName'] = '사업자명을 입력해주세요.';
      }
      if (repName.trim().isEmpty) {
        errors['repName'] = '대표자 이름을 입력해주세요.';
      }
      if (email.isNotEmpty) {
        errors['email'] = ReceiptValidator.validateEmail(email);
      }
    }

    errors.removeWhere((_, v) => v == null);
    return errors.isEmpty;
  }

  // ──────────────────────────────────────────────
  // API
  // ──────────────────────────────────────────────

  /// 영수증 설정 저장
  ///
  /// 성공 시 저장된 영수증 데이터를 반환합니다.
  /// 실패 시 [onError]를 호출하고 null을 반환합니다.
  Future<Map<String, dynamic>?> saveReceipt({
    required BuildContext context,
    required String receiptType,
    required String receiptNumberInputType,
    required String number,
    required String businessName,
    required String repName,
    required String email,
    required Map<String, String?> errors,
    required void Function(String) onError,
  }) async {
    final valid = validateFields(
      receiptType: receiptType,
      receiptNumberInputType: receiptNumberInputType,
      number: number,
      businessName: businessName,
      repName: repName,
      email: email,
      errors: errors,
    );
    if (!valid) return null;

    try {
      return await _receiptService.saveReceipt(
        type: receiptType,
        number: number,
        businessName: businessName.isNotEmpty ? businessName : null,
        repName: repName.isNotEmpty ? repName : null,
        email: email.isNotEmpty ? email : null,
      );
    } on UnauthorizedException {
      if (context.mounted) context.go('/login');
      return null;
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  /// 영수증 설정 삭제
  ///
  /// 성공 시 true 반환. 실패 시 [onError] 호출 후 false 반환.
  Future<bool> deleteReceipt({
    required BuildContext context,
    required void Function(String) onError,
  }) async {
    try {
      await _receiptService.deleteReceipt();
      return true;
    } on UnauthorizedException {
      if (context.mounted) context.go('/login');
      return false;
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

/// 영수증 편집 상태 초기화 헬퍼
///
/// 저장된 영수증 데이터로 컨트롤러 초기값을 설정합니다.
void initReceiptEditState({
  required Map<String, dynamic>? savedReceipt,
  required void Function({
    required String receiptType,
    required String receiptNumberInputType,
    required String receiptNumber,
    required String businessName,
    required String repName,
    required String email,
  }) onInit,
}) {
  onInit(
    receiptType: savedReceipt?['receiptType'] ?? '',
    receiptNumberInputType: 'phone',
    receiptNumber: savedReceipt?['receiptNumber'] ?? '',
    businessName: savedReceipt?['businessName'] ?? '',
    repName: savedReceipt?['repName'] ?? '',
    email: savedReceipt?['email'] ?? '',
  );
}
