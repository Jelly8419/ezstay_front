import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/notice.dart';
import '../../models/faq.dart';
import '../../models/inquiry.dart';
import '../../services/auth_service.dart';
import '../../services/support_service.dart';
import '../../widgets/common/app_footer.dart';
import '../../core/utils/seo_helper.dart';

class CustomerCenterPage extends StatefulWidget {
  /// 초기 탭: 'notices', 'faqs', 'inquiries'
  final String? initialTab;

  const CustomerCenterPage({super.key, this.initialTab});

  @override
  State<CustomerCenterPage> createState() => _CustomerCenterPageState();
}

class _CustomerCenterPageState extends State<CustomerCenterPage> {
  final SupportService _supportService = SupportService();

  String _activeTab = 'notices'; // notices, faqs, inquiries
  int? _expandedFaqId;
  int? _expandedInquiryId;
  int? _selectedCategory;

  // 공지사항 상태
  List<Notice> _notices = [];
  bool _noticesLoading = true;
  String? _noticesError;

  // FAQ 상태
  List<FAQCategory> _faqCategories = [];
  List<FAQ> _faqs = [];
  bool _faqsLoading = true;
  String? _faqsError;

  // 문의 상태
  List<Inquiry> _inquiries = [];
  bool _inquiriesLoading = true;
  String? _inquiriesError;

  /// 현재 사용자 모드 (host/guest)
  String get _userMode {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUser?.mode.name ?? 'guest';
  }

