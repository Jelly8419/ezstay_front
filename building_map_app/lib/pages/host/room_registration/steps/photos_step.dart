import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/form_section.dart';
import '../components/option_toggle.dart';
import '../components/draggable_image_grid.dart';

/// 침대 선택 정보
class BedSelection {
  final String size;
  final int count;

  BedSelection({required this.size, required this.count});

  Map<String, dynamic> toJson() => {'size': size, 'count': count};
}

/// Step 2: 사진 및 편의옵션 (리액트 PhotosStep 복제)
class PhotosStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final List<String> validationErrors;

  const PhotosStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.validationErrors,
  });

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _wifiPasswordController;

  @override
  void initState() {
    super.initState();
    _wifiPasswordController = TextEditingController(
      text: (widget.formData['wifiPassword'] as String?) ?? '',
    );
  }

  @override
  void dispose() {
    _wifiPasswordController.dispose();
    super.dispose();
  }

  // 기본 옵션 리스트
  static const List<String> _basicOptionsList = [
    '침대',
    '인터넷(wi-fi)',
    '냉장고',
    '세탁기',
    'TV',
    '에어컨',
  ];

  // 추가 편의옵션 리스트
  static const List<String> _conveniences = [
    '전자레인지',
    '건조기',
    '공기청정기',
    '책상',
    '의자',
    '옷장',
    '소파',
    '헤어드라이기',
    '비데',
    '샤워부스',
    '욕조',
    '정수기',
    '전기포트',
    '식기',
    '조리도구',
    '발코니/베란다',
    '도어락',
    'CCTV',
    '관리실',
    '반려동물 가능',
  ];

  // 침대 크기 리스트
  static const List<String> _bedSizes = ['싱글', '슈퍼싱글', '퀸', '킹'];

  List<String> get _uploadedImages =>
      (widget.formData['uploadedImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  List<String> get _basicOptions =>
      (widget.formData['basicOptions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  List<String> get _selectedOptions =>
      (widget.formData['selectedOptions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  List<BedSelection> get _bedSelections {
    final data = widget.formData['bedSelections'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map(
          (e) =>
              BedSelection(size: e['size'] as String, count: e['count'] as int),
        )
        .toList();
  }

  void _updateFormData(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(widget.formData);
    updated[key] = value;
    widget.onFormDataChange(updated);
  }

  Future<void> _handleImageUpload() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final newImages = images.map((xFile) => xFile.path).toList();
        final updatedImages = [..._uploadedImages, ...newImages];

        // XFile 객체도 함께 저장 (API 업로드용)
        final rawXFiles = widget.formData['uploadedXFiles'];
        final existingXFiles = rawXFiles is List
            ? rawXFiles.whereType<XFile>().toList()
            : <XFile>[];
        final updatedXFiles = [...existingXFiles, ...images];

        // 최대 20장 제한
        if (updatedImages.length > 20) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('최대 20장까지 업로드 가능합니다')));
          }
          _updateFormData('uploadedImages', updatedImages.sublist(0, 20));
          _updateFormData('uploadedXFiles', updatedXFiles.sublist(0, 20));
        } else {
          _updateFormData('uploadedImages', updatedImages);
          _updateFormData('uploadedXFiles', updatedXFiles);
        }
      }
    } catch (e) {
      debugPrint('이미지 업로드 에러: $e');
    }
  }

  void _removeImage(int index) {
    final updated = List<String>.from(_uploadedImages);
    final removedImageUrl = updated[index];
    updated.removeAt(index);
    _updateFormData('uploadedImages', updated);

    // XFile 목록에서도 제거
    final rawXFiles = widget.formData['uploadedXFiles'];
    final xFiles = rawXFiles is List
        ? rawXFiles.whereType<XFile>().toList()
        : <XFile>[];
    if (index < xFiles.length) {
      final updatedXFiles = List<XFile>.from(xFiles);
      updatedXFiles.removeAt(index);
      _updateFormData('uploadedXFiles', updatedXFiles);
    }

    // 서버에 업로드된 사진인 경우 삭제할 photoId 추적
    final uploadedPhotos =
        (widget.formData['uploadedPhotos'] as List<dynamic>?) ?? [];
    if (index < uploadedPhotos.length) {
      final photoObject = uploadedPhotos[index] as Map<String, dynamic>;
      if (photoObject['id'] != null) {
        // deletedPhotoIds 리스트에 추가
        final deletedPhotoIds =
            (widget.formData['deletedPhotoIds'] as List<int>?) ?? [];
        deletedPhotoIds.add(photoObject['id'] as int);
        _updateFormData('deletedPhotoIds', deletedPhotoIds);

        debugPrint('🗑️ 사진 삭제 예약: photoId=${photoObject['id']}, url=$removedImageUrl');
      }

      // uploadedPhotos 리스트에서도 제거
      final updatedPhotos = List<Map<String, dynamic>>.from(
        uploadedPhotos.map((e) => e as Map<String, dynamic>),
      );
      updatedPhotos.removeAt(index);
      _updateFormData('uploadedPhotos', updatedPhotos);
    }
  }

  void _toggleBasicOption(String option) {
    final updated = List<String>.from(_basicOptions);
    if (updated.contains(option)) {
      updated.remove(option);

      // 침대 옵션 해제 시 침대 선택 초기화
      if (option == '침대') {
        _updateFormData('bedSelections', []);
      }
      // Wi-Fi 옵션 해제 시 비밀번호 초기화
      if (option == '인터넷(wi-fi)') {
        _wifiPasswordController.clear();
        _updateFormData('wifiPassword', '');
      }
    } else {
      updated.add(option);
    }
    _updateFormData('basicOptions', updated);
  }

  void _toggleOption(String option) {
    final updated = List<String>.from(_selectedOptions);
    if (updated.contains(option)) {
      updated.remove(option);
    } else {
      updated.add(option);
    }
    _updateFormData('selectedOptions', updated);
  }

  void _addBedSize(String size) {
    final updated = List<BedSelection>.from(_bedSelections);
    final existing = updated.firstWhere(
      (b) => b.size == size,
      orElse: () => BedSelection(size: '', count: 0),
    );

    if (existing.size.isNotEmpty) {
      // 기존 침대 크기의 개수 증가
      final index = updated.indexWhere((b) => b.size == size);
      updated[index] = BedSelection(size: size, count: existing.count + 1);
    } else {
      // 새 침대 크기 추가
      updated.add(BedSelection(size: size, count: 1));
    }

    _updateFormData('bedSelections', updated.map((b) => b.toJson()).toList());
  }

  void _updateBedCount(String size, int delta) {
    final updated = List<BedSelection>.from(_bedSelections);
    final index = updated.indexWhere((b) => b.size == size);

    if (index != -1) {
      final newCount = (updated[index].count + delta).clamp(0, 99);
      if (newCount == 0) {
        updated.removeAt(index);
      } else {
        updated[index] = BedSelection(size: size, count: newCount);
      }
      _updateFormData('bedSelections', updated.map((b) => b.toJson()).toList());
    }
  }

  void _removeBedSelection(String size) {
    final updated = _bedSelections.where((b) => b.size != size).toList();
    _updateFormData('bedSelections', updated.map((b) => b.toJson()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사진 업로드 섹션
          FormSection(
            icon: Icons.camera_alt,
            title: '방 사진',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 및 카운트
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '방 사진',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${_uploadedImages.length} / 20${_uploadedImages.length < 5 ? ' (최소 5장)' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _uploadedImages.length >= 5
                            ? AppColors.success600
                            : AppColors.error600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 업로드 버튼 (20장 미만일 때만 표시)
                if (_uploadedImages.length < 20)
                  InkWell(
                    onTap: _handleImageUpload,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 128,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.gray300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload,
                              size: 32,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '사진을 업로드하세요 (최소 5장, 최대 20장)',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 이미지 그리드
                if (_uploadedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DraggableImageGrid(
                    images: _uploadedImages,
                    onReorder: (reordered) =>
                        _updateFormData('uploadedImages', reordered),
                    onRemove: _removeImage,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '* 첫 번째 사진이 대표 사진으로 설정되며, 드래그하여 사진 순서를 변경할 수 있습니다.',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
                  ),
                  if (_uploadedImages.length < 5) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ 최소 5장의 사진을 업로드해주세요',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error600),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 기본 옵션 섹션
          FormSection(
            title: '기본 옵션',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '방에 제공되는 기본 옵션을 선택해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _basicOptionsList.map((option) {
                    return OptionToggle(
                      label: option,
                      selected: _basicOptions.contains(option),
                      onToggle: () => _toggleBasicOption(option),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 침대 정보 섹션 (침대 옵션 선택 시에만 표시)
          if (_basicOptions.contains('침대')) ...[
            const SizedBox(height: 32),
            FormSection(
              icon: Icons.bed,
              title: '침대 정보',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '침대 크기 선택',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bedSizes.map((size) {
                      return ElevatedButton.icon(
                        onPressed: () => _addBedSize(size),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(size),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.gray300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // 선택된 침대 목록
                  if (_bedSelections.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._bedSelections.map((bed) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bed.size,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                // 감소 버튼
                                IconButton(
                                  onPressed: () =>
                                      _updateBedCount(bed.size, -1),
                                  icon: const Icon(Icons.remove, size: 16),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(32, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: AppColors.gray300,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 개수 표시
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${bed.count}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 증가 버튼
                                IconButton(
                                  onPressed: () => _updateBedCount(bed.size, 1),
                                  icon: const Icon(Icons.add, size: 16),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(32, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: AppColors.gray300,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 삭제 버튼
                                IconButton(
                                  onPressed: () =>
                                      _removeBedSelection(bed.size),
                                  icon: const Icon(Icons.close, size: 16),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.error50,
                                    foregroundColor: AppColors.error600,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(32, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],

          // Wi-Fi 비밀번호 섹션 (인터넷(wi-fi) 옵션 선택 시에만 표시)
          if (_basicOptions.contains('인터넷(wi-fi)')) ...[
            const SizedBox(height: 32),
            FormSection(
              icon: Icons.wifi,
              title: 'Wi-Fi 비밀번호',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _wifiPasswordController,
                    onChanged: (value) =>
                        _updateFormData('wifiPassword', value),
                    decoration: InputDecoration(
                      hintText: 'Wi-Fi 비밀번호를 입력해주세요',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary600,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '* 지금 입력하지 않아도 괜찮아요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 추가 편의옵션 섹션
          const SizedBox(height: 32),
          FormSection(
            title: '추가 편의옵션 (선택)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '추가로 제공되는 편의옵션을 선택해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _conveniences.map((option) {
                    return OptionToggle(
                      label: option,
                      selected: _selectedOptions.contains(option),
                      onToggle: () => _toggleOption(option),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
