import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notice.dart';
import '../../services/support_service.dart';
import '../../widgets/common/app_footer.dart';

class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  final SupportService _supportService = SupportService();

  List<Notice> _notices = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await _supportService.getNotices(
        page: _page,
        limit: 10,
      );

      if (result != null) {
        setState(() {
          _notices = result.items;
          _totalPages = result.pagination.totalPages;
        });
      } else {
        setState(() {
          _errorMessage = '공지사항을 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch notices: $e');
      setState(() {
        _errorMessage = '공지사항을 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
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
                  const Text(
                    '공지사항',
                    style: TextStyle(
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
            onPressed: _fetchNotices,
            child: const Text('다시 시도'),
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
                child: Column(
                  children: [
                    _buildNoticeList(),
                    if (_totalPages > 1) ...[
                      const SizedBox(height: 24),
                      _buildPagination(),
                    ],
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

  Widget _buildNoticeList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _notices.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: const Center(
                child: Text(
                  '등록된 공지사항이 없습니다',
                  style: TextStyle(
                    color: AppColors.gray600,
                  ),
                ),
              ),
            )
          : Column(
              children: _notices.asMap().entries.map((entry) {
                final index = entry.key;
                final notice = entry.value;
                final isLast = index == _notices.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: AppColors.gray200),
                          ),
                  ),
                  child: InkWell(
                    onTap: () {
                      context.push('/support/notices/${notice.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 컨텐츠
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 배지 및 날짜 (customer_center_page.dart와 동일)
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
                                        child: const Text(
                                          '공지',
                                          style: TextStyle(
                                            fontSize: 12, // text-xs
                                            fontWeight: FontWeight.w700, // font-bold
                                            color: Color(
                                                0xFF1D4ED8), // text-blue-700 (#1D4ED8)
                                          ),
                                        ),
                                      ),
                                    Text(
                                      notice.formattedDate,
                                      style: const TextStyle(
                                        fontSize: 14, // text-sm
                                        color: AppColors.neutral500, // text-gray-500
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
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이전 버튼
        OutlinedButton(
          onPressed: _page == 1
              ? null
              : () {
                  setState(() {
                    _page = (_page - 1).clamp(1, _totalPages);
                  });
                  _fetchNotices();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gray600,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('이전'),
        ),
        const SizedBox(width: 8),
        // 페이지 번호들
        ...List.generate(_totalPages.clamp(0, 5), (index) {
          final pageNum = index + 1;
          final isActive = pageNum == _page;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _page = pageNum;
                });
                _fetchNotices();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF3B82F6)
                      : AppColors.neutral0,
                  borderRadius: BorderRadius.circular(8),
                  border: isActive ? null : Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isActive
                          ? AppColors.neutral0
                          : AppColors.neutral700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        // 다음 버튼
        OutlinedButton(
          onPressed: _page == _totalPages
              ? null
              : () {
                  setState(() {
                    _page = (_page + 1).clamp(1, _totalPages);
                  });
                  _fetchNotices();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gray600,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('다음'),
        ),
      ],
    );
  }
}
