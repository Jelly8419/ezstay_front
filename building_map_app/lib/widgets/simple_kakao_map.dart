import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

/// 단일 위치 표시용 간단한 카카오 지도 위젯
/// (room_detail_page에서 사용 - 가격 마커, 클러스터링 없음)
class SimpleKakaoMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String roomName;

  const SimpleKakaoMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.roomName,
  });

  @override
  State<SimpleKakaoMap> createState() => _SimpleKakaoMapState();
}

class _SimpleKakaoMapState extends State<SimpleKakaoMap> {
  static int _idCounter = 0;
  late final String _viewId;
  late final html.DivElement _mapElement;

  @override
  void initState() {
    super.initState();
    _viewId = 'simple-kakao-map-${_idCounter++}';

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
            AppLogger.e('❌ kakao.maps 로드 타임아웃');
          }
          return;
        }

        // DOM에 컨테이너가 추가될 때까지 대기
        final container = html.document.getElementById(_viewId);
        if (container == null) {
          if (attempts < 20) {
            Future.delayed(Duration(milliseconds: 300), tryInit);
          } else {
            AppLogger.e('❌ 컨테이너 타임아웃: $_viewId');
          }
          return;
        }


        // JavaScript로 지도 생성 및 단일 마커 추가
        final jsCode = '''
          (function() {
            var container = document.getElementById('$_viewId');
            if (!container) {
              console.error('컨테이너 없음: $_viewId');
              return;
            }

            // 지도 옵션 설정
            var options = {
              center: new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude}),
              level: 3  // 확대 레벨 (3 = 적당히 확대)
            };

            // 지도 생성
            var map = new kakao.maps.Map(container, options);

            // 줌 컨트롤 추가
            var zoomControl = new kakao.maps.ZoomControl();
            map.addControl(zoomControl, kakao.maps.ControlPosition.RIGHT);

            // 마커 위치
            var markerPosition = new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude});

            // 기본 마커 생성 (빨간 핀)
            var marker = new kakao.maps.Marker({
              position: markerPosition
            });

            // 마커를 지도에 표시
            marker.setMap(map);

            // 지도 인스턴스를 컨테이너에 저장
            container._kakaoMap = map;

            // 창 크기 변경 시 지도 리사이즈
            var resizeTimeout;
            window.addEventListener('resize', function() {
              clearTimeout(resizeTimeout);
              resizeTimeout = setTimeout(function() {
                if (container._kakaoMap) {
                  console.log('🔄 SimpleKakaoMap 리사이즈');
                  container._kakaoMap.relayout();
                  // 중심 좌표 재설정 (리사이즈 후 중심이 유지되도록)
                  container._kakaoMap.setCenter(markerPosition);
                }
              }, 300);
            });

            // 초기 relayout (렌더링 완료 후)
            setTimeout(function() {
              if (container._kakaoMap) {
                container._kakaoMap.relayout();
                container._kakaoMap.setCenter(markerPosition);
              }
            }, 100);

            console.log('✅ SimpleKakaoMap 지도 및 마커 생성 완료', {
              lat: ${widget.latitude},
              lng: ${widget.longitude},
              name: '${widget.roomName}'
            });
          })();
        ''';

        js.context.callMethod('eval', [jsCode]);
      } catch (e) {
        AppLogger.e('❌ SimpleKakaoMap 초기화 실패: $e');
      }
    }

    tryInit();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
