import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/room.dart';
import '../constants/app_constants.dart';
import '../widgets/kakao_map_web.dart';
import '../services/guest_room_service.dart';
import 'package:intl/intl.dart';

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

  Room? _room;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPhotoIndex = 0;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // 옵션 선택 상태
  bool _beddingOption = false;
  bool _amenityKitOption = false;
  bool _towelOption = false;

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
                              // 사진 캐러셀
                              _buildPhotoCarousel(),

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
                                    // 방 기본 정보
                                    _buildRoomBasicInfo(),
                                    const SizedBox(height: 32),

                                    // 공간 정보
                                    _buildSpaceInfo(),
                                    const SizedBox(height: 32),

                                    // 편의시설
                                    _buildAmenities(),
                                    const SizedBox(height: 32),

                                    // 무료 부가서비스
                                    if (_room!.freeServicesList.isNotEmpty) ...[
                                      _buildFreeServices(),
                                      const SizedBox(height: 32),
                                    ],

                                    // 위치 정보
                                    _buildLocationSection(),
                                    const SizedBox(height: 32),

                                    // 가격 상세
                                    _buildPricingSection(),
                                    const SizedBox(height: 32),

                                                    // 환불 규정
                                    _buildRefundPolicy(),
                                    const SizedBox(height: 32),

                                    // 호스트 정보
                                    _buildHostInfo(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 상단 AppBar (반투명)
                        _buildAppBar(),

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

  /// 상단 AppBar
  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  // TODO: 찜하기 기능
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: 공유 기능
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 사진 캐러셀
  Widget _buildPhotoCarousel() {
    if (_room == null || _room!.photos.isEmpty) {
      return Container(
        height: 500,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.home, size: 80, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          // 메인 사진
          PageView.builder(
            itemCount: _room!.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _room!.photos[index].url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.home, size: 80, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),

          // 사진 인디케이터
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1} / ${_room!.photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

          // 썸네일 네비게이션 (하단)
          if (_room!.photos.length > 1)
            Positioned(
              bottom: 56,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _room!.photos.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentPhotoIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentPhotoIndex = index;
                        });
                      },
                      child: Container(
                        width: 80,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            _room!.photos[index].url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 방 기본 정보
  Widget _buildRoomBasicInfo() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방 이름
        Text(
          _room!.roomName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
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
        const SizedBox(height: 16),

        // 특징 태그
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag(_room!.buildingType),
            if (_room!.parkingAvailable) _buildTag('주차 가능'),
            if (_room!.isPetFriendly) _buildTag('반려동물 동반 가능'),
            if (_room!.isNearSubway) _buildTag('역세권'),
            if (_room!.elevatorAvailable) _buildTag('엘리베이터'),
          ],
        ),
        const SizedBox(height: 24),

        // 방 설명
        Text(
          _room!.description ?? '',
          style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.6),
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

  /// 편의시설
  Widget _buildAmenities() {
    if (_room == null) return const SizedBox.shrink();

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
          children: _room!.amenitiesList.map((amenity) {
            return Chip(
              label: Text(amenity),
              backgroundColor: Colors.grey[100],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 무료 부가서비스
  Widget _buildFreeServices() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '무료 부가서비스',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _room!.freeServicesList.map((service) {
            return Chip(
              label: Text(service),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: AppColors.primary),
            );
          }).toList(),
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
        const Text(
          '위치',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: kIsWeb
              ? KakaoMapWeb(
                  controller: KakaoMapWebController(),
                  rooms: [
                    {
                      'id': _room!.id,
                      'latitude': _room!.latitude,
                      'longitude': _room!.longitude,
                      'roomName': _room!.roomName,
                      'weeklyRent': _room!.weeklyRent,
                    }
                  ],
                  onMarkerTap: null,
                  onBoundsChanged: null,
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Text('모바일 지도는 준비 중입니다.'),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          _room!.address,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  /// 가격 상세
  Widget _buildPricingSection() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요금 안내',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildPriceRow('주 임대료', _room!.weeklyRent),
              if (_room!.monthlyRent > 0) ...[
                const SizedBox(height: 12),
                _buildPriceRow('월 임대료', _room!.monthlyRent),
              ],
              if (_room!.maintenanceFee > 0) ...[
                const SizedBox(height: 12),
                _buildPriceRow('관리비', _room!.maintenanceFee),
              ],
              if (_room!.cleaningFee > 0) ...[
                const SizedBox(height: 12),
                _buildPriceRow('청소비', _room!.cleaningFee),
              ],
            ],
          ),
        ),
        if (_room!.maintenanceDetail != null &&
            _room!.maintenanceDetail!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '관리비: ${_room!.maintenanceDetail}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(String label, int price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(
          '${_currencyFormat.format(price)}원',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 환불 규정
  Widget _buildRefundPolicy() {
    if (_room == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '환불 규정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getRefundPolicyText(_room!.refundPolicy),
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
        ),
      ],
    );
  }

  /// 환불 정책 텍스트 변환
  String _getRefundPolicyText(String policy) {
    switch (policy) {
      case 'flexible':
        return '유연함: 체크인 24시간 전까지 전액 환불';
      case 'moderate':
        return '보통: 체크인 5일 전까지 전액 환불';
      case 'strict':
        return '엄격함: 체크인 7일 전까지 50% 환불, 이후 환불 불가';
      default:
        return policy;
    }
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
        width: 350,
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(' / 주', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),

            // 체크인/체크아웃 선택
            _buildDateSelector(),
            const SizedBox(height: 16),

            // 옵션 선택
            _buildOptions(),
            const SizedBox(height: 20),

            // 예약하기 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 예약하기 기능
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '예약하기',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 총 금액 안내
            if (_checkInDate != null && _checkOutDate != null)
              _buildTotalPrice(),
          ],
        ),
      ),
    );
  }

  /// 날짜 선택기
  Widget _buildDateSelector() {
    return Column(
      children: [
        _buildDateField(
          label: '체크인',
          date: _checkInDate,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() {
                _checkInDate = picked;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _buildDateField(
          label: '체크아웃',
          date: _checkOutDate,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _checkInDate?.add(const Duration(days: 7)) ?? DateTime.now(),
              firstDate: _checkInDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() {
                _checkOutDate = picked;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? DateFormat('yyyy.MM.dd').format(date)
                      : '날짜 선택',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  /// 옵션 선택
  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '옵션 선택',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildOptionCheckbox('침구류 (+10,000원)', _beddingOption, (val) {
          setState(() {
            _beddingOption = val!;
          });
        }),
        _buildOptionCheckbox('어메니티 키트 (+15,000원)', _amenityKitOption, (val) {
          setState(() {
            _amenityKitOption = val!;
          });
        }),
        _buildOptionCheckbox('수건 세트 (+5,000원)', _towelOption, (val) {
          setState(() {
            _towelOption = val!;
          });
        }),
      ],
    );
  }

  Widget _buildOptionCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  /// 총 금액 계산
  Widget _buildTotalPrice() {
    if (_checkInDate == null || _checkOutDate == null || _room == null) {
      return const SizedBox.shrink();
    }

    final days = _checkOutDate!.difference(_checkInDate!).inDays;
    final weeks = (days / 7).ceil();
    int totalPrice = _room!.weeklyRent * weeks;

    // 옵션 추가
    if (_beddingOption) totalPrice += 10000;
    if (_amenityKitOption) totalPrice += 15000;
    if (_towelOption) totalPrice += 5000;

    // 관리비 추가
    if (_room!.maintenanceFee > 0) {
      totalPrice += _room!.maintenanceFee * weeks;
    }

    // 청소비 추가
    if (_room!.cleaningFee > 0) {
      totalPrice += _room!.cleaningFee;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$weeks주', style: const TextStyle(fontSize: 14)),
              Text(
                '${_currencyFormat.format(_room!.weeklyRent * weeks)}원',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          if (_room!.maintenanceFee > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('관리비', style: TextStyle(fontSize: 14)),
                Text(
                  '${_currencyFormat.format(_room!.maintenanceFee * weeks)}원',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          if (_room!.cleaningFee > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('청소비', style: TextStyle(fontSize: 14)),
                Text(
                  '${_currencyFormat.format(_room!.cleaningFee)}원',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 금액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_currencyFormat.format(totalPrice)}원',
                style: const TextStyle(
                  fontSize: 16,
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
}
