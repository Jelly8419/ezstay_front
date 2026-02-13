import 'package:flutter/material.dart';
import 'app_gnb.dart';

/// ShellRoute용 공통 레이아웃 Scaffold
///
/// AppGNB를 appBar로 제공하며, child는 GoRouter의 matched route 페이지입니다.
/// 이 위젯을 사용하는 페이지들은 자체 Scaffold/AppGNB를 포함하지 않아야 합니다.
class AppShellScaffold extends StatelessWidget {
  final Widget child;

  const AppShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGNB(),
      body: child,
    );
  }
}
