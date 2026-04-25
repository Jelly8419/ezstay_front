import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/fee_constants.dart';
import '../../../utils/contract_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../../services/launch_status_service.dart';
import '../../../services/room_service.dart';
import '../../../widgets/common/responsive_page_layout.dart';
import '../../../widgets/common/custom_toast.dart';
import '../../../widgets/modals/benefit_result_modal.dart';
import 'steps/basic_info_step.dart';
import 'steps/photos_step.dart';
import 'steps/pricing_step.dart';
import 'steps/description_step.dart';
import 'validators/registration_validator.dart';
import 'components/registration_flow_indicator.dart';

/// 방 등록 플로우 메인 페이지
///
/// 4단계로 구성된 방 등록 프로세스를 관리:
/// 1. 기본 정보
/// 2. 사진 및 편의옵션
/// 3. 요금 설정 (청소 서비스 포함)
/// 4. 방 소개 및 안내
class RoomRegistrationFlowPage extends StatefulWidget {
  /// 편집할 방 ID (null이면 신규 등록)
  final int? roomId;

  /// 초기 시작 단계 (null이면 자동 계산)
  final int? initialStep;

  const RoomRegistrationFlowPage({super.key, this.roomId, this.initialStep});

  @override
  State<RoomRegistrationFlowPage> createState() =>
      _RoomRegistrationFlowPageState();
}

class _RoomRegistrationFlowPageState extends State<RoomRegistrationFlowPage> {
  // RoomService 인스턴스
  final _roomService = RoomService();

  // 현재 등록 중인 방 ID (null이면 신규 등록)
  int? _currentRoomId;

  // 현재 단계 (1-4)
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
    'deposit': FeeConstants.depositAmount.toString(), // 고정 보증금
    'dailyMaintenanceFee': '',
    'weeklyMaintenanceFee': '',
    'maintenanceInclusions': <String>['수도세', '전기세'],
    'maintenanceDescription': '',
    'cleaningFee': '',
    'minContractDays': '7',
    'refundPolicy': '',
    'refundPolicyConfirmed': false,
    'longTermDiscountWeeks': '',
    'longTermDiscountPercent': '',
    'earlyCheckinDiscountDays': '',
    'earlyCheckinDiscountAmount': '',

    // Step 3: 청소 서비스 (요금 설정에 포함)
    'cleaningService': false,
    'exitInspectionService': false,
    'servicePassword': '',

    // Step 4: 방 소개 및 안내
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
            final photosList = <String>[];
            final photoObjects = <Map<String, dynamic>>[];

            for (var photo in roomData['photos']) {
              final url = photo['url'] as String;
              // 상대 경로인 경우 절대 URL로 변환
              final fullUrl = ContractUtils.getFullImageUrl(url);

              photosList.add(fullUrl);
              photoObjects.add({'id': photo['id'], 'url': fullUrl});
            }

