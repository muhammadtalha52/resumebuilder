import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/tag_field.dart';

class EditStudentCareerGoalsScreen extends ConsumerStatefulWidget {
  const EditStudentCareerGoalsScreen({super.key});

  @override
  ConsumerState<EditStudentCareerGoalsScreen> createState() =>
      _EditStudentCareerGoalsScreenState();
}

class _EditStudentCareerGoalsScreenState
    extends ConsumerState<EditStudentCareerGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jobTitlesController = TextEditingController();

  List<String> _jobTitles = [];
  String? _jobTitlesError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<String> _originalJobTitles = [];

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
      // Load ideal job titles
      if (user.idealJobTitles != null && user.idealJobTitles!.isNotEmpty) {
        _jobTitles = user.idealJobTitles!
            .map((job) => job.title ?? '')
            .toList();
        _originalJobTitles = List.from(_jobTitles);
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _jobTitlesController.dispose();
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
        _jobTitlesError = null;
      });
      controller.clear();
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  void _clearTagError() {
    setState(() {
      _jobTitlesError = null;
    });
  }

  bool _hasChanges() {
    return !_listEquals(_jobTitles, _originalJobTitles);
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
      _jobTitlesError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;

      if (_jobTitles.isEmpty) {
        _jobTitlesError = 'Please add at least one ideal job title';
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

      // Only add fields that have changed
      if (!_listEquals(_jobTitles, _originalJobTitles)) {
        updateData['ideal_job_titles'] = _jobTitles;
      }

      // Use profile provider to update
      final profileNotifier = ref.read(profileProvider.notifier);
      final success = await profileNotifier.updateProfileFields(updateData);

      if (success && mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Career goals updated successfully!',
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(profileProvider).error;
        showErrorSnackBar(
          context: context,
          message: error ?? 'Failed to update career goals. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: const BackNavigationAppBar(title: 'Career Goals'),
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
                              // Ideal Job Titles
                              TagField(
                                label: 'Ideal Job Titles',
                                isRequired: false,
                                tags: _jobTitles,
                                controller: _jobTitlesController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _jobTitles,
                                  _jobTitlesController,
                                ),
                                onRemove: (tag) => _removeTag(tag, _jobTitles),
                                errorText: _jobTitlesError,
                                onClearError: _clearTagError,
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
