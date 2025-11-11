import 'package:flutter/material.dart';
import '../../models/faq.dart';
import '../../services/support_service.dart';
import '../../widgets/support/faq_accordion.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../constants/app_constants.dart';

/// FAQ 목록 페이지
class FAQListPage extends StatefulWidget {
  const FAQListPage({super.key});

  @override
  State<FAQListPage> createState() => _FAQListPageState();
}

class _FAQListPageState extends State<FAQListPage> {
  final SupportService _supportService = SupportService();
  final TextEditingController _searchController = TextEditingController();

  List<FAQCategory> _categories = [];
  Map<String, List<FAQ>> _faqsByCategory = {};
  FAQCategory? _selectedCategory;
  String _searchKeyword = '';

  bool _isLoadingCategories = true;
  bool _isLoadingFAQs = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 카테고리 로드
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _hasError = false;
    });

    try {
      final categories = await _supportService.getFAQCategories(
        userType: 'all', // 모든 사용자 대상
      );

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });

      // 카테고리 로드 후 FAQ 로드
      _loadFAQs();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoadingCategories = false;
      });
    }
  }

  /// FAQ 목록 로드
  Future<void> _loadFAQs() async {
    setState(() {
      _isLoadingFAQs = true;
      _hasError = false;
    });

    try {
      final response = await _supportService.getFAQs(
        categoryId: _selectedCategory?.id,
        userType: 'all',
        searchKeyword: _searchKeyword.isEmpty ? null : _searchKeyword,
      );

      setState(() {
        _faqsByCategory = response.faqsByCategory;
        _isLoadingFAQs = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoadingFAQs = false;
      });
    }
  }

  /// 검색 실행
  void _onSearch() {
    _loadFAQs();
  }

  /// 검색어 클리어
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
    });
    _loadFAQs();
  }

  /// 카테고리 선택
  void _onCategorySelected(FAQCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadFAQs();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: '자주 묻는 질문',
      useGNB: true,
      useCardStyle: false,
      scrollable: false,  // Column + Expanded가 레이아웃을 처리하므로 외부 스크롤 비활성화
      usePadding: false,  // 각 위젯에 padding이 있으므로 외부 패딩 비활성화
      body: Column(
        children: [
          // 검색바
          _buildSearchBar(),
          // 카테고리 탭
          if (!_isLoadingCategories && _categories.isNotEmpty)
            _buildCategoryTabs(),
          // FAQ 목록
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  /// 검색바
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'FAQ 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                filled: true,
                fillColor: AppColors.grey50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                });
              },
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }

  /// 카테고리 탭
  Widget _buildCategoryTabs() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.grey200),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 전체 탭
          _buildCategoryChip(
            label: '전체',
            isSelected: _selectedCategory == null,
            onTap: () => _onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          // 카테고리 탭들
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                label: category.name,
                isSelected: _selectedCategory?.id == category.id,
                onTap: () => _onCategorySelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 카테고리 칩
  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.grey300,
      ),
    );
  }

  /// 본문
  Widget _buildBody() {
    if (_isLoadingCategories || _isLoadingFAQs) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'FAQ를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_faqsByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchKeyword.isNotEmpty
                  ? '검색 결과가 없습니다'
                  : '등록된 FAQ가 없습니다',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFAQs,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _faqsByCategory.length,
        itemBuilder: (context, index) {
          final categoryName = _faqsByCategory.keys.elementAt(index);
          final faqs = _faqsByCategory[categoryName]!;

          return FAQCategorySection(
            categoryName: categoryName,
            faqs: faqs,
          );
        },
      ),
    );
  }
}
