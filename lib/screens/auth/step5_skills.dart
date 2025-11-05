import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/tag_field.dart';

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

  // Error states for each field
  String? _hardSkillsError;
  String? _softSkillsError;
  String? _toolsError;

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

    // Load from parsed resume data if available and no existing skills
    _loadFromResumeIfAvailable();
  }

  void _loadFromResumeIfAvailable() {
    final resumeData = ref.read(onboardingProvider.notifier).parsedResumeData;
    if (resumeData != null &&
        resumeData.skills != null &&
        _hardSkills.isEmpty &&
        _softSkills.isEmpty &&
        _tools.isEmpty) {
      setState(() {
        // Populate from resume data
        _hardSkills = List.from(resumeData.skills!.hardSkills);
        _softSkills = List.from(resumeData.skills!.softSkills);
        _tools = List.from(resumeData.skills!.toolsAndTechnologies);
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
        // Clear error when a tag is added
        if (list == _hardSkills && _hardSkillsError != null) {
          _hardSkillsError = null;
        } else if (list == _softSkills && _softSkillsError != null) {
          _softSkillsError = null;
        } else if (list == _tools && _toolsError != null) {
          _toolsError = null;
        }
      });
      controller.clear();
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  void _handleSubmit() {
    // Dismiss keyboard before validation
    FocusScope.of(context).requestFocus(FocusNode());

    bool hasErrors = false;

    setState(() {
      // Validate each field
      if (_hardSkills.isEmpty) {
        _hardSkillsError = 'Please add at least one hard skill';
        hasErrors = true;
      } else {
        _hardSkillsError = null;
      }

      if (_softSkills.isEmpty) {
        _softSkillsError = 'Please add at least one soft skill';
        hasErrors = true;
      } else {
        _softSkillsError = null;
      }

      if (_tools.isEmpty) {
        _toolsError = 'Please add at least one tool/technology';
        hasErrors = true;
      } else {
        _toolsError = null;
      }
    });

    if (hasErrors) {
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
    final resumeData = ref.read(onboardingProvider.notifier).parsedResumeData;
    final hasResumeSkills =
        resumeData?.skills != null &&
        (resumeData!.skills!.hardSkills.isNotEmpty ||
            resumeData.skills!.softSkills.isNotEmpty ||
            resumeData.skills!.toolsAndTechnologies.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagField(
          label: 'Hard Skills',
          isRequired: true,
          tags: _hardSkills,
          controller: _hardSkillsController,
          onAdd: (tag) => _addTag(tag, _hardSkills, _hardSkillsController),
          onRemove: (tag) => _removeTag(tag, _hardSkills),
          errorText: _hardSkillsError,
          onClearError: () {
            setState(() {
              _hardSkillsError = null;
            });
          },
        ),
        const SizedBox(height: 20),
        TagField(
          label: 'Soft Skills',
          isRequired: true,
          tags: _softSkills,
          controller: _softSkillsController,
          onAdd: (tag) => _addTag(tag, _softSkills, _softSkillsController),
          onRemove: (tag) => _removeTag(tag, _softSkills),
          errorText: _softSkillsError,
          onClearError: () {
            setState(() {
              _softSkillsError = null;
            });
          },
        ),
        const SizedBox(height: 20),
        TagField(
          label: 'Tools/Technologies',
          isRequired: true,
          tags: _tools,
          controller: _toolsController,
          onAdd: (tag) => _addTag(tag, _tools, _toolsController),
          onRemove: (tag) => _removeTag(tag, _tools),
          errorText: _toolsError,
          onClearError: () {
            setState(() {
              _toolsError = null;
            });
          },
        ),
        const SizedBox(height: 20),
        // Next button
        CustomButton(text: 'Next', onPressed: _handleSubmit, height: 56),
      ],
    );
  }
}
