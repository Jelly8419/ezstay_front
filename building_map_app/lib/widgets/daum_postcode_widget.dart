import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'daum_postcode_web.dart';
import '../core/theme/app_text_styles.dart';

/// 다음 우편번호 검색 위젯
class DaumPostcodeWidget extends StatefulWidget {
  final Function(Map<String, String>) onAddressSelected;

  const DaumPostcodeWidget({
    super.key,
    required this.onAddressSelected,
  });

  @override
  State<DaumPostcodeWidget> createState() => _DaumPostcodeWidgetState();
}

class _DaumPostcodeWidgetState extends State<DaumPostcodeWidget> {
  late final WebViewController? controller;

  @override
  void initState() {
    super.initState();

    // 웹이 아닌 플랫폼에서만 WebView 컨트롤러 초기화
    if (!kIsWeb) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // 페이지 로드 완료 시 다음 우편번호 API 실행
            _executeDaumPostcode();
          },
        ),
      )
      ..addJavaScriptChannel(
        'AddressResult',
        onMessageReceived: (JavaScriptMessage message) {
          // JavaScript에서 주소 선택 결과를 받음
          final addressData = _parseAddressData(message.message);
          widget.onAddressSelected(addressData);
          Navigator.of(context).pop(); // 팝업 닫기
        },
      )
      ..loadHtmlString(_getHtmlContent());
    } else {
      controller = null;
    }
  }

  void _executeDaumPostcode() {
    controller?.runJavaScript('''
      if (typeof daum !== 'undefined' && daum.Postcode) {
        new daum.Postcode({
          oncomplete: function(data) {
            var result = {
              'zonecode': data.zonecode,
              'address': data.address,
              'addressEnglish': data.addressEnglish,
              'addressType': data.addressType,
              'userSelectedType': data.userSelectedType,
              'roadAddress': data.roadAddress,
              'roadAddressEnglish': data.roadAddressEnglish,
              'jibunAddress': data.jibunAddress,
              'jibunAddressEnglish': data.jibunAddressEnglish,
              'autoRoadAddress': data.autoRoadAddress,
              'autoJibunAddress': data.autoJibunAddress,
              'buildingName': data.buildingName,
              'buildingCode': data.buildingCode,
              'apartment': data.apartment,
              'sido': data.sido,
              'sidoEnglish': data.sidoEnglish,
              'sigungu': data.sigungu,
              'sigunguEnglish': data.sigunguEnglish,
              'sigunguCode': data.sigunguCode,
              'roadnameCode': data.roadnameCode,
              'bcode': data.bcode,
              'roadname': data.roadname,
              'roadnameEnglish': data.roadnameEnglish
            };
            AddressResult.postMessage(JSON.stringify(result));
          },
          onclose: function(state) {
            if (state === 'FORCE_CLOSE' || state === 'COMPLETE_CLOSE') {
              AddressResult.postMessage('{"action": "close"}');
            }
          },
          width: '100%',
          height: '100%'
        }).open();
      } else {
        console.log('다음 우편번호 API가 로드되지 않았습니다.');
      }
    ''');
  }

  String _getHtmlContent() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>주소 검색</title>
        <style>
            body {
                margin: 0;
                padding: 0;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            }
            #loading {
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                font-size: 18px;
                color: #666;
            }
        </style>
    </head>
    <body>
        <div id="loading">주소 검색 서비스를 불러오는 중...</div>
        <script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                document.getElementById('loading').style.display = 'none';
            });
        </script>
    </body>
    </html>
    ''';
  }

  Map<String, String> _parseAddressData(String jsonString) {
    try {
      // JSON 파싱을 위한 간단한 구현
      if (jsonString.contains('"action": "close"')) {
        return {'action': 'close'};
      }

      // 실제로는 JSON 파싱 라이브러리를 사용해야 하지만, 여기서는 간단히 구현
      final Map<String, String> result = {};

      // 정규식을 사용한 간단한 JSON 파싱
      final RegExp regExp = RegExp(r'"(\w+)":"([^"]*)"');
      final matches = regExp.allMatches(jsonString);

      for (final match in matches) {
        final key = match.group(1) ?? '';
        final value = match.group(2) ?? '';
        result[key] = value;
      }

      return result;
    } catch (e) {
      return {'error': 'Failed to parse address data'};
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹에서는 전용 위젯 사용
    if (kIsWeb) {
      return DaumPostcodeWeb(onAddressSelected: widget.onAddressSelected);
    }

    // 모바일에서는 WebView 사용
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WebViewWidget(controller: controller!),
    );
  }

  /// 웹용 주소 검색 대안 UI
  Widget _buildWebAddressSearch(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '웹에서는 주소 직접 입력',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '웹 환경에서는 다음 우편번호 검색을 지원하지 않습니다.\n아래 버튼으로 샘플 주소를 선택하거나 직접 입력해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 샘플 주소 버튼들
            _buildSampleAddressButton('서울특별시 강남구 테헤란로 123', context),
            const SizedBox(height: 12),
            _buildSampleAddressButton('서울특별시 마포구 홍대입구역 456', context),
            const SizedBox(height: 12),
            _buildSampleAddressButton('서울특별시 송파구 잠실동 789', context),
            const SizedBox(height: 12),
            _buildSampleAddressButton('부산광역시 해운대구 해운대해변로 101', context),

            const SizedBox(height: 24),

            // 직접 입력 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDirectInputDialog(context),
                child: const Text('주소 직접 입력'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleAddressButton(String address, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onAddressSelected({
            'address': address,
            'roadAddress': address,
            'zonecode': '12345',
          });
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        child: Text(address, style: AppTextStyles.bodySmall),
      ),
    );
  }

  void _showDirectInputDialog(BuildContext context) {
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주소 직접 입력'),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: '예: 서울특별시 강남구 테헤란로 123',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.isNotEmpty) {
                widget.onAddressSelected({
                  'address': addressController.text,
                  'roadAddress': addressController.text,
                  'zonecode': '00000',
                });
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 주소 검색 페이지 닫기
              }
            },
            child: const Text('선택'),
          ),
        ],
      ),
    );
  }
}