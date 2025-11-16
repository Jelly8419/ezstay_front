/// 방 등록 유효성 검증 로직
///
/// 각 Step의 formData를 검증하여 에러 메시지 리스트 반환
class RegistrationValidator {
  /// Step 1: 기본 정보 검증
  static List<String> validateBasicInfo(Map<String, dynamic> formData) {
    final errors = <String>[];

    // 건물 종류
    final buildingType = formData['buildingType'] as String?;
    if (buildingType == null || buildingType.isEmpty || buildingType == '선택') {
      errors.add('건물 종류를 선택해주세요');
    }

    // 주소
    final address = formData['address'] as String?;
    if (address == null || address.isEmpty) {
      errors.add('주소를 입력해주세요');
    }

    final detailAddress = formData['detailAddress'] as String?;
    if (detailAddress == null || detailAddress.isEmpty) {
      errors.add('상세 주소를 입력해주세요');
    }

    // 방 이름
    final roomName = formData['roomName'] as String?;
    if (roomName == null || roomName.isEmpty) {
      errors.add('방 이름을 입력해주세요');
    } else if (roomName.length < 2) {
      errors.add('방 이름을 2글자 이상 입력해주세요');
    }

    // 면적
    final area = formData['area'] as String?;
    if (area == null || area.isEmpty) {
      errors.add('면적을 입력해주세요');
    } else {
      final areaValue = double.tryParse(area);
      if (areaValue == null || areaValue <= 0) {
        errors.add('올바른 면적을 입력해주세요');
      }
    }

    // 방 개수 (int 또는 String)
    final roomCount = formData['roomCount'];
    if (roomCount == null) {
      errors.add('방 개수를 입력해주세요');
    } else {
      final roomCountValue = roomCount is int ? roomCount : int.tryParse(roomCount.toString());
      if (roomCountValue == null || roomCountValue <= 0) {
        errors.add('올바른 방 개수를 입력해주세요');
      }
    }

    // 화장실 개수 (int 또는 String)
    final bathroomCount = formData['bathroomCount'];
    if (bathroomCount == null) {
      errors.add('화장실 개수를 입력해주세요');
    } else {
      final bathroomCountValue = bathroomCount is int ? bathroomCount : int.tryParse(bathroomCount.toString());
      if (bathroomCountValue == null || bathroomCountValue <= 0) {
        errors.add('올바른 화장실 개수를 입력해주세요');
      }
    }

    // 주차 여부
    final parkingAvailable = formData['parkingAvailable'];
    if (parkingAvailable == null) {
      errors.add('주차 여부를 선택해주세요');
    }

    // 엘리베이터
    final elevatorAvailable = formData['elevatorAvailable'];
    if (elevatorAvailable == null) {
      errors.add('엘리베이터를 선택해주세요');
    }

    return errors;
  }

  /// Step 2: 사진 및 편의옵션 검증
  static List<String> validatePhotos(Map<String, dynamic> formData) {
    final errors = <String>[];

    // 사진 (최소 5장)
    final photos = formData['photos'] as List<String>?;
    if (photos == null || photos.isEmpty) {
      errors.add('사진을 최소 5장 이상 업로드해주세요');
    } else if (photos.length < 5) {
      errors.add('사진을 최소 5장 이상 업로드해주세요 (현재 ${photos.length}장)');
    }

    // 기본 옵션 선택 여부 확인 (최소 1개)
    final basicOptions = formData['basicOptions'] as List<String>?;
    if (basicOptions == null || basicOptions.isEmpty) {
      errors.add('기본 옵션을 최소 1개 이상 선택해주세요');
    }

    // 침대 선택 시 침대 정보 필수
    if (basicOptions != null && basicOptions.contains('침대')) {
      final bedInfo = formData['bedInfo'] as String?;
      if (bedInfo == null || bedInfo.isEmpty) {
        errors.add('침대 종류를 선택해주세요');
      }
    }

    // 인터넷(wi-fi) 선택 시 비밀번호 필수
    if (basicOptions != null && basicOptions.contains('인터넷(wi-fi)')) {
      final wifiPassword = formData['wifiPassword'] as String?;
      if (wifiPassword == null || wifiPassword.isEmpty) {
        errors.add('Wi-Fi 비밀번호를 입력해주세요');
      }
    }

    return errors;
  }

