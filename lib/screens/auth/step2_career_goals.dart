import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/salary_ranges.dart';
import '../../../../providers/onboarding_provider.dart';
import '../../../../widgets/common/custom_picker_field.dart';
import '../../../../widgets/common/tag_field.dart';
import '../../widgets/common/custom_button.dart';

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

  List<String> _jobTitles = [];
  List<String> _industries = [];
  List<String> _locationPreferences = [];
  String? _desiredSalaryRange;
  String? _jobTitlesError;
  String? _industriesError;
  String? _locationError;
  String? _salaryError;

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
        _desiredSalaryRange = careerGoals['desiredPayRange'];
        _locationPreferences = List.from(
          careerGoals['locationPreferences'] ??
              (careerGoals['locationPreference'] != null
                  ? [careerGoals['locationPreference']]
                  : []),
        );
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers before calling super.dispose()
    // to ensure they're cleaned up while the widget tree is still stable
    _jobTitlesController.dispose();
    _industriesController.dispose();
    _longTermGoalsController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Unfocus any text fields before deactivation to prevent
    // looking up deactivated widget's ancestor
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
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

  void _clearTagError(List<String> list) {
    setState(() {
      if (list == _jobTitles) _jobTitlesError = null;
      if (list == _industries) _industriesError = null;
    });
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
                fontSize: 17,
                fontWeight: FontWeight.w500,
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
    // Dismiss keyboard before validation
    FocusScope.of(context).requestFocus(FocusNode());

    bool isValid = _formKey.currentState!.validate();
    bool hasCustomErrors = false;

    // Validate custom fields
    setState(() {
      _jobTitlesError = null;
      _industriesError = null;
      _locationError = null;
      _salaryError = null;

      if (_jobTitles.isEmpty) {
        _jobTitlesError = 'Please add at least one job title';
        hasCustomErrors = true;
      }

      if (_industries.isEmpty) {
        _industriesError = 'Please add at least one industry';
        hasCustomErrors = true;
      }

      if (_locationPreferences.isEmpty) {
        _locationError = 'Please select at least one location preference';
        hasCustomErrors = true;
      }

      if (_desiredSalaryRange == null) {
        _salaryError = 'Please select a salary range';
        hasCustomErrors = true;
      }
    });

    if (isValid && !hasCustomErrors) {
      ref.read(onboardingProvider.notifier).updateCareerGoals({
        'jobTitles': _jobTitles,
        'industries': _industries,
        'desiredPayRange': _desiredSalaryRange,
        'locationPreferences': _locationPreferences,
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
          TagField(
            label: 'Desired Job Titles',
            isRequired: true,
            tags: _jobTitles,
            controller: _jobTitlesController,
            onAdd: (tag) => _addTag(tag, _jobTitles, _jobTitlesController),
            onRemove: (tag) => _removeTag(tag, _jobTitles),
            errorText: _jobTitlesError,
            onClearError: () => _clearTagError(_jobTitles),
          ),
          const SizedBox(height: 20),
          TagField(
            label: 'Preferred Industries',
            isRequired: true,
            tags: _industries,
            controller: _industriesController,
            onAdd: (tag) => _addTag(tag, _industries, _industriesController),
            onRemove: (tag) => _removeTag(tag, _industries),
            errorText: _industriesError,
            onClearError: () => _clearTagError(_industries),
          ),
          const SizedBox(height: 20),
          CustomPickerField(
            labelText: 'Location Preference',
            isRequired: true,
            selectedValues: _locationPreferences,
            items: const ['On-site', 'Remote', 'Hybrid'],
            hintText: 'Select Options',
            errorText: _locationError,
            enableSearch: false,
            pickerTitle: 'Select Location Preference',
            isMultiSelect: true,
            onMultiChanged: (values) {
              setState(() {
                _locationPreferences = values;
                _locationError = null;
              });
            },
          ),
          const SizedBox(height: 20),
          CustomPickerField(
            labelText: 'Desired Salary Range',
            isRequired: true,
            value: _desiredSalaryRange,
            items: SalaryRanges.ranges,
            hintText: 'Select salary range',
            errorText: _salaryError,
            enableSearch: true,
            searchHint: 'Search salary ranges...',
            pickerTitle: 'Select Desired Salary Range',
            onChanged: (value) {
              setState(() {
                _desiredSalaryRange = value;
                _salaryError = null;
              });
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
          CustomButton(text: 'Next', onPressed: _handleSubmit, height: 56),
        ],
      ),
    );
  }
}
