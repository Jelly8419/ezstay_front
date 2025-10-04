import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import '../models/building.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

/// 웹용 카카오 지도 위젯 (JavaScript SDK 직접 사용)
class KakaoMapWeb extends StatefulWidget {
  final List<Building> buildings;
  final Function(Building) onMarkerTap;

  const KakaoMapWeb({
    super.key,
    required this.buildings,
    required this.onMarkerTap,
  });

  @override
  State<KakaoMapWeb> createState() => _KakaoMapWebState();
}

class _KakaoMapWebState extends State<KakaoMapWeb> {
  static int _idCounter = 0;
  late final String _viewId;
  late final html.DivElement _mapElement;

  @override
  void initState() {
    super.initState();
    _viewId = 'kakao-map-${_idCounter++}';

    // div 생성
    _mapElement = html.DivElement()
      ..id = _viewId
      ..style.width = '100%'
      ..style.height = '100%';

    // ViewFactory 등록
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _mapElement,
    );

    // 지도 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMap();
    });
  }

  void _initMap() {
    int attempts = 0;

    void tryInit() {
      attempts++;

      try {
        final kakaoMaps = js.context['kakao']?['maps'];
        if (kakaoMaps == null) {
          if (attempts < 20) {
            Future.delayed(Duration(milliseconds: 300), tryInit);
          } else {
            print('❌ kakao.maps 로드 타임아웃');
          }
          return;
        }

        // DOM에 컨테이너가 추가될 때까지 대기
        final container = html.document.getElementById(_viewId);
        if (container == null) {
          print('⏳ 컨테이너 대기 중... (시도 $attempts)');
          if (attempts < 20) {
            Future.delayed(Duration(milliseconds: 300), tryInit);
          } else {
            print('❌ 컨테이너 타임아웃: $_viewId');
          }
          return;
        }

        print('✅ 컨테이너 발견, 지도 생성 중...');

        // JavaScript로 지도 생성
        js.context.callMethod('eval', ['''
          (function() {
            var container = document.getElementById('$_viewId');
            if (!container) {
              console.error('컨테이너 없음: $_viewId');
              return;
            }

            var options = {
              center: new kakao.maps.LatLng(37.5665, 126.9780),
              level: 5
            };

            var map = new kakao.maps.Map(container, options);
            var zoomControl = new kakao.maps.ZoomControl();
            map.addControl(zoomControl, kakao.maps.ControlPosition.RIGHT);

            console.log('✅ 지도 생성 완료');
          })();
        ''']);
      } catch (e) {
        print('❌ 지도 초기화 실패: $e');
      }
    }

    tryInit();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
