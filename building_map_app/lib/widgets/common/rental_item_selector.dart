import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/rental_item.dart';
import '../../models/selected_rental_item.dart';

/// 렌탈 아이템 선택 위젯 (React UI 스타일)
/// 옵션 제품(침구류, 어메니티, 헤어드라이어, 타올)의 수량을 선택합니다.
class RentalItemSelector extends StatelessWidget {
  final RentalItem item;
  final int currentQuantity;
  final Function(int quantity) onQuantityChanged;

  const RentalItemSelector({
    super.key,
    required this.item,
    required this.currentQuantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: currentQuantity > 0
              ? AppColors.primary600
              : AppColors.border,
          width: currentQuantity > 0 ? 2 : 1,
        ),
        borderRadius: AppRadius.radiusMd,
        color: currentQuantity > 0
            ? AppColors.primary50
            : AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이템 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 또는 이미지
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: AppRadius.radiusSm,
                  child: Image.network(
                    item.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultIcon(),
                  ),
                )
              else
                _buildDefaultIcon(),

              SizedBox(width: AppSpacing.md),

              // 이름 및 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md),

          // 가격 및 수량 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 가격 표시
              Text(
                '${_formatPrice(item.price)}/개',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary700,
                ),
              ),

              // 수량 선택 버튼
              Row(
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (currentQuantity > 0) {
                        onQuantityChanged(currentQuantity - 1);
                      }
                    },
                    enabled: currentQuantity > 0,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$currentQuantity',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onTap: () {
                      if (currentQuantity < item.availableStock) {
                        onQuantityChanged(currentQuantity + 1);
                      }
                    },
                    enabled: currentQuantity < item.availableStock,
                  ),
                ],
              ),
            ],
          ),

          // 재고 정보
          if (item.availableStock > 0) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              '재고: ${item.availableStock}개',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              '품절',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultIcon() {
    IconData iconData;
    switch (item.name) {
      case '침구 세트':
      case '침구류':
        iconData = Icons.bed;
        break;
      case '어메니티 키트':
      case '어메니티':
        iconData = Icons.spa;
        break;
      case '헤어드라이어':
      case '드라이어':
        iconData = Icons.air;
        break;
      case '타올 세트':
      case '타올':
        iconData = Icons.dry_cleaning;
        break;
      default:
        iconData = Icons.shopping_bag;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Icon(
        iconData,
        color: AppColors.primary600,
        size: 24,
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary600 : AppColors.neutral300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          color: AppColors.neutral0,
          size: 20,
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// 렌탈 아이템 카테고리 섹션 (여러 아이템을 그룹으로 표시)
class RentalItemCategorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<RentalItem> items;
  final List<SelectedRentalItem> selectedItems;
  final Function(SelectedRentalItem) onItemUpdated;

  const RentalItemCategorySection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.selectedItems,
    required this.onItemUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 제목
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary600),
            SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.headingSmall,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),

        // 아이템 목록
        ...items.map((item) {
          final currentQuantity = _getCurrentQuantity(item.id);
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: RentalItemSelector(
              item: item,
              currentQuantity: currentQuantity,
              onQuantityChanged: (quantity) {
                onItemUpdated(SelectedRentalItem(
                  id: item.id,
                  name: item.name,
                  description: item.description,
                  price: item.price,
                  quantity: quantity,
                ));
              },
            ),
          );
        }),
      ],
    );
  }

  int _getCurrentQuantity(int itemId) {
    final selected = selectedItems.where((item) => item.id == itemId).firstOrNull;
    return selected?.quantity ?? 0;
  }
}
