import 'package:flutter/material.dart';
import '../../utils/responsive_util.dart';
import 'app_gnb.dart';
import 'mobile_bottom_nav.dart';

/// ShellRoute용 공통 레이아웃 Scaffold
///
/// 데스크톱(>= 1024px): 상단 AppGNB
/// 모바일/태블릿(< 1024px): 하단 MobileBottomNav
///
/// child는 GoRouter의 matched route 페이지입니다.
/// 이 위젯을 사용하는 페이지들은 자체 Scaffold/AppGNB를 포함하지 않아야 합니다.
class AppShellScaffold extends StatelessWidget {
  final Widget child;

  const AppShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtil.isDesktop(context);

    return Scaffold(
      appBar: isDesktop ? const AppGNB() : null,
      body: child,
      bottomNavigationBar: isDesktop ? null : const MobileBottomNav(),
    );
  }
}
