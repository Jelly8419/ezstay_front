import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

/// 카카오 지도 웹 컨트롤러
class KakaoMapWebController {
  _KakaoMapWebState? _state;

  void _attach(_KakaoMapWebState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// 특정 위치로 지도 포커싱
  void focusOnLocation(double latitude, double longitude, {int zoomLevel = 5}) {
    _state?.focusOnLocation(latitude, longitude, zoomLevel: zoomLevel);
  }
}

/// 웹용 카카오 지도 위젯 (JavaScript SDK 직접 사용)
class KakaoMapWeb extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;
  final Function(Map<String, dynamic>)? onMarkerTap;
  final Function(double)? onZoomChanged;
  final Function(double swLat, double swLng, double neLat, double neLng, int zoom)? onBoundsChanged;
  final KakaoMapWebController? controller;

  const KakaoMapWeb({
    super.key,
    required this.rooms,
    this.onMarkerTap,
    this.onZoomChanged,
    this.onBoundsChanged,
    this.controller,
  });

  @override
  State<KakaoMapWeb> createState() => _KakaoMapWebState();
}

class _KakaoMapWebState extends State<KakaoMapWeb> {
  static int _idCounter = 0;
  late final String _viewId;
  late final html.DivElement _mapElement;
  html.EventListener? _boundsChangedListener;
  html.EventListener? _markerClickListener;

  @override
  void initState() {
    super.initState();
    _viewId = 'kakao-map-${_idCounter++}';

    // 컨트롤러에 state 연결
    widget.controller?._attach(this);

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

    // bounds_changed 이벤트 리스너 등록
    _boundsChangedListener = (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map && messageEvent.data['type'] == 'bounds_changed') {
        final data = messageEvent.data;
        if (widget.onBoundsChanged != null) {
          // zoom을 안전하게 int로 변환
          int zoom = 5; // 기본값
          if (data['zoom'] != null) {
            if (data['zoom'] is int) {
              zoom = data['zoom'] as int;
            } else if (data['zoom'] is double) {
              zoom = (data['zoom'] as double).toInt();
            } else if (data['zoom'] is String) {
              zoom = int.tryParse(data['zoom']) ?? 5;
            }
          }

          widget.onBoundsChanged!(
            data['swLat'] as double,
            data['swLng'] as double,
            data['neLat'] as double,
            data['neLng'] as double,
            zoom,
          );
        }
      }
    };
    html.window.addEventListener('message', _boundsChangedListener);

