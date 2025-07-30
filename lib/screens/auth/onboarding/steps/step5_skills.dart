import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../providers/onboarding_provider.dart';

class Step5Skills extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step5Skills({super.key, required this.onNext});

  @override
  ConsumerState<Step5Skills> createState() => _Step5SkillsState();
}

class _Step5SkillsState extends ConsumerState<Step5Skills> {
  final TextEditingController _hardSkillsController = TextEditingController();
  final TextEditingController _softSkillsController = TextEditingController();
  final TextEditingController _toolsController = TextEditingController();

  List<String> _hardSkills = [];
  List<String> _softSkills = [];
  List<String> _tools = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final skills = ref.read(onboardingProvider).skills;
    if (skills != null) {
      setState(() {
        _hardSkills = List.from(skills['hardSkills'] ?? []);
        _softSkills = List.from(skills['softSkills'] ?? []);
        _tools = List.from(skills['tools'] ?? []);
      });
    }
  }

  @override
  void dispose() {
    _hardSkillsController.dispose();
    _softSkillsController.dispose();
    _toolsController.dispose();
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

  void _handleSubmit() {
    if (_hardSkills.isEmpty || _softSkills.isEmpty || _tools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item in each category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(onboardingProvider.notifier).updateSkills({
      'hardSkills': _hardSkills,
      'softSkills': _softSkills,
      'tools': _tools,
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagField(
          label: 'Hard Skills',
          isRequired: true,
          tags: _hardSkills,
          controller: _hardSkillsController,
          onAdd: (tag) => _addTag(tag, _hardSkills, _hardSkillsController),
          onRemove: (tag) => _removeTag(tag, _hardSkills),
        ),
        const SizedBox(height: 20),
        _buildTagField(
          label: 'Soft Skills',
          isRequired: true,
          tags: _softSkills,
          controller: _softSkillsController,
          onAdd: (tag) => _addTag(tag, _softSkills, _softSkillsController),
          onRemove: (tag) => _removeTag(tag, _softSkills),
        ),
        const SizedBox(height: 20),
        _buildTagField(
          label: 'Tools/Technologies',
          isRequired: true,
          tags: _tools,
          controller: _toolsController,
          onAdd: (tag) => _addTag(tag, _tools, _toolsController),
          onRemove: (tag) => _removeTag(tag, _tools),
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