  /// Step 3: 요금 설정 검증
  static List<String> validatePricing(Map<String, dynamic> formData) {
    final errors = <String>[];

    // 일일 임대료
    final dailyRent = formData['dailyRent'] as String?;
    if (dailyRent == null || dailyRent.isEmpty) {
      errors.add('일일 임대료를 입력해주세요');
    } else {
      final dailyRentValue = int.tryParse(dailyRent);
      if (dailyRentValue == null || dailyRentValue <= 0) {
        errors.add('올바른 일일 임대료를 입력해주세요');
      } else if (dailyRentValue % 1000 != 0) {
        errors.add('일일 임대료는 천원 단위로 입력해주세요');
      }
    }

    // 주간 임대료
    final weeklyRent = formData['weeklyRent'] as String?;
    if (weeklyRent == null || weeklyRent.isEmpty) {
      errors.add('주간 임대료를 입력해주세요');
    } else {
      final weeklyRentValue = int.tryParse(weeklyRent);
      if (weeklyRentValue == null || weeklyRentValue <= 0) {
        errors.add('올바른 주간 임대료를 입력해주세요');
      }
    }

    // 보증금 (고정 300,000원이므로 검증 불필요)

    // 일일 관리비
    final dailyMaintenanceFee = formData['dailyMaintenanceFee'] as String?;
    if (dailyMaintenanceFee == null || dailyMaintenanceFee.isEmpty) {
      errors.add('일일 관리비를 입력해주세요');
    } else {
      final feeValue = int.tryParse(dailyMaintenanceFee);
      if (feeValue == null || feeValue < 0) {
        errors.add('올바른 일일 관리비를 입력해주세요');
      }
    }

    // 주간 관리비
    final weeklyMaintenanceFee = formData['weeklyMaintenanceFee'] as String?;
    if (weeklyMaintenanceFee == null || weeklyMaintenanceFee.isEmpty) {
      errors.add('주간 관리비를 입력해주세요');
    } else {
      final feeValue = int.tryParse(weeklyMaintenanceFee);
      if (feeValue == null || feeValue < 0) {
        errors.add('올바른 주간 관리비를 입력해주세요');
      }
    }

    // 청소비
    final cleaningFee = formData['cleaningFee'] as String?;
    if (cleaningFee == null || cleaningFee.isEmpty) {
      errors.add('청소비를 입력해주세요');
    } else {
      final cleaningFeeValue = int.tryParse(cleaningFee);
      if (cleaningFeeValue == null || cleaningFeeValue < 0) {
        errors.add('올바른 청소비를 입력해주세요');
      }
    }

    // 최소 계약 기간
    final minContractPeriod = formData['minContractPeriod'] as String?;
    if (minContractPeriod == null || minContractPeriod.isEmpty) {
      errors.add('최소 계약 기간을 선택해주세요');
    }

    // 환불 정책
    final refundPolicy = formData['refundPolicy'] as String?;
    if (refundPolicy == null || refundPolicy.isEmpty) {
      errors.add('환불 정책을 선택해주세요');
    }

    // 장기 할인 (선택사항이므로 값이 있을 때만 검증)
    final longTermDiscountWeeks = formData['longTermDiscountWeeks'] as String?;
    final longTermDiscountPercent =
        formData['longTermDiscountPercent'] as String?;

    if ((longTermDiscountWeeks != null && longTermDiscountWeeks.isNotEmpty) ||
        (longTermDiscountPercent != null &&
            longTermDiscountPercent.isNotEmpty)) {
      // 둘 중 하나만 입력된 경우
      if (longTermDiscountWeeks == null || longTermDiscountWeeks.isEmpty) {
        errors.add('장기 할인 주 수를 입력해주세요');
      }
      if (longTermDiscountPercent == null || longTermDiscountPercent.isEmpty) {
        errors.add('장기 할인 퍼센트를 입력해주세요');
      }

      // 값 검증
      if (longTermDiscountWeeks != null && longTermDiscountWeeks.isNotEmpty) {
        final weeksValue = int.tryParse(longTermDiscountWeeks);
        if (weeksValue == null || weeksValue <= 0) {
          errors.add('올바른 장기 할인 주 수를 입력해주세요');
        }
      }

      if (longTermDiscountPercent != null &&
          longTermDiscountPercent.isNotEmpty) {
        final percentValue = int.tryParse(longTermDiscountPercent);
        if (percentValue == null || percentValue <= 0 || percentValue > 100) {
          errors.add('올바른 장기 할인 퍼센트를 입력해주세요 (1-100)');
        }
      }
    }

    // 조기 체크인 할인 (선택사항이므로 값이 있을 때만 검증)
    final earlyCheckinDiscountDays =
        formData['earlyCheckinDiscountDays'] as String?;
    final earlyCheckinDiscountAmount =
        formData['earlyCheckinDiscountAmount'] as String?;

    if ((earlyCheckinDiscountDays != null &&
            earlyCheckinDiscountDays.isNotEmpty) ||
        (earlyCheckinDiscountAmount != null &&
            earlyCheckinDiscountAmount.isNotEmpty)) {
      // 둘 중 하나만 입력된 경우
      if (earlyCheckinDiscountDays == null ||
          earlyCheckinDiscountDays.isEmpty) {
        errors.add('조기 체크인 할인 일 수를 입력해주세요');
      }
      if (earlyCheckinDiscountAmount == null ||
          earlyCheckinDiscountAmount.isEmpty) {
        errors.add('조기 체크인 할인 금액을 입력해주세요');
      }

      // 값 검증
      if (earlyCheckinDiscountDays != null &&
          earlyCheckinDiscountDays.isNotEmpty) {
        final daysValue = int.tryParse(earlyCheckinDiscountDays);
        if (daysValue == null || daysValue <= 0) {
          errors.add('올바른 조기 체크인 할인 일 수를 입력해주세요');
        }
      }

      if (earlyCheckinDiscountAmount != null &&
          earlyCheckinDiscountAmount.isNotEmpty) {
        final amountValue = int.tryParse(earlyCheckinDiscountAmount);
        if (amountValue == null || amountValue <= 0) {
          errors.add('올바른 조기 체크인 할인 금액을 입력해주세요');
        } else if (amountValue % 10000 != 0) {
          errors.add('조기 체크인 할인 금액은 만원 단위로 입력해주세요');
        }
      }
    }

    return errors;
  }

