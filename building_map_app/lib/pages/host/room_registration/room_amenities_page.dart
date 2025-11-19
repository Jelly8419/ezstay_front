import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/registration_flow_indicator.dart';
import '../../../services/room_service.dart';
import '../../../config/api_config.dart';
import 'dart:io';
import 'dart:convert';
import '../../../widgets/common/responsive_page_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_amenity_freezed.dart';
import '../../../models/amenity/basic_options.dart';
import '../../../models/amenity/additional_options.dart';
import '../../../models/amenity/convenience_options.dart';

/// 사진 및 편의시설 페이지
class RoomAmenitiesPage extends StatefulWidget {
  final int? roomId;
  const RoomAmenitiesPage({super.key, this.roomId});

  @override
  State<RoomAmenitiesPage> createState() => _RoomAmenitiesPageState();
}

class _RoomAmenitiesPageState extends State<RoomAmenitiesPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final _roomService = RoomService();
  int? _roomId;

  // 방 사진 목록
  List<XFile> _roomImages = [];
  // 서버에서 받은 사진 URL 목록 (이미 업로드된 사진)
  List<Map<String, dynamic>> _existingPhotos = [];

  // 편의시설 정보 (Freezed 모델 사용)
  RoomAmenityFreezed? _amenity;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    if (_roomId != null) {
      _loadRoomData();
    }
  }

  /// 서버에서 받은 값을 boolean으로 안전하게 변환
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  /// 저장된 방 정보 불러오기
  Future<void> _loadRoomData() async {
    if (_roomId == null) return;

    final roomData = await _roomService.getRoom(_roomId!);
    if (roomData != null && mounted) {
      setState(() {
        // 편의시설 정보가 있으면 Freezed 모델로 파싱
        if (roomData['amenities'] != null) {
          final amenitiesData = roomData['amenities'];

          try {
            // 백엔드 응답 구조에 따라 파싱
            final basicOptionsJson = _parseOptionsJson(amenitiesData['basicOptions']);
            final additionalOptionsJson = _parseOptionsJson(amenitiesData['additionalOptions']);
            final convenienceOptionsJson = _parseOptionsJson(amenitiesData['convenienceOptions']);

            // petsAllowed는 최상위 필드에서 읽기 (필터 기능 확장성)
            // 백엔드가 snake_case 또는 camelCase 사용할 수 있으므로 둘 다 대응
            final petsAllowed = _toBool(
              roomData['petAllowed'] ??
              roomData['pet_allowed'] ??
              amenitiesData['petsAllowed'] // 하위 호환성 유지
            );

            _amenity = RoomAmenityFreezed(
              roomId: _roomId!,
              basicOptions: BasicOptions.fromJson(basicOptionsJson),
              additionalOptions: AdditionalOptions.fromJson(additionalOptionsJson),
              convenienceOptions: ConvenienceOptions.fromJson(convenienceOptionsJson),
              petsAllowed: petsAllowed,
            );
          } catch (e) {
            debugPrint('⚠️ [AMENITIES] 편의시설 로드 실패: $e');
            // 기본값으로 초기화
            _amenity = RoomAmenityFreezed(
              roomId: _roomId!,
              basicOptions: const BasicOptions(),
              additionalOptions: const AdditionalOptions(),
              convenienceOptions: const ConvenienceOptions(),
            );
          }
        } else {
          // 편의시설 정보가 없으면 기본값으로 초기화
          _amenity = RoomAmenityFreezed(
            roomId: _roomId!,
            basicOptions: const BasicOptions(),
            additionalOptions: const AdditionalOptions(),
            convenienceOptions: const ConvenienceOptions(),
          );
        }

        // 사진 정보
        if (roomData['photos'] != null) {
          _existingPhotos = List<Map<String, dynamic>>.from(roomData['photos']);
          debugPrint('📷 [AMENITIES] 기존 사진 로드: ${_existingPhotos.length}개');
        }
      });
    }
  }

  /// JSON 문자열 또는 Map을 Map으로 파싱 (백엔드 이중직렬화 대응)
  Map<String, dynamic> _parseOptionsJson(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      // int 값(1/0)을 bool로 변환
      return data.map((key, value) => MapEntry(key, _toBool(value)));
    }
    if (data is String) {
      try {
        final decoded = json.decode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded.map((key, value) => MapEntry(key, _toBool(value)));
        }
      } catch (e) {
        debugPrint('⚠️ [AMENITIES] JSON 파싱 실패: $e');
      }
    }
    return {};
  }

  /// 사진 URL에 경로 prefix 추가
  String _getPhotoUrl(String url) {
    // 웹 환경에서는 서버 URL 사용
    if (kIsWeb) {
      if (url.startsWith('/uploads/')) {
        return '${ApiConfig.baseUrl}$url';
      }
      return url;
    }

    // 모바일/데스크톱 로컬 환경에서는 C:\study 경로 사용
    // TODO: 테스트서버나 운영서버는 다른 경로 사용
    if (url.startsWith('/uploads/')) {
      return 'C:\\study$url';
    }
    return url;
  }

  void _removeExistingPhoto(int photoId) {
    setState(() {
      _existingPhotos.removeWhere((photo) => photo['id'] == photoId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalPhotos = _existingPhotos.length + _roomImages.length;
    if (totalPhotos >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 20장까지 등록 가능합니다')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        int remainingSlots = 20 - totalPhotos;
        _roomImages.addAll(images.take(remainingSlots));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _roomImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 및 편의시설'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const RegistrationFlowIndicator(currentStep: 2),
          Expanded(
            child: ResponsivePageLayout(
              child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // 섹션1: 방 사진 등록
                  _buildSectionTitle('방 사진 등록 (${_existingPhotos.length + _roomImages.length}/20)'),
                  _buildPhotoSection(),
                  const SizedBox(height: 24),

                  // 통합 섹션: 옵션들
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 기본 옵션
                          _buildSectionTitle('기본 옵션'),
                          const SizedBox(height: 16),
                          _buildBasicOptions(),
                          const SizedBox(height: 32),

                          // 추가 옵션
                          _buildSectionTitle('추가 옵션'),
                          const SizedBox(height: 16),
                          _buildAdditionalOptions(),
                          const SizedBox(height: 32),

                          // 편의 옵션
                          _buildSectionTitle('편의 옵션'),
                          const SizedBox(height: 16),
                          _buildConvenienceOptions(),
                          const SizedBox(height: 32),

                          // 반려동물 동반 여부
                          _buildSectionTitle('반려동물 동반 여부'),
                          const SizedBox(height: 16),
                          _buildPetOptions(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                        // 하단 버튼
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진 그리드
            if (_existingPhotos.isNotEmpty || _roomImages.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // 기존 사진들 (서버에서 받은 것)
                  ..._existingPhotos.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> photo = entry.value;
                    return _buildExistingPhotoCard(photo, index);
                  }),
                  // 새로 추가한 사진들
                  ..._roomImages.asMap().entries.map((entry) {
                    int index = entry.key + _existingPhotos.length;
                    XFile image = entry.value;
                    return _buildDraggableImageCard(image, index);
                  }),
                  if (_existingPhotos.length + _roomImages.length < 20) _buildAddPhotoButton(),
                ],
              )
            else
              _buildAddPhotoButton(),

            const SizedBox(height: 16),

            // 설명 텍스트
            Text(
              '방 사진은 최소 6장 ~ 20장까지 등록이 가능합니다.\n'
              '사진을 누른 상태로 이동시켜서 순서를 변경할 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // 사진 TIP
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '사진 TIP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '- 매력적인 사진은 계약으로 이어집니다.\n'
                    '- 방 뿐만 아니라 거실, 화장실, 주방 등 게스트가 사용하는 모든 공간을 촬영해주세요.\n'
                    '- 짐 정리와 청소가 완료된 상태에서 광각모드로 촬영하면 공간이 넓어보여요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPhotoCard(Map<String, dynamic> photo, int index) {
    final photoUrl = _getPhotoUrl(photo['url']);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    photoUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    headers: const {
                      'Access-Control-Allow-Origin': '*',
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ [PHOTO] 이미지 로드 실패: $photoUrl');
                      debugPrint('❌ [PHOTO] 에러: $error');
                      debugPrint('❌ [PHOTO] 스택트레이스: $stackTrace');
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 30,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Load failed',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(photoUrl),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ [PHOTO] 이미지 로드 실패: $photoUrl');
                      debugPrint('❌ [PHOTO] 에러: $error');
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeExistingPhoto(photo['id']),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '대표사진',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableImageCard(XFile image, int index) {
    return Draggable<int>(
      data: index,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    image.path,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[200],
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          setState(() {
            final oldIndex = details.data;
            final newIndex = index;
            if (oldIndex != newIndex) {
              final XFile item = _roomImages.removeAt(oldIndex);
              _roomImages.insert(newIndex, item);
            }
          });
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? AppColors.primary600
                    : Colors.grey[300]!,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          image.path,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(image.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                ),
                // 드래그 핸들 영역 (웹에서도 작동하도록)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '대표사진',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              '+ 사진 첨부',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicOptions() {
    final basic = _amenity?.basicOptions ?? const BasicOptions();

    return Column(
      children: [
        Row(
          children: [
            _buildCheckboxItem('냉장고', basic.refrigerator, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(refrigerator: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('세탁기', basic.washingMachine, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(washingMachine: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('에어컨', basic.airConditioner, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(airConditioner: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('싱크대', basic.sink, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(sink: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('침대', basic.bed, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(bed: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('TV', basic.tv, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(tv: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('인터넷 (Wi-Fi)', basic.internet, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  basicOptions: basic.copyWith(internet: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    final additional = _amenity?.additionalOptions ?? const AdditionalOptions();

    return Column(
      children: [
        Row(
          children: [
            _buildCheckboxItem('도어락', additional.doorLock, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(doorLock: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('CCTV', additional.cctv, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(cctv: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('관리실', additional.managementOffice, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(managementOffice: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('가스레인지', additional.gasRange, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(gasRange: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('인덕션', additional.induction, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(induction: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('전자레인지', additional.microwave, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(microwave: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('식탁', additional.diningTable, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(diningTable: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('신발장', additional.shoeRack, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(shoeRack: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('옷장', additional.wardrobe, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(wardrobe: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('드레스룸', additional.dressRoom, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(dressRoom: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('화장대', additional.vanity, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(vanity: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('케이블 TV', additional.cableTv, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(cableTv: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('소파', additional.sofa, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(sofa: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('책상', additional.desk, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(desk: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('커튼', additional.curtain, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(curtain: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('발코니/베란다', additional.balcony, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  additionalOptions: additional.copyWith(balcony: value!),
                );
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildConvenienceOptions() {
    final convenience = _amenity?.convenienceOptions ?? const ConvenienceOptions();

    return Column(
      children: [
        Row(
          children: [
            _buildCheckboxItem('냉난방기', convenience.heatingCooling, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(heatingCooling: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('히터', convenience.heater, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(heater: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('공기청정기', convenience.airPurifier, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(airPurifier: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('건조기', convenience.dryer, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(dryer: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('다리미', convenience.iron, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(iron: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('정수기', convenience.waterPurifier, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(waterPurifier: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('전기밥솥', convenience.riceCooker, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(riceCooker: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('전기포트', convenience.electricKettle, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(electricKettle: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('식기(그릇,수저)', convenience.dishes, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(dishes: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('조리도구(팬, 냄비)', convenience.cookware, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(cookware: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('욕조', convenience.bathtub, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(bathtub: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('드라이어', convenience.hairDryer, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(hairDryer: value!),
                );
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('비데', convenience.bidet, (value) {
              setState(() {
                _amenity = _amenity?.copyWith(
                  convenienceOptions: convenience.copyWith(bidet: value!),
                );
              });
            }),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildPetOptions() {
    final petsAllowed = _amenity?.petsAllowed ?? false;

    return Row(
      children: [
        _buildCheckboxItem('동반가능', petsAllowed, (value) {
          setState(() {
            _amenity = _amenity?.copyWith(petsAllowed: value!);
          });
        }),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildCheckboxItem(String label, bool value, Function(bool?) onChanged) {
    return Expanded(
      child: CheckboxListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary600,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        tileColor: value ? AppColors.primary50 : AppColors.neutral0,
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              if (_roomId != null) {
                context.go('/host/pricing/$_roomId');
              } else {
                context.pop();
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '이전으로',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 250,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              final totalPhotos = _existingPhotos.length + _roomImages.length;
              if (totalPhotos < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('방 사진을 최소 6장 이상 등록해주세요')),
                );
                return;
              }

              if (_roomId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('방 ID가 없습니다. 처음부터 다시 시작해주세요.')),
                );
                return;
              }

              if (_formKey.currentState!.validate()) {
                // 1. 사진 업로드
                final photoUrls = await _roomService.uploadPhotos(_roomId!, _roomImages);

                if (photoUrls == null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사진 업로드에 실패했습니다.')),
                  );
                  return;
                }

                // 2. 편의시설 데이터 수집
                if (_amenity == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('편의시설 데이터가 초기화되지 않았습니다.')),
                    );
                  }
                  return;
                }

                // Freezed 모델을 JSON으로 변환
                final fullData = _amenity!.toJson();

                // 백엔드 API 스펙에 맞게 구조 변환
                // petAllowed를 최상위로 분리 (필터 기능 확장성)
                final amenitiesData = {
                  'basicOptions': fullData['basicOptions'],
                  'additionalOptions': fullData['additionalOptions'],
                  'convenienceOptions': fullData['convenienceOptions'],
                  'petAllowed': fullData['petsAllowed'], // snake_case로 변환
                };

                // 3. 편의시설 정보 전송
                final success = await _roomService.updateAmenities(_roomId!, amenitiesData);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사진 및 편의시설 정보가 저장되었습니다.')),
                  );
                  context.go('/host/free-services/$_roomId');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('편의시설 정보 저장에 실패했습니다.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '저장 후 다음',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