            _formData['uploadedImages'] = photosList;
            _formData['uploadedPhotos'] = photoObjects; // photoId 추적용
          }

          // amenities 객체 파싱 (Map 직접 응답 또는 JSON 문자열 이중 직렬화 모두 대응)
          if (roomData['amenities'] != null && roomData['amenities'] is Map) {
            final amenities = roomData['amenities'] as Map<String, dynamic>;
            final optionMapping = _getOptionMapping();
            final reverseMapping = {
              for (var e in optionMapping.entries) e.value: e.key,
            };

            Map<String, dynamic>? toMap(dynamic raw) {
              if (raw == null) return null;
              if (raw is Map<String, dynamic>) return raw;
              if (raw is String) {
                try {
                  dynamic decoded = jsonDecode(raw);
                  if (decoded is String) decoded = jsonDecode(decoded);
                  if (decoded is Map<String, dynamic>) return decoded;
                } catch (_) {}
              }
              return null;
            }

            // basicOptions 파싱
            final basicOptionsMap = toMap(amenities['basicOptions']);
            if (basicOptionsMap != null) {
              basicOptionsMap.forEach((englishKey, value) {
                if (englishKey == 'bed' && value is Map) {
                  final bedMap = value as Map<String, dynamic>;
                  final sizeReverseMapping = {
                    'king': '킹',
                    'queen': '퀸',
                    'single': '싱글',
                    'superSingle': '슈퍼싱글',
                  };
                  bool hasBed = false;
                  bedMap.forEach((englishSize, count) {
                    final koreanSize = sizeReverseMapping[englishSize];
                    final cnt = count is int ? count : (count as num?)?.toInt() ?? 0;
                    if (koreanSize != null && cnt > 0) {
                      hasBed = true;
                      bedSelectionsList.add({'size': koreanSize, 'count': cnt});
                    }
                  });
                  if (hasBed) basicOptionsList.add('침대');
                } else if (value == true) {
                  final koreanKey = reverseMapping[englishKey];
                  if (koreanKey != null) basicOptionsList.add(koreanKey);
                }
              });
            }

            // additionalOptions 파싱
            final additionalOptionsMap = toMap(amenities['additionalOptions']);
            if (additionalOptionsMap != null) {
              additionalOptionsMap.forEach((englishKey, value) {
                if (value == true) {
                  final koreanKey = reverseMapping[englishKey];
                  if (koreanKey != null) selectedOptionsList.add(koreanKey);
                }
              });
            }

            // convenienceOptions 파싱
            final convenienceOptionsMap = toMap(amenities['convenienceOptions']);
            if (convenienceOptionsMap != null) {
              convenienceOptionsMap.forEach((englishKey, value) {
                if (value == true) {
                  final koreanKey = reverseMapping[englishKey];
                  if (koreanKey != null) selectedOptionsList.add(koreanKey);
                }
              });
            }
          }

          _formData['basicOptions'] = basicOptionsList;
          _formData['selectedOptions'] = selectedOptionsList;
          _formData['bedSelections'] = bedSelectionsList;
          _formData['wifiPassword'] = roomData['wifiPassword'] ?? '';

          // Step 3: 요금 설정
          _formData['dailyRent'] = roomData['dailyRent']?.toString() ?? '';
          _formData['weeklyRent'] = roomData['weeklyRent']?.toString() ?? '';
          _formData['deposit'] = roomData['deposit']?.toString() ?? FeeConstants.depositAmount.toString();
          _formData['dailyMaintenanceFee'] =
              roomData['dailyMaintenanceFee']?.toString() ?? '';
          _formData['weeklyMaintenanceFee'] =
              roomData['weeklyMaintenanceFee']?.toString() ?? '';
          final inclusions = <String>[];
          if (roomData['includeElectricity'] == true) inclusions.add('전기세');
          if (roomData['includeWater'] == true) inclusions.add('수도세');
          if (roomData['includeGas'] == true) inclusions.add('가스비');
          if (roomData['includeInternet'] == true) inclusions.add('인터넷');
          _formData['maintenanceInclusions'] = inclusions;
          _formData['maintenanceDescription'] =
              roomData['maintenanceDetail'] ?? '';
          _formData['cleaningFee'] = roomData['cleaningFee']?.toString() ?? '';
          _formData['minContractDays'] =
              roomData['minContractDays']?.toString() ?? '7';
          _formData['refundPolicy'] = roomData['refundPolicy'] ?? '';
          _formData['longTermDiscountWeeks'] =
              roomData['longTermWeeks']?.toString() ?? '';
          _formData['longTermDiscountPercent'] =
              roomData['longTermDiscount']?.toString() ?? '';
          _formData['earlyCheckinDiscountDays'] =
              roomData['quickMoveIn']?.toString() ?? '';
          _formData['earlyCheckinDiscountAmount'] =
              roomData['quickMoveInDiscount']?.toString() ?? '';

          // Step 4: 이지스테이 관리 서비스 (API ezService 객체에서 가져오기)
          if (roomData['ezService'] != null && roomData['ezService'] is Map) {
            final ezServices = roomData['ezService'] as Map<String, dynamic>;

            // API 필드명 → Frontend 필드명 매핑
            _formData['cleaningService'] =
                ezServices['cleaningService'] ?? false;
            _formData['exitInspectionService'] =
                ezServices['autoPasswordChange'] ??
                false; // API: autoPasswordChange
            _formData['servicePassword'] =
                ezServices['roomPassword'] ?? ''; // API: roomPassword

          }

          // Step 4: 방 소개
          _formData['maxGuests'] = roomData['maxGuests']?.toString() ?? '';
          _formData['checkInTime'] = roomData['checkInTime'] ?? '14:00';
          _formData['checkOutTime'] = roomData['checkOutTime'] ?? '11:00';
          _formData['propertyDescription'] =
              roomData['description'] ?? roomData['propertyDescription'] ?? '';

          // initialStep이 지정되면 우선 적용, 아니면 진행 상태에 따라 계산
          _currentStep = widget.initialStep ?? _calculateCurrentStep(roomData);
        });

      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ 등록 중인 데이터 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// registrationProgress를 분석하여 현재 진행 중인 단계 계산
  int _calculateCurrentStep(Map<String, dynamic> roomData) {
    final progress = roomData['registrationProgress'];

    // registrationProgress가 없으면 1단계부터 시작
    if (progress == null) {
      return 1;
    }

    final steps = progress['steps'] as Map<String, dynamic>?;

    // steps 정보가 없으면 1단계부터 시작
    if (steps == null) {
      return 1;
    }

    // 완료되지 않은 첫 번째 단계를 찾음
    if (steps['basicInfo'] == false) {
      return 1;
    } else if (steps['photosAndAmenities'] == false) {
      return 2;
    } else if (steps['pricing'] == false) {
      return 3;
    } else if (steps['description'] == false) {
      return 4;
    } else {
      // 모든 단계 완료 → 마지막 단계로 이동 (재확인용)
      return 4;
    }
  }

  // formData 키 → 에러 메시지 키워드 매핑
  static const _fieldToErrorKeywords = <String, List<String>>{
    'roomName': ['방 이름'],
    'address': ['주소'],
    'detailAddress': ['상세 주소'],
    'floor': ['층 수'],
    'buildingType': ['건물 종류', '건물 유형'],
    'area': ['면적', '전용 면적'],
    'roomCount': ['방 개수'],
    'bathroomCount': ['화장실 개수'],
    'parkingAvailable': ['주차 여부'],
    'elevatorAvailable': ['엘리베이터'],
    'entrancePassword': ['공동현관 비밀번호'],
    'uploadedImages': ['사진'],
    'basicOptions': ['기본 옵션'],
    'bedSelections': ['침대'],
    'dailyRent': ['임대료'],
    'cleaningFee': ['청소비'],
    'minContractDays': ['최소 계약 기간'],
    'refundPolicy': ['환불 정책'],
    'longTermDiscountWeeks': ['장기 할인 주'],
    'longTermDiscountPercent': ['장기 할인 퍼센트'],
    'earlyCheckinDiscountDays': ['조기 입주 할인 일'],
    'earlyCheckinDiscountAmount': ['조기 입주 할인 금액'],
    'servicePassword': ['비밀번호'],
    'maxGuests': ['최대 인원'],
    'propertyDescription': ['방 소개'],
  };

  /// 폼 데이터 업데이트 핸들러
  void _handleFormDataChange(Map<String, dynamic> newData) {
    setState(() {
      // 실제로 값이 변경된 키만 추출 (newData는 전체 formData 복사본이므로 비교 필요)
      final changedKeys = <String>{};
      for (final key in newData.keys) {
        final oldValue = _formData[key];
        final newValue = newData[key];
        if (oldValue != newValue) {
          changedKeys.add(key);
        }
      }

      _formData.addAll(newData);

      // 변경된 필드에 해당하는 에러만 제거
      if (_currentStepErrors.isNotEmpty && changedKeys.isNotEmpty) {
        _currentStepErrors = _currentStepErrors.where((error) {
          return !changedKeys.any((key) {
            final keywords = _fieldToErrorKeywords[key];
            if (keywords == null) return false;
            return keywords.any((kw) => error.contains(kw));
          });
        }).toList();
      }
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
      // 첫 번째 에러 메시지를 토스트로 표시
      if (_currentStepErrors.isNotEmpty) {
        CustomToast.error(context, _currentStepErrors.first);
      } else {
        CustomToast.error(context, '입력하신 정보를 다시 확인해주세요');
      }
      return;
    }

    // 2. API에 현재 단계 데이터 저장
    setState(() => _isLoading = true);
    try {
      await _saveCurrentStepToApi();

      // 저장 성공 토스트 (마지막 단계 제외)
      if (_currentStep < 4 && mounted) {
        CustomToast.success(context, '저장되었습니다');
      }

      // 3. 다음 단계로 이동
      if (_currentStep < 4) {
        setState(() {
          _currentStep++;
          _currentStepErrors = [];
        });
      } else {
        // 마지막 단계: 심사 요청
        await _submitForReview();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
        }
        break;

      case 2:
        // Step 2: 사진 및 편의옵션 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        bool photosSuccess = true;
        bool amenitiesSuccess = false;

        // 1. 사진 삭제 API 호출 (삭제된 사진들)
        final deletedPhotoIds =
            _formData['deletedPhotoIds'] as List<int>? ?? [];
        if (deletedPhotoIds.isNotEmpty) {
          for (final photoId in deletedPhotoIds) {
            final deleteResult = await _roomService.deletePhoto(
              _currentRoomId!,
              photoId,
            );
            if (!deleteResult) {
              AppLogger.w('⚠️ 사진 삭제 실패: photoId=$photoId');
            } else {
            }
          }
          // 삭제 완료 후 deletedPhotoIds 초기화
          _formData['deletedPhotoIds'] = [];
        }

        // 2. 사진 업로드 API 호출 (새로 추가된 이미지만)
        final rawXFiles = _formData['uploadedXFiles'];
        final uploadedXFiles = rawXFiles is List
            ? rawXFiles.whereType<XFile>().toList()
            : <XFile>[];
        final uploadedImages =
            _formData['uploadedImages'] as List<dynamic>? ?? [];

        // 이미 업로드된 이미지 개수 (URL 형식)
        final existingImageCount = uploadedImages
            .where(
              (img) =>
                  img is String &&
                  (img.startsWith('http') || img.startsWith('/')),
            )
            .length;

        // 새로 추가된 XFile만 필터링 (uploadedImages의 기존 URL 개수를 제외)
        final newXFiles = uploadedXFiles
            .skip(0)
            .take(
              uploadedXFiles.length > existingImageCount
                  ? uploadedXFiles.length - existingImageCount
                  : uploadedXFiles.length,
            )
            .toList();

        if (newXFiles.isNotEmpty) {
          final photoResult = await _roomService.uploadPhotos(
            _currentRoomId!,
            newXFiles,
          );

          if (photoResult == null) {
            photosSuccess = false;
            throw Exception('사진 업로드 실패');
          }

          // 업로드 성공 후 uploadedXFiles 초기화 (중복 업로드 방지)
          _formData['uploadedXFiles'] = [];

          // uploadedPhotos에 새로 업로드된 사진 정보 추가
          final uploadedPhotos =
              _formData['uploadedPhotos'] as List<dynamic>? ?? [];
          for (var photo in photoResult) {
            uploadedPhotos.add({'id': photo['id'], 'url': photo['url']});
          }
          _formData['uploadedPhotos'] = uploadedPhotos;

        } else {
          AppLogger.w('⚠️ 새로 추가된 사진이 없습니다 (기존: $existingImageCount개)');
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


        // 4. 편의시설 저장 API 호출
        amenitiesSuccess = await _roomService.updateAmenities(
          _currentRoomId!,
          amenitiesData,
        );

        if (!amenitiesSuccess) {
          throw Exception('편의시설 설정 실패');
        }


        // 5. 사진과 편의시설 모두 성공한 경우에만 진행
        if (!photosSuccess || !amenitiesSuccess) {
          throw Exception('사진 업로드 또는 편의시설 설정 실패');
        }

        break;

      case 3:
        // Step 3: 요금 설정 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        final pricingData = {
          'dailyRent': int.tryParse(_formData['dailyRent'] ?? ''),
          'weeklyRent': int.tryParse(_formData['weeklyRent'] ?? ''),
          'deposit': int.tryParse(_formData['deposit'] ?? FeeConstants.depositAmount.toString()),
          'dailyMaintenanceFee': int.tryParse(
            _formData['dailyMaintenanceFee'] ?? '',
          ),
          'weeklyMaintenanceFee': int.tryParse(
            _formData['weeklyMaintenanceFee'] ?? '',
          ),
          'includeElectricity': (_formData['maintenanceInclusions'] as List?)?.contains('전기세') ?? false,
          'includeWater': (_formData['maintenanceInclusions'] as List?)?.contains('수도세') ?? false,
          'includeGas': (_formData['maintenanceInclusions'] as List?)?.contains('가스비') ?? false,
          'includeInternet': (_formData['maintenanceInclusions'] as List?)?.contains('인터넷') ?? false,
          'maintenanceDetail': _formData['maintenanceDescription'],
          'cleaningFee': int.tryParse(_formData['cleaningFee'] ?? ''),
          'minContractDays': int.tryParse(_formData['minContractDays'] ?? '7'),
          'refundPolicy': _formData['refundPolicy'],
          'longTermWeeks': int.tryParse(
            _formData['longTermDiscountWeeks'] ?? '',
          ),
          'longTermDiscount': int.tryParse(
            _formData['longTermDiscountPercent'] ?? '',
          ),
          'quickMoveIn': int.tryParse(
            _formData['earlyCheckinDiscountDays'] ?? '',
          ),
          'quickMoveInDiscount': int.tryParse(
            _formData['earlyCheckinDiscountAmount'] ?? '',
          ),
        };

        final pricingSuccess = await _roomService.updatePricing(
          _currentRoomId!,
          pricingData,
        );
        if (!pricingSuccess) {
          throw Exception('요금 설정 실패');
        }

        // 청소 서비스 데이터도 함께 저장
        final servicesData = {
          'cleaningService': _formData['cleaningService'] ?? false,
          'autoPasswordChange': false,
          'roomPassword': _formData['servicePassword'] ?? '',
        };

        final servicesSuccess = await _roomService.updateEzServices(
          _currentRoomId!,
          servicesData,
        );
        if (!servicesSuccess) {
          throw Exception('청소 서비스 설정 실패');
        }
        break;

      case 4:
        // Step 4: 방 소개 및 안내 저장
        if (_currentRoomId == null) {
          throw Exception('roomId가 없습니다. Step 1을 먼저 완료해주세요.');
        }

        final descriptionData = {
          'maxGuests': int.tryParse(_formData['maxGuests'] ?? ''),
          'description':
              _formData['propertyDescription'], // 백엔드가 'description' 필드를 기대함
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
      final resultStatus = await _roomService.submitReview(_currentRoomId!);

      if (resultStatus == null) {
        throw Exception('심사 요청 API 호출 실패');
      }

      if (!mounted) return;

      // 혜택 상태 조회 → 대상이면 모달 먼저 표시 (1회)
      final isBenefitApplied = await _roomService.getBenefitStatus();
      if (mounted && isBenefitApplied == true) {
        await BenefitResultModal.show(context);
      }

      if (!mounted) return;

      // 성공 토스트 표시
      CustomToast.success(context, '방 등록이 완료되었습니다!');

      final isPendingReview = resultStatus == 'pending_review';
      // 런칭 전에는 "할인 혜택 적용" 안내, 런칭 후에는 기존 "공개" 안내
      final isPrelaunch = context.read<LaunchStatusService>().isPrelaunch;

      // 성공 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 성공 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success600,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // 제목
              Text(
                '등록 완료',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // 설명 (pending_review일 때만 심사 안내 표시)
              Text(
                isPendingReview
                    ? '방 등록이 완료되었습니다!\n\n관리자 심사가 진행됩니다. (보통 1-2일 소요)\n${isPrelaunch ? '심사 승인 후 해당 방에 할인 혜택이 적용됩니다.' : '심사 승인 후 방이 공개됩니다.'}'
                    : '방 정보가 저장되었습니다!',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    context.go('/host'); // 호스트 홈으로 이동
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ 심사 요청 실패: $e');
      _showErrorSnackBar('심사 요청 중 오류가 발생했습니다: $e');
    }
  }

  /// 에러 토스트 표시
  void _showErrorSnackBar(String message) {
    CustomToast.error(context, message);
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
      return const Center(child: CircularProgressIndicator());
    }

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          // 진행 상태 표시 (전체 너비, 컨텐츠는 중앙)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.cardDefault,
            ),
            padding: AppSpacing.paddingMd,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: RegistrationFlowIndicator(
                  currentStep: _currentStep,
                  totalSteps: 4,
                  stepTitles: const [
                    '기본 정보',
                    '사진·편의옵션',
                    '요금 설정',
                    '방 소개',
                  ],
                ),
              ),
            ),
          ),

          // 구분선
          const Divider(height: 1),

          // 스크롤 가능한 컨텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: MaxWidthContainer(
                maxWidth: 1000,
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
                                child: Text(
                                  '이전',
                                  style: AppTextStyles.labelLarge.copyWith(
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
                                      _currentStep == 4 ? '등록 완료' : '다음',
                                      style: AppTextStyles.labelLarge.copyWith(
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
          ),
        ],
      ),
    );
  }
}
