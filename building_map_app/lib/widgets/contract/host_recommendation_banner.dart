import 'package:flutter/material.dart';
import '../../models/contract.dart';

/// 호스트 권장 옵션 배너 (APPROVED 상태, recommendedItems 있을 때만 표시)
/// 결제 버튼 바로 위에 위치 — 구매 유도 없이 호스트 안내 느낌으로 표현
class HostRecommendationBanner extends StatelessWidget {
  final RecommendedItemsInfo recommendedItems;

  const HostRecommendationBanner({required this.recommendedItems, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.chat_bubble_outline,
                size: 15,
                color: Color(0xFF0369A1),
              ),
              SizedBox(width: 6),
              Text(
                '임대인이 입주 전 챙기면 좋을 상품을 안내해뒀어요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0369A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...recommendedItems.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  const Text('• ', style: TextStyle(color: Color(0xFF64748B))),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '필요한 옵션 상품을 추가할 수 있어요',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
