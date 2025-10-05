import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:building_map_app/utils/responsive_util.dart';

void main() {
  group('ResponsiveUtil', () {
    testWidgets('모바일 크기 감지', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveUtil.isMobile(context), isTrue);
              expect(ResponsiveUtil.isTablet(context), isFalse);
              expect(ResponsiveUtil.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );

      addTearDown(tester.view.reset);
    });

    testWidgets('태블릿 크기 감지', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveUtil.isMobile(context), isFalse);
              expect(ResponsiveUtil.isTablet(context), isTrue);
              expect(ResponsiveUtil.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );

      addTearDown(tester.view.reset);
    });

    testWidgets('데스크톱 크기 감지', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveUtil.isMobile(context), isFalse);
              expect(ResponsiveUtil.isTablet(context), isFalse);
              expect(ResponsiveUtil.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      addTearDown(tester.view.reset);
    });

    testWidgets('그리드 컬럼 개수', (WidgetTester tester) async {
      // 모바일
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveUtil.getGridCrossAxisCount(context), equals(2));
              return const SizedBox();
            },
          ),
        ),
      );

      addTearDown(tester.view.reset);
    });
  });
}
