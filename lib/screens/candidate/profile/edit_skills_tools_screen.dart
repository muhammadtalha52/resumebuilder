import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/tag_field.dart';

class EditSkillsToolsScreen extends ConsumerStatefulWidget {
  const EditSkillsToolsScreen({super.key});

  @override
  ConsumerState<EditSkillsToolsScreen> createState() =>
      _EditSkillsToolsScreenState();
}

class _EditSkillsToolsScreenState extends ConsumerState<EditSkillsToolsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hardSkillsController = TextEditingController();
  final TextEditingController _softSkillsController = TextEditingController();
  final TextEditingController _toolsTechnologiesController =
      TextEditingController();

  // Store objects to preserve IDs
  List<HardSkill> _hardSkillObjects = [];
  List<SoftSkill> _softSkillObjects = [];
  List<ToolTechnology> _toolObjects = [];

  String? _hardSkillsError;
  String? _softSkillsError;
  String? _toolsError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<HardSkill> _originalHardSkillObjects = [];
  List<SoftSkill> _originalSoftSkillObjects = [];
  List<ToolTechnology> _originalToolObjects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      // Load objects preserving IDs
      if (user.hardSkills != null && user.hardSkills!.isNotEmpty) {
        _hardSkillObjects = List.from(user.hardSkills!);
        _originalHardSkillObjects = List.from(_hardSkillObjects);
      }

      if (user.softSkills != null && user.softSkills!.isNotEmpty) {
        _softSkillObjects = List.from(user.softSkills!);
        _originalSoftSkillObjects = List.from(_softSkillObjects);
      }

      if (user.toolsTechnologies != null &&
          user.toolsTechnologies!.isNotEmpty) {
        _toolObjects = List.from(user.toolsTechnologies!);
        _originalToolObjects = List.from(_toolObjects);
      }

      setState(() {});
    }
  }

  // Helper methods to convert objects to strings for display
  List<String> _hardSkillStrings() {
    return _hardSkillObjects
        .map((e) => e.skill ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _softSkillStrings() {
    return _softSkillObjects
        .map((e) => e.skill ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _toolStrings() {
    return _toolObjects
        .map((e) => e.tool ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _hardSkillsController.dispose();
    _softSkillsController.dispose();
    _toolsTechnologiesController.dispose();
    super.dispose();
  }

  // Add hard skill
  void _addHardSkill(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    if (_hardSkillObjects.any((obj) => obj.skill == trimmed)) return;

    setState(() {
      _hardSkillObjects.add(HardSkill(skill: trimmed));
      _hardSkillsError = null;
    });
    _hardSkillsController.clear();
  }

  void _removeHardSkill(String tag) {
    setState(() {
      _hardSkillObjects.removeWhere((obj) => obj.skill == tag);
    });
  }

  // Add soft skill
  void _addSoftSkill(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    if (_softSkillObjects.any((obj) => obj.skill == trimmed)) return;

    setState(() {
      _softSkillObjects.add(SoftSkill(skill: trimmed));
      _softSkillsError = null;
    });
    _softSkillsController.clear();
  }

  void _removeSoftSkill(String tag) {
    setState(() {
      _softSkillObjects.removeWhere((obj) => obj.skill == tag);
    });
  }

  // Add tool/technology
  void _addTool(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    if (_toolObjects.any((obj) => obj.tool == trimmed)) return;

    setState(() {
      _toolObjects.add(ToolTechnology(tool: trimmed));
      _toolsError = null;
    });
    _toolsTechnologiesController.clear();
  }

  void _removeTool(String tag) {
    setState(() {
      _toolObjects.removeWhere((obj) => obj.tool == tag);
    });
  }

  bool _hasChanges() {
    final hardSkillsChanged = !_listEquals(
      _hardSkillStrings(),
      _originalHardSkillObjects.map((e) => e.skill ?? '').toList(),
    );
    final softSkillsChanged = !_listEquals(
      _softSkillStrings(),
      _originalSoftSkillObjects.map((e) => e.skill ?? '').toList(),
    );
    final toolsChanged = !_listEquals(
      _toolStrings(),
      _originalToolObjects.map((e) => e.tool ?? '').toList(),
    );

    return hardSkillsChanged || softSkillsChanged || toolsChanged;
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _handleSave() async {
    // Validate custom fields
    bool hasCustomErrors = false;
    setState(() {
      _hardSkillsError = null;
      _softSkillsError = null;
      _toolsError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;

      if (_hardSkillObjects.isEmpty) {
        _hardSkillsError = 'Please add at least one hard skill';
        hasCustomErrors = true;
      }

      if (_softSkillObjects.isEmpty) {
        _softSkillsError = 'Please add at least one soft skill';
        hasCustomErrors = true;
      }

      if (_toolObjects.isEmpty) {
        _toolsError = 'Please add at least one tool or technology';
        hasCustomErrors = true;
      }
    });

    if (!hasCustomErrors) {
      // Check if there are any changes
      if (!_hasChanges()) {
        showErrorSnackBar(context: context, message: 'No changes to save');
        return;
      }

      // Prepare the update data
      final updateData = <String, dynamic>{};

      // Send string arrays for API
      final hardSkillsChanged = !_listEquals(
        _hardSkillStrings(),
        _originalHardSkillObjects.map((e) => e.skill ?? '').toList(),
      );
      final softSkillsChanged = !_listEquals(
        _softSkillStrings(),
        _originalSoftSkillObjects.map((e) => e.skill ?? '').toList(),
      );
      final toolsChanged = !_listEquals(
        _toolStrings(),
        _originalToolObjects.map((e) => e.tool ?? '').toList(),
      );

      if (hardSkillsChanged) {
        updateData['hard_skills'] = _hardSkillStrings();
      }

      if (softSkillsChanged) {
        updateData['soft_skills'] = _softSkillStrings();
      }

      if (toolsChanged) {
        updateData['tools_technologies'] = _toolStrings();
      }

      // Use profile provider to update
      final profileNotifier = ref.read(profileProvider.notifier);
      final success = await profileNotifier.updateProfileFields(updateData);

      if (success && mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Skills & tools updated successfully!',
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(profileProvider).error;
        showErrorSnackBar(
          context: context,
          message:
              error ?? 'Failed to update skills & tools. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/fox-mascot.png', height: 35),
            const SizedBox(width: 8),
            const Text(
              'Skills & Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Main container with white background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hard Skills
                              TagField(
                                label: 'Hard Skills',
                                isRequired: false,
                                tags: _hardSkillStrings(),
                                controller: _hardSkillsController,
                                onAdd: _addHardSkill,
                                onRemove: _removeHardSkill,
                                errorText: _hardSkillsError,
                                onClearError: () =>
                                    setState(() => _hardSkillsError = null),
                              ),
                              const SizedBox(height: 24),

                              // Soft Skills
                              TagField(
                                label: 'Soft Skills',
                                isRequired: false,
                                tags: _softSkillStrings(),
                                controller: _softSkillsController,
                                onAdd: _addSoftSkill,
                                onRemove: _removeSoftSkill,
                                errorText: _softSkillsError,
                                onClearError: () =>
                                    setState(() => _softSkillsError = null),
                              ),
                              const SizedBox(height: 24),

                              // Tools/Technologies
                              TagField(
                                label: 'Tools/Technologies',
                                isRequired: false,
                                tags: _toolStrings(),
                                controller: _toolsTechnologiesController,
                                onAdd: _addTool,
                                onRemove: _removeTool,
                                errorText: _toolsError,
                                onClearError: () =>
                                    setState(() => _toolsError = null),
                              ),

                              const SizedBox(height: 32),

                              // Update button
                              CustomButton(
                                text: 'Update',
                                onPressed: ref.watch(profileProvider).isLoading
                                    ? null
                                    : _handleSave,
                                isLoading: ref.watch(profileProvider).isLoading,
                                height: 56,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
