import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../services/room_service.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import '../../../widgets/common/app_gnb.dart';
import 'steps/basic_info_step.dart';
import 'steps/photos_step.dart';
import 'steps/pricing_step.dart';
import 'steps/services_step.dart';
import 'steps/description_step.dart';
import 'validators/registration_validator.dart';
import 'components/registration_flow_indicator.dart';

/// 방 등록 플로우 메인 페이지
///
/// 5단계로 구성된 방 등록 프로세스를 관리:
/// 1. 기본 정보
/// 2. 사진 및 편의옵션
/// 3. 요금 설정
/// 4. 무료 부가 서비스
/// 5. 방 소개 및 안내
class RoomRegistrationFlowPage extends StatefulWidget {
  /// 편집할 방 ID (null이면 신규 등록)
  final int? roomId;

  const RoomRegistrationFlowPage({super.key, this.roomId});

  @override
  State<RoomRegistrationFlowPage> createState() =>
      _RoomRegistrationFlowPageState();
}

class _RoomRegistrationFlowPageState extends State<RoomRegistrationFlowPage> {
  // RoomService 인스턴스
  final _roomService = RoomService();

  // 현재 등록 중인 방 ID (null이면 신규 등록)
  int? _currentRoomId;

  // 현재 단계 (1-5)
  int _currentStep = 1;

  // 전체 폼 데이터 (모든 Step에서 공유)
  final Map<String, dynamic> _formData = {
    // Step 1: 기본 정보
    'roomName': '', // basic_info_step.dart에서 사용하는 필드명
    'address': '',
    'detailAddress': '', // basic_info_step.dart에서 사용하는 필드명
    'floor': '',
    'buildingType': '선택',
    'area': '',
    'roomCount': 1, // 기본값 1 (드롭다운 items: 1~10)
    'bathroomCount': 1, // 기본값 1 (드롭다운 items: 1~5)
    'isDuplex': false, // 복층 구조 여부
    'parkingAvailable': null, // Boolean (true/false)
    'parkingInfo': '', // 주차 상세 정보 (선택사항)
    'elevatorAvailable': null, // Boolean (true/false)
    'entrancePassword': '',

    // Step 2: 사진 및 편의옵션
    'photos': <String>[],
    'basicOptions': <String>[],
    'bedInfo': '',
    'wifiPassword': '',
    'conveniences': <String>[],

    // Step 3: 요금 설정
    'dailyRent': '',
    'weeklyRent': '',
    'deposit': '300000', // 고정 보증금
    'dailyMaintenanceFee': '',
    'weeklyMaintenanceFee': '',
    'maintenanceInclusions': <String>['수도세', '전기세'],
    'maintenanceDescription': '',
    'cleaningFee': '',
    'minContractPeriod': '1주',
    'refundPolicy': '보통',
    'longTermDiscountWeeks': '',
    'longTermDiscountPercent': '',
    'earlyCheckinDiscountDays': '',
    'earlyCheckinDiscountAmount': '',

    // Step 4: 무료 부가 서비스
    'cleaningService': false,
    'exitInspectionService': false,
    'beddingRentalService': false,
    'hairDryerRental': false,
    'amenityKitPurchase': false,
    'servicePassword': '',

    // Step 5: 방 소개 및 안내
    'maxGuests': '',
    'checkInTime': '14:00',
    'checkOutTime': '11:00',
    'propertyDescription': '',
  };

  // 현재 단계의 유효성 검증 에러 목록
  List<String> _currentStepErrors = [];

