import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../providers/onboarding_provider.dart';
import '../../../../widgets/common/tag_field.dart';

class Step6OptionalInfo extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step6OptionalInfo({super.key, required this.onNext});

  @override
  ConsumerState<Step6OptionalInfo> createState() => _Step6OptionalInfoState();
}

class _Step6OptionalInfoState extends ConsumerState<Step6OptionalInfo> {
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _volunteerWorkController =
      TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _referencesController = TextEditingController();

  List<String> _languages = [];
  List<String> _volunteerWork = [];
  List<String> _hobbies = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final optionalInfo = ref.read(onboardingProvider).optionalInfo;
    if (optionalInfo != null) {
      setState(() {
        _languages = List.from(optionalInfo['languages'] ?? []);
        _volunteerWork = List.from(optionalInfo['volunteerWork'] ?? []);
        _hobbies = List.from(optionalInfo['hobbies'] ?? []);
        _referencesController.text = optionalInfo['references'] ?? '';
      });
    }
    
    // Load from parsed resume data if available
    _loadFromResumeIfAvailable();
  }

  void _loadFromResumeIfAvailable() {
    // Step 6 is optional info that doesn't directly map to resume fields
    // We'll just provide a visual indicator if a resume was processed
    // Users can manually add languages, volunteer work, hobbies, and references
  }

  @override
  void dispose() {
    _languagesController.dispose();
    _volunteerWorkController.dispose();
    _hobbiesController.dispose();
    _referencesController.dispose();
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
      });
      controller.clear();
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }


  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
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

  void _handleSubmit() {
    // Since this is optional info, we don't need strict validation
    // Save whatever data is available
    ref.read(onboardingProvider.notifier).updateOptionalInfo({
      'languages': _languages,
      'volunteerWork': _volunteerWork,
      'hobbies': _hobbies,
      'references': _referencesController.text.trim(),
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final resumeData = ref.read(onboardingProvider.notifier).parsedResumeData;
    final hasResumeData = resumeData != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        TagField(
          label: 'Languages',
          isRequired: false,
          tags: _languages,
          controller: _languagesController,
          onAdd: (tag) => _addTag(tag, _languages, _languagesController),
          onRemove: (tag) => _removeTag(tag, _languages),
        ),
        const SizedBox(height: 20),
        TagField(
          label: 'Volunteer Work',
          isRequired: false,
          tags: _volunteerWork,
          controller: _volunteerWorkController,
          onAdd: (tag) =>
              _addTag(tag, _volunteerWork, _volunteerWorkController),
          onRemove: (tag) => _removeTag(tag, _volunteerWork),
        ),
        const SizedBox(height: 20),
        TagField(
          label: 'Hobbies & Interests',
          isRequired: false,
          tags: _hobbies,
          controller: _hobbiesController,
          onAdd: (tag) => _addTag(tag, _hobbies, _hobbiesController),
          onRemove: (tag) => _removeTag(tag, _hobbies),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'References',
          isRequired: false,
          controller: _referencesController,
          hintText: 'Type here',
          maxLines: 4,
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
    );
  }
}
