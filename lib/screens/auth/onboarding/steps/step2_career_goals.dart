import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../providers/onboarding_provider.dart';
import '../../../../widgets/common/custom_dropdown.dart';

class Step2CareerGoals extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step2CareerGoals({super.key, required this.onNext});

  @override
  ConsumerState<Step2CareerGoals> createState() => _Step2CareerGoalsState();
}

class _Step2CareerGoalsState extends ConsumerState<Step2CareerGoals> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jobTitlesController = TextEditingController();
  final TextEditingController _industriesController = TextEditingController();
  final TextEditingController _longTermGoalsController =
      TextEditingController();
  final TextEditingController _desiredPayRangeController =
      TextEditingController();

  List<String> _jobTitles = [];
  List<String> _industries = [];
  String? _locationPreference;
  String? _jobTitlesError;
  String? _industriesError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final careerGoals = ref.read(onboardingProvider).careerGoals;
    if (careerGoals != null) {
      setState(() {
        _jobTitles = List.from(careerGoals['jobTitles'] ?? []);
        _industries = List.from(careerGoals['industries'] ?? []);
        _longTermGoalsController.text = careerGoals['longTermGoals'] ?? '';
        _desiredPayRangeController.text = (careerGoals['desiredPayRange'] ?? '')
            .toString();
        _locationPreference = careerGoals['locationPreference'];
      });
    }
  }

  @override
  void dispose() {
    _jobTitlesController.dispose();
    _industriesController.dispose();
    _longTermGoalsController.dispose();
    _desiredPayRangeController.dispose();
    super.dispose();
  }

  void _addTag(
    String tag,
    List<String> list,
    TextEditingController controller,
  ) {
    if (tag.trim().isNotEmpty && !list.contains(tag.trim())) {
      setState(() {
        list.add(tag.trim());
        // Clear errors when adding tags
        if (list == _jobTitles) _jobTitlesError = null;
        if (list == _industries) _industriesError = null;
      });
      controller.clear();
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  Widget _buildTagField({
    required String label,
    required bool isRequired,
    required List<String> tags,
    required TextEditingController controller,
    required Function(String) onAdd,
    required Function(String) onRemove,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              onAdd(value);
            }
          },
          decoration: InputDecoration(
            hintText: 'Add tags...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.inputBorderFocused,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        // Error message
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
        // Tags display (outside the input field)
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => _buildTag(tag, onRemove)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String tag, Function(String) onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEEFF), // Surface color
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF7777F8),
          width: 1.5,
        ), // Border color
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Colors.black,
              // White text for better contrast on the blue background
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onRemove(tag),
            child: const Icon(Icons.close, size: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixText != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0,
                      child: Text(
                        prefixText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: prefixText != null
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorderFocused),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required bool isRequired,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${value.toInt()}${suffix ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.inputBorder,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 1000).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    bool isValid = _formKey.currentState!.validate();
    bool hasCustomErrors = false;

    // Validate custom fields
    setState(() {
      _jobTitlesError = null;
      _industriesError = null;
      _locationError = null;

      if (_jobTitles.isEmpty) {
        _jobTitlesError = 'Please add at least one job title';
        hasCustomErrors = true;
      }

      if (_industries.isEmpty) {
        _industriesError = 'Please add at least one industry';
        hasCustomErrors = true;
      }

      if (_locationPreference == null) {
        _locationError = 'Please select a location preference';
        hasCustomErrors = true;
      }
    });

    if (isValid && !hasCustomErrors) {
      // Parse desired pay range, default to empty string if invalid
      final desiredPayRange = _desiredPayRangeController.text.trim().isEmpty
          ? ''
          : _desiredPayRangeController.text.trim();

      ref.read(onboardingProvider.notifier).updateCareerGoals({
        'jobTitles': _jobTitles,
        'industries': _industries,
        'desiredPayRange': desiredPayRange,
        'locationPreference': _locationPreference,
        'longTermGoals': _longTermGoalsController.text.trim(),
      });

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagField(
            label: 'Desired Job Titles',
            isRequired: true,
            tags: _jobTitles,
            controller: _jobTitlesController,
            onAdd: (tag) => _addTag(tag, _jobTitles, _jobTitlesController),
            onRemove: (tag) => _removeTag(tag, _jobTitles),
            errorText: _jobTitlesError,
          ),
          const SizedBox(height: 20),
          _buildTagField(
            label: 'Preferred Industries',
            isRequired: true,
            tags: _industries,
            controller: _industriesController,
            onAdd: (tag) => _addTag(tag, _industries, _industriesController),
            onRemove: (tag) => _removeTag(tag, _industries),
            errorText: _industriesError,
          ),
          const SizedBox(height: 20),
          CustomStringDropdown(
            labelText: 'Location Preference',
            isRequired: true,
            value: _locationPreference,
            items: const ['On-site', 'Remote', 'Hybrid'],
            hintText: 'Select Options',
            errorText: _locationError,
            onChanged: (value) {
              setState(() {
                _locationPreference = value;
                _locationError = null;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Desired Salary',
            isRequired: true,
            controller: _desiredPayRangeController,
            hintText: 'Enter your desired salary',
            keyboardType: TextInputType.number,
            prefixText: '\$',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your desired salary';
              }
              // Check if it's a valid number
              final numValue = int.tryParse(value.trim());
              if (numValue == null) {
                return 'Please enter a valid number';
              }
              if (numValue <= 0) {
                return 'Please enter a positive amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Long-term Goals',
            isRequired: false,
            controller: _longTermGoalsController,
            hintText:
                'e.g., Become a technical lead and mentor junior developers',
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
