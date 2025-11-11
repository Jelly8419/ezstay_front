import 'package:flutter/material.dart';
import '../../models/notice.dart';
import '../../services/support_service.dart';
import '../../widgets/support/notice_card.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../constants/app_constants.dart';
import 'notice_detail_page.dart';

/// 공지사항 목록 페이지
class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  final SupportService _supportService = SupportService();
  final ScrollController _scrollController = ScrollController();

  List<Notice> _notices = [];
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
    _loadNotices();
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

  /// 공지사항 로드
  Future<void> _loadNotices({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (refresh) {
        _notices.clear();
        _currentPage = 1;
      }
    });

    try {
      final response = await _supportService.getNotices(
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _notices = response.notices;
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

  /// 다음 페이지 로드 (무한 스크롤)
  Future<void> _loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await _supportService.getNotices(
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _notices.addAll(response.notices);
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: '공지사항',
      useGNB: true,
      useCardStyle: false,
      scrollable: false,  // ListView가 스크롤을 처리하므로 외부 스크롤 비활성화
      usePadding: false,  // ListView 자체에 padding이 있으므로 외부 패딩 비활성화
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError && _notices.isEmpty) {
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
              '공지사항을 불러올 수 없습니다',
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
              onPressed: () => _loadNotices(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_notices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              '등록된 공지사항이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotices(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _notices.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // 로딩 인디케이터
          if (index == _notices.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notice = _notices[index];
          return NoticeCard(
            notice: notice,
            onTap: () => _navigateToDetail(notice),
          );
        },
      ),
    );
  }

  /// 상세 페이지로 이동
  void _navigateToDetail(Notice notice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoticeDetailPage(noticeId: notice.id),
      ),
    );
  }
}
