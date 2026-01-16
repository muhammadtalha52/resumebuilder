import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/location_service.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_picker_field.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/tag_field.dart';

class EditCareerGoalsScreen extends ConsumerStatefulWidget {
  const EditCareerGoalsScreen({super.key});

  @override
  ConsumerState<EditCareerGoalsScreen> createState() =>
      _EditCareerGoalsScreenState();
}

class _EditCareerGoalsScreenState extends ConsumerState<EditCareerGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _industriesController = TextEditingController();
  final TextEditingController _hometownController = TextEditingController();
  final TextEditingController _longTermGoalsController =
      TextEditingController();

  // Store objects to preserve IDs and metadata
  List<DesiredJobTitle> _jobTitleObjects = [];
  List<IndustryPreference> _industryObjects = [];
  List<CareerGoal> _longTermGoalObjects = [];
  List<String> _locationPreferences = [];
  List<int> _selectedPlacementTypes = [];

  String? _jobTitlesError;
  String? _industriesError;
  String? _locationError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isDetectingLocation = false;
  final LocationService _locationService = LocationService();

  // Store original values for comparison
  List<DesiredJobTitle> _originalJobTitleObjects = [];
  List<IndustryPreference> _originalIndustryObjects = [];
  List<CareerGoal> _originalLongTermGoalObjects = [];
  List<String> _originalLocationPreferences = [];
  String _originalHometown = '';
  List<int> _originalPlacementTypes = [];

  // Hardcoded placement type options with IDs
  static const List<Map<String, dynamic>> _placementTypeOptions = [
    {'id': 1, 'name': 'full_time', 'displayName': 'Full-time'},
    {'id': 2, 'name': 'part_time', 'displayName': 'Part-time'},
    {'id': 3, 'name': 'seasonal', 'displayName': 'Seasonal'},
  ];

  // Get display names for multi-select
  List<String> get _placementTypeDisplayNames =>
      _placementTypeOptions.map((e) => e['displayName'] as String).toList();

  // Convert IDs to display names for UI
  List<String> _getSelectedPlacementTypeNames() {
    return _selectedPlacementTypes
        .map((id) {
          final option = _placementTypeOptions.firstWhere(
            (e) => e['id'] == id,
            orElse: () => {'displayName': ''},
          );
          return option['displayName'] as String;
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Convert display names to IDs for API
  List<int> _displayNamesToIds(List<String> displayNames) {
    return displayNames
        .map((name) {
          final option = _placementTypeOptions.firstWhere(
            (e) => e['displayName'] == name,
            orElse: () => {'id': 0},
          );
          return option['id'] as int;
        })
        .where((id) => id != 0)
        .toList();
  }

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

      // Load hometown
      _hometownController.text = user.homeTown ?? '';
      _originalHometown = user.homeTown ?? '';

      // Load placement types (list of IDs from PlacementType objects)
      if (user.placementTypes != null && user.placementTypes!.isNotEmpty) {
        _selectedPlacementTypes = user.placementTypes!
            .map((e) => e.id ?? 0)
            .where((id) => id != 0)
            .toList();
        _originalPlacementTypes = List.from(_selectedPlacementTypes);
      }

      setState(() {});
    }
  }

  // Helper methods to convert between objects and strings for display
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
    _industriesController.dispose();
    _hometownController.dispose();
    _longTermGoalsController.dispose();
    super.dispose();
  }

  // Remove job title object
  void _removeJobTitle(String tag) {
    setState(() {
      _jobTitleObjects.removeWhere((obj) => obj.title == tag);
    });
  }

  // Update years of experience for a specific job title
  void _updateJobTitleYears(int index, double years) {
    if (index < 0 || index >= _jobTitleObjects.length) return;
    setState(() {
      final oldObj = _jobTitleObjects[index];
      _jobTitleObjects[index] = oldObj.copyWith(yearsOfExperience: years);
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
    // Compare job title objects (title + years of experience)
    final jobTitlesChanged = !_jobTitleObjectsEqual(
      _jobTitleObjects,
      _originalJobTitleObjects,
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
    final hometownChanged =
        _hometownController.text.trim() != _originalHometown;

    // Check placement types change (compare int lists)
    final placementTypesChanged = !_listEqualsInt(
      _selectedPlacementTypes,
      _originalPlacementTypes,
    );

    return jobTitlesChanged ||
        industriesChanged ||
        longTermGoalsChanged ||
        locationChanged ||
        hometownChanged ||
        placementTypesChanged;
  }

  // Compare job title objects including years of experience
  bool _jobTitleObjectsEqual(
    List<DesiredJobTitle> list1,
    List<DesiredJobTitle> list2,
  ) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].title != list2[i].title ||
          list1[i].yearsOfExperience != list2[i].yearsOfExperience) {
        return false;
      }
    }
    return true;
  }

  bool _listEqualsInt(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    final sorted1 = List<int>.from(list1)..sort();
    final sorted2 = List<int>.from(list2)..sort();
    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i] != sorted2[i]) return false;
    }
    return true;
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentCityAndState();

      if (location != null && mounted) {
        setState(() {
          _hometownController.text = location;
        });
        if (mounted) {
          showSuccessSnackBar(
            context: context,
            message: 'Location detected successfully!',
          );
        }
      } else if (mounted) {
        showErrorSnackBar(
          context: context,
          message:
              'Could not detect location. Please enable GPS and grant permission.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'Failed to detect location. Please enter manually.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  // Build job titles section with years of experience per title
  Widget _buildJobTitlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Desired Job Titles',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Add Job Title button
        GestureDetector(
          onTap: _showAddJobTitleDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _jobTitlesError != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Add Job Title',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error message
        if (_jobTitlesError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              _jobTitlesError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],

        // Job titles as card list
        if (_jobTitleObjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _jobTitleObjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildJobTitleCard(index, _jobTitleObjects[index]);
            },
          ),
        ],
      ],
    );
  }

  // Show dialog to add a new job title
  void _showAddJobTitleDialog() {
    final titleController = TextEditingController();
    int selectedYears = 0;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Center(
                      child: Text(
                        'Add Job Title',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job Title field
                    const Text(
                      'Job Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: titleController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Software Engineer',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? AppColors.error
                                : AppColors.inputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? AppColors.error
                                : AppColors.inputBorderFocused,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        if (errorText != null && value.isNotEmpty) {
                          setDialogState(() => errorText = null);
                        }
                      },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Years of Experience dropdown
                    const Text(
                      'Years of Experience',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedYears,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textHint,
                          ),
                          items: List.generate(31, (i) => i)
                              .map(
                                (y) => DropdownMenuItem<int>(
                                  value: y,
                                  child: Text('$y years'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedYears = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final title = titleController.text.trim();
                              if (title.isEmpty) {
                                setDialogState(() {
                                  errorText = 'Please enter a job title';
                                });
                                return;
                              }
                              if (_jobTitleObjects.any(
                                (obj) => obj.title == title,
                              )) {
                                setDialogState(() {
                                  errorText = 'This job title already exists';
                                });
                                return;
                              }
                              // Add the job title
                              setState(() {
                                _jobTitleObjects.add(
                                  DesiredJobTitle(
                                    title: title,
                                    yearsOfExperience: selectedYears.toDouble(),
                                  ),
                                );
                                _jobTitlesError = null;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build job title card with two lines
  Widget _buildJobTitleCard(int index, DesiredJobTitle jobTitle) {
    final years = jobTitle.yearsOfExperience ?? 0.0;
    final yearsInt = years.toInt();
    final yearsText = years == yearsInt.toDouble()
        ? '$yearsInt ${yearsInt == 1 ? 'year' : 'years'} of experience'
        : '${years.toStringAsFixed(1)} years of experience';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Job title + X button
          Row(
            children: [
              Expanded(
                child: Text(
                  jobTitle.title ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeJobTitle(jobTitle.title ?? ''),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Years of experience (clickable dropdown)
          PopupMenuButton<double>(
            onSelected: (value) => _updateJobTitleYears(index, value),
            offset: const Offset(0, 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            itemBuilder: (context) => List.generate(
              31,
              (i) => PopupMenuItem<double>(
                value: i.toDouble(),
                height: 40,
                child: Text(
                  '$i ${i == 1 ? 'year' : 'years'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: i.toDouble() == years
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: i.toDouble() == years
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  yearsText,
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    // Clear any previous errors
    setState(() {
      _jobTitlesError = null;
      _industriesError = null;
      _locationError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    {
      // Check if there are any changes
      if (!_hasChanges()) {
        showErrorSnackBar(context: context, message: 'No changes to save');
        return;
      }

      // Prepare the update data
      final updateData = <String, dynamic>{};

      // Check if job titles changed (including years of experience)
      final jobTitlesChanged = !_jobTitleObjectsEqual(
        _jobTitleObjects,
        _originalJobTitleObjects,
      );
      final industriesChanged = !_listEquals(
        _industryStrings(),
        _originalIndustryObjects.map((e) => e.industry ?? '').toList(),
      );
      final longTermGoalsChanged = !_listEquals(
        _longTermGoalStrings(),
        _originalLongTermGoalObjects.map((e) => e.goal ?? '').toList(),
      );

      // Send job titles as objects with title and years_of_experience
      if (jobTitlesChanged) {
        updateData['desired_job_titles'] = _jobTitleObjects
            .map(
              (e) => {
                'title': e.title,
                'years_of_experience': e.yearsOfExperience ?? 0,
              },
            )
            .toList();
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

      // Add hometown if changed
      if (_hometownController.text.trim() != _originalHometown) {
        updateData['home_town'] = _hometownController.text.trim();
      }

      // Add placement types if changed (send list of IDs)
      if (!_listEqualsInt(_selectedPlacementTypes, _originalPlacementTypes)) {
        updateData['placement_types'] = _selectedPlacementTypes;
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
                              // Desired Job Titles with Years of Experience
                              _buildJobTitlesSection(),
                              const SizedBox(height: 24),

                              // Placement Type (Multi-select)
                              CustomPickerField(
                                labelText: 'Placement Type',
                                isRequired: false,
                                selectedValues:
                                    _getSelectedPlacementTypeNames(),
                                items: _placementTypeDisplayNames,
                                hintText: 'Select placement types',
                                enableSearch: false,
                                pickerTitle: 'Select Placement Types',
                                isMultiSelect: true,
                                onMultiChanged: (values) {
                                  setState(() {
                                    _selectedPlacementTypes =
                                        _displayNamesToIds(values);
                                  });
                                },
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

                              // Current Hometown & State
                              CustomTextField(
                                controller: _hometownController,
                                labelText: 'Current Hometown & State',
                                hintText: 'e.g., Austin, Texas',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                isRequired: false,
                                suffixIcon: _isDetectingLocation
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.primary,
                                                ),
                                          ),
                                        ),
                                      )
                                    : InkWell(
                                        onTap: _detectLocation,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.my_location,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Locate',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
