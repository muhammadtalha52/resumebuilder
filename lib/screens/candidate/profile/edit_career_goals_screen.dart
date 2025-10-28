import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_picker_field.dart';
import '../../../widgets/common/tag_field.dart';

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

  // Store objects to preserve IDs and metadata
  List<DesiredJobTitle> _jobTitleObjects = [];
  List<IndustryPreference> _industryObjects = [];
  List<CareerGoal> _longTermGoalObjects = [];
  List<String> _locationPreferences = [];

  String? _jobTitlesError;
  String? _industriesError;
  String? _locationError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<DesiredJobTitle> _originalJobTitleObjects = [];
  List<IndustryPreference> _originalIndustryObjects = [];
  List<CareerGoal> _originalLongTermGoalObjects = [];
  List<String> _originalLocationPreferences = [];

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
      // Load job title objects - preserving IDs
      if (user.desiredJobTitles != null && user.desiredJobTitles!.isNotEmpty) {
        _jobTitleObjects = List.from(user.desiredJobTitles!);
        _originalJobTitleObjects = List.from(_jobTitleObjects);
      }

      // Load industry objects - preserving IDs
      if (user.industryPreferences != null &&
          user.industryPreferences!.isNotEmpty) {
        _industryObjects = List.from(user.industryPreferences!);
        _originalIndustryObjects = List.from(_industryObjects);
      }

      // Load career goal objects - preserving IDs
      if (user.careerGoals != null && user.careerGoals!.isNotEmpty) {
        _longTermGoalObjects = List.from(user.careerGoals!);
        _originalLongTermGoalObjects = List.from(_longTermGoalObjects);
      }

      // Load location preferences - extract location strings from objects
      if (user.locationPreferences != null &&
          user.locationPreferences!.isNotEmpty) {
        _locationPreferences = user.locationPreferences!
            .map((e) => e.location ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        _originalLocationPreferences = List.from(_locationPreferences);
      }

      setState(() {});
    }
  }

  // Helper methods to convert between objects and strings for display
  List<String> _jobTitleStrings() {
    return _jobTitleObjects
        .map((e) => e.title ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _industryStrings() {
    return _industryObjects
        .map((e) => e.industry ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _longTermGoalStrings() {
    return _longTermGoalObjects
        .map((e) => e.goal ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _jobTitlesController.dispose();
    _industriesController.dispose();
    _longTermGoalsController.dispose();
    super.dispose();
  }

  // Add job title - create new object or preserve existing
  void _addJobTitle(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    // Check if already exists
    if (_jobTitleObjects.any((obj) => obj.title == trimmed)) return;

    setState(() {
      // Add new object without ID (backend will assign)
      _jobTitleObjects.add(DesiredJobTitle(title: trimmed));
      _jobTitlesError = null;
    });
    _jobTitlesController.clear();
  }

  // Remove job title object
  void _removeJobTitle(String tag) {
    setState(() {
      _jobTitleObjects.removeWhere((obj) => obj.title == tag);
    });
  }

  // Add industry - create new object or preserve existing
  void _addIndustry(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    // Check if already exists
    if (_industryObjects.any((obj) => obj.industry == trimmed)) return;

    setState(() {
      // Add new object without ID (backend will assign)
      _industryObjects.add(IndustryPreference(industry: trimmed));
      _industriesError = null;
    });
    _industriesController.clear();
  }

  // Remove industry object
  void _removeIndustry(String tag) {
    setState(() {
      _industryObjects.removeWhere((obj) => obj.industry == tag);
    });
  }

  // Add long-term goal - create new object or preserve existing
  void _addLongTermGoal(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    // Check if already exists
    if (_longTermGoalObjects.any((obj) => obj.goal == trimmed)) return;

    setState(() {
      // Add new object without ID (backend will assign)
      _longTermGoalObjects.add(CareerGoal(goal: trimmed));
    });
    _longTermGoalsController.clear();
  }

  // Remove long-term goal object
  void _removeLongTermGoal(String tag) {
    setState(() {
      _longTermGoalObjects.removeWhere((obj) => obj.goal == tag);
    });
  }

  bool _hasChanges() {
    // Compare object lists by their string values
    final jobTitlesChanged = !_listEquals(
      _jobTitleStrings(),
      _originalJobTitleObjects.map((e) => e.title ?? '').toList(),
    );
    final industriesChanged = !_listEquals(
      _industryStrings(),
      _originalIndustryObjects.map((e) => e.industry ?? '').toList(),
    );
    final longTermGoalsChanged = !_listEquals(
      _longTermGoalStrings(),
      _originalLongTermGoalObjects.map((e) => e.goal ?? '').toList(),
    );
    final locationChanged = !_listEquals(
      _locationPreferences,
      _originalLocationPreferences,
    );

    return jobTitlesChanged ||
        industriesChanged ||
        longTermGoalsChanged ||
        locationChanged;
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
      _locationError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;

      if (_jobTitleObjects.isEmpty) {
        _jobTitlesError = 'Please add at least one job title';
        hasCustomErrors = true;
      }

      if (_industryObjects.isEmpty) {
        _industriesError = 'Please add at least one industry';
        hasCustomErrors = true;
      }

      if (_locationPreferences.isEmpty) {
        _locationError = 'Please select at least one location preference';
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

      // Send string arrays for API (backend expects string arrays, not objects)
      final jobTitlesChanged = !_listEquals(
        _jobTitleStrings(),
        _originalJobTitleObjects.map((e) => e.title ?? '').toList(),
      );
      final industriesChanged = !_listEquals(
        _industryStrings(),
        _originalIndustryObjects.map((e) => e.industry ?? '').toList(),
      );
      final longTermGoalsChanged = !_listEquals(
        _longTermGoalStrings(),
        _originalLongTermGoalObjects.map((e) => e.goal ?? '').toList(),
      );

      if (jobTitlesChanged) {
        updateData['desired_job_titles'] = _jobTitleStrings();
      }

      if (industriesChanged) {
        updateData['industry_preferences'] = _industryStrings();
      }

      if (longTermGoalsChanged) {
        updateData['long_term_career_goals'] = _longTermGoalStrings();
      }

      // Add location preferences if changed
      if (!_listEquals(_locationPreferences, _originalLocationPreferences)) {
        updateData['location_preferences'] = _locationPreferences;
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
      appBar: const BackNavigationAppBar(title: 'Career Goal & Preference'),
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
                                tags: _jobTitleStrings(),
                                controller: _jobTitlesController,
                                onAdd: _addJobTitle,
                                onRemove: _removeJobTitle,
                                errorText: _jobTitlesError,
                                onClearError: () =>
                                    setState(() => _jobTitlesError = null),
                              ),
                              const SizedBox(height: 24),

                              // Preferred Industries
                              TagField(
                                label: 'Preferred Industries',
                                isRequired: false,
                                tags: _industryStrings(),
                                controller: _industriesController,
                                onAdd: _addIndustry,
                                onRemove: _removeIndustry,
                                errorText: _industriesError,
                                onClearError: () =>
                                    setState(() => _industriesError = null),
                              ),
                              const SizedBox(height: 24),

                              // Location Preferences
                              CustomPickerField(
                                labelText: 'Location Preferences',
                                isRequired: false,
                                selectedValues: _locationPreferences,
                                items: const ['On-site', 'Remote', 'Hybrid'],
                                hintText: 'Select Options',
                                errorText: _locationError,
                                enableSearch: false,
                                pickerTitle: 'Select Location Preferences',
                                isMultiSelect: true,
                                onMultiChanged: (values) {
                                  setState(() {
                                    _locationPreferences = values;
                                    _locationError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Long-term Goals
                              TagField(
                                label: 'Long-term Goals',
                                isRequired: false,
                                tags: _longTermGoalStrings(),
                                controller: _longTermGoalsController,
                                onAdd: _addLongTermGoal,
                                onRemove: _removeLongTermGoal,
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
