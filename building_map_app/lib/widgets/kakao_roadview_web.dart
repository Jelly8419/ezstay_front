import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import '../core/theme/app_text_styles.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

/// 카카오 로드뷰 웹 위젯 (거리뷰)
class KakaoRoadviewWeb extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? roomName;

  const KakaoRoadviewWeb({
    super.key,
    required this.latitude,
    required this.longitude,
    this.roomName,
  });

  @override
  State<KakaoRoadviewWeb> createState() => _KakaoRoadviewWebState();
}

class _KakaoRoadviewWebState extends State<KakaoRoadviewWeb> {
  static int _idCounter = 0;
  late final String _viewId;
  late final html.DivElement _roadviewElement;
  bool _isRoadviewAvailable = true;

  @override
  void initState() {
    super.initState();
    _viewId = 'kakao-roadview-${_idCounter++}';

    // div 생성
    _roadviewElement = html.DivElement()
      ..id = _viewId
      ..style.width = '100%'
      ..style.height = '100%';

    // ViewFactory 등록
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _roadviewElement,
    );

    // 로드뷰 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRoadview();
    });
  }

  @override
  void didUpdateWidget(KakaoRoadviewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 위치가 변경되면 로드뷰 업데이트
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _updateRoadviewLocation();
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 로드뷰 위치 업데이트
  void _updateRoadviewLocation() {
    debugPrint('🔄 로드뷰 위치 업데이트: ${widget.latitude}, ${widget.longitude}');

    final jsCode = '''
      (function() {
        var container = document.getElementById('$_viewId');
        if (!container || !container._roadview || !container._roadviewClient) {
          console.error('로드뷰 인스턴스를 찾을 수 없습니다');
          return;
        }

        var roadview = container._roadview;
        var roadviewClient = container._roadviewClient;
        var position = new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude});

        // 로드뷰 위치 업데이트
        roadviewClient.getNearestPanoId(position, 50, function(panoId) {
          if (panoId === null) {
            console.warn('⚠️ 이 위치에서 가까운 로드뷰가 없습니다');

            // 로드뷰 없음 메시지 표시
            var messageDiv = document.getElementById('roadview-unavailable-$_viewId');
            if (!messageDiv) {
              messageDiv = document.createElement('div');
              messageDiv.id = 'roadview-unavailable-$_viewId';
              messageDiv.style.cssText = 'position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(255,255,255,0.95);padding:20px 30px;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.15);font-size:16px;color:#666;font-weight:500;z-index:9999;';
              messageDiv.textContent = '이 위치에서는 거리뷰를 사용할 수 없습니다';
              container.appendChild(messageDiv);
            }
          } else {
            console.log('✅ 로드뷰 업데이트 - panoId:', panoId);

            // 메시지 제거
            var messageDiv = document.getElementById('roadview-unavailable-$_viewId');
            if (messageDiv) {
              messageDiv.remove();
            }

            roadview.setPanoId(panoId, position);
          }
        });
      })();
    ''';

    js.context.callMethod('eval', [jsCode]);
  }

  void _initRoadview() {
    int attempts = 0;

    void tryInit() {
      attempts++;

      try {
        final kakaoMaps = js.context['kakao']?['maps'];
        if (kakaoMaps == null) {
          if (attempts < 20) {
            Future.delayed(const Duration(milliseconds: 300), tryInit);
          } else {
            debugPrint('❌ kakao.maps 로드 타임아웃');
          }
          return;
        }

        // DOM에 컨테이너가 추가될 때까지 대기
        final container = html.document.getElementById(_viewId);
        if (container == null) {
          debugPrint('⏳ 로드뷰 컨테이너 대기 중... (시도 $attempts)');
          if (attempts < 20) {
            Future.delayed(const Duration(milliseconds: 300), tryInit);
          } else {
            debugPrint('❌ 로드뷰 컨테이너 타임아웃: $_viewId');
          }
          return;
        }

        debugPrint('✅ 로드뷰 컨테이너 발견, 로드뷰 생성 중...');

        // JavaScript로 로드뷰 생성
        final jsCode = '''
          (function() {
            var container = document.getElementById('$_viewId');
            if (!container) {
              console.error('로드뷰 컨테이너 없음: $_viewId');
              return;
            }

            var position = new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude});

            // 로드뷰 객체 생성
            var roadview = new kakao.maps.Roadview(container);
            var roadviewClient = new kakao.maps.RoadviewClient();

            // 로드뷰 인스턴스 저장
            container._roadview = roadview;
            container._roadviewClient = roadviewClient;

            // 좌표로부터 가장 가까운 로드뷰 panoId 가져오기
            roadviewClient.getNearestPanoId(position, 50, function(panoId) {
              if (panoId === null) {
                console.warn('⚠️ 이 위치에서 가까운 로드뷰가 없습니다 (반경 50m 내)');

                // 로드뷰 없음 메시지 표시
                var messageDiv = document.createElement('div');
                messageDiv.id = 'roadview-unavailable-$_viewId';
                messageDiv.style.position = 'absolute';
                messageDiv.style.top = '50%';
                messageDiv.style.left = '50%';
                messageDiv.style.transform = 'translate(-50%, -50%)';
                messageDiv.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
                messageDiv.style.padding = '20px 30px';
                messageDiv.style.borderRadius = '12px';
                messageDiv.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
                messageDiv.style.fontSize = '16px';
                messageDiv.style.color = '#666';
                messageDiv.style.fontWeight = '500';
                messageDiv.style.zIndex = '9999';
                messageDiv.textContent = '이 위치에서는 거리뷰를 사용할 수 없습니다';
                container.appendChild(messageDiv);

                // Flutter에 로드뷰 사용 불가 알림
                window.postMessage({
                  type: 'roadview_unavailable'
                }, '*');

                return;
              }

              console.log('✅ 로드뷰 생성 완료 - panoId:', panoId);

              // 로드뷰 표시
              roadview.setPanoId(panoId, position);

              // Flutter에 로드뷰 사용 가능 알림
              window.postMessage({
                type: 'roadview_available'
              }, '*');
            });
          })();
        ''';

        js.context.callMethod('eval', [jsCode]);
      } catch (e) {
        debugPrint('❌ 로드뷰 초기화 실패: $e');
        setState(() {
          _isRoadviewAvailable = false;
        });
      }
    }

    tryInit();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRoadviewAvailable) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '이 위치에서는 거리뷰를 사용할 수 없습니다',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return HtmlElementView(viewType: _viewId);
  }
}