    // marker_click 이벤트 리스너 등록
    _markerClickListener = (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map && messageEvent.data['type'] == 'marker_click') {
        final data = messageEvent.data;
        final roomId = data['roomId'] as int;

        // 클릭된 방의 정보를 찾아서 콜백 호출
        final clickedRoom = widget.rooms.firstWhere(
          (room) => room['id'] == roomId,
          orElse: () => {},
        );

        if (clickedRoom.isNotEmpty && widget.onMarkerTap != null) {
          widget.onMarkerTap!(clickedRoom);
        }
      }
    };
    html.window.addEventListener('message', _markerClickListener);

    // 지도 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMap();
    });
  }

  @override
  void didUpdateWidget(KakaoMapWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 방 데이터가 변경되었으면 마커 업데이트
    if (widget.rooms != oldWidget.rooms) {
      debugPrint('🔄 [Dart] 방 데이터 변경 감지 - 마커 업데이트 시작');
      debugPrint('🔄 [Dart] 이전: ${oldWidget.rooms.length}개, 현재: ${widget.rooms.length}개');

      // 지도 초기화를 기다린 후 마커 업데이트 (약간의 딜레이)
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _updateMarkers();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    if (_boundsChangedListener != null) {
      html.window.removeEventListener('message', _boundsChangedListener);
    }
    if (_markerClickListener != null) {
      html.window.removeEventListener('message', _markerClickListener);
    }
    super.dispose();
  }

  /// 마커 업데이트 (기존 마커 제거 후 새로 생성)
  void _updateMarkers() {
    debugPrint('🔄 [Dart] _updateMarkers 호출됨 - 방 ${widget.rooms.length}개');

    // 방 데이터를 JavaScript로 전달하여 마커 재생성
    final roomsJsonString = widget.rooms.map((room) {
      final weeklyRent = room['weeklyRent'] ?? room['weeklyPrice'] ?? room['price'] ?? 0;
      return '''{
        id: ${room['id']},
        latitude: ${room['latitude']},
        longitude: ${room['longitude']},
        weeklyRent: $weeklyRent,
        roomName: "${room['roomName'] ?? ''}"
      }''';
    }).join(',');

    final jsCode = '''
      (function() {
        var container = document.getElementById('$_viewId');
        if (!container || !container._kakaoMap) {
          console.warn('🔄 [JS] 지도가 아직 초기화되지 않음 - 마커 업데이트 스킵');
          return;
        }

        // 마커 배열이 없으면 초기화
        if (!container._markers) {
          console.warn('🔄 [JS] 마커 배열 없음 - 초기화');
          container._markers = [];
        }

        var map = container._kakaoMap;
        var markers = container._markers;

        console.log('🔄 [JS] 마커 업데이트 시작 - 기존 마커: ' + markers.length + '개');

        // 기존 마커 모두 제거
        markers.forEach(function(marker) {
          marker.setMap(null);
        });
        markers = [];

        // 새로운 방 데이터
        var allRooms = [$roomsJsonString];
        console.log('🔄 [JS] 새로운 방 데이터: ' + allRooms.length + '개');

        // 현재 줌 레벨
        var currentZoomLevel = map.getLevel();

        // 헬퍼 함수가 없으면 스킵
        if (!container._getClusterDistance || !container._clusterRooms) {
          console.warn('🔄 [JS] 클러스터링 함수 없음 - 마커 업데이트 스킵');
          return;
        }

        // 클러스터링 (기존 로직 재사용)
        var clusterDistance = container._getClusterDistance(currentZoomLevel);
        var clusters = container._clusterRooms(allRooms, clusterDistance);

        console.log('🔄 [JS] 클러스터링 완료: ' + clusters.length + '개');

        // 마커 재생성
        clusters.forEach(function(cluster) {
          if (cluster.minPrice === 0) return;

          var markerPosition = new kakao.maps.LatLng(cluster.centerLat, cluster.centerLng);
          var priceInManWon = Math.round(cluster.minPrice / 10000);
          var roomCount = cluster.rooms.length;

          var markerText = roomCount > 1
            ? priceInManWon + '만원 외 ' + (roomCount - 1) + '개'
            : priceInManWon + '만원';

          var content = document.createElement('div');
          content.className = 'price-marker';
          content.style.cssText = 'background:#4A90E2;color:white;padding:8px 14px;border-radius:20px;font-size:14px;font-weight:600;cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,0.25);white-space:nowrap;transition:all 0.2s ease;z-index:10;position:relative;';
          content.textContent = markerText;

          content.dataset.clusterRooms = JSON.stringify(cluster.rooms.map(function(r) { return r.id; }));
          content.dataset.firstRoomId = cluster.rooms[0].id;

          var overlay = new kakao.maps.CustomOverlay({
            position: markerPosition,
            content: content,
            yAnchor: 1.2
          });

          // 줌 레벨 6 미만(확대)일 때만 마커 표시
          var shouldShow = currentZoomLevel < 6;
          if (shouldShow) {
            overlay.setMap(map);
          }
          markers.push(overlay);

          // 호버 효과
          content.addEventListener('mouseover', function() {
            content.style.backgroundColor = '#3A7BC8';
            content.style.transform = 'scale(1.08)';
            content.style.boxShadow = '0 4px 12px rgba(0,0,0,0.35)';
          });

          content.addEventListener('mouseout', function() {
            content.style.backgroundColor = '#4A90E2';
            content.style.transform = 'scale(1)';
            content.style.boxShadow = '0 2px 8px rgba(0,0,0,0.25)';
          });

          // 클릭 이벤트
          content.addEventListener('click', function() {
            var firstRoomId = content.dataset.firstRoomId;
            console.log('마커 클릭, 방 ID:', firstRoomId);
            window.postMessage({
              type: 'marker_click',
              roomId: parseInt(firstRoomId)
            }, '*');
          });
        });

        // 업데이트된 마커 배열을 컨테이너에 저장
        container._markers = markers;

        console.log('✅ [JS] 마커 업데이트 완료 - 새 마커: ' + markers.length + '개');
      })();
    ''';

    js.context.callMethod('eval', [jsCode]);
  }

  /// 특정 위치로 지도 포커싱
  void focusOnLocation(double latitude, double longitude, {int zoomLevel = 5}) {
    final jsCode = '''
      (function() {
        var container = document.getElementById('$_viewId');
        if (!container || !container._kakaoMap) {
          console.error('지도 인스턴스를 찾을 수 없습니다');
          return;
        }

        var map = container._kakaoMap;
        var moveLatLng = new kakao.maps.LatLng($latitude, $longitude);
        map.setCenter(moveLatLng);
        map.setLevel($zoomLevel);

        console.log('지도 포커싱:', { lat: $latitude, lng: $longitude, zoom: $zoomLevel });
      })();
    ''';

    js.context.callMethod('eval', [jsCode]);
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
            debugPrint('❌ kakao.maps 로드 타임아웃');
          }
          return;
        }

        // DOM에 컨테이너가 추가될 때까지 대기
        final container = html.document.getElementById(_viewId);
        if (container == null) {
          debugPrint('⏳ 컨테이너 대기 중... (시도 $attempts)');
          if (attempts < 20) {
            Future.delayed(Duration(milliseconds: 300), tryInit);
          } else {
            debugPrint('❌ 컨테이너 타임아웃: $_viewId');
          }
          return;
        }

        debugPrint('✅ 컨테이너 발견, 지도 생성 중...');

        // 첫 번째 방의 좌표를 중심으로 설정 (없으면 서울시청)
        double centerLat = 37.5665;
        double centerLng = 126.9780;

        if (widget.rooms.isNotEmpty) {
          final firstRoom = widget.rooms.first;
          if (firstRoom['latitude'] != null && firstRoom['longitude'] != null) {
            centerLat = double.tryParse(firstRoom['latitude'].toString()) ?? centerLat;
            centerLng = double.tryParse(firstRoom['longitude'].toString()) ?? centerLng;
          }
        }

        // JavaScript로 지도 생성 및 마커 추가
        final jsCode = '''
          (function() {
            var container = document.getElementById('$_viewId');
            if (!container) {
              console.error('컨테이너 없음: $_viewId');
              return;
            }

            var options = {
              center: new kakao.maps.LatLng($centerLat, $centerLng),
              level: 5
            };

            var map = new kakao.maps.Map(container, options);
            var zoomControl = new kakao.maps.ZoomControl();
            map.addControl(zoomControl, kakao.maps.ControlPosition.RIGHT);

            // 지도 인스턴스를 컨테이너에 저장 (외부에서 접근 가능하도록)
            container._kakaoMap = map;

            // 마커 배열 저장
            var markers = [];

            // 지도 영역 변경 이벤트 리스너 (드래그 후, 줌 후)
            var boundsChangedTimeout;
            var lastBounds = null;
            var isInitialLoad = true;

            kakao.maps.event.addListener(map, 'bounds_changed', function() {
              // 디바운스: 1초 후에 실행
              clearTimeout(boundsChangedTimeout);
              boundsChangedTimeout = setTimeout(function() {
                var bounds = map.getBounds();
                var sw = bounds.getSouthWest();
                var ne = bounds.getNorthEast();

                // 현재 줌 레벨 가져오기
                var currentZoom = map.getLevel();

                // 줌 레벨 6 이상(축소)이면 API 호출 및 마커 표시 중단
                if (currentZoom >= 6) {
                  console.log('🚫 줌 레벨 ' + currentZoom + ' - API 호출 스킵 (줌 레벨 6 미만 필요)');
                  //return;
                }

                // 초기 로드 시 실제 지도 범위로 API 호출
                if (isInitialLoad) {
                  isInitialLoad = false;
                  lastBounds = { swLat: sw.getLat(), swLng: sw.getLng(), neLat: ne.getLat(), neLng: ne.getLng() };
                  console.log('📍 [초기 로드] 실제 지도 범위로 API 호출');

                  // Flutter로 메시지 전송
                  window.postMessage({
                    type: 'bounds_changed',
                    swLat: sw.getLat(),
                    swLng: sw.getLng(),
                    neLat: ne.getLat(),
                    neLng: ne.getLng(),
                    zoom: currentZoom
                  }, '*');

                  return;
                }

                // 이전 영역과 비교하여 큰 변화가 있을 때만 API 호출
                if (lastBounds) {
                  var latChange = Math.abs(sw.getLat() - lastBounds.swLat) + Math.abs(ne.getLat() - lastBounds.neLat);
                  var lngChange = Math.abs(sw.getLng() - lastBounds.swLng) + Math.abs(ne.getLng() - lastBounds.neLng);

                  // 위도/경도 변화가 0.002 미만이면 무시 (약 200m 미만)
                  // 작은 변화는 스킵하지만, 적당한 지도 이동은 API 호출
                  if (latChange < 0.002 && lngChange < 0.002) {
                    console.log('영역 변화 미미 - API 호출 스킵 (변화: lat=' + latChange.toFixed(4) + ', lng=' + lngChange.toFixed(4) + ')');
                    return;
                  }
                  console.log('✅ 영역 변화 감지 - API 호출 (변화: lat=' + latChange.toFixed(4) + ', lng=' + lngChange.toFixed(4) + ')');
                }

                // 현재 영역 저장
                lastBounds = { swLat: sw.getLat(), swLng: sw.getLng(), neLat: ne.getLat(), neLng: ne.getLng() };

                // Flutter로 메시지 전송 (줌 레벨 포함)
                window.postMessage({
                  type: 'bounds_changed',
                  swLat: sw.getLat(),
                  swLng: sw.getLng(),
                  neLat: ne.getLat(),
                  neLng: ne.getLng(),
                  zoom: currentZoom
                }, '*');

                console.log('지도 영역 변경 - API 호출:', {
                  sw: { lat: sw.getLat(), lng: sw.getLng() },
                  ne: { lat: ne.getLat(), lng: ne.getLng() }
                });
              }, 1000);
            });

            // 마커 배열 초기화
            container._markers = [];

            // 헬퍼 함수 등록 (마커 업데이트 시 사용)
            container._getClusterDistance = function(zoomLevel) {
              if (zoomLevel <= 2) return 0.00001;
              if (zoomLevel <= 4) return 0.0005;
              if (zoomLevel <= 6) return 0.002;
              if (zoomLevel <= 8) return 0.01;
              if (zoomLevel <= 10) return 0.05;
              return 0.1;
            };

            container._clusterRooms = function(rooms, distance) {
              var clusters = [];
              var processed = new Set();

              rooms.forEach(function(room, index) {
                if (processed.has(index)) return;

                var cluster = {
                  rooms: [room],
                  centerLat: room.latitude,
                  centerLng: room.longitude,
                  minPrice: room.weeklyRent
                };

                processed.add(index);

                rooms.forEach(function(otherRoom, otherIndex) {
                  if (processed.has(otherIndex)) return;

                  var latDiff = Math.abs(room.latitude - otherRoom.latitude);
                  var lngDiff = Math.abs(room.longitude - otherRoom.longitude);

                  if (latDiff < distance && lngDiff < distance) {
                    cluster.rooms.push(otherRoom);
                    cluster.centerLat = (cluster.centerLat * (cluster.rooms.length - 1) + otherRoom.latitude) / cluster.rooms.length;
                    cluster.centerLng = (cluster.centerLng * (cluster.rooms.length - 1) + otherRoom.longitude) / cluster.rooms.length;

                    if (otherRoom.weeklyRent > 0 && (cluster.minPrice === 0 || otherRoom.weeklyRent < cluster.minPrice)) {
                      cluster.minPrice = otherRoom.weeklyRent;
                    }

                    processed.add(otherIndex);
                  }
                });

                clusters.push(cluster);
              });

              return clusters;
            };

            console.log('✅ 지도 생성 완료, 헬퍼 함수 등록됨');

            // 초기 로드를 위해 수동으로 bounds_changed 트리거
            setTimeout(function() {
              var bounds = map.getBounds();
              var sw = bounds.getSouthWest();
              var ne = bounds.getNorthEast();
              var currentZoom = map.getLevel();

              // 줌 레벨 체크
              if (currentZoom >= 6) {
                console.log('🚫 초기 줌 레벨 ' + currentZoom + ' - 확대 필요');
                return;
              }

              console.log('📍 [초기 로드] 수동으로 API 호출 트리거');

              window.postMessage({
                type: 'bounds_changed',
                swLat: sw.getLat(),
                swLng: sw.getLng(),
                neLat: ne.getLat(),
                neLng: ne.getLng(),
                zoom: currentZoom
              }, '*');
            }, 500);
          })();
        ''';

        js.context.callMethod('eval', [jsCode]);
      } catch (e) {
        debugPrint('❌ 지도 초기화 실패: $e');
      }
    }

    tryInit();
  }

  /// 방 데이터를 기반으로 JavaScript 마커 생성 코드 반환
  /// 줌 레벨에 따라 동적으로 클러스터링하여 표시
  String _generateMarkersJS() {
    if (widget.rooms.isEmpty) {
      return '// 마커 없음';
    }

    debugPrint('🎯 [Dart] 마커 생성 시작 - 방 개수: ${widget.rooms.length}');
    debugPrint('🎯 [Dart] 방 데이터: ${widget.rooms}');

    // 모든 방 데이터를 JavaScript 배열로 전달
    final roomsJson = widget.rooms.map((room) {
      final weeklyRent = room['weeklyRent'] ?? room['weeklyPrice'] ?? room['price'] ?? 0;
      debugPrint('🎯 [Dart] 방 ID: ${room['id']}, 가격: $weeklyRent, 위도: ${room['latitude']}, 경도: ${room['longitude']}');
      return {
        'id': room['id'],
        'latitude': room['latitude'],
        'longitude': room['longitude'],
        'weeklyRent': weeklyRent,
        'roomName': room['roomName'] ?? '',
      };
    }).toList();

    final roomsJsonString = roomsJson.map((room) => '''
      {
        id: ${room['id']},
        latitude: ${room['latitude']},
        longitude: ${room['longitude']},
        weeklyRent: ${room['weeklyRent']},
        roomName: "${room['roomName']}"
      }
    ''').join(',');

    // JavaScript에서 동적 클러스터링 수행
    return '''
      var allRooms = [$roomsJsonString];

      // 현재 줌 레벨 가져오기
      var currentZoomLevel = map.getLevel();
      console.log('🔍 [초기 마커 생성 시작] 방 개수: ' + allRooms.length);
      console.log('🔍 [초기 마커 생성] 현재 줌 레벨: ' + currentZoomLevel);

      // 헬퍼 함수들을 컨테이너에 저장 (마커 업데이트 시 재사용)
      container._getClusterDistance = function(zoomLevel) {
        // 카카오맵: 레벨이 낮을수록 확대(작은 거리), 높을수록 축소(큰 거리)
        if (zoomLevel <= 2) return 0.00001;  // 줌 1-2 (최대확대) → 클러스터링 거의 비활성화 (약 1m)
        if (zoomLevel <= 4) return 0.0005;   // 줌 3-4 (확대) → 약 50m 반경
        if (zoomLevel <= 6) return 0.002;    // 줌 5-6 (중간) → 약 200m 반경
        if (zoomLevel <= 8) return 0.01;     // 줌 7-8 (축소) → 1km 반경
        if (zoomLevel <= 10) return 0.05;    // 줌 9-10 (더 축소) → 5km 반경
        return 0.1;                           // 줌 11+ (최대축소) → 10km 반경
      };

      container._clusterRooms = function(rooms, distance) {
        var clusters = [];
        var processed = new Set();

        rooms.forEach(function(room, index) {
          if (processed.has(index)) return;

          var cluster = {
            rooms: [room],
            centerLat: room.latitude,
            centerLng: room.longitude,
            minPrice: room.weeklyRent
          };

          processed.add(index);

          // 근처의 다른 방들을 찾아서 클러스터에 추가
          rooms.forEach(function(otherRoom, otherIndex) {
            if (processed.has(otherIndex)) return;

            var latDiff = Math.abs(room.latitude - otherRoom.latitude);
            var lngDiff = Math.abs(room.longitude - otherRoom.longitude);

            if (latDiff < distance && lngDiff < distance) {
              cluster.rooms.push(otherRoom);
              cluster.centerLat = (cluster.centerLat * (cluster.rooms.length - 1) + otherRoom.latitude) / cluster.rooms.length;
              cluster.centerLng = (cluster.centerLng * (cluster.rooms.length - 1) + otherRoom.longitude) / cluster.rooms.length;

              if (otherRoom.weeklyRent > 0 && (cluster.minPrice === 0 || otherRoom.weeklyRent < cluster.minPrice)) {
                cluster.minPrice = otherRoom.weeklyRent;
              }

              processed.add(otherIndex);
            }
          });

          clusters.push(cluster);
        });

        return clusters;
      };

      // 줌 레벨에 따른 클러스터링 거리 설정
      var clusterDistance = container._getClusterDistance(currentZoomLevel);

      // 방들을 클러스터링
      var clusters = container._clusterRooms(allRooms, clusterDistance);
      console.log('🗂️ [클러스터링 완료] 클러스터 개수: ' + clusters.length);

      // 마커 배열을 컨테이너에 저장
      container._markers = markers;

      // 클러스터별로 마커 생성
      clusters.forEach(function(cluster) {
        if (cluster.minPrice === 0) return; // 가격 정보 없으면 스킵

        var markerPosition = new kakao.maps.LatLng(cluster.centerLat, cluster.centerLng);
        var priceInManWon = Math.round(cluster.minPrice / 10000);
        var roomCount = cluster.rooms.length;

        // 마커 텍스트 생성
        var markerText;
        if (roomCount > 1) {
          markerText = priceInManWon + '만원 외 ' + (roomCount - 1) + '개';
        } else {
          markerText = priceInManWon + '만원';
        }

        // 커스텀 오버레이로 가격 마커 생성
        var content = document.createElement('div');
        content.className = 'price-marker';
        content.style.cssText = 'background:#4A90E2;color:white;padding:8px 14px;border-radius:20px;font-size:14px;font-weight:600;cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,0.25);white-space:nowrap;transition:all 0.2s ease;z-index:10;position:relative;';
        content.textContent = markerText;

        // 클러스터 정보를 data attribute로 저장
        content.dataset.clusterRooms = JSON.stringify(cluster.rooms.map(function(r) { return r.id; }));
        content.dataset.firstRoomId = cluster.rooms[0].id;

        var overlay = new kakao.maps.CustomOverlay({
          position: markerPosition,
          content: content,
          yAnchor: 1.2
        });

        // 줌 레벨 6 미만(확대)일 때만 마커 표시
        var shouldShow = currentZoomLevel < 6;
        console.log('📍 [초기 마커] 줌레벨: ' + currentZoomLevel + ' 표시여부: ' + shouldShow);
        if (shouldShow) {
          overlay.setMap(map);
        }
        markers.push(overlay);

        // 호버 효과
        content.addEventListener('mouseover', function() {
          content.style.backgroundColor = '#3A7BC8';
          content.style.transform = 'scale(1.08)';
          content.style.boxShadow = '0 4px 12px rgba(0,0,0,0.35)';
        });

        content.addEventListener('mouseout', function() {
          content.style.backgroundColor = '#4A90E2';
          content.style.transform = 'scale(1)';
          content.style.boxShadow = '0 2px 8px rgba(0,0,0,0.25)';
        });

        // 클릭 이벤트
        content.addEventListener('click', function() {
          var firstRoomId = content.dataset.firstRoomId;
          console.log('마커 클릭, 방 ID:', firstRoomId);

          // Flutter로 메시지 전송
          window.postMessage({
            type: 'marker_click',
            roomId: parseInt(firstRoomId)
          }, '*');
        });
      });

      // 줌 변경 시 마커 재생성을 위한 이벤트 리스너
      var previousZoomLevel = currentZoomLevel;
      kakao.maps.event.addListener(map, 'zoom_changed', function() {
        var newZoomLevel = map.getLevel();
        console.log('🔄 [줌 변경] 레벨: ' + previousZoomLevel + ' → ' + newZoomLevel);

        var messageDiv = document.getElementById('zoom-message-$_viewId');
        var wasZoomedOut = previousZoomLevel < 6;  // 이전에 확대 상태였는가?
        var isZoomedOut = newZoomLevel >= 6;        // 현재 축소 상태인가?

        // 케이스 1: 5→6 (확대→축소) - 마커 제거 및 메시지 표시
        if (wasZoomedOut && isZoomedOut) {
          console.log('📤 [줌 변경] 확대→축소: 마커 제거 및 메시지 표시');

          // 모든 마커 제거
          markers.forEach(function(marker) {
            marker.setMap(null);
          });

          // 메시지 표시
          if (!messageDiv) {
            messageDiv = document.createElement('div');
            messageDiv.id = 'zoom-message-$_viewId';
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
            messageDiv.style.pointerEvents = 'none';
            messageDiv.textContent = '지도를 확대하면 매물을 볼 수 있어요';
            container.appendChild(messageDiv);
          }

          previousZoomLevel = newZoomLevel;
          return;
        }

        // 케이스 2: 6→5 (축소→확대) - API 요청 트리거
        if (!wasZoomedOut && !isZoomedOut) {
          console.log('📥 [줌 변경] 축소→확대: API 요청 및 마커 표시');

          // 메시지 제거
          if (messageDiv) {
            messageDiv.remove();
          }

          // bounds_changed 이벤트를 트리거하여 API 요청
          previousZoomLevel = newZoomLevel;

          // 즉시 bounds_changed 이벤트 발생시켜 API 호출
          var bounds = map.getBounds();
          var sw = bounds.getSouthWest();
          var ne = bounds.getNorthEast();

          window.postMessage({
            type: 'bounds_changed',
            swLat: sw.getLat(),
            swLng: sw.getLng(),
            neLat: ne.getLat(),
            neLng: ne.getLng(),
            zoom: newZoomLevel
          }, '*');

          return;
        }

        // 케이스 3: 축소 상태 유지 (6 이상)
        if (isZoomedOut) {
          console.log('⛔ [줌 변경] 축소 상태 유지 - 마커 표시 안함');
          previousZoomLevel = newZoomLevel;
          return;
        }

        // 케이스 4: 확대 상태에서 줌 레벨 변경 (0-5 범위 내)
        // 메시지 제거
        if (messageDiv) {
          messageDiv.remove();
        }

        // 줌 레벨이 크게 변경되었을 때만 마커 재생성
        if (Math.abs(newZoomLevel - previousZoomLevel) >= 1) {
          console.log('🔄 [클러스터링] 마커 재생성 시작');
          previousZoomLevel = newZoomLevel;

          // 기존 마커 제거
          markers.forEach(function(marker) {
            marker.setMap(null);
          });
          markers = [];

          // 새로운 클러스터 거리로 재계산
          var newClusterDistance = container._getClusterDistance(newZoomLevel);
          var newClusters = container._clusterRooms(allRooms, newClusterDistance);

          // 마커 재생성 (위 코드 반복)
          newClusters.forEach(function(cluster) {
            if (cluster.minPrice === 0) return;

            var markerPosition = new kakao.maps.LatLng(cluster.centerLat, cluster.centerLng);
            var priceInManWon = Math.round(cluster.minPrice / 10000);
            var roomCount = cluster.rooms.length;

            var markerText;
            if (roomCount > 1) {
              markerText = priceInManWon + '만원 외 ' + (roomCount - 1) + '개';
            } else {
              markerText = priceInManWon + '만원';
            }

            var content = document.createElement('div');
            content.className = 'price-marker';
            content.style.cssText = 'background:#4A90E2;color:white;padding:8px 14px;border-radius:20px;font-size:14px;font-weight:600;cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,0.25);white-space:nowrap;transition:all 0.2s ease;z-index:10;position:relative;';
            content.textContent = markerText;

            content.dataset.clusterRooms = JSON.stringify(cluster.rooms.map(function(r) { return r.id; }));
            content.dataset.firstRoomId = cluster.rooms[0].id;

            var overlay = new kakao.maps.CustomOverlay({
              position: markerPosition,
              content: content,
              yAnchor: 1.2
            });

            // 줌 레벨 6 미만(확대)일 때만 마커 표시
            var shouldShow = newZoomLevel < 6;
            console.log('📍 [재생성 마커] 줌레벨: ' + newZoomLevel + ' 표시여부: ' + shouldShow);
            if (shouldShow) {
              overlay.setMap(map);
            }
            markers.push(overlay);

            content.addEventListener('mouseover', function() {
              content.style.backgroundColor = '#3A7BC8';
              content.style.transform = 'scale(1.08)';
              content.style.boxShadow = '0 4px 12px rgba(0,0,0,0.35)';
            });

            content.addEventListener('mouseout', function() {
              content.style.backgroundColor = '#4A90E2';
              content.style.transform = 'scale(1)';
              content.style.boxShadow = '0 2px 8px rgba(0,0,0,0.25)';
            });

            content.addEventListener('click', function() {
              var firstRoomId = content.dataset.firstRoomId;
              console.log('마커 클릭, 방 ID:', firstRoomId);

              window.postMessage({
                type: 'marker_click',
                roomId: parseInt(firstRoomId)
              }, '*');
            });
          });
        }
      });
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
