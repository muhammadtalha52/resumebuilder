import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import 'bottom_sheet_picker.dart';

class CustomPickerField extends StatelessWidget {
  final String labelText;
  final String? value;
  final List<String>? selectedValues;
  final List<String> items;
  final Function(String?)? onChanged;
  final Function(List<String>)? onMultiChanged;
  final String hintText;
  final bool isRequired;
  final String? errorText;
  final bool enableSearch;
  final String searchHint;
  final String pickerTitle;
  final bool isMultiSelect;

  const CustomPickerField({
    super.key,
    required this.labelText,
    this.value,
    this.selectedValues,
    required this.items,
    this.onChanged,
    this.onMultiChanged,
    this.hintText = 'Select an option',
    this.isRequired = false,
    this.errorText,
    this.enableSearch = true,
    this.searchHint = 'Search...',
    String? pickerTitle,
    this.isMultiSelect = false,
  }) : pickerTitle = pickerTitle ?? labelText;

  String _getDisplayText() {
    if (isMultiSelect) {
      if (selectedValues?.isEmpty ?? true) {
        return hintText;
      }
      return selectedValues!.join(', ');
    } else {
      return value ?? hintText;
    }
  }

  bool _hasSelection() {
    if (isMultiSelect) {
      return selectedValues?.isNotEmpty ?? false;
    } else {
      return value != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              labelText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Picker Field
        GestureDetector(
          onTap: () {
            // Dismiss keyboard before opening picker
            FocusScope.of(context).requestFocus(FocusNode());
            HapticFeedback.lightImpact();
            if (isMultiSelect) {
              showBottomSheetMultiPicker(
                context: context,
                title: pickerTitle,
                items: items,
                selectedItems: selectedValues ?? [],
                onItemsSelected: onMultiChanged!,
                enableSearch: enableSearch,
                searchHint: searchHint,
              );
            } else {
              showBottomSheetPicker(
                context: context,
                title: pickerTitle,
                items: items,
                selectedItem: value,
                onItemSelected: onChanged!,
                enableSearch: enableSearch,
                searchHint: searchHint,
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: TextStyle(
                      color: _hasSelection()
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        // Error message
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
