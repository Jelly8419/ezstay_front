import 'package:flutter/material.dart';

/// Sonner 스타일의 오버레이 토스트
/// 화면 하단 중앙에 카드 형태로 표시됩니다.
class OverlayToast {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  /// 토스트 메시지 표시
  /// [context] - BuildContext
  /// [message] - 표시할 메시지
  /// [duration] - 표시 시간 (기본 3초)
  /// [type] - 토스트 타입 (error, warning, info, success)
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    ToastType type = ToastType.error,
  }) {
    // 이미 표시 중인 토스트가 있으면 제거
    hide();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _SonnerToastWidget(
        message: message,
        type: type,
        onDismiss: hide,
      ),
    );

    _isShowing = true;
    overlay.insert(_currentEntry!);

    // 지정된 시간 후 자동 제거
    Future.delayed(duration, () {
      hide();
    });
  }

  /// 토스트 숨기기
  static void hide() {
    if (_currentEntry != null && _isShowing) {
      _currentEntry?.remove();
      _currentEntry = null;
      _isShowing = false;
    }
  }
}

/// 토스트 타입
enum ToastType {
  error,
  warning,
  info,
  success,
}

/// Sonner 스타일 토스트 위젯
class _SonnerToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _SonnerToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_SonnerToastWidget> createState() => _SonnerToastWidgetState();
}

class _SonnerToastWidgetState extends State<_SonnerToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 심플한 흰색 배경 스타일
  Color get _backgroundColor => Colors.white;

  Color get _borderColor => const Color(0xFFE5E7EB); // gray-200

  Color get _iconColor => const Color(0xFF374151); // gray-700

  Color get _textColor => const Color(0xFF1F2937); // gray-800

  IconData get _icon {
    switch (widget.type) {
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
      case ToastType.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    // 모바일에서는 양쪽 패딩, 데스크톱에서는 최대 너비 제한
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 400) / 2 : 16.0;

    return Positioned(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: bottomPadding + 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 아이콘
                    Icon(
                      _icon,
                      color: _iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    // 메시지
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textColor,
                          height: 1.4,
                        ),
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
