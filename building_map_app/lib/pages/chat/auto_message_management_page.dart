import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auto_message_template.dart';
import '../../services/auto_message_service.dart';
import '../../widgets/chat/auto_message_form_modal.dart';
import '../../widgets/chat/auto_message_list_item.dart';

/// 자동메시지 관리 페이지
/// React AutoMessageManagement.tsx를 Flutter로 완전 복제
class AutoMessageManagementPage extends StatefulWidget {
  const AutoMessageManagementPage({super.key});

  @override
  State<AutoMessageManagementPage> createState() =>
      _AutoMessageManagementPageState();
}

class _AutoMessageManagementPageState extends State<AutoMessageManagementPage> {
  final AutoMessageService _autoMessageService = AutoMessageService();

  AutoMessageTemplate? _editingTemplate;
  List<AutoMessageTemplate> _templates = [];
  List<PropertyInfo> _properties = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// API에서 데이터 로드
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 병렬로 템플릿과 방 목록 로드
      final results = await Future.wait([
        _autoMessageService.getAutoMessages(),
        _autoMessageService.getHostProperties(),
      ]);

      setState(() {
        _templates = results[0] as List<AutoMessageTemplate>;
        _properties = results[1] as List<PropertyInfo>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.e('❌ [AUTO_MSG_PAGE] 데이터 로드 실패: $e');
    }
  }

  Future<void> _handleToggle(String id) async {
    try {
      await _autoMessageService.toggleAutoMessage(id);

      // 로컬 상태 업데이트
      setState(() {
        _templates = _templates.map((t) {
          if (t.id == id) {
            return t.copyWith(isActive: !t.isActive);
          }
          return t;
        }).toList();
      });
    } catch (e) {
      _showErrorSnackBar('토글 실패: $e');
    }
  }

  void _handleEdit(AutoMessageTemplate template) {
    _editingTemplate = template;
    _showFormModal();
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 자동메시지를 삭제하시겠습니까? 예정된 발송도 모두 취소됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error500,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _autoMessageService.deleteAutoMessage(id);

        setState(() {
          _templates = _templates.where((t) => t.id != id).toList();
        });

        _showSuccessSnackBar('자동메시지가 삭제되었습니다.');
      } catch (e) {
        _showErrorSnackBar('삭제 실패: $e');
      }
    }
  }

  Future<void> _handleSaveTemplate(AutoMessageTemplate template) async {
    try {
      if (_editingTemplate != null) {
        // Update existing
        final updated = await _autoMessageService.updateAutoMessage(
          template.copyWith(id: _editingTemplate!.id),
        );

        setState(() {
          _templates = _templates.map((t) {
            if (t.id == _editingTemplate!.id) {
              return updated;
            }
            return t;
          }).toList();
        });

        _showSuccessSnackBar('자동메시지가 수정되었습니다.');
      } else {
        // Create new
        final created = await _autoMessageService.createAutoMessage(template);

        setState(() {
          _templates = [..._templates, created];
        });

        _showSuccessSnackBar('자동메시지가 생성되었습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('저장 실패: $e');
    }

    _editingTemplate = null;
  }

  void _showFormModal() {
    AutoMessageFormModal.show(
      context: context,
      editingTemplate: _editingTemplate,
      properties: _properties,
      onSave: _handleSaveTemplate,
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success600,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // React: min-h-screen bg-gray-50
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// AppBar (React: PageHeader)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.neutral0,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        '자동메시지 관리',
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.neutral900,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.gray200,
          height: 1,
        ),
      ),
    );
  }

  /// Body (React: max-w-4xl mx-auto px-4 py-6 pb-24 lg:py-8 lg:pb-8)
  Widget _buildBody() {
    // 로딩 상태
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러 상태
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error500,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16, // px-4
              vertical: 24, // py-6
            ),
            child: Column(
              children: [
                // Add Button - Centered at top (React: flex justify-center mb-6)
                _buildAddButton(),
                const SizedBox(height: 24), // mb-6

                // Template List
                if (_templates.isEmpty)
                  _buildEmptyState()
                else
                  _buildTemplateList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 추가 버튼 (React: flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg)
  Widget _buildAddButton() {
    return InkWell(
      onTap: () {
        _editingTemplate = null;
        _showFormModal();
      },
      borderRadius: BorderRadius.circular(8), // rounded-lg
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24, // px-6
          vertical: 12, // py-3
        ),
        decoration: BoxDecoration(
          color: AppColors.blue600, // bg-blue-600
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add, // Plus
              size: 20, // w-5 h-5
              color: AppColors.neutral0, // text-white
            ),
            const SizedBox(width: 8), // gap-2
            Text(
              '자동메시지 추가',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0, // text-white
                fontWeight: FontWeight.bold, // font-bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 상태 (React: text-center py-12)
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48), // py-12
      child: Text(
        '등록된 자동메시지가 없습니다.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500, // text-gray-500
        ),
      ),
    );
  }

  /// 템플릿 목록 (React: space-y-4)
  Widget _buildTemplateList() {
    return Column(
      children: _templates
          .map((template) => Padding(
                padding: const EdgeInsets.only(bottom: 16), // space-y-4
                child: AutoMessageListItem(
                  template: template,
                  onToggle: () => _handleToggle(template.id),
                  onEdit: () => _handleEdit(template),
                  onDelete: () => _handleDelete(template.id),
                ),
              ))
          .toList(),
    );
  }

}
