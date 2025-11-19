import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../models/booking_state.dart';
import '../../models/rental_item.dart';
import '../../models/selected_rental_item.dart';
import '../../services/guest_room_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/simple_kakao_map.dart';
import '../../widgets/room_detail/booking_bottom_sheet.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/date_range_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/price_calculator.dart';
import '../host/room_registration/components/form_section.dart';
import 'package:intl/intl.dart';
import '../contract/contract_start_page.dart';
import '../../widgets/kakao_roadview_web.dart';

/// 방 상세 정보 페이지
class RoomDetailPage extends StatefulWidget {
  final int roomId;

  const RoomDetailPage({super.key, required this.roomId});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final GuestRoomService _guestRoomService = GuestRoomService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final ScrollController _thumbnailScrollController = ScrollController();

  Room? _room;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPhotoIndex = 0;

  // 지도 vs 로드뷰 표시 상태
  bool _showRoadview = false;

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

        // 📊 Analytics: 방 상세 페이지 조회
        await _analyticsService.logViewRoomDetail(roomId: widget.roomId);
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

    // 📊 Analytics: 가격 안내 바텀시트 열기
    _analyticsService.logClickOpenPricingSheet(roomId: widget.roomId);

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

    // 📊 Analytics: 계약 요청 버튼 클릭
    _analyticsService.logClickRequestContract(
      roomId: widget.roomId,
      checkInDate: _bookingState.checkInDate,
      checkOutDate: _bookingState.checkOutDate,
    );

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
      } else if (_room!.availableRentalItems!.beddingSets.any(
        (b) => b.id == item.id,
      )) {
        selectedBeddingSetId = item.id;
        beddingSetQuantity = item.quantity;
      } else if (_room!.availableRentalItems!.amenityKits.any(
        (a) => a.id == item.id,
      )) {
        selectedAmenityKitId = item.id;
        amenityKitQuantity = item.quantity;
      } else if (_room!.availableRentalItems!.towelSets.any(
        (t) => t.id == item.id,
      )) {
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
                      constraints: const BoxConstraints(maxWidth: 1280),
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
        FormSection(title: _room!.roomName, child: _buildPropertyInfo()),
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
        FormSection(title: '호스트 정보', child: _buildHostContent()),
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
              FormSection(title: _room!.roomName, child: _buildPropertyInfo()),
              const SizedBox(height: 24),

              // 편의시설
              FormSection(title: '옵션', child: _buildAmenitiesGrid()),
              const SizedBox(height: 24),

              // 위치 정보
              FormSection(title: '위치', child: _buildLocationContent()),
              const SizedBox(height: 24),

              // 요금 안내
              FormSection(title: '요금 안내', child: _buildPricingContent()),
              const SizedBox(height: 24),

              // 호스트 정보
              FormSection(title: '호스트 정보', child: _buildHostContent()),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // 오른쪽: Sticky 예약 위젯 (1/3 너비)
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(child: _buildFixedBookingWidget()),
          ),
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
            const Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _room!.address,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid 레이아웃
        Column(
          children: [
            // 1행: 건물유형, 면적, 방 갯수
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.apartment,
                    '건물유형',
                    _room!.buildingType,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.straighten,
                    '면적',
                    '${_room!.area}㎡',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.meeting_room,
                    '방 갯수',
                    '${_room!.roomCount}개',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2행: 화장실, 권장 최대인원, 엘리베이터
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.bathroom,
                    '화장실',
                    '${_room!.bathroomCount}개',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.people,
                    '권장 최대인원',
                    '${_room!.maxGuests}명',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.elevator,
                    '엘리베이터',
                    _room!.elevatorAvailable ? '있음' : '없음',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3행: 주차
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.local_parking,
                    '주차',
                    _room!.parkingAvailable ? '가능' : '불가',
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // 빈 공간
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // 빈 공간
              ],
            ),
          ],
        ),

        // 방 설명
        if (_room!.description != null && _room!.description!.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            '방 소개',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(_room!.description!, style: AppTextStyles.bodyMedium),
        ],
      ],
    );
  }

  /// Info 항목 (아이콘 + 라벨 + 값)
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 28, color: AppColors.primary600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 편의시설 그리드 (리액트 UI 스타일 - 기본/편의 옵션 분리)
  Widget _buildAmenitiesGrid() {
    if (_room!.amenity == null) {
      return Text(
        '제공되는 편의시설이 없습니다.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final amenity = _room!.amenity!;

    // 기본 옵션 (BasicOptions + AdditionalOptions)
    final basicOptions = <String>[];

    // BasicOptions (7개)
    if (amenity.basicOptions.refrigerator) basicOptions.add('냉장고');
    if (amenity.basicOptions.washingMachine) basicOptions.add('세탁기');
    if (amenity.basicOptions.airConditioner) basicOptions.add('에어컨');
    if (amenity.basicOptions.sink) basicOptions.add('싱크대');
    if (amenity.basicOptions.bed) basicOptions.add('침대');
    if (amenity.basicOptions.tv) basicOptions.add('TV');
    if (amenity.basicOptions.internet) basicOptions.add('인터넷 (Wi-Fi)');

    // AdditionalOptions (16개)
    if (amenity.additionalOptions.doorLock) basicOptions.add('도어락');
    if (amenity.additionalOptions.cctv) basicOptions.add('CCTV');
    if (amenity.additionalOptions.managementOffice) basicOptions.add('관리실');
    if (amenity.additionalOptions.gasRange) basicOptions.add('가스레인지');
    if (amenity.additionalOptions.induction) basicOptions.add('인덕션');
    if (amenity.additionalOptions.microwave) basicOptions.add('전자레인지');
    if (amenity.additionalOptions.diningTable) basicOptions.add('식탁');
    if (amenity.additionalOptions.shoeRack) basicOptions.add('신발장');
    if (amenity.additionalOptions.wardrobe) basicOptions.add('옷장');
    if (amenity.additionalOptions.dressRoom) basicOptions.add('드레스룸');
    if (amenity.additionalOptions.vanity) basicOptions.add('화장대');
    if (amenity.additionalOptions.cableTv) basicOptions.add('케이블 TV');
    if (amenity.additionalOptions.sofa) basicOptions.add('소파');
    if (amenity.additionalOptions.desk) basicOptions.add('책상');
    if (amenity.additionalOptions.curtain) basicOptions.add('커튼');
    if (amenity.additionalOptions.balcony) basicOptions.add('발코니/베란다');

    // 편의 옵션 (ConvenienceOptions 13개)
    final convenienceOptions = <String>[];
    if (amenity.convenienceOptions.heatingCooling)
      convenienceOptions.add('냉난방기');
    if (amenity.convenienceOptions.heater) convenienceOptions.add('히터');
    if (amenity.convenienceOptions.airPurifier) convenienceOptions.add('공기청정기');
    if (amenity.convenienceOptions.dryer) convenienceOptions.add('건조기');
    if (amenity.convenienceOptions.iron) convenienceOptions.add('다리미');
    if (amenity.convenienceOptions.waterPurifier) convenienceOptions.add('정수기');
    if (amenity.convenienceOptions.riceCooker) convenienceOptions.add('전기밥솥');
    if (amenity.convenienceOptions.electricKettle)
      convenienceOptions.add('전기포트');
    if (amenity.convenienceOptions.dishes) convenienceOptions.add('식기(그릇,수저)');
    if (amenity.convenienceOptions.cookware)
      convenienceOptions.add('조리도구(팬, 냄비)');
    if (amenity.convenienceOptions.bathtub) convenienceOptions.add('욕조');
    if (amenity.convenienceOptions.hairDryer) convenienceOptions.add('드라이어');
    if (amenity.convenienceOptions.bidet) convenienceOptions.add('비데');

    // 반려동물
    if (amenity.petsAllowed) convenienceOptions.add('반려동물 동반 가능');

    if (basicOptions.isEmpty && convenienceOptions.isEmpty) {
      return Text(
        '제공되는 편의시설이 없습니다.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기본 옵션
        if (basicOptions.isNotEmpty) ...[
          Text(
            '기본 옵션',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildOptionsGrid(basicOptions),
          ),
        ],

        // 편의 옵션
        if (convenienceOptions.isNotEmpty) ...[
          if (basicOptions.isNotEmpty) const SizedBox(height: 24),
          Text(
            '편의 옵션',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildOptionsGrid(convenienceOptions),
          ),
        ],
      ],
    );
  }

  /// 옵션을 3열 그리드로 배치
  Widget _buildOptionsGrid(List<String> options) {
    final rows = <Widget>[];

    for (int i = 0; i < options.length; i += 3) {
      final rowItems = <String>[];
      for (int j = 0; j < 3 && i + j < options.length; j++) {
        rowItems.add(options[i + j]);
      }

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < 3; j++)
              Expanded(
                child: j < rowItems.length
                    ? _buildOptionItem(rowItems[j])
                    : const SizedBox(),
              ),
          ],
        ),
      );

      if (i + 3 < options.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }

  /// 개별 옵션 아이템
  Widget _buildOptionItem(String option) {
    return Row(
      children: [
        Text(
          '• ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary600,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(child: Text(option, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  /// 위치 섹션 컨텐츠 (지도 ↔ 로드뷰 토글)
  Widget _buildLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_room!.address, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 16),
        // 지도 / 로드뷰 전환 버튼
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              // 지도 또는 로드뷰 표시
              _showRoadview
                  ? KakaoRoadviewWeb(
                      latitude: _room!.latitude,
                      longitude: _room!.longitude,
                      roomName: _room!.roomName,
                    )
                  : SimpleKakaoMap(
                      latitude: _room!.latitude,
                      longitude: _room!.longitude,
                      roomName: _room!.roomName,
                    ),
              // 지도 ↔ 로드뷰 토글 버튼 (우측하단)
              Positioned(
                bottom: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: AppRadius.radiusMd,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showRoadview = !_showRoadview;
                      });
                    },
                    borderRadius: AppRadius.radiusMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Text(
                        _showRoadview ? '지도 보기' : '로드뷰 보기',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 요금 안내 컨텐츠
  Widget _buildPricingContent() {
    // 관리비 포함 항목 문자열 생성
    final includedItems = <String>[];
    if (_room!.includeElectricity) includedItems.add('전기');
    if (_room!.includeWater) includedItems.add('수도');
    if (_room!.includeGas) includedItems.add('가스');
    if (_room!.includeInternet) includedItems.add('인터넷');
    final includedItemsText = includedItems.isNotEmpty
        ? '${includedItems.join(', ')} 포함'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 임대료 (1주)
        _buildPriceRow('임대료 (1주)', _room!.weeklyRent),
        const Divider(),

        // 2. 관리비 (1주)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '관리비 (1주)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(_room!.dailyMaintenanceFee * 7),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (includedItemsText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  includedItemsText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(),

        // 3. 청소비 (cleaningService 신청 시 5만원, 아니면 호스트 설정값)
        _buildPriceRow(
          '청소비',
          (_room!.freeService?.cleaningService == true) ? 50000 : _room!.cleaningFee,
        ),
        const Divider(),

        // 4. 보증금
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '보증금',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(_room!.deposit),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '제3자 예치기관에 보관되며, 퇴실 완료 후 자동 환급됩니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        // 5. 입주/퇴실 시간
        _buildInfoRow('입주 시간', '15:00 이후'),
        const SizedBox(height: 8),
        _buildInfoRow('퇴실 시간', '11:00 이전'),

        // 6. 장기 계약 할인
        if (_room!.longTermDiscount != null &&
            _room!.longTermDiscount! > 0) ...[
          const Divider(),
          _buildDiscountRow(
            '장기 계약 할인',
            '${_room!.longTermWeeks ?? 4}주 이상 계약 시 ${_room!.longTermDiscount}% 할인',
          ),
        ],

        // 7. 빠른 입주 할인
        if (_room!.quickMoveInDiscount != null &&
            _room!.quickMoveInDiscount! > 0) ...[
          const Divider(),
          _buildDiscountRow(
            '빠른 입주 할인',
            '${_room!.quickMoveIn ?? 3}일 이내 입주 시 ${_currencyFormat.format(_room!.quickMoveInDiscount)}원 할인',
          ),
        ],

        // 8. 환불 규정
        if (_room!.refundPolicy.isNotEmpty) ...[
          const Divider(),
          _buildDiscountRow('환불 규정', _room!.refundPolicy),
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

  /// 정보 행 (체크인/체크아웃 시간 등)
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 할인 정보 행
  Widget _buildDiscountRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 호스트 정보 컨텐츠
  Widget _buildHostContent() {
    final hostName = _room!.hostName ?? '호스트';
    final hostInitial = hostName.isNotEmpty ? hostName[0] : '?';
    final isVerified =
        _room!.hostPhoneVerified == true || _room!.hostAccountVerified == true;

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
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.primary600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        hostName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4), // green-50
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Color(0xFF15803D), // green-700
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '인증완료',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF15803D), // green-700
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '호스트',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      _currentPhotoIndex =
          (_currentPhotoIndex - 1 + _room!.photos.length) %
          _room!.photos.length;
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
                          child: Icon(
                            Icons.home,
                            size: 80,
                            color: AppColors.neutral400,
                          ),
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
                            icon: Icon(
                              Icons.chevron_left,
                              color: AppColors.neutral900,
                            ),
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
                            icon: Icon(
                              Icons.chevron_right,
                              color: AppColors.neutral900,
                            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPhotoIndex + 1} / ${_room!.photos.length}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.surface,
                        ),
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
                        color: isSelected
                            ? AppColors.primary600
                            : AppColors.neutral200,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary600.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        14,
                      ), // radiusLg - borderWidth
                      child: Image.network(
                        _room!.photos[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.neutral100,
                            child: Icon(
                              Icons.image,
                              color: AppColors.neutral400,
                              size: 24,
                            ),
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

    final canRequestContract =
        _bookingState.hasSelectedDates && validationError == null;

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
          if (_room!.longTermDiscount != null &&
              _room!.longTermDiscount! > 0) ...[
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
                    '${PriceCalculator.formatKRW((_room!.weeklyRent * (1 - _room!.longTermDiscount! / 100)).round())}/주',
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
            child: Column(children: _buildRentalItemsList()),
          ),

          // 최소 주문 금액 안내
          if (priceBreakdown.rentalItemsFee > 0 &&
              priceBreakdown.rentalItemsFee < 10000) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // amber-50
                borderRadius: AppRadius.radiusMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: const Color(0xFFD97706), // amber-600
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '옵션 상품은 최소 10,000원 이상 주문 가능합니다',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFD97706), // amber-600
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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

            _buildPriceRowDetailed(
              '임대료 (${_bookingState.selectedDays}일)',
              priceBreakdown.baseRent,
            ),
            if (priceBreakdown.longTermDiscount > 0)
              _buildPriceRowDetailed(
                '장기계약 할인',
                -priceBreakdown.longTermDiscount,
                isDiscount: true,
              ),
            _buildPriceRowDetailed(
              '관리비 (${_bookingState.selectedDays}일)',
              priceBreakdown.maintenanceFee,
            ),
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
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
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

    if (_room!.availableRentalItems == null)
      return [
        Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Text(
            '옵션 상품이 없습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
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
      items.add(_buildCompactRentalItem(item));

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
                                  _bookingState = _bookingState
                                      .updateRentalItem(
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
                                  _bookingState = _bookingState
                                      .updateRentalItem(
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
  Widget _buildPriceRowDetailed(
    String label,
    int amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDiscount
                  ? AppColors.primary600
                  : AppColors.textSecondary,
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
