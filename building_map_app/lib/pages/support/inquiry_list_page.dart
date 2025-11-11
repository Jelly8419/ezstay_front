import 'package:flutter/material.dart';
import '../../models/inquiry.dart';
import '../../services/support_service.dart';
import '../../widgets/support/inquiry_card.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../constants/app_constants.dart';
import 'inquiry_form_page.dart';
import 'inquiry_detail_page.dart';

/// 내 문의 목록 페이지
class InquiryListPage extends StatefulWidget {
  const InquiryListPage({super.key});

  @override
  State<InquiryListPage> createState() => _InquiryListPageState();
}

class _InquiryListPageState extends State<InquiryListPage> {
  final SupportService _supportService = SupportService();
  final ScrollController _scrollController = ScrollController();

  List<Inquiry> _inquiries = [];
  InquiryStatus? _filterStatus;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 리스너 (무한 스크롤)
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_currentPage < _totalPages && !_isLoading) {
        _loadMore();
      }
    }
  }

  /// 문의 목록 로드
  Future<void> _loadInquiries({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (refresh) {
        _inquiries.clear();
        _currentPage = 1;
      }
    });

    try {
      final response = await _supportService.getMyInquiries(
        page: _currentPage,
        limit: _limit,
        status: _filterStatus,
      );

      setState(() {
        _inquiries = response.inquiries;
        _totalPages = response.pagination.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 다음 페이지 로드
  Future<void> _loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await _supportService.getMyInquiries(
        page: _currentPage,
        limit: _limit,
        status: _filterStatus,
      );

      setState(() {
        _inquiries.addAll(response.inquiries);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('더 불러오기 실패: $e')),
        );
      }
    }
  }

  /// 상태 필터 변경
  void _onStatusFilterChanged(InquiryStatus? status) {
    setState(() {
      _filterStatus = status;
      _currentPage = 1;
    });
    _loadInquiries(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: '내 문의',
      useGNB: true,
      useCardStyle: false,
      scrollable: false,  // Column + Expanded가 레이아웃을 처리하므로 외부 스크롤 비활성화
      usePadding: false,  // 각 위젯에 padding이 있으므로 외부 패딩 비활성화
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '문의 작성',
          onPressed: _navigateToForm,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        icon: const Icon(Icons.edit),
        label: const Text('문의하기'),
      ),
      body: Column(
        children: [
          // 상태 필터
          _buildStatusFilter(),
          // 문의 목록
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadInquiries(refresh: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 필터
  Widget _buildStatusFilter() {
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
          _buildFilterChip(
            label: '전체',
            isSelected: _filterStatus == null,
            onTap: () => _onStatusFilterChanged(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '확인중',
            isSelected: _filterStatus == InquiryStatus.pending,
            onTap: () => _onStatusFilterChanged(InquiryStatus.pending),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '답변완료',
            isSelected: _filterStatus == InquiryStatus.answered,
            onTap: () => _onStatusFilterChanged(InquiryStatus.answered),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '종료',
            isSelected: _filterStatus == InquiryStatus.closed,
            onTap: () => _onStatusFilterChanged(InquiryStatus.closed),
          ),
        ],
      ),
    );
  }

  /// 필터 칩
  Widget _buildFilterChip({
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
    if (_isLoading && _inquiries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError && _inquiries.isEmpty) {
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
              '문의 목록을 불러올 수 없습니다',
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
              onPressed: () => _loadInquiries(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_inquiries.isEmpty) {
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
            const Text(
              '등록된 문의가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToForm,
              icon: const Icon(Icons.edit),
              label: const Text('문의하기'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _inquiries.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 로딩 인디케이터
        if (index == _inquiries.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final inquiry = _inquiries[index];
        return InquiryCard(
          inquiry: inquiry,
          onTap: () => _navigateToDetail(inquiry),
        );
      },
    );
  }

  /// 문의 작성 페이지로 이동
  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InquiryFormPage(),
      ),
    );

    // 문의 작성 후 목록 새로고침
    if (result == true && mounted) {
      _loadInquiries(refresh: true);
    }
  }

  /// 상세 페이지로 이동
  void _navigateToDetail(Inquiry inquiry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryDetailPage(inquiryId: inquiry.id),
      ),
    );
  }
}
