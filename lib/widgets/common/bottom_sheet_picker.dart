import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class BottomSheetPicker extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final Function(String) onItemSelected;
  final bool enableSearch;
  final String searchHint;
  final double maxHeight;

  const BottomSheetPicker({
    super.key,
    required this.title,
    required this.items,
    this.selectedItem,
    required this.onItemSelected,
    this.enableSearch = true,
    this.searchHint = 'Search...',
    this.maxHeight = 0.7,
  });

  @override
  State<BottomSheetPicker> createState() => _BottomSheetPickerState();
}

class _BottomSheetPickerState extends State<BottomSheetPicker> {
  late List<String> filteredItems;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * widget.maxHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Search bar
          if (widget.enableSearch) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterItems('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(height: 1),

          // Items list
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = item == widget.selectedItem;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onItemSelected(item);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the bottom sheet picker
Future<void> showBottomSheetPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  String? selectedItem,
  required Function(String) onItemSelected,
  bool enableSearch = true,
  String searchHint = 'Search...',
  double maxHeight = 0.7,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BottomSheetPicker(
      title: title,
      items: items,
      selectedItem: selectedItem,
      onItemSelected: onItemSelected,
      enableSearch: enableSearch,
      searchHint: searchHint,
      maxHeight: maxHeight,
    ),
  );
}
