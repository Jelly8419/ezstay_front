import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../models/booking_state.dart';
import '../../models/rental_item.dart';
import '../../models/selected_rental_item.dart';
import '../../services/guest_room_service.dart';
import '../../widgets/simple_kakao_map.dart';
import '../../widgets/room_detail/booking_bottom_sheet.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/date_range_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/price_calculator.dart';
import '../host/room_registration/components/form_section.dart';
import '../host/room_registration/components/option_toggle.dart';
import 'package:intl/intl.dart';
import '../contract/contract_start_page.dart';

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

  // 예약 상태 (React UI 스타일)
  BookingState _bookingState = const BookingState();

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

  /// 모바일 예약 Bottom Sheet 표시
  void _showBookingBottomSheet() {
    if (_room == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(
        room: _room!,
        initialState: _bookingState,
        onStateChanged: (newState) {
          setState(() {
            _bookingState = newState;
          });
        },
        onRequestContract: () {
          Navigator.pop(context); // Bottom sheet 닫기
          _navigateToContractPage();
        },
      ),
    );
  }

  /// 계약 시작 페이지로 이동
  void _navigateToContractPage() {
    if (_room == null || !_bookingState.hasSelectedDates) return;

    // BookingState에서 개별 데이터 추출
    final selectedItems = _bookingState.selectedRentalItems;

    // 각 렌탈 아이템 타입별로 선택된 항목 찾기
    int? selectedHairDryerId;
    int? selectedBeddingSetId;
    int? selectedAmenityKitId;
    int? selectedTowelSetId;
    int beddingSetQuantity = 1;
    int amenityKitQuantity = 1;
    int towelSetQuantity = 1;

    for (final item in selectedItems) {
      // ID 범위로 타입 구분 (임시 방법, 나중에 type 필드 추가 고려)
      if (_room!.availableRentalItems!.hairDryers.any((h) => h.id == item.id)) {
        selectedHairDryerId = item.id;
      } else if (_room!.availableRentalItems!.beddingSets.any((b) => b.id == item.id)) {
        selectedBeddingSetId = item.id;
        beddingSetQuantity = item.quantity;
      } else if (_room!.availableRentalItems!.amenityKits.any((a) => a.id == item.id)) {
        selectedAmenityKitId = item.id;
        amenityKitQuantity = item.quantity;
      } else if (_room!.availableRentalItems!.towelSets.any((t) => t.id == item.id)) {
        selectedTowelSetId = item.id;
        towelSetQuantity = item.quantity;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractStartPage(
          room: _room!,
          checkInDate: _bookingState.checkInDate!,
          checkOutDate: _bookingState.checkOutDate!,
          selectedHairDryerId: selectedHairDryerId,
          selectedBeddingSetId: selectedBeddingSetId,
          selectedAmenityKitId: selectedAmenityKitId,
          selectedTowelSetId: selectedTowelSetId,
          beddingSetQuantity: beddingSetQuantity,
          amenityKitQuantity: amenityKitQuantity,
          towelSetQuantity: towelSetQuantity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGNB(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _room != null
                  ? Stack(
                      children: [
                        // 리액트 UI 스타일: 2컬럼 그리드 레이아웃
                        SingleChildScrollView(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 16 : 32),
                                child: isMobile
                                    ? _buildMobileLayout()
                                    : _buildDesktopLayout(),
                              ),
                            ),
                          ),
                        ),

                        // 모바일 하단 고정 바
                        if (isMobile)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: MobileFloatingBar(
                              room: _room!,
                              onTap: _showBookingBottomSheet,
                            ),
                          ),
                      ],
                    )
                  : const Center(child: Text('데이터를 불러올 수 없습니다.')),
    );
  }

  /// 모바일 레이아웃 (단일 컬럼)
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 사진 갤러리
        _buildPhotoGallery(),
        const SizedBox(height: 24),

        // 방 기본 정보
        FormSection(
          icon: Icons.home,
          title: _room!.roomName,
          child: _buildPropertyInfo(),
        ),
        const SizedBox(height: 24),

        // 편의시설
        FormSection(
          icon: Icons.check_circle_outline,
          title: '편의시설',
          child: _buildAmenitiesGrid(),
        ),
        const SizedBox(height: 24),

        // 위치 정보
        FormSection(
          icon: Icons.location_on,
          title: '위치',
          child: _buildLocationContent(),
        ),
        const SizedBox(height: 24),

        // 요금 안내
        FormSection(
          icon: Icons.account_balance_wallet,
          title: '요금 안내',
          child: _buildPricingContent(),
        ),
        const SizedBox(height: 24),

        // 호스트 정보
        FormSection(
          icon: Icons.person,
          title: '호스트 정보',
          child: _buildHostContent(),
        ),
        const SizedBox(height: 100), // 하단 바 공간
      ],
    );
  }

  /// 데스크톱 레이아웃 (2컬럼 그리드)
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 왼쪽: 상세 정보 (2/3 너비)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 갤러리
              _buildPhotoGallery(),
              const SizedBox(height: 24),

              // 방 기본 정보
              FormSection(
                icon: Icons.home,
                title: _room!.roomName,
                child: _buildPropertyInfo(),
              ),
              const SizedBox(height: 24),

              // 편의시설
              FormSection(
                icon: Icons.check_circle_outline,
                title: '편의시설',
                child: _buildAmenitiesGrid(),
              ),
              const SizedBox(height: 24),

              // 위치 정보
              FormSection(
                icon: Icons.location_on,
                title: '위치',
                child: _buildLocationContent(),
              ),
              const SizedBox(height: 24),

              // 요금 안내
              FormSection(
                icon: Icons.account_balance_wallet,
                title: '요금 안내',
                child: _buildPricingContent(),
              ),
              const SizedBox(height: 24),

              // 호스트 정보
              FormSection(
                icon: Icons.person,
                title: '호스트 정보',
                child: _buildHostContent(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // 오른쪽: 고정 예약 위젯 (1/3 너비)
        Expanded(
          flex: 1,
          child: _buildFixedBookingWidget(),
        ),
      ],
    );
  }

  /// Property Info 컨텐츠 (리액트 UI 스타일)
  Widget _buildPropertyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주소
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _room!.address,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid 2-3열 레이아웃 (리액트: grid-cols-2 sm:grid-cols-3)
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildInfoItem(Icons.straighten, '면적', '${_room!.area}㎡'),
            _buildInfoItem(Icons.stairs, '층수', '${_room!.floor}층'),
            _buildInfoItem(Icons.elevator, '엘리베이터', _room!.elevatorAvailable ? '있음' : '없음'),
            _buildInfoItem(Icons.local_parking, '주차', _room!.parkingAvailable ? '가능' : '불가'),
          ],
        ),

        // 방 설명
        if (_room!.description != null && _room!.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            _room!.description!,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ],
    );
  }

  /// Info 항목 (아이콘 + 라벨 + 값)
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  /// 편의시설 그리드 (리액트 UI 스타일 - 기본/편의 옵션 분리)
  Widget _buildAmenitiesGrid() {
    if (_room!.amenity == null) {
      return Text('제공되는 편의시설이 없습니다.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary));
    }

    final basicOptions = <String>[];
    final convenienceOptions = <String>[];

    // 기본 옵션 (basicOptions + additionalOptions)
    if (_room!.amenity!.basicOptions['wifi'] == true) basicOptions.add('WiFi');
    if (_room!.amenity!.basicOptions['tv'] == true) basicOptions.add('TV');
    if (_room!.amenity!.basicOptions['airConditioner'] == true) basicOptions.add('에어컨');
    if (_room!.amenity!.basicOptions['heater'] == true) basicOptions.add('난방');
    if (_room!.amenity!.additionalOptions['washer'] == true) basicOptions.add('세탁기');
    if (_room!.amenity!.additionalOptions['dryer'] == true) basicOptions.add('건조기');
    if (_room!.amenity!.additionalOptions['iron'] == true) basicOptions.add('다리미');

    // 편의 옵션
    if (_room!.amenity!.convenienceOptions['microwave'] == true) convenienceOptions.add('전자레인지');
    if (_room!.amenity!.convenienceOptions['refrigerator'] == true) convenienceOptions.add('냉장고');
    if (_room!.amenity!.convenienceOptions['dishwasher'] == true) convenienceOptions.add('식기세척기');

    if (basicOptions.isEmpty && convenienceOptions.isEmpty) {
      return Text('제공되는 편의시설이 없습니다.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기본 옵션
        if (basicOptions.isNotEmpty) ...[
          Text('기본 옵션', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: basicOptions.map((option) {
              return OptionToggle(
                label: option,
                selected: true,
                onToggle: () {}, // Read-only
              );
            }).toList(),
          ),
        ],

        // 편의 옵션
        if (convenienceOptions.isNotEmpty) ...[
          if (basicOptions.isNotEmpty) const SizedBox(height: 16),
          Text('편의 옵션', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: convenienceOptions.map((option) {
              return OptionToggle(
                label: option,
                selected: true,
                onToggle: () {}, // Read-only
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// 위치 섹션 컨텐츠
  Widget _buildLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_room!.address, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 16),
        // 지도 (기존 코드 재사용)
        SizedBox(
          height: 300,
          child: SimpleKakaoMap(
            latitude: _room!.latitude,
            longitude: _room!.longitude,
            roomName: _room!.roomName,
          ),
        ),
      ],
    );
  }

  /// 요금 안내 컨텐츠
  Widget _buildPricingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRow('일일 임대료', _room!.dailyRent),
        const SizedBox(height: 8),
        _buildPriceRow('주간 임대료', _room!.weeklyRent),
        const SizedBox(height: 8),
        _buildPriceRow('보증금', _room!.deposit),
        const SizedBox(height: 8),
        _buildPriceRow('일일 관리비', _room!.dailyMaintenanceFee),
        const SizedBox(height: 8),
        _buildPriceRow('청소비', _room!.cleaningFee),

        // 환불 규정
        if (_room!.refundPolicy != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('환불 규정: ${_room!.refundPolicy}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  /// 가격 행
  Widget _buildPriceRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          '${_currencyFormat.format(amount)}원',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 호스트 정보 컨텐츠
  Widget _buildHostContent() {
    final hostName = _room!.hostName ?? '호스트';
    final hostInitial = hostName.isNotEmpty ? hostName[0] : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary100,
              child: Text(
                hostInitial,
                style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hostName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  Text('호스트', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: 호스트에게 문의하기 기능
            },
            icon: const Icon(Icons.message, size: 18),
            label: const Text('호스트에게 문의하기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary600,
              side: BorderSide(color: AppColors.primary600),
            ),
          ),
        ),
      ],
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

  /// 사진 갤러리 (리액트 UI 스타일: 1:1 썸네일 그리드)
  Widget _buildPhotoGallery() {
    if (_room == null || _room!.photos.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusXl,
          border: Border.all(color: AppColors.border),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Icon(Icons.home, size: 80, color: AppColors.neutral400),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 사진 (16:9 비율)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Image.network(
                    _room!.photos[_currentPhotoIndex].url,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.neutral200,
                        child: Center(
                          child: Icon(Icons.home, size: 80, color: AppColors.neutral400),
                        ),
                      );
                    },
                  ),

                  // 왼쪽 화살표 (호버 시 표시)
                  if (_room!.photos.length > 1)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.floatingButton,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.chevron_left, color: AppColors.neutral900),
                            onPressed: _goToPreviousPhoto,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),

                  // 오른쪽 화살표 (호버 시 표시)
                  if (_room!.photos.length > 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.floatingButton,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.chevron_right, color: AppColors.neutral900),
                            onPressed: _goToNextPhoto,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),

                  // 사진 카운터 (우측 하단)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPhotoIndex + 1} / ${_room!.photos.length}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.surface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 썸네일 그리드 (1:1 비율, 5열)
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, // 1:1 정사각형
              ),
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
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(
                        color: isSelected ? AppColors.primary600 : AppColors.neutral200,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary600.withValues(alpha: 0.2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14), // radiusLg - borderWidth
                      child: Image.network(
                        _room!.photos[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.neutral100,
                            child: Icon(Icons.image, color: AppColors.neutral400, size: 24),
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
      ),
    );
  }

  /// 방 기본 정보 (이름 + 뱃지) - 사용됨
  /// 고정 예약 위젯 (데스크톱)
  /// PC 고정 예약 위젯 (리액트 UI 스타일)
  Widget _buildFixedBookingWidget() {
    if (_room == null) return const SizedBox.shrink();

    final priceBreakdown = PriceCalculator.calculate(
      room: _room!,
      bookingState: _bookingState,
    );

    final validationError = PriceCalculator.validateDateSelection(
      room: _room!,
      bookingState: _bookingState,
    );

    final canRequestContract = _bookingState.hasSelectedDates && validationError == null;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더: 주당 가격
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                PriceCalculator.formatKRW(_room!.weeklyRent),
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ' /주',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // 장기계약 할인 정보
          if (_room!.longTermDiscount != null && _room!.longTermDiscount! > 0) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: AppRadius.radiusLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_room!.longTermWeeks}주 이상 계약 시 ${_room!.longTermDiscount}% 할인',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${PriceCalculator.formatKRW(
                      (_room!.weeklyRent! * (1 - _room!.longTermDiscount! / 100)).round(),
                    )}/주',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: AppSpacing.md),

          // 날짜 선택
          Text(
            '임대 기간',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          DateRangePicker(
            checkInDate: _bookingState.checkInDate,
            checkOutDate: _bookingState.checkOutDate,
            minContractDays: _room!.minContractDays,
            errorMessage: validationError,
            onDateSelected: (checkIn, checkOut) {
              setState(() {
                _bookingState = _bookingState.copyWith(
                  checkInDate: checkIn,
                  checkOutDate: checkOut,
                );
              });
            },
          ),

          SizedBox(height: AppSpacing.md),

          // 옵션 상품
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '옵션 상품(EZstay에서 제공해드려요)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '옵션 상품은 계약 승인 후에도 구매할 수 있어요.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),

          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.radiusXl,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _buildRentalItemsList(),
            ),
          ),

          // 가격 분석 (날짜 선택 시만 표시)
          if (_bookingState.hasSelectedDates) ...[
            SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.divider),
            SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '결제 예상 금액',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  PriceCalculator.formatKRW(priceBreakdown.total),
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 22,
                    color: AppColors.primary600,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.sm),

            _buildPriceRowDetailed('임대료 (${_bookingState.selectedDays}일)', priceBreakdown.baseRent),
            if (priceBreakdown.longTermDiscount > 0)
              _buildPriceRowDetailed('장기계약 할인', -priceBreakdown.longTermDiscount, isDiscount: true),
            _buildPriceRowDetailed('관리비 (${_bookingState.selectedDays}일)', priceBreakdown.maintenanceFee),
            _buildPriceRowDetailed('청소비', priceBreakdown.cleaningFee),
            _buildPriceRowDetailed('계약 수수료', priceBreakdown.contractFee),
            if (priceBreakdown.rentalItemsFee > 0)
              _buildPriceRowDetailed('옵션 상품', priceBreakdown.rentalItemsFee),
            _buildPriceRowDetailed('보증금(퇴실 후 환급)', priceBreakdown.deposit),

            SizedBox(height: AppSpacing.sm),

            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(color: AppColors.primary100),
              ),
              child: Text(
                '보증금은 제3자 예치기관에 보관되며, 퇴실 완료 후 자동 환급됩니다.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary800,
                  height: 1.4,
                ),
              ),
            ),
          ],

          SizedBox(height: AppSpacing.lg),

          // 계약 요청 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canRequestContract ? _handleContractRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.neutral300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                ),
              ),
              child: Text(
                canRequestContract ? '계약 요청' : '날짜를 선택해주세요',
                style: AppTextStyles.buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 렌탈 아이템 리스트 생성
  List<Widget> _buildRentalItemsList() {
    final items = <Widget>[];

    if (_room!.availableRentalItems == null) return [
      Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Text(
          '옵션 상품이 없습니다.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
    ];

    final allItems = [
      ..._room!.availableRentalItems!.beddingSets,
      ..._room!.availableRentalItems!.amenityKits,
      ..._room!.availableRentalItems!.hairDryers,
      ..._room!.availableRentalItems!.towelSets,
    ];

    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i];
      items.add(
        _buildCompactRentalItem(item),
      );

      if (i < allItems.length - 1) {
        items.add(Divider(height: AppSpacing.md * 2, color: AppColors.divider));
      }
    }

    return items;
  }

  /// 컴팩트한 렌탈 아이템 (리액트 UI 스타일)
  Widget _buildCompactRentalItem(RentalItem item) {
    final currentQuantity = _bookingState.getQuantity(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상품명과 설명
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.xs),

        // 가격 및 수량 조절
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 왼쪽: 단가 + 수량 조절
            Row(
              children: [
                Text(
                  PriceCalculator.formatKRW(item.price),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: currentQuantity > 0
                            ? () {
                                setState(() {
                                  _bookingState = _bookingState.updateRentalItem(
                                    SelectedRentalItem(
                                      id: item.id,
                                      name: item.name,
                                      description: item.description,
                                      price: item.price,
                                      quantity: currentQuantity - 1,
                                    ),
                                  );
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: currentQuantity > 0
                                ? AppColors.textSecondary
                                : AppColors.neutral400,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '$currentQuantity',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: currentQuantity < 4
                            ? () {
                                setState(() {
                                  _bookingState = _bookingState.updateRentalItem(
                                    SelectedRentalItem(
                                      id: item.id,
                                      name: item.name,
                                      description: item.description,
                                      price: item.price,
                                      quantity: currentQuantity + 1,
                                    ),
                                  );
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: currentQuantity < 4
                                ? AppColors.textSecondary
                                : AppColors.neutral400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 오른쪽: 총액
            Text(
              PriceCalculator.formatKRW(item.price * currentQuantity),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 가격 행 (상세 버전 - 할인 표시 포함)
  Widget _buildPriceRowDetailed(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDiscount ? AppColors.primary600 : AppColors.textSecondary,
            ),
          ),
          Text(
            PriceCalculator.formatKRW(amount.abs()),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDiscount ? AppColors.primary600 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 계약 요청 핸들러
  void _handleContractRequest() {
    // BookingState의 selectedRentalItems에서 개별 아이템 ID와 수량 추출
    int? hairDryerId;
    int? beddingSetId;
    int? amenityKitId;
    int? towelSetId;
    int beddingSetQty = 1;
    int amenityKitQty = 1;
    int towelSetQty = 1;

    for (final item in _bookingState.selectedRentalItems) {
      if (item.quantity > 0) {
        // 아이템 이름으로 타입 판별 (간단한 방법)
        if (item.name.contains('헤어드라이어') || item.name.contains('드라이어')) {
          hairDryerId = item.id;
        } else if (item.name.contains('침구')) {
          beddingSetId = item.id;
          beddingSetQty = item.quantity;
        } else if (item.name.contains('어메니티')) {
          amenityKitId = item.id;
          amenityKitQty = item.quantity;
        } else if (item.name.contains('타올')) {
          towelSetId = item.id;
          towelSetQty = item.quantity;
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractStartPage(
          room: _room!,
          checkInDate: _bookingState.checkInDate!,
          checkOutDate: _bookingState.checkOutDate!,
          selectedHairDryerId: hairDryerId,
          selectedBeddingSetId: beddingSetId,
          selectedAmenityKitId: amenityKitId,
          selectedTowelSetId: towelSetId,
          beddingSetQuantity: beddingSetQty,
          amenityKitQuantity: amenityKitQty,
          towelSetQuantity: towelSetQty,
        ),
      ),
    );
  }
}
