import 'package:building_map_app/core/utils/app_logger.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';

/// 렌탈 아이템 데이터 보강 서비스
/// - API에서 완전한 렌탈 아이템 데이터를 조회하여 계약 데이터에 병합
class RentalItemEnrichmentService {
  final ContractService _contractService;

  RentalItemEnrichmentService({ContractService? contractService})
      : _contractService = contractService ?? ContractService();

  /// 모든 계약의 렌탈 아이템을 완전한 데이터로 보강
  /// [savedRentalItems]에 계약별 원본 옵션 저장
  Future<void> enrichAllContracts(
    List<ContractListItem> contracts,
    Map<int, List<RentalItem>> savedRentalItems,
  ) async {
    try {
      final rentalItemsResponse = await _contractService.getAllRentalItems();

      if (rentalItemsResponse == null) {
        AppLogger.w('⚠️ [RENTAL_ITEMS] Failed to fetch rental items from API');
        return;
      }

      // API 응답에서 렌탈 아이템 맵 구성
      final allRentalItems = <String, Map<String, dynamic>>{};
      for (final item in rentalItemsResponse) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          final id = item['id'].toString();
          allRentalItems[id] = {
            'id': id,
            'name': item['name'] ?? '',
            'description': item['description'] ?? '',
            'price': _parsePriceFromString(item['price']),
            'itemType': item['itemType'] ?? '',
            'itemTypeLabel': item['itemTypeLabel'] ?? '',
            'availableStock': item['availableStock'] ?? 0,
            'imageUrl': item['imageUrl'],
          };
        }
      }

      // 각 계약의 렌탈 아이템을 완전한 데이터로 변환
      for (final contract in contracts) {
        if (contract.rentalItems == null || contract.rentalItems!.isEmpty) {
          continue;
        }

        final completeRentalItems = <RentalItem>[];

        for (final contractItem in contract.rentalItems!) {
          final itemData = allRentalItems[contractItem.id.toString()];

          if (itemData != null) {
            completeRentalItems.add(
              RentalItem(
                id: itemData['id'] as String,
                name: itemData['name'] as String,
                description: itemData['description'] as String,
                price: itemData['price'] as int,
                quantity: contractItem.quantity,
                deliveryStatus: contractItem.deliveryStatus,
              ),
            );
          } else {
            completeRentalItems.add(contractItem);
          }
        }

        savedRentalItems[contract.id] = completeRentalItems;
        contract.rentalItems?.clear();
        contract.rentalItems?.addAll(completeRentalItems);
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ [RENTAL_ITEMS] Failed to fetch rental items: $e');
      AppLogger.e('📍 Stack trace: $stackTrace');
    }
  }

  /// 가격 문자열을 int로 변환 ("5000.00" → 5000)
  static int _parsePriceFromString(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.toInt();
    if (price is String) {
      try {
        return double.parse(price).toInt();
      } catch (e) {
        AppLogger.w('⚠️ [PRICE_PARSE] Failed to parse price: $price');
        return 0;
      }
    }
    return 0;
  }
}
