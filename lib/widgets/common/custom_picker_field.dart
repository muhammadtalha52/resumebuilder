import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import 'bottom_sheet_picker.dart';

class CustomPickerField extends StatelessWidget {
  final String labelText;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String hintText;
  final bool isRequired;
  final String? errorText;
  final bool enableSearch;
  final String searchHint;
  final String pickerTitle;

  const CustomPickerField({
    super.key,
    required this.labelText,
    this.value,
    required this.items,
    required this.onChanged,
    this.hintText = 'Select an option',
    this.isRequired = false,
    this.errorText,
    this.enableSearch = true,
    this.searchHint = 'Search...',
    String? pickerTitle,
  }) : pickerTitle = pickerTitle ?? labelText;

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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Picker Field
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            showBottomSheetPicker(
              context: context,
              title: pickerTitle,
              items: items,
              selectedItem: value,
              onItemSelected: onChanged,
              enableSearch: enableSearch,
              searchHint: searchHint,
            );
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
                    value ?? hintText,
                    style: TextStyle(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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
