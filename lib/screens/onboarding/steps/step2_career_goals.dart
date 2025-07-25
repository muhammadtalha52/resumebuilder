import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/onboarding_provider.dart';

class Step2CareerGoals extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step2CareerGoals({super.key, required this.onNext});

  @override
  ConsumerState<Step2CareerGoals> createState() => _Step2CareerGoalsState();
}

class _Step2CareerGoalsState extends ConsumerState<Step2CareerGoals> {
  final TextEditingController _jobTitlesController = TextEditingController();
  final TextEditingController _industriesController = TextEditingController();
  final TextEditingController _longTermGoalsController =
      TextEditingController();

  List<String> _jobTitles = [];
  List<String> _industries = [];

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
      });
    }
  }

  @override
  void dispose() {
    _jobTitlesController.dispose();
    _industriesController.dispose();
    _longTermGoalsController.dispose();
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

  Widget _buildTagField({
    required String label,
    required bool isRequired,
    required List<String> tags,
    required TextEditingController controller,
    required Function(String) onAdd,
    required Function(String) onRemove,
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              onAdd(value);
            }
          },
          decoration: InputDecoration(
            hintText: 'Add tags...',
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
    if (_jobTitles.isEmpty || _industries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one desired job title and preferred industry',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(onboardingProvider.notifier).updateCareerGoals({
      'jobTitles': _jobTitles,
      'industries': _industries,
      'longTermGoals': _longTermGoalsController.text.trim(),
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagField(
          label: 'Desired Job Titles',
          isRequired: true,
          tags: _jobTitles,
          controller: _jobTitlesController,
          onAdd: (tag) => _addTag(tag, _jobTitles, _jobTitlesController),
          onRemove: (tag) => _removeTag(tag, _jobTitles),
        ),
        const SizedBox(height: 20),
        _buildTagField(
          label: 'Preferred Industries',
          isRequired: true,
          tags: _industries,
          controller: _industriesController,
          onAdd: (tag) => _addTag(tag, _industries, _industriesController),
          onRemove: (tag) => _removeTag(tag, _industries),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Long-term Goals',
          isRequired: false,
          controller: _longTermGoalsController,
          hintText:
              'e.g., Become a technical lead and mentor junior developers',
          maxLines: 3,
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
