import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/room.dart';
import '../constants/app_constants.dart';
import '../services/guest_room_service.dart';
import '../widgets/simple_kakao_map.dart';
import '../widgets/kakao_roadview_web.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'contract_start_page.dart';

/// 방 상세 정보 페이지
class RoomDetailPage extends StatefulWidget {
  final int roomId;

  const RoomDetailPage({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final GuestRoomService _guestRoomService = GuestRoomService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final ScrollController _thumbnailScrollController = ScrollController();

  Room? _room;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPhotoIndex = 0;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // 선택된 렌탈 아이템 (카테고리별)
  int? _selectedHairDryerId;
  int? _selectedBeddingSetId;
  int? _selectedAmenityKitId;
  int? _selectedTowelSetId;

  // 렌탈 아이템 수량 (침구류, 어메니티키트, 타올만)
  int _beddingSetQuantity = 1;
  int _amenityKitQuantity = 1;
  int _towelSetQuantity = 1;

  // 지도/로드뷰 전환 상태
  bool _showRoadview = false;

  // 옵션 확장 상태
  bool _optionsExpanded = false;

  @override
  void dispose() {
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRoomDetail();
  }

  /// API에서 방 상세 정보 가져오기
  Future<void> _loadRoomDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final room = await _guestRoomService.getRoomDetail(widget.roomId);

      if (room != null) {
        setState(() {
          _room = room;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '방 정보를 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '방 정보를 불러오는데 실패했습니다.';
        _isLoading = false;
      });
      debugPrint('❌ 방 상세 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _room != null
                  ? Stack(
                      children: [
                        // 스크롤 가능한 메인 콘텐츠
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 상단 여백 (헤더 공간)
                              const SizedBox(height: 80),

                              // 메인 콘텐츠 영역
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isMobile ? 16 : 40,
                                  right: isMobile ? 16 : 400,
                                  top: 24,
                                  bottom: 100,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 방 기본 정보 (이름 + 주소)
                                    _buildRoomBasicInfo(),
                                    const SizedBox(height: 24),

                                    // 사진 갤러리
                                    _buildPhotoGallery(),
                                    const SizedBox(height: 32),

                                    // 방 소개 및 안내
                                    _buildRoomIntroduction(),
                                    const SizedBox(height: 32),

                                    // 공간 정보
                                    _buildSpaceInfo(),
                                    const SizedBox(height: 32),

                                    // 편의시설 (amenity 기반)
                                    _buildAmenitiesFromModel(),
                                    const SizedBox(height: 32),

                                    // 옵션 (예약 시 선택 가능한 항목)
                                    _buildBookingOptions(),
                                    const SizedBox(height: 32),

                                    // 체크인/체크아웃 시간
                                    _buildCheckInOutTime(),
                                    const SizedBox(height: 32),

                                    // 위치 정보
                                    _buildLocationSection(),
                                    const SizedBox(height: 32),

                                    // 요금 안내 (환불 규정 포함)
                                    _buildPricingSectionWithRefund(),
                                    const SizedBox(height: 32),

                                    // 호스트 정보
                                    _buildHostInfo(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 상단 헤더 (로고)
                        _buildHeader(),

                        // 고정 예약 위젯 (데스크톱에서만, 오른쪽 하단)
                        if (!isMobile) _buildFixedBookingWidget(),
                      ],
                    )
                  : const Center(child: Text('데이터를 불러올 수 없습니다.')),
    );
  }

  /// 에러 위젯
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '오류가 발생했습니다.',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  /// 상단 헤더 (로고)
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 뒤로 가기 버튼
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),

                // EZStay 로고
                const Text(
                  'EZStay',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),

                // 찜하기 버튼
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black87),
                  onPressed: () {
                    // TODO: 찜하기 기능
                  },
                ),

