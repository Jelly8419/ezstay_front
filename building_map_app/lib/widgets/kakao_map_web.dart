import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
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

  /// 특정 방 ID의 마커를 선택 (PropertyCard 클릭 시 호출)
  void selectMarker(int roomId) {
    _state?.selectMarker(roomId);
  }

  /// 지도 드래그 활성화/비활성화 (드롭다운 열림/닫힘 시 호출)
  void setMapDraggable(bool enabled) {
    _state?.setMapDraggable(enabled);
  }
}

/// 웹용 카카오 지도 위젯 (JavaScript SDK 직접 사용)
class KakaoMapWeb extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;
  final Function(Map<String, dynamic>)? onMarkerTap;
  final Function(double)? onZoomChanged;
  final Function(
    double swLat,
    double swLng,
    double neLat,
    double neLng,
    int zoom,
  )?
  onBoundsChanged;
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
  Timer? _markerUpdateTimer;

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
      // 🔒 위젯이 dispose된 후에는 콜백 호출하지 않음
      if (!mounted) return;

      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map &&
          messageEvent.data['type'] == 'bounds_changed') {
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
      // 🔒 위젯이 dispose된 후에는 콜백 호출하지 않음
      if (!mounted) return;

      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map &&
          messageEvent.data['type'] == 'marker_click') {
        final data = messageEvent.data;

        // 클러스터 클릭인지 개별 마커 클릭인지 구분
        final clusterRoomIds = data['clusterRoomIds'] as List?;

        // 클러스터 이벤트인 경우 (clusterRoomIds가 2개 이상이면) onMarkerTap 호출하지 않음
        // → map_screen.dart의 _setupClusterClickListener()가 처리
        // 개별 마커는 클러스터 크기가 1이므로 onMarkerTap 호출해야 함
        if (clusterRoomIds != null && clusterRoomIds.length > 1) {
          return;
        }

        // 개별 마커 이벤트인 경우 (clusterRoomIds 필드 없음) onMarkerTap 콜백 호출
        final roomId = data['roomId'] as int?;
        if (roomId == null) return;

        // roomId: -1인 경우 → 개별 마커 재클릭 (선택 해제)
        if (roomId == -1) {
          if (widget.onMarkerTap != null) {
            widget.onMarkerTap!({'id': -1}); // 특수 마커로 재클릭 이벤트 전달
          }
          return;
        }

        // 일반 개별 마커 클릭: 클릭된 방의 정보를 찾아서 콜백 호출
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
      // 🔒 위젯이 dispose된 후에는 초기화하지 않음
      if (!mounted) return;
      _initMap();
    });
  }

  @override
  void didUpdateWidget(KakaoMapWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 방 데이터가 실제로 변경되었는지 체크 (ID + isAvailable 비교)
    final oldRoomKeys = oldWidget.rooms.map((r) => '${r['id']}_${r['isAvailable']}').toList()..sort();
    final newRoomKeys = widget.rooms.map((r) => '${r['id']}_${r['isAvailable']}').toList()..sort();

    // ID 또는 isAvailable이 변경된 경우 마커 업데이트
    final roomsChanged =
        oldRoomKeys.length != newRoomKeys.length ||
        !_listEquals(oldRoomKeys, newRoomKeys);

    if (roomsChanged) {

      // 연속 호출 시 이전 예약 취소 후 재시작
      _markerUpdateTimer?.cancel();
      _markerUpdateTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) _updateMarkers();
      });
    } else {
    }
  }

  /// 두 리스트가 같은지 비교 (순서 무관)
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _markerUpdateTimer?.cancel();
    widget.controller?._detach();
    if (_boundsChangedListener != null) {
      html.window.removeEventListener('message', _boundsChangedListener);
    }
    if (_markerClickListener != null) {
      html.window.removeEventListener('message', _markerClickListener);
    }
    super.dispose();
  }

  /// 마커 diff 업데이트 (삭제/추가/스타일 갱신만 수행)
  void _updateMarkers() {
    final roomsJsonString = widget.rooms
        .map((room) {
          final weeklyRent =
              room['weeklyRent'] ?? room['weeklyPrice'] ?? room['price'] ?? 0;
          final isAvailable = room['isAvailable'] ?? true;
          return '''{
        id: ${room['id']},
        latitude: ${room['latitude']},
        longitude: ${room['longitude']},
        weeklyRent: $weeklyRent,
        roomName: "${room['roomName'] ?? ''}",
        isAvailable: $isAvailable
      }''';
        })
        .join(',');

    final jsCode = '''
      (function() {
        var container = document.getElementById('$_viewId');
        if (!container || !container._kakaoMap) {
          console.warn('🔄 [JS] 지도가 아직 초기화되지 않음 - 마커 업데이트 스킵');
          return;
        }
        if (!container._getClusterDistance || !container._clusterRooms) {
          console.warn('🔄 [JS] 클러스터링 함수 없음 - 마커 업데이트 스킵');
          return;
        }

        var map = container._kakaoMap;
        var currentZoomLevel = map.getLevel();

        // _markerMap: { clusterKey -> { overlay, content, firstRoomId, allUnavailable, text } }
        if (!container._markerMap) container._markerMap = {};
        if (container._selectedMarkerId === undefined) container._selectedMarkerId = null;

        // ── 헬퍼: 클러스터 키 생성 (소속 방 ID 정렬 조인) ──────────────────
        function clusterKey(cluster) {
          return cluster.rooms.map(function(r) { return r.id; }).sort().join(',');
        }

        // ── 헬퍼: 마커 스타일 적용 ──────────────────────────────────────────
        function applyStyle(content, isSelected, allUnavailable) {
          var baseStyle = isSelected
            ? 'background:#3B82F6;color:white;border:none;'
            : allUnavailable
            ? 'background:#E5E7EB;color:#9CA3AF;border:1px solid #D1D5DB;'
            : 'background:white;color:#1F2937;border:1px solid #E5E7EB;';
          content.style.cssText = baseStyle +
            'padding:8px 14px;border-radius:20px;font-size:14px;font-weight:600;' +
            'cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,0.15);white-space:nowrap;' +
            'transition:all 0.2s ease;z-index:' + (isSelected ? '20' : '10') + ';position:relative;';
        }

        // ── 헬퍼: 오버레이 신규 생성 ────────────────────────────────────────
        function createOverlay(cluster) {
          var firstRoomId = cluster.rooms[0].id;
          var allUnavailable = cluster.rooms.every(function(r) { return r.isAvailable === false; });
          var priceInManWon = Math.round(cluster.minPrice / 10000);
          var roomCount = cluster.rooms.length;
          var markerText = roomCount > 1
            ? priceInManWon + '만원 외 ' + (roomCount - 1) + '개'
            : priceInManWon + '만원';
          var isSelected = container._selectedMarkerId === firstRoomId;

          var content = document.createElement('div');
          content.className = 'price-marker';
          content.textContent = markerText;
          content.dataset.clusterRooms = JSON.stringify(cluster.rooms.map(function(r) { return r.id; }));
          content.dataset.firstRoomId = firstRoomId;
          content.dataset.unavailable = allUnavailable ? 'true' : 'false';
          applyStyle(content, isSelected, allUnavailable);

          // 호버 효과
          content.addEventListener('mouseover', function() {
            if (allUnavailable) return;
            var sel = container._selectedMarkerId === firstRoomId;
            content.style.backgroundColor = sel ? '#2563EB' : '#F3F4F6';
            content.style.transform = 'scale(1.05)';
            content.style.boxShadow = '0 4px 12px rgba(0,0,0,0.2)';
          });
          content.addEventListener('mouseout', function() {
            var sel = container._selectedMarkerId === firstRoomId;
            if (sel) {
              content.style.backgroundColor = '#3B82F6';
              content.style.color = 'white';
              content.style.border = 'none';
            } else if (allUnavailable) {
              content.style.backgroundColor = '#E5E7EB';
              content.style.color = '#9CA3AF';
              content.style.border = '1px solid #D1D5DB';
            } else {
              content.style.backgroundColor = 'white';
              content.style.color = '#1F2937';
              content.style.border = '1px solid #E5E7EB';
            }
            content.style.transform = 'scale(1)';
            content.style.boxShadow = '0 2px 8px rgba(0,0,0,0.15)';
          });

          // 클릭 이벤트
          content.addEventListener('click', function(event) {
            event.stopPropagation();
            var clickedRoomId = parseInt(content.dataset.firstRoomId);
            var clusterRoomIds = JSON.parse(content.dataset.clusterRooms);

            // 같은 마커 재클릭 → 선택 해제
            if (container._selectedMarkerId === clickedRoomId) {
              container._selectedMarkerId = null;
              applyStyle(content, false, content.dataset.unavailable === 'true');
              window.postMessage({ type: 'marker_click', roomId: -1 }, '*');
              return;
            }

            // 이전 선택 마커 스타일 초기화
            if (container._selectedMarkerId !== null) {
              var prevKey = null;
              Object.keys(container._markerMap).forEach(function(k) {
                if (container._markerMap[k].firstRoomId === container._selectedMarkerId) prevKey = k;
              });
              if (prevKey) {
                var prev = container._markerMap[prevKey];
                applyStyle(prev.content, false, prev.allUnavailable);
              }
            }

            // 현재 마커 선택
            container._selectedMarkerId = clickedRoomId;
            applyStyle(content, true, false);
            window.postMessage({
              type: 'marker_click',
              roomId: clickedRoomId,
              clusterRoomIds: clusterRoomIds
            }, '*');
          });

          var overlay = new kakao.maps.CustomOverlay({
            position: new kakao.maps.LatLng(cluster.centerLat, cluster.centerLng),
            content: content,
            yAnchor: 1.2
          });
          if (currentZoomLevel < 6) overlay.setMap(map);

          return { overlay: overlay, content: content, firstRoomId: firstRoomId,
                   allUnavailable: allUnavailable, text: markerText };
        }

        // ── 새 클러스터 계산 ─────────────────────────────────────────────────
        var allRooms = [$roomsJsonString];
        var clusterDistance = container._getClusterDistance(currentZoomLevel);
        var newClusters = container._clusterRooms(allRooms, clusterDistance);

        // 가격 0인 클러스터 제외
        newClusters = newClusters.filter(function(c) { return c.minPrice > 0; });

        // 새 클러스터 맵 구성
        var newClusterMap = {};
        newClusters.forEach(function(c) { newClusterMap[clusterKey(c)] = c; });

        var oldKeys = Object.keys(container._markerMap);
        var newKeys = Object.keys(newClusterMap);

        var removed = 0, added = 0, updated = 0;

        // ── 1. 없어진 클러스터 제거 ──────────────────────────────────────────
        oldKeys.forEach(function(k) {
          if (!newClusterMap[k]) {
            container._markerMap[k].overlay.setMap(null);
            // 제거된 마커가 선택 상태였으면 초기화
            if (container._selectedMarkerId === container._markerMap[k].firstRoomId) {
              container._selectedMarkerId = null;
            }
            delete container._markerMap[k];
            removed++;
          }
        });

        // ── 2. 새 클러스터 추가 / 기존 클러스터 스타일 갱신 ─────────────────
        newKeys.forEach(function(k) {
          var cluster = newClusterMap[k];
          var firstRoomId = cluster.rooms[0].id;
          var allUnavailable = cluster.rooms.every(function(r) { return r.isAvailable === false; });
          var priceInManWon = Math.round(cluster.minPrice / 10000);
          var roomCount = cluster.rooms.length;
          var markerText = roomCount > 1
            ? priceInManWon + '만원 외 ' + (roomCount - 1) + '개'
            : priceInManWon + '만원';

          if (!container._markerMap[k]) {
            // 신규 추가
            container._markerMap[k] = createOverlay(cluster);
            added++;
          } else {
            // 기존 유지 — 가격 또는 isAvailable 변경 시만 스타일 갱신
            var existing = container._markerMap[k];
            var isSelected = container._selectedMarkerId === firstRoomId;
            var textChanged = existing.text !== markerText;
            var unavailableChanged = existing.allUnavailable !== allUnavailable;

            if (textChanged || unavailableChanged) {
              existing.content.textContent = markerText;
              existing.content.dataset.unavailable = allUnavailable ? 'true' : 'false';
              applyStyle(existing.content, isSelected, allUnavailable);
              existing.text = markerText;
              existing.allUnavailable = allUnavailable;
              updated++;
            }

            // 줌 레벨 변경에 따른 표시/숨김 동기화
            if (currentZoomLevel < 6) {
              existing.overlay.setMap(map);
            } else {
              existing.overlay.setMap(null);
            }
          }
        });

        console.log('✅ [JS] 마커 diff 완료 - 제거:' + removed + ' 추가:' + added + ' 갱신:' + updated);
      })();
    ''';

    js.context.callMethod('eval', [jsCode]);
  }

  /// 특정 위치로 지도 포커싱
  void focusOnLocation(double latitude, double longitude, {int zoomLevel = 5}) {
    final jsCode =
        '''
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

  /// 특정 방 ID의 마커를 선택
  void selectMarker(int roomId) {
    final jsCode =
        '''
      (function() {
        var container = document.getElementById('$_viewId');
        if (!container || !container._kakaoMap) {
          console.error('지도 인스턴스를 찾을 수 없습니다');
          return;
        }

        // selectMarkerById 함수 호출
        if (container._selectMarkerById) {
          container._selectMarkerById($roomId);
        }
      })();
    ''';

    js.context.callMethod('eval', [jsCode]);
  }

  /// 지도 드래그 활성화/비활성화
  void setMapDraggable(bool enabled) {
    final jsCode =
        '''
      (function() {
        var container = document.getElementById('$_viewId');
        if (!container || !container._kakaoMap) {
          console.warn('[지도 드래그 제어] 지도 인스턴스를 찾을 수 없습니다');
          return;
        }

        var map = container._kakaoMap;
        map.setDraggable($enabled);
        console.log('[지도 드래그 제어] 드래그 ${enabled ? '활성화' : '비활성화'}됨');
      })();
    ''';

    js.context.callMethod('eval', [jsCode]);
  }

  void _initMap() {
    int attempts = 0;

    void tryInit() {
      // 🔒 위젯이 dispose된 후에는 초기화 중단
      if (!mounted) {
        return;
      }

      attempts++;

      try {
        final kakaoMaps = js.context['kakao']?['maps'];
        if (kakaoMaps == null) {
          if (attempts < 20) {
            Future.delayed(Duration(milliseconds: 300), tryInit);
          } else {
            AppLogger.e('❌ [MAP WEB] kakao.maps 로드 타임아웃 (20회 시도 실패)');
          }
          return;
        }


        // DOM에 컨테이너가 추가될 때까지 대기
        final container = html.document.getElementById(_viewId);
        if (container == null) {
          if (attempts < 20) {
            Future.delayed(Duration(milliseconds: 300), tryInit);
          } else {
            AppLogger.e('❌ [MAP WEB] 컨테이너 타임아웃: $_viewId (20회 시도 실패)');
          }
          return;
        }


        // 첫 번째 방의 좌표를 중심으로 설정 (없으면 서울시청)
        double centerLat = 37.5665;
        double centerLng = 126.9780;

        if (widget.rooms.isNotEmpty) {
          final firstRoom = widget.rooms.first;
          if (firstRoom['latitude'] != null && firstRoom['longitude'] != null) {
            centerLat =
                double.tryParse(firstRoom['latitude'].toString()) ?? centerLat;
            centerLng =
                double.tryParse(firstRoom['longitude'].toString()) ?? centerLng;
          }
        }

        // JavaScript로 지도 생성 및 마커 추가
        final jsCode =
            '''
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

            // 커스텀 라운드 줌 컨트롤 생성
            var zoomControlDiv = document.createElement('div');
            zoomControlDiv.style.cssText = 'position:absolute;top:24px;right:16px;display:flex;flex-direction:column;gap:8px;z-index:100;';

            // 줌 인 버튼 (+)
            var zoomInBtn = document.createElement('button');
            zoomInBtn.textContent = '+';
            zoomInBtn.style.cssText = 'width:40px;height:40px;background:white;border:none;border-radius:50%;box-shadow:0 2px 8px rgba(0,0,0,0.15);cursor:pointer;font-size:20px;font-weight:600;color:#374151;transition:all 0.2s ease;display:flex;align-items:center;justify-content:center;';
            zoomInBtn.addEventListener('mouseover', function() {
              zoomInBtn.style.backgroundColor = '#F3F4F6';
              zoomInBtn.style.boxShadow = '0 4px 12px rgba(0,0,0,0.2)';
            });
            zoomInBtn.addEventListener('mouseout', function() {
              zoomInBtn.style.backgroundColor = 'white';
              zoomInBtn.style.boxShadow = '0 2px 8px rgba(0,0,0,0.15)';
            });
            zoomInBtn.addEventListener('click', function() {
              var level = map.getLevel();
              map.setLevel(level - 1);
            });

            // 줌 아웃 버튼 (-)
            var zoomOutBtn = document.createElement('button');
            zoomOutBtn.textContent = '−';
            zoomOutBtn.style.cssText = 'width:40px;height:40px;background:white;border:none;border-radius:50%;box-shadow:0 2px 8px rgba(0,0,0,0.15);cursor:pointer;font-size:20px;font-weight:600;color:#374151;transition:all 0.2s ease;display:flex;align-items:center;justify-content:center;';
            zoomOutBtn.addEventListener('mouseover', function() {
              zoomOutBtn.style.backgroundColor = '#F3F4F6';
              zoomOutBtn.style.boxShadow = '0 4px 12px rgba(0,0,0,0.2)';
            });
            zoomOutBtn.addEventListener('mouseout', function() {
              zoomOutBtn.style.backgroundColor = 'white';
              zoomOutBtn.style.boxShadow = '0 2px 8px rgba(0,0,0,0.15)';
            });
            zoomOutBtn.addEventListener('click', function() {
              var level = map.getLevel();
              map.setLevel(level + 1);
            });

            zoomControlDiv.appendChild(zoomInBtn);
            zoomControlDiv.appendChild(zoomOutBtn);
            container.appendChild(zoomControlDiv);

            // 지도 인스턴스를 컨테이너에 저장 (외부에서 접근 가능하도록)
            container._kakaoMap = map;

            // 마커 배열 저장
            var markers = [];

            // 지도 영역 변경 이벤트 리스너 (dragend / zoom_changed)
            var lastBounds = null;
            var isInitialLoad = true;

            // 공통 전송 함수
            function sendBoundsToFlutter() {
              var bounds = map.getBounds();
              var sw = bounds.getSouthWest();
              var ne = bounds.getNorthEast();
              var currentZoom = map.getLevel();

              // 초기 로드: 최초 1회 무조건 전송
              if (isInitialLoad) {
                isInitialLoad = false;
                lastBounds = { swLat: sw.getLat(), swLng: sw.getLng(), neLat: ne.getLat(), neLng: ne.getLng() };
                console.log('📍 [초기 로드] 실제 지도 범위로 API 호출');
                window.postMessage({
                  type: 'bounds_changed',
                  swLat: sw.getLat(), swLng: sw.getLng(),
                  neLat: ne.getLat(), neLng: ne.getLng(),
                  zoom: currentZoom
                }, '*');
                return;
              }

              // 이전 영역과 비교 — 변화가 미미하면 스킵
              if (lastBounds) {
                var latChange = Math.abs(sw.getLat() - lastBounds.swLat) + Math.abs(ne.getLat() - lastBounds.neLat);
                var lngChange = Math.abs(sw.getLng() - lastBounds.swLng) + Math.abs(ne.getLng() - lastBounds.neLng);
                if (latChange < 0.002 && lngChange < 0.002) {
                  console.log('영역 변화 미미 - API 호출 스킵 (lat=' + latChange.toFixed(4) + ', lng=' + lngChange.toFixed(4) + ')');
                  return;
                }
              }

              lastBounds = { swLat: sw.getLat(), swLng: sw.getLng(), neLat: ne.getLat(), neLng: ne.getLng() };
              console.log('✅ bounds 전송 (dragend/zoom_changed)');
              window.postMessage({
                type: 'bounds_changed',
                swLat: sw.getLat(), swLng: sw.getLng(),
                neLat: ne.getLat(), neLng: ne.getLng(),
                zoom: currentZoom
              }, '*');
            }

            // 초기 로드: bounds_changed 첫 발생 시 1회만 처리
            kakao.maps.event.addListener(map, 'bounds_changed', function() {
              if (isInitialLoad) sendBoundsToFlutter();
            });

            // 드래그 종료: 손 뗀 즉시 발생 (관성 이동 완료 후)
            kakao.maps.event.addListener(map, 'dragend', function() {
              sendBoundsToFlutter();
            });

            // 줌 변경 완료
            kakao.maps.event.addListener(map, 'zoom_changed', function() {
              sendBoundsToFlutter();
            });

            // 뷰포트 크기 변경 시 지도 레이아웃 재계산 (개발자도구 열기/닫기, 창 크기 조정 대응)
            var relayoutTimer;
            window.addEventListener('resize', function() {
              clearTimeout(relayoutTimer);
              relayoutTimer = setTimeout(function() {
                map.relayout();
                console.log('🔄 [MAP] relayout 완료');
              }, 100);
            });

            // 마커 맵 초기화 (diff 업데이트용 — key: clusterKey, value: {overlay, content, ...})
            container._markerMap = {};

            // 선택된 마커 ID 초기화
            container._selectedMarkerId = null;

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

            // 특정 방 ID의 마커를 선택하는 함수 (Flutter에서 호출)
            container._selectMarkerById = function(roomId) {
              console.log('🎯 [JS] 마커 선택 요청, 방 ID:', roomId);

              // 헬퍼: _markerMap에서 firstRoomId로 항목 찾기
              function findEntryByRoomId(id) {
                var keys = Object.keys(container._markerMap);
                for (var i = 0; i < keys.length; i++) {
                  if (container._markerMap[keys[i]].firstRoomId === id) {
                    return container._markerMap[keys[i]];
                  }
                }
                return null;
              }

              // 헬퍼: 스타일 적용
              function applyStyle(content, isSelected, allUnavailable) {
                var baseStyle = isSelected
                  ? 'background:#3B82F6;color:white;border:none;'
                  : allUnavailable
                  ? 'background:#E5E7EB;color:#9CA3AF;border:1px solid #D1D5DB;'
                  : 'background:white;color:#1F2937;border:1px solid #E5E7EB;';
                content.style.cssText = baseStyle +
                  'padding:8px 14px;border-radius:20px;font-size:14px;font-weight:600;' +
                  'cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,0.15);white-space:nowrap;' +
                  'transition:all 0.2s ease;z-index:' + (isSelected ? '20' : '10') + ';position:relative;';
              }

              // -1: 모든 마커 선택 해제
              if (roomId === -1) {
                if (container._selectedMarkerId !== null) {
                  var prevEntry = findEntryByRoomId(container._selectedMarkerId);
                  if (prevEntry) applyStyle(prevEntry.content, false, prevEntry.allUnavailable);
                }
                container._selectedMarkerId = null;
                console.log('✅ [JS] 모든 마커 선택 해제 완료');
                return;
              }

              // 이전 선택 마커 스타일 초기화
              if (container._selectedMarkerId !== null && container._selectedMarkerId !== roomId) {
                var oldEntry = findEntryByRoomId(container._selectedMarkerId);
                if (oldEntry) applyStyle(oldEntry.content, false, oldEntry.allUnavailable);
              }

              // 새 마커 선택
              container._selectedMarkerId = roomId;
              var newEntry = findEntryByRoomId(roomId);
              if (newEntry) applyStyle(newEntry.content, true, false);

              console.log('✅ [JS] 마커 선택 완료');
            };

            console.log('✅ 지도 생성 완료, 헬퍼 함수 등록됨');
          })();
        ''';

        js.context.callMethod('eval', [jsCode]);
      } catch (e) {
        AppLogger.e('❌ [MAP WEB] 지도 초기화 실패: $e');
      }
    }

    tryInit();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
