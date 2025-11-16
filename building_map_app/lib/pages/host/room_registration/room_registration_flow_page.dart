import 'package:flutter/material.dart';
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
    'propertyName': '', // basic_info_step.dart에서 사용하는 필드명
    'address': '',
    'addressDetail': '', // basic_info_step.dart에서 사용하는 필드명
    'floor': '',
    'buildingType': '선택',
    'area': '',
    'roomCount': 1, // 기본값 1 (드롭다운 items: 1~10)
    'bathroomCount': 1, // 기본값 1 (드롭다운 items: 1~5)
    'isDuplex': false, // 복층 구조 여부
    'parkingAvailable': null, // Boolean (true/false)
    'parkingInfo': '', // 주차 상세 정보 (선택사항)
    'elevatorAvailable': null, // Boolean (true/false)
    'hasEntrancePassword': false,
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
          _formData['propertyName'] = roomData['roomName'] ?? '';
          _formData['address'] = roomData['address'] ?? '';
          _formData['addressDetail'] = roomData['addressDetail'] ?? '';
          _formData['floor'] = roomData['floor']?.toString() ?? '';
          _formData['buildingType'] = roomData['buildingType'] ?? '선택';
          _formData['area'] = roomData['area']?.toString() ?? '';
          _formData['roomCount'] = roomData['roomCount'] ?? 1;
          _formData['bathroomCount'] = roomData['bathroomCount'] ?? 1;
          _formData['isDuplex'] = roomData['isDuplex'] ?? false;
          _formData['parkingAvailable'] = roomData['parkingAvailable'];
          _formData['parkingInfo'] = roomData['parkingInfo'] ?? '';
          _formData['elevatorAvailable'] = roomData['elevatorAvailable'];
          _formData['hasEntrancePassword'] =
              roomData['hasEntrancePassword'] ?? false;
          _formData['entrancePassword'] = roomData['entrancePassword'] ?? '';

          // Step 2: 사진 및 편의옵션
          if (roomData['basicOptions'] != null) {
            _formData['basicOptions'] = List<String>.from(
              roomData['basicOptions'],
            );
          }
          _formData['bedInfo'] = roomData['bedInfo'] ?? '';
          _formData['wifiPassword'] = roomData['wifiPassword'] ?? '';
          if (roomData['conveniences'] != null) {
            _formData['conveniences'] = List<String>.from(
              roomData['conveniences'],
            );
          }

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

          // Step 4: 무료 부가 서비스
          _formData['cleaningService'] = roomData['cleaningService'] ?? false;
          _formData['exitInspectionService'] =
              roomData['exitInspectionService'] ?? false;
          _formData['beddingRentalService'] =
              roomData['beddingRentalService'] ?? false;
          _formData['hairDryerRental'] = roomData['hairDryerRental'] ?? false;
          _formData['amenityKitPurchase'] =
              roomData['amenityKitPurchase'] ?? false;
          _formData['servicePassword'] = roomData['servicePassword'] ?? '';

          // Step 5: 방 소개
          _formData['maxGuests'] = roomData['maxGuests']?.toString() ?? '';
          _formData['checkInTime'] = roomData['checkInTime'] ?? '14:00';
          _formData['checkOutTime'] = roomData['checkOutTime'] ?? '11:00';
          _formData['propertyDescription'] =
              roomData['propertyDescription'] ?? '';

          // 진행 상태에 따라 현재 단계 설정
          // status가 draft면 계속 진행 가능
          _currentStep = 1; // 기본적으로 1단계부터 시작
        });

        debugPrint('✅ 저장된 등록 데이터 복원 완료 - roomId: $_currentRoomId');
      }
    } catch (e) {
      debugPrint('❌ 등록 중인 데이터 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
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

  /// 현재 단계 데이터를 API에 저장
  Future<void> _saveCurrentStepToApi() async {
    switch (_currentStep) {
      case 1:
        // Step 1: 기본 정보 저장
        final basicInfoData = {
          'roomName': _formData['propertyName'], // UI 필드명 -> API 필드명 매핑
          'address': _formData['address'],
          'detailAddress': _formData['addressDetail'],
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
          'hasEntrancePassword': _formData['hasEntrancePassword'] ?? false,
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

        // 사진 업로드는 PhotosStep 내부에서 처리되므로 여기서는 편의옵션만 저장
        final amenitiesData = {
          'basicOptions': _formData['basicOptions'] ?? [],
          'bedInfo': _formData['bedInfo'],
          'wifiPassword': _formData['wifiPassword'],
          'conveniences': _formData['conveniences'] ?? [],
        };

        final amenitiesSuccess = await _roomService.updateAmenities(
          _currentRoomId!,
          amenitiesData,
        );
        if (!amenitiesSuccess) {
          throw Exception('편의시설 설정 실패');
        }
        debugPrint('✅ Step 2 저장 완료');
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

        final servicesData = {
          'cleaningService': _formData['cleaningService'] ?? false,
          'exitInspectionService': _formData['exitInspectionService'] ?? false,
          'beddingRentalService': _formData['beddingRentalService'] ?? false,
          'hairDryerRental': _formData['hairDryerRental'] ?? false,
          'amenityKitPurchase': _formData['amenityKitPurchase'] ?? false,
          'servicePassword': _formData['servicePassword'],
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
          'checkInTime': _formData['checkInTime'],
          'checkOutTime': _formData['checkOutTime'],
          'propertyDescription': _formData['propertyDescription'],
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
                Navigator.of(context).pop(); // 등록 페이지 닫기
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
                  '부가 서비스',
                  '방 소개',
                ],
              ),
            ),

            // 구분선
            const Divider(height: 1),

            // 현재 Step 컨텐츠
            Expanded(child: _buildCurrentStep()),

            // 하단 네비게이션 버튼
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: AppSpacing.paddingMd,
              child: SafeArea(
                child: Row(
                  children: [
                    // 이전 버튼
                    if (_currentStep > 1)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _handlePrevious,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.gray300),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
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
            ),
          ],
        ),
      ),
    );
  }
}