  // 로딩 상태
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // widget.roomId가 있으면 해당 방 데이터 불러오기 (이어서 등록)
    // widget.roomId가 null이면 신규 등록
    if (widget.roomId != null) {
      _currentRoomId = widget.roomId;
      _loadSavedData();
    }
  }

  /// 저장된 등록 데이터 불러오기 (API)
  Future<void> _loadSavedData() async {
    if (_currentRoomId == null) return; // roomId 없으면 신규 등록

    setState(() => _isLoading = true);
    try {
      // 방 상세 정보 조회
      final roomData = await _roomService.getRoom(_currentRoomId!);

      if (roomData != null) {
        // API 데이터를 formData로 복원 (API 필드명 -> UI 필드명 매핑)
        setState(() {
          // Step 1: 기본 정보
          _formData['roomName'] = roomData['roomName'] ?? '';
          _formData['address'] = roomData['address'] ?? '';
          _formData['detailAddress'] = roomData['detailAddress'] ?? '';
          _formData['floor'] = roomData['floor']?.toString() ?? '';
          _formData['buildingType'] = roomData['buildingType'] ?? '선택';
          _formData['area'] = roomData['area']?.toString() ?? '';
          _formData['roomCount'] = roomData['roomCount'] ?? 1;
          _formData['bathroomCount'] = roomData['bathroomCount'] ?? 1;
          _formData['isDuplex'] = roomData['isDuplex'] ?? false;
          _formData['parkingAvailable'] = roomData['parkingAvailable'];
          _formData['parkingInfo'] = roomData['parkingInfo'] ?? '';
          _formData['elevatorAvailable'] = roomData['elevatorAvailable'];
          _formData['entrancePassword'] = roomData['entrancePassword'] ?? '';

          // Step 2: 사진 및 편의옵션 (API 형식: photos 배열 + amenities JSON → UI 형식: List 변환)
          final basicOptionsList = <String>[];
          final selectedOptionsList = <String>[];
          final bedSelectionsList = <Map<String, dynamic>>[];

          // 사진 데이터 처리 (상대 경로 → 완전한 URL 변환)
          if (roomData['photos'] != null && roomData['photos'] is List) {
            final photosList = (roomData['photos'] as List<dynamic>).map((
              photo,
            ) {
              final url = photo['url'] as String;
              // 상대 경로인 경우 API_BASE_URL 추가
              if (url.startsWith('/')) {
                return '${ApiConfig.baseUrl}$url';
              }
              return url;
            }).toList();
            _formData['uploadedImages'] = photosList;
          }

          // amenities 객체에서 JSON 문자열 파싱
          if (roomData['amenities'] != null && roomData['amenities'] is Map) {
            final amenities = roomData['amenities'] as Map<String, dynamic>;
            final optionMapping = _getOptionMapping();
            final reverseMapping = {
              for (var e in optionMapping.entries) e.value: e.key,
            };

            // basicOptions JSON 문자열 파싱
            if (amenities['basicOptions'] != null &&
                amenities['basicOptions'] is String) {
              try {
                final basicOptionsMap =
                    jsonDecode(amenities['basicOptions'])
                        as Map<String, dynamic>;

                // 영어 필드명을 한글로 역변환
                basicOptionsMap.forEach((englishKey, value) {
                  if (englishKey == 'bed' && value is Map) {
                    // 침대 정보 처리
                    basicOptionsList.add('침대');
                    final bedMap = value as Map<String, dynamic>;
                    final sizeReverseMapping = {
                      'king': '킹',
                      'queen': '퀸',
                      'single': '싱글',
                      'superSingle': '슈퍼싱글',
                    };

                    bedMap.forEach((englishSize, count) {
                      final koreanSize = sizeReverseMapping[englishSize];
                      if (koreanSize != null && count > 0) {
                        bedSelectionsList.add({
                          'size': koreanSize,
                          'count': count,
                        });
                      }
                    });
                  } else if (value == true) {
                    // boolean 옵션 (true인 것만)
                    final koreanKey = reverseMapping[englishKey];
                    if (koreanKey != null) {
                      basicOptionsList.add(koreanKey);
                    }
                  }
                });
              } catch (e) {
                debugPrint('❌ basicOptions JSON 파싱 실패: $e');
              }
            }

            // additionalOptions JSON 문자열 파싱
            if (amenities['additionalOptions'] != null &&
                amenities['additionalOptions'] is String) {
              try {
                final additionalOptionsMap =
                    jsonDecode(amenities['additionalOptions'])
                        as Map<String, dynamic>;

                additionalOptionsMap.forEach((englishKey, value) {
                  if (value == true) {
                    final koreanKey = reverseMapping[englishKey];
                    if (koreanKey != null) {
                      selectedOptionsList.add(koreanKey);
                    }
                  }
                });
              } catch (e) {
                debugPrint('❌ additionalOptions JSON 파싱 실패: $e');
              }
            }

            // convenienceOptions JSON 문자열 파싱
            if (amenities['convenienceOptions'] != null &&
                amenities['convenienceOptions'] is String) {
              try {
                final convenienceOptionsMap =
                    jsonDecode(amenities['convenienceOptions'])
                        as Map<String, dynamic>;

                convenienceOptionsMap.forEach((englishKey, value) {
                  if (value == true) {
                    final koreanKey = reverseMapping[englishKey];
                    if (koreanKey != null) {
                      selectedOptionsList.add(koreanKey);
                    }
                  }
                });
              } catch (e) {
                debugPrint('❌ convenienceOptions JSON 파싱 실패: $e');
              }
            }
          }

          _formData['basicOptions'] = basicOptionsList;
          _formData['selectedOptions'] = selectedOptionsList;
          _formData['bedSelections'] = bedSelectionsList;
          _formData['wifiPassword'] = roomData['wifiPassword'] ?? '';

          // Step 3: 요금 설정
          _formData['dailyRent'] = roomData['dailyRent']?.toString() ?? '';
          _formData['weeklyRent'] = roomData['weeklyRent']?.toString() ?? '';
          _formData['deposit'] = roomData['deposit']?.toString() ?? '300000';
          _formData['dailyMaintenanceFee'] =
              roomData['dailyMaintenanceFee']?.toString() ?? '';
          _formData['weeklyMaintenanceFee'] =
              roomData['weeklyMaintenanceFee']?.toString() ?? '';
          if (roomData['maintenanceInclusions'] != null) {
            _formData['maintenanceInclusions'] = List<String>.from(
              roomData['maintenanceInclusions'],
            );
          }
          _formData['maintenanceDescription'] =
              roomData['maintenanceDescription'] ?? '';
          _formData['cleaningFee'] = roomData['cleaningFee']?.toString() ?? '';
          _formData['minContractPeriod'] =
              roomData['minContractPeriod'] ?? '1주';
          _formData['refundPolicy'] = roomData['refundPolicy'] ?? '보통';
          _formData['longTermDiscountWeeks'] =
              roomData['longTermDiscountWeeks']?.toString() ?? '';
          _formData['longTermDiscountPercent'] =
              roomData['longTermDiscountPercent']?.toString() ?? '';
          _formData['earlyCheckinDiscountDays'] =
              roomData['earlyCheckinDiscountDays'] ?? '';
          _formData['earlyCheckinDiscountAmount'] =
              roomData['earlyCheckinDiscountAmount']?.toString() ?? '';

          // Step 4: 무료 부가 서비스 (API freeServices 객체에서 가져오기)
          if (roomData['freeServices'] != null &&
              roomData['freeServices'] is Map) {
            final freeServices = roomData['freeServices'] as Map<String, dynamic>;
            debugPrint('📦 freeServices 데이터: $freeServices');

            // API 필드명 → Frontend 필드명 매핑
            _formData['cleaningService'] = freeServices['cleaningService'] ?? false;
            _formData['exitInspectionService'] =
                freeServices['autoPasswordChange'] ?? false;  // API: autoPasswordChange
            _formData['beddingRentalService'] =
                freeServices['beddingService'] ?? false;  // API: beddingService
            _formData['hairDryerRental'] = freeServices['hairDryerRental'] ?? false;
            _formData['amenityKitPurchase'] =
                freeServices['amenityKit'] ?? false;  // API: amenityKit
            _formData['servicePassword'] =
                freeServices['roomPassword'] ?? '';  // API: roomPassword

            debugPrint('✅ servicePassword 로드: ${_formData['servicePassword']}');
          }

          // Step 5: 방 소개
          _formData['maxGuests'] = roomData['maxGuests']?.toString() ?? '';
          _formData['checkInTime'] = roomData['checkInTime'] ?? '14:00';
          _formData['checkOutTime'] = roomData['checkOutTime'] ?? '11:00';
          _formData['propertyDescription'] =
              roomData['propertyDescription'] ?? '';

          // 진행 상태에 따라 현재 단계 설정
          _currentStep = _calculateCurrentStep(roomData);
        });

        debugPrint('✅ 저장된 등록 데이터 복원 완료 - roomId: $_currentRoomId');
      }
    } catch (e) {
      debugPrint('❌ 등록 중인 데이터 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// registrationProgress를 분석하여 현재 진행 중인 단계 계산
  int _calculateCurrentStep(Map<String, dynamic> roomData) {
    final progress = roomData['registrationProgress'];

    // registrationProgress가 없으면 1단계부터 시작
    if (progress == null) {
      debugPrint('📍 registrationProgress 없음 → Step 1부터 시작');
      return 1;
    }

    final steps = progress['steps'] as Map<String, dynamic>?;

    // steps 정보가 없으면 1단계부터 시작
    if (steps == null) {
      debugPrint('📍 steps 정보 없음 → Step 1부터 시작');
      return 1;
    }

    // 완료되지 않은 첫 번째 단계를 찾음
    if (steps['basicInfo'] == false) {
      debugPrint('📍 basicInfo 미완료 → Step 1로 이동');
      return 1;
    } else if (steps['photosAndAmenities'] == false) {
      debugPrint('📍 photosAndAmenities 미완료 → Step 2로 이동');
      return 2;
    } else if (steps['pricing'] == false) {
      debugPrint('📍 pricing 미완료 → Step 3으로 이동');
      return 3;
    } else if (steps['freeServices'] == false) {
      debugPrint('📍 freeServices 미완료 → Step 4로 이동');
      return 4;
    } else if (steps['description'] == false) {
      debugPrint('📍 description 미완료 → Step 5로 이동');
      return 5;
    } else {
      // 모든 단계 완료 → 마지막 단계로 이동 (재확인용)
      debugPrint('📍 모든 단계 완료 → Step 5로 이동 (재확인)');
      return 5;
    }
  }

  /// 폼 데이터 업데이트 핸들러
  void _handleFormDataChange(Map<String, dynamic> newData) {
    setState(() {
      _formData.addAll(newData);
    });
  }

  /// 현재 단계 검증
  bool _validateCurrentStep() {
    List<String> errors = [];

    switch (_currentStep) {
      case 1:
        errors = RegistrationValidator.validateBasicInfo(_formData);
        break;
      case 2:
        errors = RegistrationValidator.validatePhotos(_formData);
        break;
      case 3:
        errors = RegistrationValidator.validatePricing(_formData);
        break;
      case 4:
        errors = RegistrationValidator.validateServices(_formData);
        break;
      case 5:
        errors = RegistrationValidator.validateDescription(_formData);
        break;
    }

    setState(() {
      _currentStepErrors = errors;
    });

    return errors.isEmpty;
  }

  /// 다음 단계로 이동
  Future<void> _handleNext() async {
    // 1. 현재 단계 검증
    if (!_validateCurrentStep()) {
      _showErrorSnackBar('입력하신 정보를 다시 확인해주세요');
      return;
    }

    // 2. API에 현재 단계 데이터 저장
    setState(() => _isLoading = true);
    try {
      await _saveCurrentStepToApi();

      // 3. 다음 단계로 이동
      if (_currentStep < 5) {
        setState(() {
          _currentStep++;
          _currentStepErrors = [];
        });
      } else {
        // 마지막 단계: 심사 요청
        await _submitForReview();
      }
    } catch (e) {
      _showErrorSnackBar('저장 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 이전 단계로 이동
  void _handlePrevious() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _currentStepErrors = [];
      });
    }
  }

  /// 한글 옵션명을 영문 필드명으로 매핑
  Map<String, String> _getOptionMapping() {
    return {
      '냉장고': 'refrigerator',
      '세탁기': 'washingMachine',
      '에어컨': 'airConditioner',
      '싱크대': 'sink',
      'TV': 'tv',
      '인터넷(wi-fi)': 'internet',
      '침대': 'bed', // 침대 매핑 추가
      '도어락': 'doorLock',
      'CCTV': 'cctv',
      '관리실': 'managementOffice',
      '가스레인지': 'gasRange',
      '인덕션': 'induction',
      '전자레인지': 'microwave',
      '식탁': 'diningTable',
      '신발장': 'shoeRack',
      '옷장': 'wardrobe',
      '드레스룸': 'dressRoom',
      '화장대': 'vanity',
      '케이블 TV': 'cableTv',
      '소파': 'sofa',
      '책상': 'desk',
      '커튼': 'curtain',
      '발코니/베란다': 'balcony',
      '냉난방기': 'heatingCooling',
      '히터': 'heater',
      '공기청정기': 'airPurifier',
      '건조기': 'dryer',
      '다리미': 'iron',
      '정수기': 'waterPurifier',
      '전기밥솥': 'riceCooker',
      '전기포트': 'electricKettle',
      '식기': 'dishes',
      '조리도구': 'cookware',
      '욕조': 'bathtub',
      '헤어드라이기': 'hairDryer',
      '비데': 'bidet',
      '반려동물 가능': 'petsAllowed',
    };
  }

  /// 현재 단계 데이터를 API에 저장
  Future<void> _saveCurrentStepToApi() async {
    switch (_currentStep) {
      case 1:
        // Step 1: 기본 정보 저장
        final basicInfoData = {
          'roomName': _formData['roomName'], // UI 필드명 -> API 필드명 매핑
          'address': _formData['address'],
          'detailAddress': _formData['detailAddress'],
          'floor': int.tryParse(_formData['floor']?.toString() ?? ''),
          'buildingType': _formData['buildingType'],
          'area': double.tryParse(_formData['area']?.toString() ?? ''),
          'roomCount': _formData['roomCount'] is int
              ? _formData['roomCount']
              : int.tryParse(_formData['roomCount']?.toString() ?? '1'),
          'bathroomCount': _formData['bathroomCount'] is int
              ? _formData['bathroomCount']
              : int.tryParse(_formData['bathroomCount']?.toString() ?? '1'),
          'isDuplex': _formData['isDuplex'] ?? false,
          'parkingAvailable': _formData['parkingAvailable'],
          'parkingInfo': _formData['parkingInfo'] ?? '',
          'elevatorAvailable': _formData['elevatorAvailable'],
          'entrancePassword': _formData['entrancePassword'] ?? '',
        };

        if (_currentRoomId == null) {
          // 신규 방 등록
          final result = await _roomService.createRoom(basicInfoData);
          if (result != null) {
            _currentRoomId = result['roomId'];
            debugPrint('✅ Step 1 저장 완료 - 새 roomId: $_currentRoomId');
          } else {
            throw Exception('방 생성 실패');
          }
        } else {
          // 기존 방 수정
          final result = await _roomService.updateRoom(
            _currentRoomId!,
            basicInfoData,
          );
          if (result == null) {
            throw Exception('방 수정 실패');
          }
          debugPrint('✅ Step 1 저장 완료 - roomId: $_currentRoomId');
        }
        break;

      case 2:
        // Step 2: 사진 및 편의옵션 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        bool photosSuccess = true;
        bool amenitiesSuccess = false;

        // 1. 사진 업로드 API 호출
        final uploadedXFiles =
            _formData['uploadedXFiles'] as List<XFile>? ?? [];
        if (uploadedXFiles.isNotEmpty) {
          debugPrint('📸 사진 업로드 시작: ${uploadedXFiles.length}개');
          final photoResult = await _roomService.uploadPhotos(
            _currentRoomId!,
            uploadedXFiles,
          );

          if (photoResult == null) {
            photosSuccess = false;
            throw Exception('사진 업로드 실패');
          }
          debugPrint('✅ 사진 업로드 성공: ${photoResult.length}개');
        } else {
          debugPrint('⚠️ 업로드할 사진이 없습니다');
        }

        // 2. 편의시설 데이터 변환 (한글 → 영문 필드명)
        final optionMapping = _getOptionMapping();

        // basicOptions 변환
        final basicOptionsMap = <String, dynamic>{};
        final basicOptionsList =
            _formData['basicOptions'] as List<dynamic>? ?? [];

        // 기본 옵션 처리 (boolean)
        for (var key in ['냉장고', '세탁기', '에어컨', '싱크대', 'TV', '인터넷(wi-fi)']) {
          final englishKey = optionMapping[key];
          if (englishKey != null) {
            basicOptionsMap[englishKey] = basicOptionsList.contains(key);
          }
        }

        // 침대 정보 처리 (중첩 객체 - 영어 필드명)
        if (basicOptionsList.contains('침대')) {
          final bedSelections =
              _formData['bedSelections'] as List<dynamic>? ?? [];
          final bedMap = {
            'king': 0, // 킹 → king
            'queen': 0, // 퀸 → queen
            'single': 0, // 싱글 → single
            'superSingle': 0, // 슈퍼싱글 → superSingle
          };

          // 한글 사이즈를 영어로 매핑
          final sizeMapping = {
            '킹': 'king',
            '퀸': 'queen',
            '싱글': 'single',
            '슈퍼싱글': 'superSingle',
          };

          for (var bed in bedSelections) {
            final koreanSize = bed['size'] as String;
            final englishSize = sizeMapping[koreanSize];
            final count = bed['count'] as int;
            if (englishSize != null) {
              bedMap[englishSize] = count;
            }
          }

          basicOptionsMap['bed'] = bedMap; // '침대' → 'bed'
        }

        // additionalOptions와 convenienceOptions 분류
        final additionalOptionsMap = <String, dynamic>{};
        final convenienceOptionsMap = <String, dynamic>{};
        final selectedOptions =
            _formData['selectedOptions'] as List<dynamic>? ?? [];

        // additionalOptions에 속하는 옵션들
        final additionalKeys = [
          '도어락',
          'CCTV',
          '관리실',
          '가스레인지',
          '인덕션',
          '전자레인지',
          '식탁',
          '신발장',
          '옷장',
          '드레스룸',
          '화장대',
          '케이블 TV',
          '소파',
          '책상',
          '커튼',
          '발코니/베란다',
          '반려동물 가능',
        ];

        // convenienceOptions에 속하는 옵션들
        final convenienceKeys = [
          '냉난방기',
          '히터',
          '공기청정기',
          '건조기',
          '다리미',
          '정수기',
          '전기밥솥',
          '전기포트',
          '식기',
          '조리도구',
          '욕조',
          '헤어드라이기',
          '비데',
        ];

        for (var key in additionalKeys) {
          final englishKey = optionMapping[key];
          if (englishKey != null) {
            additionalOptionsMap[englishKey] = selectedOptions.contains(key);
          }
        }

        for (var key in convenienceKeys) {
          final englishKey = optionMapping[key];
          if (englishKey != null) {
            convenienceOptionsMap[englishKey] = selectedOptions.contains(key);
          }
        }

        // 3. API 요청 데이터 구성
        final amenitiesData = {
          'basicOptions': basicOptionsMap,
          'additionalOptions': additionalOptionsMap,
          'convenienceOptions': convenienceOptionsMap,
          'wifiPassword': _formData['wifiPassword'],
        };

        debugPrint('📤 편의시설 API 요청 데이터: $amenitiesData');

        // 4. 편의시설 저장 API 호출
        amenitiesSuccess = await _roomService.updateAmenities(
          _currentRoomId!,
          amenitiesData,
        );

        if (!amenitiesSuccess) {
          throw Exception('편의시설 설정 실패');
        }

        debugPrint('✅ 편의시설 설정 성공');

        // 5. 사진과 편의시설 모두 성공한 경우에만 진행
        if (!photosSuccess || !amenitiesSuccess) {
          throw Exception('사진 업로드 또는 편의시설 설정 실패');
        }

        debugPrint('✅ Step 2 저장 완료 (사진 + 편의시설 모두 성공)');
        break;

      case 3:
        // Step 3: 요금 설정 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        final pricingData = {
          'dailyRent': int.tryParse(_formData['dailyRent'] ?? ''),
          'weeklyRent': int.tryParse(_formData['weeklyRent'] ?? ''),
          'deposit': int.tryParse(_formData['deposit'] ?? '300000'),
          'dailyMaintenanceFee': int.tryParse(
            _formData['dailyMaintenanceFee'] ?? '',
          ),
          'weeklyMaintenanceFee': int.tryParse(
            _formData['weeklyMaintenanceFee'] ?? '',
          ),
          'maintenanceInclusions': _formData['maintenanceInclusions'] ?? [],
          'maintenanceDescription': _formData['maintenanceDescription'],
          'cleaningFee': int.tryParse(_formData['cleaningFee'] ?? ''),
          'minContractPeriod': _formData['minContractPeriod'],
          'refundPolicy': _formData['refundPolicy'],
          'longTermDiscountWeeks': int.tryParse(
            _formData['longTermDiscountWeeks'] ?? '0',
          ),
          'longTermDiscountPercent': int.tryParse(
            _formData['longTermDiscountPercent'] ?? '0',
          ),
          'earlyCheckinDiscountDays': _formData['earlyCheckinDiscountDays'],
          'earlyCheckinDiscountAmount': int.tryParse(
            _formData['earlyCheckinDiscountAmount'] ?? '0',
          ),
        };

        final pricingSuccess = await _roomService.updatePricing(
          _currentRoomId!,
          pricingData,
        );
        if (!pricingSuccess) {
          throw Exception('요금 설정 실패');
        }
        debugPrint('✅ Step 3 저장 완료');
        break;

      case 4:
        // Step 4: 무료 부가 서비스 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        // Frontend → API 필드명 매핑
        final servicesData = {
          'cleaningService': _formData['cleaningService'] ?? false,
          'autoPasswordChange': _formData['exitInspectionService'] ?? false,  // API 필드명
          'beddingService': _formData['beddingRentalService'] ?? false,  // API 필드명
          'hairDryerRental': _formData['hairDryerRental'] ?? false,
          'amenityKit': _formData['amenityKitPurchase'] ?? false,  // API 필드명
          'roomPassword': _formData['servicePassword'],  // API 필드명
        };

        final servicesSuccess = await _roomService.updateFreeServices(
          _currentRoomId!,
          servicesData,
        );
        if (!servicesSuccess) {
          throw Exception('무료 부가 서비스 설정 실패');
        }
        debugPrint('✅ Step 4 저장 완료');
        break;

      case 5:
        // Step 5: 방 소개 및 안내 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        final descriptionData = {
          'maxGuests': int.tryParse(_formData['maxGuests'] ?? ''),
          'description': _formData['propertyDescription'],  // 백엔드가 'description' 필드를 기대함
          // checkInTime, checkOutTime은 백엔드가 아직 처리하지 않으므로 주석 처리
          // 'checkInTime': _formData['checkInTime'],
          // 'checkOutTime': _formData['checkOutTime'],
        };

        final descriptionSuccess = await _roomService.updateDescription(
          _currentRoomId!,
          descriptionData,
        );
        if (!descriptionSuccess) {
          throw Exception('방 소개 설정 실패');
        }
        debugPrint('✅ Step 5 저장 완료');
        break;
    }
  }

  /// 심사 요청
  Future<void> _submitForReview() async {
    if (_currentRoomId == null) {
      _showErrorSnackBar('방 정보가 없습니다. 처음부터 다시 시작해주세요.');
      return;
    }

    try {
      // API로 심사 요청
      final success = await _roomService.submitReview(_currentRoomId!);

      if (!success) {
        throw Exception('심사 요청 API 호출 실패');
      }

      debugPrint('✅ 심사 요청 완료 - roomId: $_currentRoomId');

      if (!mounted) return;

      // 성공 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('등록 완료'),
          content: const Text(
            '방 등록이 완료되었습니다!\n\n'
            '관리자 심사가 진행됩니다. (보통 1-2일 소요)\n'
            '심사 승인 후 매물이 공개됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                context.go('/host'); // 호스트 홈으로 이동
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ 심사 요청 실패: $e');
      _showErrorSnackBar('심사 요청 중 오류가 발생했습니다: $e');
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 현재 단계에 맞는 Step 위젯 반환
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return BasicInfoStep(
          formData: _formData,
          onFormDataChange: _handleFormDataChange,
          validationErrors: _currentStepErrors,
        );
      case 2:
        return PhotosStep(
          formData: _formData,
          onFormDataChange: _handleFormDataChange,
          validationErrors: _currentStepErrors,
        );
      case 3:
        return PricingStep(
          formData: _formData,
          onFormDataChange: _handleFormDataChange,
          validationErrors: _currentStepErrors,
        );
      case 4:
        return ServicesStep(
          formData: _formData,
          onFormDataChange: _handleFormDataChange,
        );
      case 5:
        return DescriptionStep(
          formData: _formData,
          onFormDataChange: _handleFormDataChange,
          validationErrors: _currentStepErrors,
        );
      default:
        return const Center(child: Text('잘못된 단계입니다'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGNB(),
      body: MaxWidthContainer(
        maxWidth: 1000,
        child: Column(
          children: [
            // 진행 상태 표시
            Container(
              color: Colors.white,
              padding: AppSpacing.paddingMd,
              child: RegistrationFlowIndicator(
                currentStep: _currentStep,
                totalSteps: 5,
                stepTitles: const [
                  '기본 정보',
                  '사진·편의옵션',
                  '요금 설정',
                  '무료 부가 서비스',
                  '방 소개',
                ],
              ),
            ),

            // 구분선
            const Divider(height: 1),

            // 스크롤 가능한 컨텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // 현재 Step 컨텐츠
                    _buildCurrentStep(),

                    const SizedBox(height: 32),

                    // 하단 네비게이션 버튼
                    Padding(
                      padding: AppSpacing.paddingMd,
                      child: Row(
                        children: [
                          // 이전 버튼
                          if (_currentStep > 1)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _handlePrevious,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.gray300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '이전',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          if (_currentStep > 1) const SizedBox(width: 12),

                          // 다음/완료 버튼
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 5 ? '등록 완료' : '다음',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 하단 추가 여백
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