                // 공유 버튼
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.black87),
                  onPressed: () {
                    // TODO: 공유 기능
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 이전 사진으로 이동
  void _goToPreviousPhoto() {
    if (_room == null || _room!.photos.isEmpty) return;
    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex - 1 + _room!.photos.length) % _room!.photos.length;
    });
    _scrollToSelectedThumbnail();
  }

  /// 다음 사진으로 이동
  void _goToNextPhoto() {
    if (_room == null || _room!.photos.isEmpty) return;
    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex + 1) % _room!.photos.length;
    });
    _scrollToSelectedThumbnail();
  }

  /// 선택된 썸네일로 스크롤
  void _scrollToSelectedThumbnail() {
    if (!_thumbnailScrollController.hasClients) return;

    const thumbnailWidth = 100.0 + 8.0; // width + margin
    final scrollPosition = _currentPhotoIndex * thumbnailWidth;

    _thumbnailScrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 사진 갤러리 (썸네일 방식)
  Widget _buildPhotoGallery() {
    if (_room == null || _room!.photos.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.home, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 메인 사진
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                _room!.photos[_currentPhotoIndex].url,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.home, size: 80, color: Colors.grey),
                    ),
                  );
                },
              ),

              // 왼쪽 화살표 (이전 사진)
              if (_room!.photos.length > 1)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _goToPreviousPhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 오른쪽 화살표 (다음 사진)
              if (_room!.photos.length > 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _goToNextPhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 사진 인디케이터
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1} / ${_room!.photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 썸네일 갤러리
        if (_room!.photos.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              controller: _thumbnailScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _room!.photos.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentPhotoIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                    _scrollToSelectedThumbnail();
                  },
                  child: Container(
                    width: 100,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _room!.photos[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 방 기본 정보 (이름 + 뱃지)
  Widget _buildRoomBasicInfo() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방 이름 + 무료 부가서비스 뱃지
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _room!.roomName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 청결보장 뱃지
            if (_room!.freeService?.cleaningService == true)
              _buildServiceBadge('청결보장', Icons.cleaning_services),
            const SizedBox(width: 8),
            // 비밀번호 관리 뱃지
            if (_room!.freeService?.autoPasswordChange == true)
              _buildServiceBadge('비밀번호 관리', Icons.lock_outline),
          ],
        ),
        const SizedBox(height: 8),

        // 주소
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _room!.address,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 무료 부가서비스 뱃지
  Widget _buildServiceBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 방 소개 및 안내 섹션
  Widget _buildRoomIntroduction() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '방 소개 및 안내',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 특징 태그
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag(_room!.buildingType),
            if (_room!.parkingAvailable) _buildTag('주차 가능'),
            if (_room!.isNearSubway) _buildTag('역세권'),
            if (_room!.elevatorAvailable) _buildTag('엘리베이터'),
            if (_room!.isDuplex) _buildTag('복층'),
          ],
        ),
        const SizedBox(height: 16),

        // 방 설명
        if (_room!.description != null && _room!.description!.isNotEmpty)
          Text(
            _room!.description!,
            style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
          ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.primary),
      ),
    );
  }

  /// 공간 정보
  Widget _buildSpaceInfo() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공간 정보',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildSpaceItem(Icons.bed, '방 ${_room!.roomCount}개'),
            _buildSpaceItem(Icons.bathtub, '욕실 ${_room!.bathroomCount}개'),
            if (_room!.totalBeds > 0)
              _buildSpaceItem(Icons.single_bed, '침대 ${_room!.totalBeds}개'),
            if (_room!.kitchenCount > 0)
              _buildSpaceItem(Icons.kitchen, '주방 ${_room!.kitchenCount}개'),
            if (_room!.livingRoomCount > 0)
              _buildSpaceItem(Icons.weekend, '거실 ${_room!.livingRoomCount}개'),
            if (_room!.area.isNotEmpty && _room!.area != '0')
              _buildSpaceItem(Icons.square_foot, '${_room!.area}㎡'),
          ],
        ),
      ],
    );
  }

  Widget _buildSpaceItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 15)),
      ],
    );
  }

  /// 편의시설 (amenity 모델 기반)
  Widget _buildAmenitiesFromModel() {
    if (_room == null || _room!.amenity == null) return const SizedBox.shrink();

    final amenity = _room!.amenity!;
    final List<MapEntry<String, String>> amenityItems = [];

    // 기본 옵션
    amenity.basicOptions.forEach((key, value) {
      if (value) {
        switch (key) {
          case 'wifi':
            amenityItems.add(const MapEntry('WiFi', 'wifi'));
            break;
          case 'tv':
            amenityItems.add(const MapEntry('TV', 'tv'));
            break;
          case 'airConditioner':
            amenityItems.add(const MapEntry('에어컨', 'ac'));
            break;
          case 'heater':
            amenityItems.add(const MapEntry('난방', 'heat'));
            break;
        }
      }
    });

    // 추가 옵션
    amenity.additionalOptions.forEach((key, value) {
      if (value) {
        switch (key) {
          case 'washer':
            amenityItems.add(const MapEntry('세탁기', 'washer'));
            break;
          case 'dryer':
            amenityItems.add(const MapEntry('건조기', 'dryer'));
            break;
          case 'iron':
            amenityItems.add(const MapEntry('다리미', 'iron'));
            break;
        }
      }
    });

    // 편의 옵션
    amenity.convenienceOptions.forEach((key, value) {
      if (value) {
        switch (key) {
          case 'microwave':
            amenityItems.add(const MapEntry('전자레인지', 'microwave'));
            break;
          case 'refrigerator':
            amenityItems.add(const MapEntry('냉장고', 'fridge'));
            break;
          case 'dishwasher':
            amenityItems.add(const MapEntry('식기세척기', 'dishwasher'));
            break;
        }
      }
    });

    // 반려동물
    if (amenity.petsAllowed) {
      amenityItems.add(const MapEntry('반려동물 동반 가능', 'pets'));
    }

    if (amenityItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '편의시설',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: amenityItems.map((item) {
            return Chip(
              label: Text(item.key),
              backgroundColor: Colors.grey[100],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 옵션 (예약 시 선택 가능한 항목) - 설명만 표시
  Widget _buildBookingOptions() {
    if (_room == null || _room!.availableRentalItems == null) return const SizedBox.shrink();

    final rentalItems = _room!.availableRentalItems!;
    if (rentalItems.isEmpty) return const SizedBox.shrink();

    final List<String> availableOptions = [];
    if (rentalItems.hairDryers.isNotEmpty) availableOptions.add('헤어드라이어 대여');
    if (rentalItems.beddingSets.isNotEmpty) availableOptions.add('침구류 대여');
    if (rentalItems.amenityKits.isNotEmpty) availableOptions.add('어메니티 키트');
    if (rentalItems.towelSets.isNotEmpty) availableOptions.add('타올');

    if (availableOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '옵션',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '이 방은 예약 시, ${availableOptions.join(', ')} 등을 선택할 수 있어요. 오른쪽 예약 위젯에서 선택해주세요!',
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
        ),
      ],
    );
  }

  /// 체크인/체크아웃 시간
  Widget _buildCheckInOutTime() {
    // TODO: Room 모델에 체크인/아웃 시간 필드 추가 필요
    // 현재는 고정값 사용
    const checkInTime = '15:00';
    const checkOutTime = '11:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '체크인/아웃 시간',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.login, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text('체크인: ', style: TextStyle(fontSize: 15)),
                    Text(
                      checkInTime,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text('체크아웃: ', style: TextStyle(fontSize: 15)),
                    Text(
                      checkOutTime,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 위치 섹션
  Widget _buildLocationSection() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 및 지도/로드뷰 전환 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '위치',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (kIsWeb)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.map,
                      label: '지도',
                      isSelected: !_showRoadview,
                      onTap: () {
                        setState(() {
                          _showRoadview = false;
                        });
                      },
                    ),
                    _buildViewToggleButton(
                      icon: Icons.streetview,
                      label: '거리뷰',
                      isSelected: _showRoadview,
                      onTap: () {
                        setState(() {
                          _showRoadview = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // 지도 또는 로드뷰 컨테이너
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.hardEdge,
          child: kIsWeb
              ? _showRoadview
                  ? KakaoRoadviewWeb(
                      latitude: _room!.latitude,
                      longitude: _room!.longitude,
                      roomName: _room!.roomName,
                    )
                  : SimpleKakaoMap(
                      latitude: _room!.latitude,
                      longitude: _room!.longitude,
                      roomName: _room!.roomName,
                    )
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('모바일 지도는 준비 중입니다.'),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _room!.address,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 지도/로드뷰 전환 버튼
  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 요금 안내 (환불 규정 포함)
  Widget _buildPricingSectionWithRefund() {
    if (_room == null) return const SizedBox.shrink();

    const int deposit = 330000; // 보증금 고정값

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요금 안내',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 요금 테이블 (4열 그리드)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 헤더 행
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTableHeader('임대료 (1주)'),
                    _buildTableHeader('관리비용 (1주)'),
                    _buildTableHeader('청소비용 (퇴실 후 청소)'),
                    _buildTableHeader('보증금 (퇴실 후 환급)'),
                  ],
                ),
              ),
              // 구분선
              Container(height: 1, color: Colors.grey[300]),
              // 데이터 행
              Row(
                children: [
                  _buildTableCell('${_currencyFormat.format(_room!.weeklyRent)}원'),
                  _buildTableCell('${_currencyFormat.format(_room!.maintenanceFee)}원'),
                  _buildTableCell('${_currencyFormat.format(_room!.cleaningFee)}원'),
                  _buildTableCell('${_currencyFormat.format(deposit)}원'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 할인 정보
        if (_room!.longTermDiscount > 0 || (_room!.quickMoveInDiscount > 0 && _room!.quickMoveIn != null)) ...[
          const Text(
            '할인 정보',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
        ],

        // 장기계약 할인
        if (_room!.longTermDiscount > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.discount, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '장기계약 할인: ${_room!.longTermWeeks}주 이상 계약 시 ${_room!.longTermDiscount}% 할인',
                  style: TextStyle(fontSize: 14, color: Colors.green[900]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 빠른입주 할인
        if (_room!.quickMoveInDiscount > 0 && _room!.quickMoveIn != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '빠른입주 할인: ${_room!.quickMoveInDiscount}% 할인',
                  style: TextStyle(fontSize: 14, color: Colors.orange[900]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (_room!.longTermDiscount > 0 || (_room!.quickMoveInDiscount > 0 && _room!.quickMoveIn != null))
          const SizedBox(height: 16),

        // 관리비 포함 항목 (아이콘 방식)
        if (_room!.includeElectricity ||
            _room!.includeWater ||
            _room!.includeGas ||
            _room!.includeInternet) ...[
          const Text(
            '관리비 포함항목',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_room!.includeGas) _buildIncludedItemWithIcon(Icons.local_fire_department, '가스'),
              if (_room!.includeWater) _buildIncludedItemWithIcon(Icons.water_drop, '수도'),
              if (_room!.includeInternet) _buildIncludedItemWithIcon(Icons.wifi, '인터넷'),
              if (_room!.includeElectricity) _buildIncludedItemWithIcon(Icons.bolt, '전기'),
            ],
          ),
        ],

        // 관리비 상세 정보
        if (_room!.maintenanceDetail != null && _room!.maintenanceDetail!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '관리비 상세: ${_room!.maintenanceDetail}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],

        const SizedBox(height: 24),

        // 환불 규정
        const Text(
          '환불 규정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRefundPolicyItems(_room!.refundPolicy),
          ),
        ),
      ],
    );
  }

  /// 테이블 헤더 셀
  Widget _buildTableHeader(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 테이블 데이터 셀
  Widget _buildTableCell(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 관리비 포함 항목 (아이콘 + 라벨)
  Widget _buildIncludedItemWithIcon(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey[700]),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  /// 환불 규정 항목 리스트
  List<Widget> _buildRefundPolicyItems(String policy) {
    List<String> items = [];

    switch (policy) {
      case 'flexible':
        items = [
          '입주일 15일 이전 : 임대료의 계약 수수료를 90% 환불',
          '입주일 14일 ~ 8일 이전 : 임대료의 계약 수수료를 70% 환불',
          '입주일 7일 ~ 1일 이전 : 임대료의 계약 수수료를 50% 환불',
          '입주일 당일 : 환불 불가',
        ];
        break;
      case 'moderate':
        items = [
          '입주일 7일 이전 : 전액 환불',
          '입주일 6일 ~ 3일 이전 : 50% 환불',
          '입주일 2일 이전 ~ 당일 : 환불 불가',
        ];
        break;
      case 'strict':
        items = [
          '입주일 14일 이전 : 전액 환불',
          '입주일 13일 ~ 7일 이전 : 50% 환불',
          '입주일 6일 이전 ~ 당일 : 환불 불가',
        ];
        break;
      default:
        items = [policy];
    }

    return items.asMap().entries.map((entry) {
      return Padding(
        padding: EdgeInsets.only(bottom: entry.key < items.length - 1 ? 8 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
            Expanded(
              child: Text(
                entry.value,
                style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 호스트 정보
  Widget _buildHostInfo() {
    if (_room == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 32,
            backgroundImage: _room!.hostProfileImage != null
                ? NetworkImage(_room!.hostProfileImage!)
                : null,
            child: _room!.hostProfileImage == null
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _room!.hostName ?? '호스트',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_room!.hostPhoneVerified == true) ...[
                      Icon(Icons.verified, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      const Text('휴대폰 인증', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                    ],
                    if (_room!.hostAccountVerified == true) ...[
                      Icon(Icons.account_balance, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      const Text('계좌 인증', style: TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // TODO: 호스트에게 문의하기
            },
            child: const Text('문의하기'),
          ),
        ],
      ),
    );
  }

  /// 고정 예약 위젯 (데스크톱)
  Widget _buildFixedBookingWidget() {
    if (_room == null) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      right: 40,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 가격 표시
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_currencyFormat.format(_room!.weeklyRent)}원',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Text(' / 1주', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            // 1. 방 구조
            _buildRoomStructureInfo(),
            const SizedBox(height: 16),

            // 2. 날짜 선택
            _buildDateSelectorCompact(),
            const SizedBox(height: 16),

            // 3. 옵션 선택 (확장 가능)
            _buildOptionsDropdown(),
            const SizedBox(height: 16),

            // 4. 최종 결제 금액 안내
            _buildPriceBreakdown(),
            const SizedBox(height: 20),

            // 5. 예약하기 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _checkInDate != null && _checkOutDate != null
                    ? () {
                        // 계약 시작하기 페이지로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContractStartPage(
                              room: _room!,
                              checkInDate: _checkInDate!,
                              checkOutDate: _checkOutDate!,
                              selectedHairDryerId: _selectedHairDryerId,
                              selectedBeddingSetId: _selectedBeddingSetId,
                              selectedAmenityKitId: _selectedAmenityKitId,
                              selectedTowelSetId: _selectedTowelSetId,
                              beddingSetQuantity: _beddingSetQuantity,
                              amenityKitQuantity: _amenityKitQuantity,
                              towelSetQuantity: _towelSetQuantity,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _checkInDate != null && _checkOutDate != null ? '예약 하기' : '날짜를 선택하세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _checkInDate != null && _checkOutDate != null ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. 방 구조 정보
  Widget _buildRoomStructureInfo() {
    if (_room == null) return const SizedBox.shrink();

    final List<String> roomStructure = [];

    if (_room!.roomCount > 0) roomStructure.add('방 ${_room!.roomCount}');
    if (_room!.bathroomCount > 0) roomStructure.add('화장실 ${_room!.bathroomCount}');
    if (_room!.kitchenCount > 0) roomStructure.add('주방 ${_room!.kitchenCount}');
    if (_room!.livingRoomCount > 0) roomStructure.add('거실 ${_room!.livingRoomCount}');

    if (roomStructure.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              roomStructure.join(' · '),
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. 날짜 선택 (단일 컨테이너)
  Widget _buildDateSelectorCompact() {
    return InkWell(
      onTap: () async {
        if (!mounted) return;

        // 커스텀 날짜 선택 다이얼로그 표시
        await _showDateSelectionDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _checkInDate != null && _checkOutDate != null
                    ? '${DateFormat('MM.dd').format(_checkInDate!)} - ${DateFormat('MM.dd').format(_checkOutDate!)}'
                    : '날짜 선택 (최소 1주일)',
                style: TextStyle(
                  fontSize: 14,
                  color: _checkInDate != null ? Colors.grey[800] : Colors.grey[500],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  /// 날짜 선택 다이얼로그 (범위 선택 달력)
  Future<void> _showDateSelectionDialog() async {
    DateTime? rangeStart = _checkInDate;
    DateTime? rangeEnd = _checkOutDate;
    DateTime focusedDay = _checkInDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '체크인/체크아웃 선택',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rangeStart != null && rangeEnd != null
                                ? '${DateFormat('MM.dd').format(rangeStart!)} - ${DateFormat('MM.dd').format(rangeEnd!)} (${rangeEnd!.difference(rangeStart!).inDays}일)'
                                : '날짜를 선택하세요 (최소 7일)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 달력
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: focusedDay,
                        locale: 'ko_KR',
                        rangeSelectionMode: RangeSelectionMode.enforced,
                        rangeStartDay: rangeStart,
                        rangeEndDay: rangeEnd,
                        calendarFormat: CalendarFormat.month,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey[700]),
                          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey[700]),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          rangeStartDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          rangeHighlightColor: AppColors.primary.withValues(alpha: 0.2),
                          withinRangeTextStyle: const TextStyle(color: Colors.black87),
                          outsideDaysVisible: false,
                        ),
                        onDaySelected: (selectedDay, focused) {
                          setDialogState(() {
                            focusedDay = focused;

                            // 첫 번째 선택 (체크인)
                            if (rangeStart == null || (rangeStart != null && rangeEnd != null)) {
                              rangeStart = selectedDay;
                              rangeEnd = null;
                            }
                            // 두 번째 선택 (체크아웃)
                            else if (rangeStart != null && rangeEnd == null) {
                              // 체크아웃이 체크인보다 이전이면 체크인을 새로 선택한 날짜로
                              if (selectedDay.isBefore(rangeStart!)) {
                                rangeStart = selectedDay;
                                rangeEnd = null;
                              } else {
                                rangeEnd = selectedDay;
                              }
                            }
                          });
                        },
                        onRangeSelected: (start, end, focused) {
                          setDialogState(() {
                            focusedDay = focused;
                            rangeStart = start;
                            rangeEnd = end;
                          });
                        },
                        onPageChanged: (focused) {
                          focusedDay = focused;
                        },
                      ),
                    ),

                    // 안내 메시지
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: rangeStart != null && rangeEnd != null
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '총 ${rangeEnd!.difference(rangeStart!).inDays}일 (${(rangeEnd!.difference(rangeStart!).inDays / 7).ceil()}주) 선택됨',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green[900],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      rangeStart == null
                                          ? '체크인 날짜를 선택하세요'
                                          : '체크아웃 날짜를 선택하세요 (최소 7일 후)',
                                      style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: rangeStart == null || rangeEnd == null
                      ? null
                      : () {
                          // 최소 7일 검증
                          final days = rangeEnd!.difference(rangeStart!).inDays;
                          if (days < 7) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('최소 계약 기간은 1주일(7일)입니다.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _checkInDate = rangeStart;
                            _checkOutDate = rangeEnd;
                          });
                          Navigator.of(dialogContext).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text('확인', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 3. 옵션 선택 (확장 가능 드롭다운)
  Widget _buildOptionsDropdown() {
    if (_room == null || _room!.availableRentalItems == null) return const SizedBox.shrink();

    final rentalItems = _room!.availableRentalItems!;
    if (rentalItems.isEmpty) return const SizedBox.shrink();

    // 선택된 옵션 개수
    int selectedCount = 0;
    if (_selectedHairDryerId != null) selectedCount++;
    if (_selectedBeddingSetId != null) selectedCount++;
    if (_selectedAmenityKitId != null) selectedCount++;
    if (_selectedTowelSetId != null) selectedCount++;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _optionsExpanded = !_optionsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCount > 0
                        ? '옵션 선택 ($selectedCount개 선택됨)'
                        : '옵션 선택 (미선택 시, 본인 지참 권장)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
                Icon(
                  _optionsExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        // 옵션 드롭다운 (확장 시 표시)
        if (_optionsExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 침구류 1set 대여
                if (rentalItems.beddingSets.isNotEmpty) ...[
                  _buildRentalItemDropdown(
                    title: '침구류 1set 대여 (이불, 매트리스 커버, 베개 각 1개)',
                    items: rentalItems.beddingSets,
                    selectedId: _selectedBeddingSetId,
                    onChanged: (id) {
                      setState(() {
                        _selectedBeddingSetId = id;
                        if (id == null) _beddingSetQuantity = 1;
                      });
                    },
                    showQuantity: true,
                    quantity: _beddingSetQuantity,
                    onIncrement: () {
                      setState(() => _beddingSetQuantity++);
                    },
                    onDecrement: () {
                      if (_beddingSetQuantity > 1) {
                        setState(() => _beddingSetQuantity--);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 헤어 드라이어 대여 (수량 없음)
                if (rentalItems.hairDryers.isNotEmpty) ...[
                  _buildRentalItemDropdown(
                    title: '헤어 드라이어 대여',
                    items: rentalItems.hairDryers,
                    selectedId: _selectedHairDryerId,
                    onChanged: (id) {
                      setState(() => _selectedHairDryerId = id);
                    },
                    showQuantity: false,
                  ),
                  const SizedBox(height: 12),
                ],

                // 어메니티 키트
                if (rentalItems.amenityKits.isNotEmpty) ...[
                  _buildRentalItemDropdown(
                    title: '어메니티 키트',
                    items: rentalItems.amenityKits,
                    selectedId: _selectedAmenityKitId,
                    onChanged: (id) {
                      setState(() {
                        _selectedAmenityKitId = id;
                        if (id == null) _amenityKitQuantity = 1;
                      });
                    },
                    showQuantity: true,
                    quantity: _amenityKitQuantity,
                    onIncrement: () {
                      setState(() => _amenityKitQuantity++);
                    },
                    onDecrement: () {
                      if (_amenityKitQuantity > 1) {
                        setState(() => _amenityKitQuantity--);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 타올
                if (rentalItems.towelSets.isNotEmpty) ...[
                  _buildRentalItemDropdown(
                    title: '타올',
                    items: rentalItems.towelSets,
                    selectedId: _selectedTowelSetId,
                    onChanged: (id) {
                      setState(() {
                        _selectedTowelSetId = id;
                        if (id == null) _towelSetQuantity = 1;
                      });
                    },
                    showQuantity: true,
                    quantity: _towelSetQuantity,
                    onIncrement: () {
                      setState(() => _towelSetQuantity++);
                    },
                    onDecrement: () {
                      if (_towelSetQuantity > 1) {
                        setState(() => _towelSetQuantity--);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 렌탈 아이템 드롭다운 빌더
  Widget _buildRentalItemDropdown({
    required String title,
    required List items, // List<RentalItem>
    required int? selectedId,
    required Function(int?) onChanged,
    bool showQuantity = false,
    int quantity = 1,
    Function()? onIncrement,
    Function()? onDecrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: selectedId,
                    isExpanded: true,
                    hint: Text(
                      '선택안함',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('선택안함', style: TextStyle(fontSize: 13)),
                            Text('', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      ...items.map((item) {
                        return DropdownMenuItem<int?>(
                          value: item.id,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_currencyFormat.format(item.price)}원',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 수량 선택 UI (침구류, 어메니티키트, 타올만) - 드롭다운 바로 아래
        if (selectedId != null && showQuantity) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '수량',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: quantity > 1 ? onDecrement : null,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: quantity > 1 ? Colors.grey[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: quantity > 1 ? Colors.black87 : Colors.grey[400],
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onIncrement,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        // 선택된 아이템의 설명 표시
        if (selectedId != null) ...[
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              try {
                final selectedItem = items.firstWhere((item) => item.id == selectedId);
                if (selectedItem.description.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '• ${selectedItem.description}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  );
                }
              } catch (e) {
                return const SizedBox.shrink();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  /// 선택된 렌탈 아이템의 가격 조회
  int _getRentalItemPrice(int? itemId, List items) {
    if (itemId == null || items.isEmpty) return 0;
    try {
      final item = items.firstWhere((item) => item.id == itemId);
      return item.price;
    } catch (e) {
      return 0;
    }
  }

  /// 4. 최종 결제 금액 세부 안내
  Widget _buildPriceBreakdown() {
    if (_room == null) return const SizedBox.shrink();

    final rentalItems = _room!.availableRentalItems;

    // 렌탈 아이템 가격 계산 (수량 반영)
    int hairDryerPrice = rentalItems != null ? _getRentalItemPrice(_selectedHairDryerId, rentalItems.hairDryers) : 0;
    int beddingPrice = rentalItems != null ? _getRentalItemPrice(_selectedBeddingSetId, rentalItems.beddingSets) * _beddingSetQuantity : 0;
    int amenityKitPrice = rentalItems != null ? _getRentalItemPrice(_selectedAmenityKitId, rentalItems.amenityKits) * _amenityKitQuantity : 0;
    int towelSetPrice = rentalItems != null ? _getRentalItemPrice(_selectedTowelSetId, rentalItems.towelSets) * _towelSetQuantity : 0;

    // 날짜 선택 안된 경우 기본 안내
    if (_checkInDate == null || _checkOutDate == null) {
      // 계약 수수료: (임대료 + 관리비 + 청소비)의 10%
      // 단, cleaningService 무료 부가서비스 사용 시 청소비 제외
      bool hasCleaningService = _room!.freeService?.cleaningService ?? false;
      int baseForContractFee = _room!.weeklyRent + _room!.maintenanceFee;
      if (!hasCleaningService) {
        baseForContractFee += _room!.cleaningFee;
      }
      int contractFee = (baseForContractFee * 0.1).round();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceRowSimple('임대료', _room!.weeklyRent),
            const SizedBox(height: 8),
            _buildPriceRowSimple('관리비', _room!.maintenanceFee),
            const SizedBox(height: 8),
            _buildPriceRowSimple('청소비용', _room!.cleaningFee),
            if (_selectedBeddingSetId != null) ...[
              const SizedBox(height: 8),
              _buildPriceRowSimple('침구류 대여 (x$_beddingSetQuantity)', beddingPrice),
            ],
            if (_selectedHairDryerId != null) ...[
              const SizedBox(height: 8),
              _buildPriceRowSimple('헤어드라이어 대여', hairDryerPrice),
            ],
            if (_selectedAmenityKitId != null) ...[
              const SizedBox(height: 8),
              _buildPriceRowSimple('어메니티 키트 (x$_amenityKitQuantity)', amenityKitPrice),
            ],
            if (_selectedTowelSetId != null) ...[
              const SizedBox(height: 8),
              _buildPriceRowSimple('타올 (x$_towelSetQuantity)', towelSetPrice),
            ],
            const SizedBox(height: 8),
            _buildPriceRowSimple('계약 수수료 (임대료의 10%)', contractFee),
            const Divider(height: 24),
            _buildPriceRowSimple('보증금 (퇴실 후 환급)', 330000, bold: false),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최종 결제 금액',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_currencyFormat.format(_calculateTotal())}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 날짜 선택된 경우 상세 계산
    final days = _checkOutDate!.difference(_checkInDate!).inDays;
    final weeks = (days / 7).ceil();

    int weeklyRentTotal = _room!.dailyRent * days;
    int maintenanceFeeTotal = _room!.dailyMaintenanceFee * days;
    int cleaningFeeTotal = _room!.cleaningFee;
    int optionsTotal = hairDryerPrice + beddingPrice + amenityKitPrice + towelSetPrice;

    // 계약 수수료: (임대료 + 관리비 + 청소비)의 10%
    // 단, cleaningService 무료 부가서비스 사용 시 청소비 제외
    bool hasCleaningService = _room!.freeService?.cleaningService ?? false;
    int baseForContractFee = weeklyRentTotal + maintenanceFeeTotal;
    if (!hasCleaningService) {
      baseForContractFee += cleaningFeeTotal;
    }
    int contractFee = (baseForContractFee * 0.1).round();

    // 할인 계산
    int discountAmount = 0;
    String? discountLabel;

    if (_room!.longTermDiscount > 0 && weeks >= _room!.longTermWeeks) {
      discountAmount = (weeklyRentTotal * _room!.longTermDiscount / 100).round();
      discountLabel = '할인 적용';
    }

    int finalTotal = weeklyRentTotal + maintenanceFeeTotal + cleaningFeeTotal + optionsTotal + contractFee - discountAmount;
    const int deposit = 330000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRowSimple('임대료', weeklyRentTotal),
          const SizedBox(height: 8),
          _buildPriceRowSimple('관리비', maintenanceFeeTotal),
          const SizedBox(height: 8),
          _buildPriceRowSimple('청소비용', cleaningFeeTotal),
          if (_selectedBeddingSetId != null) ...[
            const SizedBox(height: 8),
            _buildPriceRowSimple('침구류 대여 (x$_beddingSetQuantity)', beddingPrice),
          ],
          if (_selectedHairDryerId != null) ...[
            const SizedBox(height: 8),
            _buildPriceRowSimple('헤어드라이어 대여', hairDryerPrice),
          ],
          if (_selectedAmenityKitId != null) ...[
            const SizedBox(height: 8),
            _buildPriceRowSimple('어메니티 키트 (x$_amenityKitQuantity)', amenityKitPrice),
          ],
          if (_selectedTowelSetId != null) ...[
            const SizedBox(height: 8),
            _buildPriceRowSimple('타올 (x$_towelSetQuantity)', towelSetPrice),
          ],
          const SizedBox(height: 8),
          _buildPriceRowSimple('계약 수수료 (임대료의 10%)', contractFee),
          if (discountAmount > 0 && discountLabel != null) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(discountLabel, style: const TextStyle(fontSize: 14, color: Colors.red)),
                Text(
                  '(-) ${_currencyFormat.format(discountAmount)}원',
                  style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          _buildPriceRowSimple('보증금 (퇴실 후 환급)', deposit, bold: false),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최종 결제 금액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_currencyFormat.format(finalTotal)}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 간단한 가격 행
  Widget _buildPriceRowSimple(String label, int price, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '${_currencyFormat.format(price)}원',
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  /// 총 금액 계산 (날짜 선택 전)
  int _calculateTotal() {
    if (_room == null) return 0;

    final rentalItems = _room!.availableRentalItems;

    // 렌탈 아이템 가격 계산 (수량 반영)
    int hairDryerPrice = rentalItems != null ? _getRentalItemPrice(_selectedHairDryerId, rentalItems.hairDryers) : 0;
    int beddingPrice = rentalItems != null ? _getRentalItemPrice(_selectedBeddingSetId, rentalItems.beddingSets) * _beddingSetQuantity : 0;
    int amenityKitPrice = rentalItems != null ? _getRentalItemPrice(_selectedAmenityKitId, rentalItems.amenityKits) * _amenityKitQuantity : 0;
    int towelSetPrice = rentalItems != null ? _getRentalItemPrice(_selectedTowelSetId, rentalItems.towelSets) * _towelSetQuantity : 0;

    // 계약 수수료: (임대료 + 관리비 + 청소비)의 10%
    // 단, cleaningService 무료 부가서비스 사용 시 청소비 제외
    bool hasCleaningService = _room!.freeService?.cleaningService ?? false;
    int baseForContractFee = _room!.weeklyRent + _room!.maintenanceFee;
    if (!hasCleaningService) {
      baseForContractFee += _room!.cleaningFee;
    }
    int contractFee = (baseForContractFee * 0.1).round();

    int total = _room!.weeklyRent + _room!.maintenanceFee + _room!.cleaningFee + contractFee;
    total += hairDryerPrice + beddingPrice + amenityKitPrice + towelSetPrice;

    return total;
  }
}
