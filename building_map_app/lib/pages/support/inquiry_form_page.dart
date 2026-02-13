import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/inquiry.dart';
import '../../services/auth_service.dart';
import '../../services/support_service.dart';
import '../../widgets/common/app_footer.dart';

class InquiryFormPage extends StatefulWidget {
  final int? inquiryId;

  const InquiryFormPage({
    super.key,
    this.inquiryId,
  });

  @override
  State<InquiryFormPage> createState() => _InquiryFormPageState();
}

class _InquiryFormPageState extends State<InquiryFormPage> {
  final SupportService _supportService = SupportService();

  bool get _isEditMode => widget.inquiryId != null;

  InquiryCategoryType? _categoryType;
  String _title = '';
  String _content = '';
  bool _loading = false;
  bool _fetchLoading = false;
  Map<String, String> _errors = {};
  String? _errorMessage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _fetchInquiry(widget.inquiryId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchInquiry(int inquiryId) async {
    setState(() {
      _fetchLoading = true;
      _errorMessage = null;
    });

    try {
      final inquiry = await _supportService.getInquiryDetail(inquiryId);

      if (inquiry != null) {
        // 수정 가능한 상태인지 확인
        if (!inquiry.canEdit) {
          _showSnackBar('답변이 완료된 문의는 수정할 수 없습니다');
          if (mounted) {
            context.go('/support?tab=inquiries');
          }
          return;
        }

        setState(() {
          _categoryType = inquiry.categoryType;
          _title = inquiry.title;
          _content = inquiry.content;
          _titleController.text = _title;
          _contentController.text = _content;
        });
      } else {
        setState(() {
          _errorMessage = '문의 정보를 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch inquiry: $e');
      setState(() {
        _errorMessage = '문의 정보를 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _fetchLoading = false;
      });
    }
  }

  bool _validateForm() {
    final newErrors = <String, String>{};

    if (_categoryType == null) {
      newErrors['category'] = '카테고리를 선택해주세요';
    }
    if (_title.trim().isEmpty) {
      newErrors['title'] = '제목을 입력해주세요';
    }
    if (_content.trim().isEmpty) {
      newErrors['content'] = '문의 내용을 입력해주세요';
    }

    setState(() {
      _errors = newErrors;
    });

    return newErrors.isEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      if (_isEditMode) {
        // 문의 수정
        final request = UpdateInquiryRequest(
          categoryType: _categoryType,
          title: _title.trim(),
          content: _content.trim(),
        );

        final result = await _supportService.updateInquiry(
          widget.inquiryId!,
          request,
        );

        if (result != null) {
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('수정 완료'),
                content: const Text('문의가 수정되었습니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
            if (mounted) {
              context.go('/support?tab=inquiries');
            }
          }
        } else {
          _showSnackBar('문의 수정에 실패했습니다. 다시 시도해주세요.');
        }
      } else {
        // 문의 등록
        final authService = Provider.of<AuthService>(context, listen: false);
        final userType = authService.currentUser?.mode.name ?? 'guest';

        final request = CreateInquiryRequest(
          categoryType: _categoryType!,
          title: _title.trim(),
          content: _content.trim(),
          userType: userType,
        );

        final result = await _supportService.createInquiry(request);

        if (result != null) {
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('등록 완료'),
                content: const Text('문의가 등록되었습니다.\n최대한 빠른 시일 내에 답변드리겠습니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
            if (mounted) {
              context.go('/support?tab=inquiries');
            }
          }
        } else {
          _showSnackBar('문의 등록에 실패했습니다. 다시 시도해주세요.');
        }
      }
    } catch (e) {
      debugPrint('Failed to submit inquiry: $e');
      _showSnackBar('문의 등록에 실패했습니다. 다시 시도해주세요.');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _fetchLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      context.go('/support?tab=inquiries');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _isEditMode ? '문의 수정' : '문의사항 등록',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '오류가 발생했습니다',
            style: const TextStyle(
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              context.go('/support?tab=inquiries');
            },
            child: const Text('목록으로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 896),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.neutral0,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryField(),
                      const SizedBox(height: 24),
                      _buildTitleField(),
                      const SizedBox(height: 24),
                      _buildContentField(),
                      const SizedBox(height: 24),
                      _buildNotice(),
                      const SizedBox(height: 32),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: '문의 유형 ',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.neutral0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InquiryCategoryType>(
              value: _categoryType,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '카테고리를 선택하세요',
                  style: TextStyle(
                    color: AppColors.neutral400,
                  ),
                ),
              ),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(8),
              items: InquiryCategoryType.values.map((category) {
                return DropdownMenuItem<InquiryCategoryType>(
                  value: category,
                  child: Text(category.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryType = value;
                });
              },
            ),
          ),
        ),
        if (_errors.containsKey('category')) ...[
          const SizedBox(height: 8),
          Text(
            _errors['category']!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: '제목 ',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.neutral0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _titleController,
            maxLength: 100,
            onChanged: (value) {
              setState(() {
                _title = value;
              });
            },
            decoration: const InputDecoration(
              hintText: '제목을 입력하세요',
              hintStyle: TextStyle(
                color: AppColors.neutral400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              counterText: '',
            ),
          ),
        ),
        if (_errors.containsKey('title')) ...[
          const SizedBox(height: 8),
          Text(
            _errors['title']!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: '문의 내용 ',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.neutral0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _contentController,
            maxLength: 1000,
            maxLines: null,
            minLines: 8,
            onChanged: (value) {
              setState(() {
                _content = value;
              });
            },
            decoration: const InputDecoration(
              hintText: '문의 내용을 상세히 입력해주세요',
              hintStyle: TextStyle(
                color: AppColors.neutral400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_errors.containsKey('content'))
              Text(
                _errors['content']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              )
            else
              const SizedBox(),
            Text(
              '${_content.length} / 1,000자',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '안내사항',
            style: TextStyle(
              color: AppColors.gray900,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '• 문의 내용을 상세히 작성해주시면 더 정확한 답변을 받으실 수 있습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• 답변은 영업일 기준 1~2일 소요됩니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• 답변 완료 후에는 수정 및 삭제가 불가능합니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // 취소 버튼
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                context.go('/support?tab=inquiries');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neutral700,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('취소'),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 등록/수정 버튼
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: AppColors.neutral0,
                disabledBackgroundColor: const Color(0xFF93C5FD),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _loading ? '처리 중...' : (_isEditMode ? '수정하기' : '등록하기'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