  /// Step 4: 무료 부가서비스 검증
  static List<String> validateServices(Map<String, dynamic> formData) {
    final errors = <String>[];

    // 호스트 관리 서비스 중 하나라도 선택 시 비밀번호 필수
    final cleaningService = formData['cleaningService'] as bool? ?? false;
    final exitInspectionService =
        formData['exitInspectionService'] as bool? ?? false;

    if (cleaningService || exitInspectionService) {
      final servicePassword = formData['servicePassword'] as String?;
      if (servicePassword == null || servicePassword.isEmpty) {
        errors.add('호스트 관리 서비스를 위해 방 비밀번호를 입력해주세요');
      } else if (servicePassword.length < 4) {
        errors.add('방 비밀번호를 4자리 이상 입력해주세요');
      }
    }

    // 청소 서비스 선택 시 면적 정보 필요 (자동 계산용)
    if (cleaningService) {
      final area = formData['area'] as String?;
      if (area == null || area.isEmpty) {
        errors.add('청소 서비스 요금 계산을 위해 면적 정보가 필요합니다');
      }
    }

    return errors;
  }

  /// Step 5: 방 소개 및 안내 검증
  static List<String> validateDescription(Map<String, dynamic> formData) {
    final errors = <String>[];

    // 최대 인원
    final maxGuests = formData['maxGuests'] as String?;
    if (maxGuests == null || maxGuests.isEmpty) {
      errors.add('최대 인원을 입력해주세요');
    } else {
      final maxGuestsValue = int.tryParse(maxGuests);
      if (maxGuestsValue == null || maxGuestsValue <= 0) {
        errors.add('올바른 최대 인원을 입력해주세요');
      }
    }

    // 입주 시간 (기본값이 있으므로 검증 불필요)

    // 퇴실 시간 (기본값이 있으므로 검증 불필요)

    // 방 소개
    final propertyDescription = formData['propertyDescription'] as String?;
    if (propertyDescription == null || propertyDescription.isEmpty) {
      errors.add('방 소개를 입력해주세요');
    } else if (propertyDescription.length < 10) {
      errors.add('방 소개를 최소 10글자 이상 입력해주세요');
    }

    return errors;
  }

  /// 전체 등록 데이터 검증 (모든 Step)
  static Map<String, List<String>> validateAll(Map<String, dynamic> formData) {
    return {
      'basicInfo': validateBasicInfo(formData),
      'photos': validatePhotos(formData),
      'pricing': validatePricing(formData),
      'services': validateServices(formData),
      'description': validateDescription(formData),
    };
  }

  /// 특정 Step의 에러 개수 반환
  static int getErrorCount(List<String> errors) {
    return errors.length;
  }

  /// 모든 Step이 유효한지 확인
  static bool isAllValid(Map<String, List<String>> allErrors) {
    return allErrors.values.every((errors) => errors.isEmpty);
  }

  /// 특정 Step까지 유효한지 확인 (부분 검증)
  static bool isValidUpToStep(
      Map<String, dynamic> formData, int currentStep) {
    switch (currentStep) {
      case 1:
        return validateBasicInfo(formData).isEmpty;
      case 2:
        return validateBasicInfo(formData).isEmpty &&
            validatePhotos(formData).isEmpty;
      case 3:
        return validateBasicInfo(formData).isEmpty &&
            validatePhotos(formData).isEmpty &&
            validatePricing(formData).isEmpty;
      case 4:
        return validateBasicInfo(formData).isEmpty &&
            validatePhotos(formData).isEmpty &&
            validatePricing(formData).isEmpty &&
            validateServices(formData).isEmpty;
      case 5:
        return validateBasicInfo(formData).isEmpty &&
            validatePhotos(formData).isEmpty &&
            validatePricing(formData).isEmpty &&
            validateServices(formData).isEmpty &&
            validateDescription(formData).isEmpty;
      default:
        return false;
    }
  }
}
