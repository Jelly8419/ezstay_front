import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../widgets/registration_flow_indicator.dart';
import '../services/room_service.dart';
import 'dart:io';

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

  // 기본 옵션
  bool _refrigerator = false;
  bool _washingMachine = false;
  bool _airConditioner = false;
  bool _sink = false;
  bool _bed = false;
  bool _tv = false;
  bool _internet = false;

  // 추가 옵션
  bool _doorLock = false;
  bool _cctv = false;
  bool _managementOffice = false;
  bool _gasRange = false;
  bool _induction = false;
  bool _microwave = false;
  bool _diningTable = false;
  bool _shoeRack = false;
  bool _wardrobe = false;
  bool _dressRoom = false;
  bool _vanity = false;
  bool _cableTv = false;
  bool _sofa = false;
  bool _desk = false;
  bool _curtain = false;
  bool _balcony = false;

  // 편의 옵션
  bool _heatingCooling = false;
  bool _heater = false;
  bool _airPurifier = false;
  bool _dryer = false;
  bool _iron = false;
  bool _waterPurifier = false;
  bool _riceCooker = false;
  bool _electricKettle = false;
  bool _dishes = false;
  bool _cookware = false;
  bool _bathtub = false;
  bool _hairDryer = false;
  bool _bidet = false;

  // 반려동물
  bool _petsAllowed = false;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    if (_roomId != null) {
      _loadRoomData();
    }
  }

  /// 저장된 방 정보 불러오기
  Future<void> _loadRoomData() async {
    if (_roomId == null) return;

    final roomData = await _roomService.getRoom(_roomId!);
    if (roomData != null && mounted) {
      setState(() {
        // 편의시설 정보가 있으면 채우기
        if (roomData['amenities'] != null) {
          final amenities = roomData['amenities'];

          // 기본 옵션
          if (amenities['basicOptions'] != null) {
            final basic = amenities['basicOptions'];
            _refrigerator = basic['refrigerator'] ?? false;
            _washingMachine = basic['washingMachine'] ?? false;
            _airConditioner = basic['airConditioner'] ?? false;
            _sink = basic['sink'] ?? false;
            _bed = basic['bed'] ?? false;
            _tv = basic['tv'] ?? false;
            _internet = basic['internet'] ?? false;
          }

          // 추가 옵션
          if (amenities['additionalOptions'] != null) {
            final additional = amenities['additionalOptions'];
            _doorLock = additional['doorLock'] ?? false;
            _cctv = additional['cctv'] ?? false;
            _managementOffice = additional['managementOffice'] ?? false;
            _gasRange = additional['gasRange'] ?? false;
            _induction = additional['induction'] ?? false;
            _microwave = additional['microwave'] ?? false;
            _diningTable = additional['diningTable'] ?? false;
            _shoeRack = additional['shoeRack'] ?? false;
            _wardrobe = additional['wardrobe'] ?? false;
            _dressRoom = additional['dressRoom'] ?? false;
            _vanity = additional['vanity'] ?? false;
            _cableTv = additional['cableTv'] ?? false;
            _sofa = additional['sofa'] ?? false;
            _desk = additional['desk'] ?? false;
            _curtain = additional['curtain'] ?? false;
            _balcony = additional['balcony'] ?? false;
          }

          // 편의 옵션
          if (amenities['convenienceOptions'] != null) {
            final convenience = amenities['convenienceOptions'];
            _heatingCooling = convenience['heatingCooling'] ?? false;
            _heater = convenience['heater'] ?? false;
            _airPurifier = convenience['airPurifier'] ?? false;
            _dryer = convenience['dryer'] ?? false;
            _iron = convenience['iron'] ?? false;
            _waterPurifier = convenience['waterPurifier'] ?? false;
            _riceCooker = convenience['riceCooker'] ?? false;
            _electricKettle = convenience['electricKettle'] ?? false;
            _dishes = convenience['dishes'] ?? false;
            _cookware = convenience['cookware'] ?? false;
            _bathtub = convenience['bathtub'] ?? false;
            _hairDryer = convenience['hairDryer'] ?? false;
            _bidet = convenience['bidet'] ?? false;
          }

          // 반려동물
          if (amenities['petsAllowed'] != null) {
            _petsAllowed = amenities['petsAllowed'];
          }
        }

        // 사진 정보 - TODO: 나중에 사진 URL에서 XFile로 변환 필요
        // if (roomData['photos'] != null) {
        //   // 사진은 URL 형태로 저장되어 있으므로 표시만 가능
        // }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_roomImages.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 20장까지 등록 가능합니다')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        int remainingSlots = 20 - _roomImages.length;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('사진 및 편의시설'),
        backgroundColor: const Color(0xFF4DB5BD),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const RegistrationFlowIndicator(currentStep: 2),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // 섹션1: 방 사진 등록
                  _buildSectionTitle('방 사진 등록 (${_roomImages.length}/20)'),
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
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
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
            if (_roomImages.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._roomImages.asMap().entries.map((entry) {
                    int index = entry.key;
                    XFile image = entry.value;
                    return _buildDraggableImageCard(image, index);
                  }),
                  if (_roomImages.length < 20) _buildAddPhotoButton(),
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
                      color: Color(0xFF2C3E50),
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
                    ? const Color(0xFF4A90E2)
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
                        color: const Color(0xFF4A90E2),
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
    return Column(
      children: [
        Row(
          children: [
            _buildCheckboxItem('냉장고', _refrigerator, (value) {
              setState(() => _refrigerator = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('세탁기', _washingMachine, (value) {
              setState(() => _washingMachine = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('에어컨', _airConditioner, (value) {
              setState(() => _airConditioner = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('싱크대', _sink, (value) {
              setState(() => _sink = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('침대', _bed, (value) {
              setState(() => _bed = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('TV', _tv, (value) {
              setState(() => _tv = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('인터넷 (Wi-Fi)', _internet, (value) {
              setState(() => _internet = value!);
            }),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        Row(
          children: [
            _buildCheckboxItem('도어락', _doorLock, (value) {
              setState(() => _doorLock = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('CCTV', _cctv, (value) {
              setState(() => _cctv = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('관리실', _managementOffice, (value) {
              setState(() => _managementOffice = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('가스레인지', _gasRange, (value) {
              setState(() => _gasRange = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('인덕션', _induction, (value) {
              setState(() => _induction = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('전자레인지', _microwave, (value) {
              setState(() => _microwave = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('식탁', _diningTable, (value) {
              setState(() => _diningTable = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('신발장', _shoeRack, (value) {
              setState(() => _shoeRack = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('옷장', _wardrobe, (value) {
              setState(() => _wardrobe = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('드레스룸', _dressRoom, (value) {
              setState(() => _dressRoom = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('화장대', _vanity, (value) {
              setState(() => _vanity = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('케이블 TV', _cableTv, (value) {
              setState(() => _cableTv = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('소파', _sofa, (value) {
              setState(() => _sofa = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('책상', _desk, (value) {
              setState(() => _desk = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('커튼', _curtain, (value) {
              setState(() => _curtain = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('발코니/베란다', _balcony, (value) {
              setState(() => _balcony = value!);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildConvenienceOptions() {
    return Column(
      children: [
        Row(
          children: [
            _buildCheckboxItem('냉난방기', _heatingCooling, (value) {
              setState(() => _heatingCooling = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('히터', _heater, (value) {
              setState(() => _heater = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('공기청정기', _airPurifier, (value) {
              setState(() => _airPurifier = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('건조기', _dryer, (value) {
              setState(() => _dryer = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('다리미', _iron, (value) {
              setState(() => _iron = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('정수기', _waterPurifier, (value) {
              setState(() => _waterPurifier = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('전기밥솥', _riceCooker, (value) {
              setState(() => _riceCooker = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('전기포트', _electricKettle, (value) {
              setState(() => _electricKettle = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('식기(그릇,수저)', _dishes, (value) {
              setState(() => _dishes = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('조리도구(팬, 냄비)', _cookware, (value) {
              setState(() => _cookware = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('욕조', _bathtub, (value) {
              setState(() => _bathtub = value!);
            }),
            const SizedBox(width: 12),
            _buildCheckboxItem('드라이어', _hairDryer, (value) {
              setState(() => _hairDryer = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCheckboxItem('비데', _bidet, (value) {
              setState(() => _bidet = value!);
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
    return Row(
      children: [
        _buildCheckboxItem('동반가능', _petsAllowed, (value) {
          setState(() => _petsAllowed = value!);
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
            color: Color(0xFF2C3E50),
          ),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF4DB5BD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        tileColor: value ? const Color(0xFF4DB5BD).withOpacity(0.05) : Colors.white,
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
                context.go('/host/pricing', extra: _roomId);
              } else {
                context.pop();
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4A90E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '이전으로',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
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
              if (_roomImages.length < 6) {
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
                final amenitiesData = {
                  'basicOptions': {
                    'refrigerator': _refrigerator,
                    'washingMachine': _washingMachine,
                    'airConditioner': _airConditioner,
                    'sink': _sink,
                    'bed': _bed,
                    'tv': _tv,
                    'internet': _internet,
                  },
                  'additionalOptions': {
                    'doorLock': _doorLock,
                    'cctv': _cctv,
                    'managementOffice': _managementOffice,
                    'gasRange': _gasRange,
                    'induction': _induction,
                    'microwave': _microwave,
                    'diningTable': _diningTable,
                    'shoeRack': _shoeRack,
                    'wardrobe': _wardrobe,
                    'dressRoom': _dressRoom,
                    'vanity': _vanity,
                    'cableTv': _cableTv,
                    'sofa': _sofa,
                    'desk': _desk,
                    'curtain': _curtain,
                    'balcony': _balcony,
                  },
                  'convenienceOptions': {
                    'heatingCooling': _heatingCooling,
                    'heater': _heater,
                    'airPurifier': _airPurifier,
                    'dryer': _dryer,
                    'iron': _iron,
                    'waterPurifier': _waterPurifier,
                    'riceCooker': _riceCooker,
                    'electricKettle': _electricKettle,
                    'dishes': _dishes,
                    'cookware': _cookware,
                    'bathtub': _bathtub,
                    'hairDryer': _hairDryer,
                    'bidet': _bidet,
                  },
                  'petsAllowed': _petsAllowed,
                };

                // 3. 편의시설 정보 전송
                final success = await _roomService.updateAmenities(_roomId!, amenitiesData);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사진 및 편의시설 정보가 저장되었습니다.')),
                  );
                  context.go('/host/free-services', extra: _roomId);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('편의시설 정보 저장에 실패했습니다.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
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
