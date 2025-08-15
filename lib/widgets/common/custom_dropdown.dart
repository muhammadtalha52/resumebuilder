import 'package:flutter/material.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'package:skillresy/constants/app_sizes.dart';

class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.errorText,
  });

  final String labelText;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final void Function(T?)? onChanged;
  final String? hintText;
  final bool isRequired;
  final bool enabled;
  final String? Function(T?)? validator;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: isRequired && labelText.endsWith(' *')
                    ? labelText.substring(0, labelText.length - 2)
                    : labelText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired && !labelText.endsWith(' *'))
                TextSpan(
                  text: '*',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spaceS),
        // Dropdown
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hintText ?? 'Select an option',
            hintStyle: TextStyle(
              color: AppColors.textHint.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            errorText: errorText,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

// Convenience class for simple string dropdowns
class CustomStringDropdown extends StatelessWidget {
  const CustomStringDropdown({
    super.key,
    required this.labelText,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.errorText,
  });

  final String labelText;
  final List<String> items;
  final String? value;
  final void Function(String?)? onChanged;
  final String? hintText;
  final bool isRequired;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      labelText: labelText,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      value: value,
      onChanged: onChanged,
      hintText: hintText,
      isRequired: isRequired,
      enabled: enabled,
      validator: validator,
      errorText: errorText,
    );
  }
}
