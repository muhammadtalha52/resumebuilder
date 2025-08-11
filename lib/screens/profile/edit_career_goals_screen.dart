import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../widgets/common/tag_field.dart';

class EditCareerGoalsScreen extends ConsumerStatefulWidget {
  const EditCareerGoalsScreen({super.key});

  @override
  ConsumerState<EditCareerGoalsScreen> createState() =>
      _EditCareerGoalsScreenState();
}

class _EditCareerGoalsScreenState extends ConsumerState<EditCareerGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jobTitlesController = TextEditingController();
  final TextEditingController _industriesController = TextEditingController();
  final TextEditingController _longTermGoalsController =
      TextEditingController();

  List<String> _jobTitles = [];
  List<String> _industries = [];
  List<String> _longTermGoals = [];
  String? _desiredJobType;
  String? _jobTitlesError;
  String? _industriesError;
  String? _jobTypeError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<String> _originalJobTitles = [];
  List<String> _originalIndustries = [];
  List<String> _originalLongTermGoals = [];
  String? _originalJobType;

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
      // Parse job titles from comma-separated string
      if (user.desiredJobTitles != null && user.desiredJobTitles!.isNotEmpty) {
        _jobTitles = user.desiredJobTitles!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _originalJobTitles = List.from(_jobTitles);
      }

      // Parse industries from comma-separated string
      if (user.industryPreferences != null &&
          user.industryPreferences!.isNotEmpty) {
        _industries = user.industryPreferences!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _originalIndustries = List.from(_industries);
      }

      // Parse long-term goals - assuming it's stored as comma-separated
      if (user.longTermCareerGoals != null &&
          user.longTermCareerGoals!.isNotEmpty) {
        _longTermGoals = user.longTermCareerGoals!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _originalLongTermGoals = List.from(_longTermGoals);
      }

      // Set job type - defaulting to "Full Time" if not set
      // You might need to adjust this based on how job type is stored
      _desiredJobType = 'Full Time'; // Default value as shown in design
      _originalJobType = _desiredJobType;

      setState(() {});
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

  bool _hasChanges() {
    // Check if any field has changed
    final jobTitlesChanged = !_listEquals(_jobTitles, _originalJobTitles);
    final industriesChanged = !_listEquals(_industries, _originalIndustries);
    final longTermGoalsChanged = !_listEquals(
      _longTermGoals,
      _originalLongTermGoals,
    );
    final jobTypeChanged = _desiredJobType != _originalJobType;

    return jobTitlesChanged ||
        industriesChanged ||
        longTermGoalsChanged ||
        jobTypeChanged;
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
      _industriesError = null;
      _jobTypeError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;

      if (_jobTitles.isEmpty) {
        _jobTitlesError = 'Please add at least one job title';
        hasCustomErrors = true;
      }

      if (_industries.isEmpty) {
        _industriesError = 'Please add at least one industry';
        hasCustomErrors = true;
      }

      if (_desiredJobType == null) {
        _jobTypeError = 'Please select a job type';
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

      // Convert lists to comma-separated strings for API
      final newJobTitles = _jobTitles.join(', ');
      final newIndustries = _industries.join(', ');
      final newLongTermGoals = _longTermGoals.join(', ');

      // Only add fields that have changed
      if (!_listEquals(_jobTitles, _originalJobTitles)) {
        updateData['desired_job_titles'] = newJobTitles;
      }

      if (!_listEquals(_industries, _originalIndustries)) {
        updateData['industry_preferences'] = newIndustries;
      }

      if (!_listEquals(_longTermGoals, _originalLongTermGoals)) {
        updateData['long_term_career_goals'] = newLongTermGoals;
      }

      // Add job type if changed (you might need to adjust the field name)
      if (_desiredJobType != _originalJobType) {
        // This field might need to be mapped to the correct API field
        // updateData['job_type'] = _desiredJobType;
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
              'Career Goal & Preference',
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
                              // Desired Job Titles
                              TagField(
                                label: 'Desired Job Titles',
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
                                onClearError: () => _clearTagError(_jobTitles),
                              ),
                              const SizedBox(height: 24),

                              // Preferred Industries
                              TagField(
                                label: 'Preferred Industries',
                                isRequired: false,
                                tags: _industries,
                                controller: _industriesController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _industries,
                                  _industriesController,
                                ),
                                onRemove: (tag) => _removeTag(tag, _industries),
                                errorText: _industriesError,
                                onClearError: () => _clearTagError(_industries),
                              ),
                              const SizedBox(height: 24),

                              // Desired Job Type
                              CustomStringDropdown(
                                labelText: 'Desired Job Type',
                                isRequired: false,
                                value: _desiredJobType,
                                items: const [
                                  'Full Time',
                                  'Part Time',
                                  'Contract',
                                  'Freelance',
                                  'Internship',
                                ],
                                hintText: 'Select job type',
                                errorText: _jobTypeError,
                                onChanged: (value) {
                                  setState(() {
                                    _desiredJobType = value;
                                    _jobTypeError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Long-term Goals
                              TagField(
                                label: 'Long-term Goals',
                                isRequired: false,
                                tags: _longTermGoals,
                                controller: _longTermGoalsController,
                                onAdd: (tag) => _addTag(
                                  tag,
                                  _longTermGoals,
                                  _longTermGoalsController,
                                ),
                                onRemove: (tag) =>
                                    _removeTag(tag, _longTermGoals),
                                errorText: null,
                                onClearError: () {},
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