  @override
  void initState() {
    super.initState();
    // 초기 탭 설정
    if (widget.initialTab != null &&
        ['notices', 'faqs', 'inquiries'].contains(widget.initialTab)) {
      _activeTab = widget.initialTab!;
    }
    // initState에서는 context 사용 불가, didChangeDependencies에서 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updatePage(
        title: '고객센터 | 이지스테이(EZstay)',
        description: '공지사항, 자주 묻는 질문, 1:1 문의 등 이지스테이(EZstay) 고객센터를 이용해보세요.',
        canonicalPath: '/support',
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 첫 번째 호출에서만 데이터 로드
    if (_noticesLoading && _notices.isEmpty) {
      _fetchNotices();
      _fetchFAQs();
      _fetchInquiries();
    }
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _noticesLoading = true;
      _noticesError = null;
    });

    try {
      final result = await _supportService.getNotices(
        page: 1,
        limit: 10,
      );

      if (result != null) {
        setState(() {
          _notices = result.items;
        });
      } else {
        setState(() {
          _noticesError = '공지사항을 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch notices: $e');
      setState(() {
        _noticesError = '공지사항을 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _noticesLoading = false;
      });
    }
  }

  Future<void> _fetchFAQs() async {
    setState(() {
      _faqsLoading = true;
      _faqsError = null;
    });

    try {
      final faqs = await _supportService.getFAQs(
        categoryId: _selectedCategory,
        userType: _userMode,
      );

      if (faqs != null) {
        setState(() {
          _faqs = faqs;
          // 전체 조회 시 FAQ 데이터로 카테고리 목록 및 카운트 계산
          if (_selectedCategory == null) {
            final countMap = <int, int>{};
            final categoryMap = <int, FAQCategory>{};
            for (final faq in faqs) {
              countMap[faq.categoryId] = (countMap[faq.categoryId] ?? 0) + 1;
              if (faq.category != null && faq.category!.name != '전체') {
                categoryMap[faq.categoryId] = faq.category!;
              }
            }
            final categories = categoryMap.values.toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            _faqCategories = categories.map((cat) => FAQCategory(
              id: cat.id,
              name: cat.name,
              userType: cat.userType,
              displayOrder: cat.displayOrder,
              faqCount: countMap[cat.id] ?? 0,
            )).toList();
          }
        });
      } else {
        setState(() {
          _faqsError = 'FAQ를 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch FAQs: $e');
      setState(() {
        _faqsError = 'FAQ를 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _faqsLoading = false;
      });
    }
  }

  Future<void> _fetchInquiries() async {
    setState(() {
      _inquiriesLoading = true;
      _inquiriesError = null;
    });

    try {
      final result = await _supportService.getMyInquiries(
        page: 1,
        limit: 10,
        userType: _userMode,
      );

      if (result != null) {
        setState(() {
          _inquiries = result.items;
        });
      } else {
        setState(() {
          _inquiriesError = '문의 내역을 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch inquiries: $e');
      setState(() {
        _inquiriesError = '문의 내역을 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _inquiriesLoading = false;
      });
    }
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
      color: AppColors.gray50, // bg-gray-50
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Content Area
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
        color: AppColors.neutral0, // bg-white
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1), // border-b
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200), // GNB와 동일한 maxWidth
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24), // GNB의 AppSpacing.lg와 동일
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24), // py-6
                  child: Text(
                    '고객센터',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                ),
                // Tab Navigation
                _buildTabNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    final tabs = [
      {'id': 'notices', 'label': '공지사항'},
      {'id': 'faqs', 'label': '자주 묻는 질문'},
      {'id': 'inquiries', 'label': '문의하기'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab['id'];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = tab['id']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, // px-4
                  vertical: 12, // py-3
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF3B82F6) // border-[#3B82F6]
                          : Colors.transparent, // border-transparent
                      width: 2, // border-b-2
                    ),
                  ),
                ),
                child: SelectionContainer.disabled(
                  child: Text(
                    tab['label']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700, // font-bold
                      color: isActive
                          ? const Color(0xFF3B82F6) // text-[#3B82F6]
                          : AppColors.gray600, // text-gray-600
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildActiveTabContent(),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'notices':
        return _buildNoticesContent();
      case 'faqs':
        return _buildFaqsContent();
      case 'inquiries':
        return _buildInquiriesContent();
      default:
        return _buildNoticesContent();
    }
  }

  // ============= 공지사항 탭 =============
  Widget _buildNoticesContent() {
    if (_noticesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_noticesError != null) {
      return _buildErrorView(
        message: _noticesError!,
        onRetry: _fetchNotices,
      );
    }

    if (_notices.isEmpty) {
      return _buildEmptyView(message: '등록된 공지사항이 없습니다');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0, // bg-white
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // shadow-sm
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.gray200), // border border-gray-200
      ),
      child: Column(
        children: _notices.asMap().entries.map((entry) {
          final index = entry.key;
          final notice = entry.value;
          final isLast = index == _notices.length - 1;

          return InkWell(
            onTap: () {
              context.push('/support/notices/${notice.id}');
            },
            child: Container(
              padding: const EdgeInsets.all(24), // p-6
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: AppColors.gray200), // border-b border-gray-200
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 배지 및 날짜
                        Row(
                          children: [
                            if (notice.isImportant)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, // px-2
                                  vertical: 2, // py-0.5
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.blue100, // bg-blue-100
                                  borderRadius:
                                      BorderRadius.circular(4), // rounded
                                ),
                                child: Text(
                                  '공지',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            Text(
                              notice.formattedDate,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // mb-2
                        // 제목
                        Text(
                          notice.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, // font-bold
                            color: AppColors.gray900, // text-gray-900
                          ),
                        ),
                        const SizedBox(height: 4), // mb-1
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20, // w-5 h-5
                    color: AppColors.neutral400, // text-gray-400
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============= 자주 묻는 질문 탭 =============
  Widget _buildFaqsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 필터
        _buildCategoryFilter(),
        const SizedBox(height: 24), // mb-6
        // FAQ 목록
        if (_faqsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_faqsError != null)
          _buildErrorView(
            message: _faqsError!,
            onRetry: _fetchFAQs,
          )
        else if (_faqs.isEmpty)
          _buildEmptyView(message: '등록된 FAQ가 없습니다')
        else
          ..._faqs.map((faq) => _buildFaqItem(faq)),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 8, // gap-2
      runSpacing: 8,
      children: [
        // 전체 버튼
        _buildCategoryButton(
          label: '전체',
          isSelected: _selectedCategory == null,
          onTap: () => _onCategorySelected(null),
        ),
        // 카테고리 버튼들
        ..._faqCategories.map((category) {
          return _buildCategoryButton(
            label: '${category.name} (${category.faqCount})',
            isSelected: _selectedCategory == category.id,
            onTap: () => _onCategorySelected(category.id),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // px-4
          vertical: 8, // py-2
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6) // bg-[#3B82F6]
              : AppColors.neutral0, // bg-white
          borderRadius: BorderRadius.circular(8), // rounded-lg
          border: isSelected
              ? null
              : Border.all(color: AppColors.gray300), // border border-gray-300
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700, // font-bold
            color: isSelected
                ? AppColors.neutral0 // text-white
                : AppColors.gray600, // text-gray-600
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(FAQ faq) {
    final isExpanded = _expandedFaqId == faq.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // space-y-3
      decoration: BoxDecoration(
        color: AppColors.neutral0, // bg-white
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // shadow-sm
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.gray200), // border border-gray-200
      ),
      child: Column(
        children: [
          // 질문 헤더
          InkWell(
            onTap: () {
              setState(() {
                _expandedFaqId = isExpanded ? null : faq.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24), // p-6
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 카테고리 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, // px-2
                            vertical: 2, // py-0.5
                          ),
                          margin: const EdgeInsets.only(bottom: 8), // mb-2
                          decoration: BoxDecoration(
                            color: AppColors.gray50, // bg-gray-100
                            borderRadius: BorderRadius.circular(4), // rounded
                          ),
                          child: Text(
                            faq.categoryName,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        // 질문
                        Text(
                          faq.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, // font-bold
                            color: AppColors.gray900, // text-gray-900
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20, // w-5 h-5
                    color: AppColors.neutral400, // text-gray-400
                  ),
                ],
              ),
            ),
          ),
          // 답변 (확장 시)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // px-6 pb-6 pt-0
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16), // p-4
                decoration: BoxDecoration(
                  color: AppColors.blue50, // bg-blue-50
                  borderRadius: BorderRadius.circular(8), // rounded-lg
                  border: const Border(
                    left: BorderSide(
                      color: Color(0xFF3B82F6), // border-[#3B82F6]
                      width: 4, // border-l-4
                    ),
                  ),
                ),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    color: AppColors.neutral700, // text-gray-700
                    height: 1.6, // leading-relaxed
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============= 문의하기 탭 =============
  Widget _buildInquiriesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 문의 등록 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                context.push('/support/inquiries/new');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6), // bg-[#3B82F6]
                foregroundColor: AppColors.neutral0, // text-white
                padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 16), // w-4 h-4
              label: const Text(
                '새 문의 등록',
                style: TextStyle(fontWeight: FontWeight.w700), // font-bold
              ),
            ),
          ],
        ),
        const SizedBox(height: 24), // mb-6
        // 문의 목록
        if (_inquiriesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_inquiriesError != null)
          _buildErrorView(
            message: _inquiriesError!,
            onRetry: _fetchInquiries,
          )
        else if (_inquiries.isEmpty)
          _buildEmptyInquiries()
        else
          ..._inquiries.map((inquiry) => _buildInquiryItem(inquiry)),
      ],
    );
  }

  Widget _buildEmptyInquiries() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48), // p-12
      decoration: BoxDecoration(
        color: AppColors.neutral0, // bg-white
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // shadow-sm
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.gray200), // border border-gray-200
      ),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64, // w-16 h-16
            color: AppColors.gray300, // text-gray-300
          ),
          const SizedBox(height: 16), // mb-4
          const Text(
            '등록된 문의가 없습니다.',
            style: TextStyle(
              color: AppColors.neutral500, // text-gray-500
            ),
          ),
          const SizedBox(height: 16), // mt-4
          ElevatedButton(
            onPressed: () {
              context.push('/support/inquiries/new');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6), // bg-[#3B82F6]
              foregroundColor: AppColors.neutral0, // text-white
              padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '문의 등록하기',
              style: TextStyle(fontWeight: FontWeight.w700), // font-bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryItem(Inquiry inquiry) {
    final isExpanded = _expandedInquiryId == inquiry.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // space-y-3
      decoration: BoxDecoration(
        color: AppColors.neutral0, // bg-white
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // shadow-sm
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.gray200), // border border-gray-200
      ),
      child: Column(
        children: [
          // 문의 헤더
          InkWell(
            onTap: () {
              setState(() {
                _expandedInquiryId = isExpanded ? null : inquiry.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24), // p-6
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상태 배지 및 카테고리
                        Row(
                          children: [
                            _buildStatusBadge(inquiry.status),
                            const SizedBox(width: 8), // gap-2
                            Text(
                              inquiry.categoryType.label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // mb-2
                        // 제목
                        Text(
                          inquiry.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, // font-bold
                            color: AppColors.gray900, // text-gray-900
                          ),
                        ),
                        const SizedBox(height: 8), // mb-2
                        // 날짜
                        Row(
                          children: [
                            Text(
                              '등록일: ${inquiry.formattedDate}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                            if (inquiry.answeredAt != null) ...[
                              const SizedBox(width: 16), // gap-4
                              Text(
                                '답변일: ${inquiry.formattedAnsweredDate}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20, // w-5 h-5
                    color: AppColors.neutral400, // text-gray-400
                  ),
                ],
              ),
            ),
          ),
          // 상세 내용 (확장 시)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // px-6 pb-6 pt-0
              child: Column(
                children: [
                  // 문의 내용
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16), // p-4
                    decoration: BoxDecoration(
                      color: AppColors.gray50, // bg-gray-50
                      borderRadius: BorderRadius.circular(8), // rounded-lg
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 20, // w-5 h-5
                              color: AppColors.gray600, // text-gray-600
                            ),
                            const SizedBox(width: 8), // gap-2
                            const Text(
                              '문의 내용',
                              style: TextStyle(
                                fontWeight: FontWeight.w700, // font-bold
                                color: AppColors.gray900, // text-gray-900
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // mb-2
                        Padding(
                          padding: const EdgeInsets.only(left: 28), // ml-7
                          child: Text(
                            inquiry.content,
                            style: const TextStyle(
                              color: AppColors.neutral700, // text-gray-700
                              height: 1.6, // leading-relaxed
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // space-y-4
                  // 답변 내용
                  if (inquiry.answer != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16), // p-4
                      decoration: BoxDecoration(
                        color: AppColors.blue50, // bg-blue-50
                        borderRadius: BorderRadius.circular(8), // rounded-lg
                        border: const Border(
                          left: BorderSide(
                            color: Color(0xFF3B82F6), // border-[#3B82F6]
                            width: 4, // border-l-4
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 20, // w-5 h-5
                                color: const Color(0xFF3B82F6), // text-[#3B82F6]
                              ),
                              const SizedBox(width: 8), // gap-2
                              const Text(
                                '답변',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700, // font-bold
                                  color: AppColors.gray900, // text-gray-900
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8), // mb-2
                          Padding(
                            padding: const EdgeInsets.only(left: 28), // ml-7
                            child: Text(
                              inquiry.answer!,
                              style: const TextStyle(
                                color: AppColors.neutral700, // text-gray-700
                                height: 1.6, // leading-relaxed
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // 답변 대기 중
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16), // p-4
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3), // bg-yellow-50
                        borderRadius: BorderRadius.circular(8), // rounded-lg
                        border: const Border(
                          left: BorderSide(
                            color: Color(0xFFFACC15), // border-yellow-400
                            width: 4, // border-l-4
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20, // w-5 h-5
                            color: const Color(0xFFCA8A04), // text-yellow-600
                          ),
                          const SizedBox(width: 8), // gap-2
                          const Expanded(
                            child: Text(
                              '답변을 준비 중입니다. 영업일 기준 1-2일 내에 답변드리겠습니다.',
                              style: TextStyle(
                                color: AppColors.neutral700, // text-gray-700
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InquiryStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case InquiryStatus.pending:
        bgColor = const Color(0xFFFEF9C3); // bg-yellow-100
        textColor = const Color(0xFFA16207); // text-yellow-700
        text = '답변 대기';
        break;
      case InquiryStatus.answered:
        bgColor = const Color(0xFFDCFCE7); // bg-green-100
        textColor = const Color(0xFF15803D); // text-green-700
        text = '답변 완료';
        break;
      case InquiryStatus.closed:
        bgColor = AppColors.gray50; // bg-gray-100
        textColor = AppColors.neutral700; // text-gray-700
        text = '종료';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8, // px-2
        vertical: 4, // py-1
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4), // rounded
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildErrorView({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.gray600,
          ),
        ),
      ),
    );
  }
}
