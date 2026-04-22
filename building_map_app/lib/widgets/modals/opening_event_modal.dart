import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/local_storage_helper.dart';
import '../common/app_buttons.dart';

/// 오픈 전 이벤트 공지 모달
///
/// - 페이지 진입 시 자동 노출 (OpeningEventModal.maybeShow)
/// - "오늘 하루 보지 않기" 체크 후 닫으면 24시간 동안 재노출 안 됨
/// - localStorage 타임스탬프 기반 (웹 전용, 非웹에서는 매번 노출)
class OpeningEventModal extends StatefulWidget {
  final VoidCallback onAlertRequest;
  final VoidCallback onHostRedirect;

  const OpeningEventModal({
    super.key,
    required this.onAlertRequest,
    required this.onHostRedirect,
  });

  static const String _storageKey = 'opening_event_modal_hidden_until';
  static const Duration _hideDuration = Duration(hours: 24);

  /// 24시간 숨김 조건이 해제된 경우에만 모달을 띄운다.
  static Future<void> maybeShow(
    BuildContext context, {
    required VoidCallback onAlertRequest,
    required VoidCallback onHostRedirect,
  }) async {
    final hiddenUntilStr = LocalStorageHelper.getItem(_storageKey);
    if (hiddenUntilStr != null) {
      final hiddenUntil = int.tryParse(hiddenUntilStr);
      if (hiddenUntil != null &&
          DateTime.now().millisecondsSinceEpoch < hiddenUntil) {
        return;
      }
    }
    await _show(context, onAlertRequest, onHostRedirect);
  }

  /// 숨김 조건을 무시하고 강제로 모달을 띄운다.
  /// 정적 랜딩에서 `?action=alert` 쿼리로 진입한 경우 사용.
  static Future<void> forceShow(
    BuildContext context, {
    required VoidCallback onAlertRequest,
    required VoidCallback onHostRedirect,
  }) async {
    await _show(context, onAlertRequest, onHostRedirect);
  }

  static Future<void> _show(
    BuildContext context,
    VoidCallback onAlertRequest,
    VoidCallback onHostRedirect,
  ) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => OpeningEventModal(
        onAlertRequest: onAlertRequest,
        onHostRedirect: onHostRedirect,
      ),
    );
  }

  @override
  State<OpeningEventModal> createState() => _OpeningEventModalState();
}

class _OpeningEventModalState extends State<OpeningEventModal> {
  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  void _hideForTodayAndClose() {
    final until = DateTime.now()
        .add(OpeningEventModal._hideDuration)
        .millisecondsSinceEpoch;
    LocalStorageHelper.setItem(
      OpeningEventModal._storageKey,
      until.toString(),
    );
    _close();
  }

  Shadow get _textShadow => Shadow(
    color: Colors.black.withValues(alpha: 0.5),
    offset: const Offset(0, 1),
    blurRadius: 3,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 480;
    final horizontalInset = isSmallMobile ? screenWidth * 0.04 : 32.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 배경 이미지 + 그라데이션 오버레이 + 본문
              _buildContent(context),
              // 우측 상단 X 버튼
              Positioned(
                top: 8,
                right: 8,
                child: _buildCloseButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/banner_bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.35),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl + 8,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '오픈 전 참여 혜택',
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: AppTextStyles.responsiveFontSize(
                  context,
                  mobile: 22,
                  desktop: 28,
                ),
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: [_textShadow],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBulletText('• 임차인은 오픈 알림 신청 후 첫 계약 시 2만원 할인'),
                const SizedBox(height: 4),
                _buildBulletText('• 임대인은 방 등록 시, 오픈 후 90일 간 정산 수수료 무료 (등록한 모든 방에 적용)'),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '5월 초 오픈 전 각 선착순 100명 마감 시, 혜택은 종료됩니다',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: AppTextStyles.responsiveFontSize(
                  context,
                  mobile: 12,
                  desktop: 13,
                ),
                color: Colors.white.withValues(alpha: 0.85),
                shadows: [_textShadow],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AppPrimaryButton(
                    text: '알림 받기',
                    fullWidth: false,
                    height: AppSizes.buttonHeightMd,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAlertRequest();
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: AppSecondaryButton(
                    text: '방 등록하기',
                    fullWidth: false,
                    height: AppSizes.buttonHeightMd,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onHostRedirect();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletText(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: AppTextStyles.responsiveFontSize(
          context,
          mobile: 13,
          desktop: 15,
        ),
        color: Colors.white,
        shadows: [_textShadow],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Center(
      child: InkWell(
        onTap: _hideForTodayAndClose,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_box_outline_blank,
                size: 18,
                color: Colors.white,
                shadows: [_textShadow],
              ),
              const SizedBox(width: 6),
              Text(
                '오늘 하루 보지 않기',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  shadows: [_textShadow],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _close,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
