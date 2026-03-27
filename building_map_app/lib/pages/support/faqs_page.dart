import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/faq.dart';
import '../../services/support_service.dart';
import '../../widgets/common/app_footer.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  final SupportService _supportService = SupportService();

  List<FAQCategory> _categories = [];
  List<FAQ> _faqs = [];
  int? _selectedCategory;
  int? _expandedFaq;
  String _searchTerm = '';
  bool _loading = true;
  String? _errorMessage;

  // TODO: Get user mode from auth context
  final String _userMode = 'guest';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchFAQs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _supportService.getFAQCategories(
        userType: _userMode,
      );

      if (categories != null) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch categories: $e');
    }
  }

  Future<void> _fetchFAQs() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final faqs = await _supportService.getFAQs(
        categoryId: _selectedCategory,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
        userType: _userMode,
      );

      if (faqs != null) {
        setState(() {
          _faqs = faqs;
        });
      } else {
        setState(() {
          _errorMessage = 'FAQ를 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch FAQs: $e');
      setState(() {
        _errorMessage = 'FAQ를 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _toggleFaq(int faqId) {
    setState(() {
      _expandedFaq = _expandedFaq == faqId ? null : faqId;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
    });
    _fetchFAQs();
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    _fetchFAQs();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
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
                      context.go('/support');
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '자주 묻는 질문',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userMode == 'host' ? '호스트 모드' : '게스트 모드',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchInput(),
                    const SizedBox(height: 24),
                    _buildCategoryTabs(),
                    const SizedBox(height: 24),
                    _buildFAQList(),
                    const SizedBox(height: 32),
                    _buildHelpText(),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              size: 20,
              color: AppColors.neutral400,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: '궁금한 내용을 검색하세요',
                hintStyle: TextStyle(
                  color: AppColors.neutral400,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _buildCategoryButton(null, '전체'),
              const SizedBox(width: 8),
              ..._categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryButton(
                    category.id,
                    '${category.name} (${category.faqCount})',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(int? categoryId, String label) {
    final isSelected = _selectedCategory == categoryId;

    return InkWell(
      onTap: () => _onCategorySelected(categoryId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : AppColors.neutral0,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.neutral0
                : AppColors.neutral700,
          ),
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
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
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchFAQs,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_faqs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            _searchTerm.isNotEmpty ? '검색 결과가 없습니다' : '등록된 FAQ가 없습니다',
            style: const TextStyle(
              color: AppColors.gray600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _faqs.asMap().entries.map((entry) {
        final faq = entry.value;
        final isExpanded = _expandedFaq == faq.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFAQItem(faq, isExpanded),
        );
      }).toList(),
    );
  }

  Widget _buildFAQItem(FAQ faq, bool isExpanded) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Question Button
          InkWell(
            onTap: () => _toggleFaq(faq.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Q Badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'Q',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Question Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Text
                        Padding(
                          padding: const EdgeInsets.only(right: 32),
                          child: Text(
                            faq.question,
                            style: const TextStyle(
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Category Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                faq.categoryName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.neutral700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand Icon
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.neutral400,
                  ),
                ],
              ),
            ),
          ),

          // Answer (Expanded)
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: const BoxDecoration(
                color: AppColors.gray50,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A Badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.gray300,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Answer Text
                    Expanded(
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: AppColors.neutral700,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpText() {
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
            '원하는 답변을 찾지 못하셨나요?',
            style: TextStyle(
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              context.push('/support/inquiries/new');
            },
            child: const Text(
              '문의하기 →',
              style: TextStyle(
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
