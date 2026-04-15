import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 토스트 메시지 타입
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// 중앙에 표시되는 커스텀 토스트 메시지
class CustomToast {
  /// 토스트 메시지 표시
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 자동으로 사라지도록 설정
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// 성공 토스트
  static void success(BuildContext context, String message) {
    show(context, message: message, type: ToastType.success);
  }

  /// 에러 토스트
  static void error(BuildContext context, String message) {
    show(context, message: message, type: ToastType.error);
  }

  /// 경고 토스트
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: ToastType.warning);
  }

  /// 정보 토스트
  static void info(BuildContext context, String message) {
    show(context, message: message, type: ToastType.info);
  }
}

/// 토스트 위젯 (내부 구현)
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // 2.5초 후 사라지는 애니메이션 시작
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success600;
      case ToastType.error:
        return AppColors.error600;
      case ToastType.warning:
        return const Color(0xFFF59E0B); // Orange
      case ToastType.info:
        return AppColors.primary600;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘
                    Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 24,
                    ),

                    const SizedBox(width: 12),

                    // 메시지
                    Flexible(
                      child: Text(
                        widget.message,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 닫기 버튼
                    GestureDetector(
                      onTap: () {
                        _controller.reverse().then((_) => widget.onDismiss());
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
