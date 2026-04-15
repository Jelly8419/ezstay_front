import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/inquiry.dart';
import '../../services/support_service.dart';
import '../../widgets/common/app_footer.dart';

class InquiriesPage extends StatefulWidget {
  const InquiriesPage({super.key});

  @override
  State<InquiriesPage> createState() => _InquiriesPageState();
}

class _InquiriesPageState extends State<InquiriesPage> {
  final SupportService _supportService = SupportService();

  List<Inquiry> _inquiries = [];
  int? _expandedInquiry;
  String _statusFilter = 'ALL';
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await _supportService.getMyInquiries(
        page: _page,
        limit: 10,
        status: _statusFilter == 'ALL' ? null : _statusFilter.toLowerCase(),
      );

      if (result != null) {
        setState(() {
          _inquiries = result.items;
          _totalPages = result.pagination.totalPages;
        });
      } else {
        setState(() {
          _errorMessage = '문의 목록을 불러오는데 실패했습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch inquiries: $e');
      setState(() {
        _errorMessage = '문의 목록을 불러오는데 실패했습니다';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _toggleInquiry(int inquiryId) {
    setState(() {
      _expandedInquiry = _expandedInquiry == inquiryId ? null : inquiryId;
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _statusFilter = status;
      _page = 1;
    });
    _fetchInquiries();
  }

  Color _getStatusBackgroundColor(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.pending:
        return const Color(0xFFFEF9C3); // bg-yellow-100
      case InquiryStatus.answered:
        return const Color(0xFFDCFCE7); // bg-green-100
      case InquiryStatus.closed:
        return AppColors.gray50; // bg-gray-100
    }
  }

  Color _getStatusTextColor(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.pending:
        return const Color(0xFF854D0E); // text-yellow-800
      case InquiryStatus.answered:
        return const Color(0xFF166534); // text-green-800
      case InquiryStatus.closed:
        return const Color(0xFF1F2937); // text-gray-800
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteInquiry(int inquiryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문의 삭제'),
        content: const Text('문의를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _supportService.deleteInquiry(inquiryId);
      if (success) {
        _showSnackBar('문의가 삭제되었습니다');
        _fetchInquiries();
      } else {
        _showSnackBar('문의 삭제에 실패했습니다');
      }
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
                  Expanded(
                    child: Text(
                      '문의하기',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/support/inquiries/new');
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('문의 등록'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: AppColors.neutral0,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    _buildStatusFilter(),
                    const SizedBox(height: 24),
                    _buildInquiryList(),
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

  Widget _buildStatusFilter() {
    final statuses = ['ALL', 'PENDING', 'ANSWERED', 'CLOSED'];
    final labels = {
      'ALL': '전체',
      'PENDING': '답변 대기',
      'ANSWERED': '답변 완료',
      'CLOSED': '처리 완료',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: statuses.map((status) {
            final isSelected = _statusFilter == status;
            final label = labels[status] ?? status;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _onStatusFilterChanged(status),
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
                    border:
                        isSelected ? null : Border.all(color: AppColors.border),
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
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInquiryList() {
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
                onPressed: _fetchInquiries,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_inquiries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '등록된 문의가 없습니다',
              style: TextStyle(
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/support/inquiries/new');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: AppColors.neutral0,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('문의사항 등록하기'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _inquiries.map((inquiry) {
        final isExpanded = _expandedInquiry == inquiry.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildInquiryItem(inquiry, isExpanded),
        );
      }).toList(),
    );
  }

  Widget _buildInquiryItem(Inquiry inquiry, bool isExpanded) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Button
          InkWell(
            onTap: () => _toggleInquiry(inquiry.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Category Badge
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
                                inquiry.categoryType.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral700,
                                ),
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _getStatusBackgroundColor(inquiry.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                inquiry.status.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _getStatusTextColor(inquiry.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Padding(
                          padding: const EdgeInsets.only(right: 32),
                          child: Text(
                            inquiry.title,
                            style: const TextStyle(
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Content Preview
                        Text(
                          inquiry.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Date
                        Text(
                          _formatDateTime(inquiry.createdAt),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral500,
                          ),
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

          // Expanded Content
          if (isExpanded) ...[
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  // Question Detail
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.gray50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '문의 내용',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          inquiry.content,
                          style: const TextStyle(
                            color: AppColors.neutral700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Answer Section
                  if (inquiry.status == InquiryStatus.answered &&
                      inquiry.answer != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.neutral0,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '답변',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            inquiry.answer!,
                            style: const TextStyle(
                              color: AppColors.neutral700,
                              height: 1.6,
                            ),
                          ),
                          if (inquiry.formattedAnsweredDate != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '답변일: ${inquiry.formattedAnsweredDate}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.neutral0,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '문의내용을 확인중입니다.\n최대한 빠른 시일 내에 답변드리겠습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Action Buttons (only for PENDING status)
                  if (inquiry.canEdit)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.gray50,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 수정 버튼
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                context.push(
                                    '/support/inquiries/${inquiry.id}/edit');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.neutral700,
                                side:
                                    const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('수정'),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 삭제 버튼
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _deleteInquiry(inquiry.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side:
                                    const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('삭제'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: _page == 1
              ? null
              : () {
                  setState(() {
                    _page = (_page - 1).clamp(1, _totalPages);
                  });
                  _fetchInquiries();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gray600,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('이전'),
        ),
        const SizedBox(width: 8),
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
                _fetchInquiries();
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
        OutlinedButton(
          onPressed: _page == _totalPages
              ? null
              : () {
                  setState(() {
                    _page = (_page + 1).clamp(1, _totalPages);
                  });
                  _fetchInquiries();
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
