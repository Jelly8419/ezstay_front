import 'package:flutter/material.dart';
import '../models/search_filters.dart';
import '../constants/app_constants.dart';
import 'date_range_calendar_dialog.dart';

/// 검색 필터 바 위젯
class SearchFilterBar extends StatefulWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;

  const SearchFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // 임대 일정 필터
          _buildFilterChip(
            label: '임대 일정',
            icon: Icons.calendar_today,
            isActive: _currentFilters.dateRange != null,
            onTap: () => _showDateRangeDialog(),
          ),
          const SizedBox(width: 8),

          // 건물 유형 필터
          _buildFilterChip(
            label: '건물 유형',
            icon: Icons.apartment,
            isActive: _currentFilters.buildingTypes.isNotEmpty,
            onTap: () => _showBuildingTypesDialog(),
          ),
          const SizedBox(width: 8),

          // 방 개수 필터
          _buildFilterChip(
            label: '방 개수',
            icon: Icons.bed,
            isActive: _currentFilters.bedroomCounts.isNotEmpty,
            onTap: () => _showBedroomCountsDialog(),
          ),
          const SizedBox(width: 8),

          // 임대료 필터
          _buildFilterChip(
            label: '임대료',
            icon: Icons.attach_money,
            isActive: !_currentFilters.priceRange.isDefault,
            onTap: () => _showPriceRangeDialog(),
          ),
          const SizedBox(width: 8),

          // 기타 옵션 필터
          _buildFilterChip(
            label: '기타 옵션',
            icon: Icons.more_horiz,
            isActive: _currentFilters.otherOptions.isNotEmpty,
            onTap: () => _showOtherOptionsDialog(),
          ),

          const Spacer(),

          // 필터 초기화 버튼
          if (_currentFilters.hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentFilters = const SearchFilters();
                });
                widget.onFiltersChanged(_currentFilters);
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('초기화'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return DateRangeCalendarDialog(
          initialDateRange: _currentFilters.dateRange,
          onDateRangeSelected: (dateRange) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(
                dateRange: dateRange,
              );
            });
            widget.onFiltersChanged(_currentFilters);
          },
        );
      },
    );
  }

  void _showBuildingTypesDialog() {
    final selectedTypes = Set<String>.from(_currentFilters.buildingTypes);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('건물 유형'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: BuildingTypes.all.map((type) {
                  return CheckboxListTile(
                    title: Text(type),
                    value: selectedTypes.contains(type),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        buildingTypes: selectedTypes,
                      );
                    });
                    widget.onFiltersChanged(_currentFilters);
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBedroomCountsDialog() {
    final selectedCounts = Set<int>.from(_currentFilters.bedroomCounts);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('방 개수'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('1개'),
                    value: selectedCounts.contains(1),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedCounts.add(1);
                        } else {
                          selectedCounts.remove(1);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('2개'),
                    value: selectedCounts.contains(2),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedCounts.add(2);
                        } else {
                          selectedCounts.remove(2);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('3개 이상'),
                    value: selectedCounts.contains(3),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedCounts.add(3);
                        } else {
                          selectedCounts.remove(3);
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        bedroomCounts: selectedCounts,
                      );
                    });
                    widget.onFiltersChanged(_currentFilters);
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPriceRangeDialog() {
    int minPrice = _currentFilters.priceRange.minPrice;
    int? maxPrice = _currentFilters.priceRange.maxPrice;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('임대료 범위'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('최소: ${minPrice}만원'),
                  Slider(
                    value: minPrice.toDouble(),
                    min: 0,
                    max: 150,
                    divisions: 15,
                    label: '${minPrice}만원',
                    onChanged: (value) {
                      setDialogState(() {
                        minPrice = value.toInt();
                        if (maxPrice != null && minPrice >= maxPrice!) {
                          maxPrice = minPrice + 10;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('최대: ${maxPrice == null ? "전체" : "${maxPrice}만원"}'),
                  Slider(
                    value: maxPrice?.toDouble() ?? 160,
                    min: 10,
                    max: 160,
                    divisions: 16,
                    label: maxPrice == null ? '전체' : '${maxPrice}만원',
                    onChanged: (value) {
                      setDialogState(() {
                        if (value >= 160) {
                          maxPrice = null; // 전체
                        } else {
                          maxPrice = value.toInt();
                          if (maxPrice! <= minPrice) {
                            minPrice = (maxPrice! - 10).clamp(0, 150);
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        priceRange: PriceRange(
                          minPrice: minPrice,
                          maxPrice: maxPrice,
                        ),
                      );
                    });
                    widget.onFiltersChanged(_currentFilters);
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOtherOptionsDialog() {
    final selectedOptions = Set<String>.from(_currentFilters.otherOptions);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('기타 옵션'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: OtherOptions.all.map((option) {
                  return CheckboxListTile(
                    title: Text(OtherOptions.labels[option]!),
                    value: selectedOptions.contains(option),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedOptions.add(option);
                        } else {
                          selectedOptions.remove(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        otherOptions: selectedOptions,
                      );
                    });
                    widget.onFiltersChanged(_currentFilters);
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
