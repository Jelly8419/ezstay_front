import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notice.dart';
import '../../services/support_service.dart';
import '../../widgets/common/app_footer.dart';

class NoticeDetailPage extends StatefulWidget {
  final int noticeId;

  const NoticeDetailPage({
    super.key,
    required this.noticeId,
  });

  @override
  State<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends State<NoticeDetailPage> {
  final SupportService _supportService = SupportService();

  Notice? _notice;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNoticeDetail();
  }

  Future<void> _fetchNoticeDetail() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final notice = await _supportService.getNoticeDetail(widget.noticeId);

      if (notice != null) {
        setState(() {
          _notice = notice;
        });
      } else {
        setState(() {
          _errorMessage = '공지사항을 찾을 수 없습니다';
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch notice detail: $e');
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
                : _errorMessage != null || _notice == null
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
            _errorMessage ?? '공지사항을 찾을 수 없습니다',
            style: const TextStyle(
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              context.go('/support?tab=notices');
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
                  // 중요 배지
                  if (_notice!.isImportant) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '중요',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Title
                  Text(
                    _notice!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta Info
                  Container(
                    padding: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Text(
                      _notice!.formattedDate,
                      style: const TextStyle(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (_notice!.content ?? '').split('\n').map((line) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: AppColors.neutral700,
                              height: 1.6,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Back Button
                  Container(
                    padding: const EdgeInsets.only(top: 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/support?tab=notices');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gray50,
                          foregroundColor: AppColors.gray900,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('목록으로'),
                      ),
                    ),
                  ),
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
}
