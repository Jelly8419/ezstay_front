import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/registration_flow_indicator.dart';
import '../services/room_service.dart';
import '../widgets/common/responsive_page_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/app_buttons.dart';

/// 방 소개 페이지
class RoomDescriptionPage extends StatefulWidget {
  final int? roomId;
  const RoomDescriptionPage({super.key, this.roomId});

  @override
  State<RoomDescriptionPage> createState() => _RoomDescriptionPageState();
}

class _RoomDescriptionPageState extends State<RoomDescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _transportationController = TextEditingController();
  final TextEditingController _houseRulesController = TextEditingController();
  final _roomService = RoomService();
  int? _roomId;

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
        // 방 소개 정보가 있으면 채우기
        if (roomData['description'] != null) {
          _descriptionController.text = roomData['description'];
        }
        if (roomData['transportation'] != null) {
          _transportationController.text = roomData['transportation'];
        }
        if (roomData['houseRules'] != null) {
          _houseRulesController.text = roomData['houseRules'];
        }
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _transportationController.dispose();
    _houseRulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방 소개', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const RegistrationFlowIndicator(currentStep: 4),
          Expanded(
            child: ResponsivePageLayout(
              child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // 섹션1: 방 소개
                  _buildSectionTitle('방 소개'),
                  _buildDescriptionCard(),
                  const SizedBox(height: 24),

                  // 섹션2: 교통편 및 주변 정보
                  _buildSectionTitle('교통편 및 주변 정보'),
                  _buildTransportationCard(),
                  const SizedBox(height: 24),

                  // 섹션3: 하우스 룰
                  _buildSectionTitle('하우스 룰'),
                  _buildHouseRulesCard(),
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
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: AppRadius.radiusXs,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(title, style: AppTextStyles.headingLarge),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.neutral200, width: 1),
        boxShadow: AppShadows.shadowSm,
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _descriptionController,
              maxLines: 10,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '방에 대한 자세한 설명을 입력하세요\n\n예시:\n- 방의 특징 및 장점\n- 주변 환경 및 편의시설\n- 게스트가 알아야 할 중요한 정보',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMd,
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMd,
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMd,
                  borderSide: const BorderSide(color: AppColors.primary600, width: 2),
                ),
                contentPadding: AppSpacing.paddingMd,
                counterText: '${_descriptionController.text.length}/1000',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '방 소개를 입력해주세요';
                }
                if (value.length < 50) {
                  return '방 소개는 최소 50자 이상 입력해주세요';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            _buildBlueInfoBox([
              '• 방의 특징, 장점, 주변 환경 등을 상세히 작성해주세요.',
              '• 게스트가 궁금해할 만한 정보를 미리 제공하면 문의가 줄어듭니다.',
              '• 최소 50자 이상 작성해주세요.',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.neutral200, width: 1),
        boxShadow: AppShadows.shadowSm,
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _transportationController,
              maxLines: 8,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '교통편 및 주변 정보를 입력하세요\n\n예시:\n- 지하철역: 2호선 홍대입구역 5번 출구 도보 3분\n- 버스: 간선버스 271, 273번\n- 편의점: GS25 도보 1분\n- 카페: 스타벅스 도보 2분',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterText: '${_transportationController.text.length}/500',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            _buildBlueInfoBox([
              '• 대중교통 이용 방법과 소요 시간을 구체적으로 알려주세요.',
              '• 주변 편의시설(편의점, 마트, 카페 등)과의 거리를 안내해주세요.',
              '• 게스트가 쉽게 찾아올 수 있도록 상세한 정보를 제공해주세요.',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseRulesCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.neutral200, width: 1),
        boxShadow: AppShadows.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _houseRulesController,
              maxLines: 8,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '하우스 룰을 입력하세요\n\n예시:\n- 흡연 금지\n- 반려동물 동반 불가\n- 10시 이후 소음 자제\n- 게스트 외 방문객 출입 금지\n- 공용 공간 사용 후 정리 정돈',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterText: '${_houseRulesController.text.length}/500',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            _buildBlueInfoBox([
              '• 게스트가 꼭 지켜야 할 규칙을 명확하게 작성해주세요.',
              '• 흡연, 반려동물, 소음, 방문객 등에 대한 규칙을 포함해주세요.',
              '• 분쟁을 예방하기 위해 사전에 규칙을 명시하는 것이 중요합니다.',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueInfoBox(List<String> items) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.info50,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              item,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info700,
                height: 1.6,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250,
          child: AppSecondaryButton(
            text: '이전으로',
            onPressed: () {
              if (_roomId != null) {
                context.go('/host/free-services/$_roomId');
              } else {
                context.pop();
              }
            },
          ),
        ),
        SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 250,
          child: AppPrimaryButton(
            text: '심사요청',
            onPressed: () async {
              if (_roomId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('방 ID가 없습니다. 처음부터 다시 시작해주세요.'),
                    backgroundColor: AppColors.error500,
                  ),
                );
                return;
              }

              if (_formKey.currentState!.validate()) {
                // 1. 방 소개 데이터 수집
                final descriptionData = {
                  'description': _descriptionController.text,
                  'transportation': _transportationController.text,
                  'houseRules': _houseRulesController.text,
                };

                // 2. 방 소개 정보 전송
                final descSuccess = await _roomService.updateDescription(_roomId!, descriptionData);

                if (!descSuccess && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('방 소개 정보 저장에 실패했습니다.'),
                      backgroundColor: AppColors.error500,
                    ),
                  );
                  return;
                }

                // 3. 심사 요청
                final reviewSuccess = await _roomService.submitReview(_roomId!);

                if (reviewSuccess && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('심사요청이 완료되었습니다. 검토 후 연락드리겠습니다.'),
                      backgroundColor: AppColors.success500,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // 호스트 홈으로 이동
                  context.go('/host');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('심사 요청에 실패했습니다. 필수 정보를 모두 입력했는지 확인해주세요.'),
                      backgroundColor: AppColors.error500,
                    ),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
