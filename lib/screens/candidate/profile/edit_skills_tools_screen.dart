import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/snackbar_utils.dart';
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

  List<String> _hardSkills = [];
  List<String> _softSkills = [];
  List<String> _toolsTechnologies = [];
  String? _hardSkillsError;
  String? _softSkillsError;
  String? _toolsError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<String> _originalHardSkills = [];
  List<String> _originalSoftSkills = [];
  List<String> _originalToolsTechnologies = [];

  @override
  void initState() {
    super.initState();
    // Delay the provider initialization to avoid modifying state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      // Load hard skills from list
      if (user.hardSkills != null && user.hardSkills!.isNotEmpty) {
        _hardSkills = List.from(user.hardSkills!);
        _originalHardSkills = List.from(_hardSkills);
      }

      // Load soft skills from list
      if (user.softSkills != null && user.softSkills!.isNotEmpty) {
        _softSkills = List.from(user.softSkills!);
        _originalSoftSkills = List.from(_softSkills);
      }

      // Load tools/technologies from list
      if (user.toolsTechnologies != null &&
          user.toolsTechnologies!.isNotEmpty) {
        _toolsTechnologies = List.from(user.toolsTechnologies!);
        _originalToolsTechnologies = List.from(_toolsTechnologies);
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _hardSkillsController.dispose();
    _softSkillsController.dispose();
    _toolsTechnologiesController.dispose();
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
        if (list == _hardSkills) _hardSkillsError = null;
        if (list == _softSkills) _softSkillsError = null;
        if (list == _toolsTechnologies) _toolsError = null;
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
      if (list == _hardSkills) _hardSkillsError = null;
      if (list == _softSkills) _softSkillsError = null;
      if (list == _toolsTechnologies) _toolsError = null;
    });
  }

  bool _hasChanges() {
    // Check if any field has changed
    final hardSkillsChanged = !_listEquals(_hardSkills, _originalHardSkills);
    final softSkillsChanged = !_listEquals(_softSkills, _originalSoftSkills);
    final toolsChanged = !_listEquals(
      _toolsTechnologies,
      _originalToolsTechnologies,
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

      if (_hardSkills.isEmpty) {
        _hardSkillsError = 'Please add at least one hard skill';
        hasCustomErrors = true;
      }

      if (_softSkills.isEmpty) {
        _softSkillsError = 'Please add at least one soft skill';
        hasCustomErrors = true;
      }

      if (_toolsTechnologies.isEmpty) {
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

      // Send lists directly as arrays for API
      // Only add fields that have changed
      if (!_listEquals(_hardSkills, _originalHardSkills)) {
        updateData['hard_skills'] = _hardSkills;
      }

      if (!_listEquals(_softSkills, _originalSoftSkills)) {
        updateData['soft_skills'] = _softSkills;
      }

      if (!_listEquals(_toolsTechnologies, _originalToolsTechnologies)) {
        updateData['tools_technologies'] = _toolsTechnologies;
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
                                tags: _hardSkills,
                                controller: _hardSkillsController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _hardSkills,
                                  _hardSkillsController,
                                ),
                                onRemove: (tag) => _removeTag(tag, _hardSkills),
                                errorText: _hardSkillsError,
                                onClearError: () => _clearTagError(_hardSkills),
                              ),
                              const SizedBox(height: 24),

                              // Soft Skills
                              TagField(
                                label: 'Soft Skills',
                                isRequired: false,
                                tags: _softSkills,
                                controller: _softSkillsController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _softSkills,
                                  _softSkillsController,
                                ),
                                onRemove: (tag) => _removeTag(tag, _softSkills),
                                errorText: _softSkillsError,
                                onClearError: () => _clearTagError(_softSkills),
                              ),
                              const SizedBox(height: 24),

                              // Tools/Technologies
                              TagField(
                                label: 'Tools/Technologies',
                                isRequired: false,
                                tags: _toolsTechnologies,
                                controller: _toolsTechnologiesController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _toolsTechnologies,
                                  _toolsTechnologiesController,
                                ),
                                onRemove: (tag) =>
                                    _removeTag(tag, _toolsTechnologies),
                                errorText: _toolsError,
                                onClearError: () =>
                                    _clearTagError(_toolsTechnologies),
                              ),

                              const SizedBox(height: 32),

                              // Update button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      ref.watch(profileProvider).isLoading
                                      ? null
                                      : _handleSave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor: AppColors.primary
                                        .withValues(alpha: 0.6),
                                  ),
                                  child: ref.watch(profileProvider).isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Update',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
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
