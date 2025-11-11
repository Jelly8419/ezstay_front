import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/app_gnb.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/notice.dart';
import '../../models/faq.dart';
import '../../services/support_service.dart';

/// 고객센터 메인 페이지 (투네이션 스타일)
class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  final SupportService _supportService = SupportService();

  List<Notice> _recentNotices = [];
  List<FAQ> _popularFaqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  /// 미리보기 데이터 로드 (최근 공지사항 3개, 인기 FAQ 6개)
  Future<void> _loadPreviewData() async {
    try {
      final noticesResponse = await _supportService.getNotices(page: 1, limit: 3);
      final faqsResponse = await _supportService.getFAQs();

      // FAQ는 카테고리별로 그룹화되어 있으므로 모든 카테고리에서 최대 6개 추출
      final allFaqs = <FAQ>[];
      faqsResponse.faqsByCategory.forEach((category, faqs) {
        allFaqs.addAll(faqs);
      });

      setState(() {
        _recentNotices = noticesResponse.notices;
        _popularFaqs = allFaqs.take(6).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGNB(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroSection(),
                  SizedBox(height: AppSpacing.xxl),
                  _buildCategoryCards(),
                  SizedBox(height: AppSpacing.xxl),
                  _buildRecentNotices(),
                  SizedBox(height: AppSpacing.xxl),
                  _buildPopularFAQs(),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  /// 히어로 섹션 (그라데이션 배경 + 제목 + 검색바)
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500,
            AppColors.primary600,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.xxl * 2,
        horizontal: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'EZstay 고객센터입니다.',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.neutral0,
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                '무엇을 도와드릴까요?',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.neutral0,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),

              // 검색바
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral0,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '궁금한 내용을 검색해보세요',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onSubmitted: (value) {
                    // TODO: 검색 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('검색 기능은 준비 중입니다: $value'),
                        backgroundColor: AppColors.primary500,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카테고리 카드 3개 (공지사항, FAQ, 문의)
  Widget _buildCategoryCards() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 1.2,
                children: [
                  _buildCategoryCard(
                    title: '공지사항',
                    description: '새로운 소식과 업데이트를 확인하세요',
                    icon: Icons.notifications_outlined,
                    gradient: LinearGradient(
                      colors: [AppColors.primary400, AppColors.primary600],
                    ),
                    onTap: () => context.go('/support/notices'),
                  ),
                  _buildCategoryCard(
                    title: 'FAQ',
                    description: '자주 묻는 질문을 확인하세요',
                    icon: Icons.help_outline,
                    gradient: LinearGradient(
                      colors: [AppColors.secondary500, Color(0xFF9B59B6)],
                    ),
                    onTap: () => context.go('/support/faqs'),
                  ),
                  _buildCategoryCard(
                    title: '1:1 문의',
                    description: '직접 문의하고 답변을 받으세요',
                    icon: Icons.question_answer_outlined,
                    gradient: LinearGradient(
                      colors: [AppColors.success500, Color(0xFF27AE60)],
                    ),
                    onTap: () => context.go('/support/inquiries'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 개별 카테고리 카드
  Widget _buildCategoryCard({
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.neutral0,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.neutral0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral0.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 최근 공지사항 미리보기
  Widget _buildRecentNotices() {
    if (_recentNotices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 공지사항',
                    style: AppTextStyles.headingMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/support/notices'),
                    child: Row(
                      children: [
                        Text('전체보기', style: AppTextStyles.bodyMedium),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              ..._recentNotices.map((notice) => _buildNoticePreviewCard(notice)),
            ],
          ),
        ),
      ),
    );
  }

  /// 공지사항 미리보기 카드
  Widget _buildNoticePreviewCard(Notice notice) {
    return InkWell(
      onTap: () => context.go('/support/notice/${notice.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (notice.isImportant)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error500,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '중요',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.neutral0,
                  ),
                ),
              ),
            if (notice.isImportant) SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    notice.createdAt.toString().substring(0, 10),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 인기 FAQ 미리보기
  Widget _buildPopularFAQs() {
    if (_popularFaqs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '자주 묻는 질문',
                    style: AppTextStyles.headingMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/support/faqs'),
                    child: Row(
                      children: [
                        Text('전체보기', style: AppTextStyles.bodyMedium),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 3,
                    children: _popularFaqs.map((faq) => _buildFAQPreviewCard(faq)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// FAQ 미리보기 카드
  Widget _buildFAQPreviewCard(FAQ faq) {
    return InkWell(
      onTap: () => context.go('/support/faq/${faq.id}'),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.help_outline,
                color: AppColors.primary500,
                size: 20,
              ),
            ),
            SizedBox(width: AppSpacing.md),

            Expanded(
              child: Text(
                faq.question,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
