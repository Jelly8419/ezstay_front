import 'package:flutter/material.dart';
import 'dart:js' as js;

/// 웹용 다음 우편번호 검색 위젯
class DaumPostcodeWeb extends StatefulWidget {
  final Function(Map<String, String>) onAddressSelected;

  const DaumPostcodeWeb({
    super.key,
    required this.onAddressSelected,
  });

  @override
  State<DaumPostcodeWeb> createState() => _DaumPostcodeWebState();
}

class _DaumPostcodeWebState extends State<DaumPostcodeWeb> {
  @override
  void initState() {
    super.initState();
    // 다음 우편번호 검색 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openDaumPostcode();
    });
  }

  void _openDaumPostcode() {
    try {
      // JavaScript 콜백 함수 등록
      js.context['onAddressComplete'] = (data) {
        final addressData = <String, String>{};

        // JavaScript 객체에서 Dart Map으로 변환
        if (data != null) {
          try {
            final jsObj = js.JsObject.fromBrowserObject(data);
            addressData['zonecode'] = jsObj['zonecode']?.toString() ?? '';
            addressData['address'] = jsObj['address']?.toString() ?? '';
            addressData['addressEnglish'] = jsObj['addressEnglish']?.toString() ?? '';
            addressData['addressType'] = jsObj['addressType']?.toString() ?? '';
            addressData['userSelectedType'] = jsObj['userSelectedType']?.toString() ?? '';
            addressData['roadAddress'] = jsObj['roadAddress']?.toString() ?? '';
            addressData['roadAddressEnglish'] = jsObj['roadAddressEnglish']?.toString() ?? '';
            addressData['jibunAddress'] = jsObj['jibunAddress']?.toString() ?? '';
            addressData['jibunAddressEnglish'] = jsObj['jibunAddressEnglish']?.toString() ?? '';
            addressData['autoRoadAddress'] = jsObj['autoRoadAddress']?.toString() ?? '';
            addressData['autoJibunAddress'] = jsObj['autoJibunAddress']?.toString() ?? '';
            addressData['buildingName'] = jsObj['buildingName']?.toString() ?? '';
            addressData['buildingCode'] = jsObj['buildingCode']?.toString() ?? '';
            addressData['apartment'] = jsObj['apartment']?.toString() ?? '';
            addressData['sido'] = jsObj['sido']?.toString() ?? '';
            addressData['sidoEnglish'] = jsObj['sidoEnglish']?.toString() ?? '';
            addressData['sigungu'] = jsObj['sigungu']?.toString() ?? '';
            addressData['sigunguEnglish'] = jsObj['sigunguEnglish']?.toString() ?? '';
            addressData['sigunguCode'] = jsObj['sigunguCode']?.toString() ?? '';
            addressData['roadnameCode'] = jsObj['roadnameCode']?.toString() ?? '';
            addressData['bcode'] = jsObj['bcode']?.toString() ?? '';
            addressData['roadname'] = jsObj['roadname']?.toString() ?? '';
            addressData['roadnameEnglish'] = jsObj['roadnameEnglish']?.toString() ?? '';
          } catch (e) {
            debugPrint('주소 데이터 파싱 오류: $e');
          }
        }

        // 주소 선택 완료 콜백 호출
        widget.onAddressSelected(addressData);
      };

      js.context['onAddressClose'] = (state) {
        // 사용자가 주소 선택 없이 창을 닫은 경우
        // 이미 pop된 경우 중복 pop 방지
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      };

      // 다음 우편번호 API 실행
      js.context.callMethod('eval', ['''
        if (typeof daum !== 'undefined' && daum.Postcode) {
          new daum.Postcode({
            oncomplete: function(data) {
              onAddressComplete(data);
            },
            onclose: function(state) {
              onAddressClose(state);
            },
            width: '100%',
            height: '100%'
          }).open();
        } else {
          console.error('다음 우편번호 API가 로드되지 않았습니다.');
          onAddressClose('ERROR');
        }
      ''']);
    } catch (e) {
      debugPrint('다음 우편번호 API 실행 중 오류: $e');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '다음 우편번호 검색 서비스를 불러오는 중...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '팝업이 나타나지 않으면 팝업 차단을 해제해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // JavaScript 콜백 정리
    try {
      js.context.deleteProperty('onAddressComplete');
      js.context.deleteProperty('onAddressClose');
    } catch (e) {
      debugPrint('JavaScript 콜백 정리 중 오류: $e');
    }
    super.dispose();
  }
}