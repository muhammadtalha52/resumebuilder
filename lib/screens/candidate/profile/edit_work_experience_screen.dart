import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/date_helpers.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';

class EditWorkExperienceScreen extends ConsumerStatefulWidget {
  const EditWorkExperienceScreen({super.key});

  @override
  ConsumerState<EditWorkExperienceScreen> createState() =>
      _EditWorkExperienceScreenState();
}

class _EditWorkExperienceScreenState
    extends ConsumerState<EditWorkExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  List<WorkExperienceEntry> _workExperiences = [WorkExperienceEntry()];

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  List<WorkExperienceEntry> _originalWorkExperiences = [];

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

    if (user != null && user.workExperience != null) {
      // Load work experience from the new array structure
      _workExperiences.clear();

      for (final userWorkExp in user.workExperience!) {
        final workExp = WorkExperienceEntry();

        // Set job title
        if (userWorkExp.jobTitle != null) {
          workExp.jobTitle.text = userWorkExp.jobTitle!;
        }

        // Set company
        if (userWorkExp.companyName != null) {
          workExp.company.text = userWorkExp.companyName!;
        }

        // Set responsibilities
        if (userWorkExp.keyResponsibilities != null &&
            userWorkExp.keyResponsibilities!.isNotEmpty) {
          // Join responsibilities with line breaks for display in text field
          workExp.responsibilities.text = userWorkExp.keyResponsibilities!.join(
            '\n',
          );
        }

        // Set dates using DateHelpers for better format handling
        if (userWorkExp.workStartDate != null &&
            userWorkExp.workStartDate!.isNotEmpty) {
          workExp.startDate = DateHelpers.parseApiDate(
            userWorkExp.workStartDate,
          );
          debugPrint(
            '📅 Start date: ${userWorkExp.workStartDate} -> ${workExp.startDate}',
          );
        }

        if (userWorkExp.workEndDate != null &&
            userWorkExp.workEndDate!.isNotEmpty) {
          workExp.endDate = DateHelpers.parseApiDate(userWorkExp.workEndDate);
          workExp.currentJob = false;
          debugPrint(
            '📅 End date: ${userWorkExp.workEndDate} -> ${workExp.endDate}',
          );
        } else if (userWorkExp.isCurrentJob == true) {
          workExp.currentJob = true;
          workExp.endDate = null;
        }

        _workExperiences.add(workExp);
      }

      // If no work experience exists, add an empty entry
      if (_workExperiences.isEmpty) {
        _workExperiences.add(WorkExperienceEntry());
      }

      // Create deep copy for original values comparison
      _originalWorkExperiences = _workExperiences
          .map((exp) => WorkExperienceEntry.fromMap(exp.toMap()))
          .toList();

      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var exp in _workExperiences) {
      exp.dispose();
    }
    super.dispose();
  }

  void _addMoreExperience() {
    setState(() {
      _workExperiences.add(WorkExperienceEntry());
    });
  }

  void _removeExperience(int index) {
    if (_workExperiences.length > 1) {
      setState(() {
        _workExperiences[index].dispose();
        _workExperiences.removeAt(index);
      });
    }
  }

  bool _hasChanges() {
    // Check if number of experiences changed
    if (_workExperiences.length != _originalWorkExperiences.length) {
      return true;
    }

    // Check if any experience data has changed
    for (int i = 0; i < _workExperiences.length; i++) {
      final current = _workExperiences[i];
      final original = _originalWorkExperiences[i];

      if (current.jobTitle.text != original.jobTitle.text ||
          current.company.text != original.company.text ||
          current.responsibilities.text != original.responsibilities.text ||
          current.currentJob != original.currentJob) {
        return true;
      }

      // Check dates if they exist
      if (current.startDate != original.startDate ||
          current.endDate != original.endDate) {
        return true;
      }
    }

    return false;
  }

  void _handleSave() async {
    bool isValid = _formKey.currentState!.validate();
    bool hasDateErrors = false;

    // Validate dates
    for (int i = 0; i < _workExperiences.length; i++) {
      final exp = _workExperiences[i];
      setState(() {
        exp.startDateError = null;
        exp.endDateError = null;
        _autovalidateMode = AutovalidateMode.onUserInteraction;

        if (exp.startDate == null) {
          exp.startDateError = 'Please select start date';
          hasDateErrors = true;
        }

        if (!exp.currentJob && exp.endDate == null) {
          exp.endDateError = 'Please select end date';
          hasDateErrors = true;
        }
      });
    }

    if (isValid && !hasDateErrors) {
      // Check if there are any changes
      if (!_hasChanges()) {
        showErrorSnackBar(context: context, message: 'No changes to save');
        return;
      }

      // Prepare the update data
      final updateData = <String, dynamic>{};

      // Convert work experiences to the new array format
      final workExperienceArray = _workExperiences.map((exp) {
        // Parse responsibilities from text field (split by newlines)
        List<String> responsibilitiesList = [];
        if (exp.responsibilities.text.trim().isNotEmpty) {
          responsibilitiesList = exp.responsibilities.text
              .split('\n')
              .map((r) => r.trim())
              .where((r) => r.isNotEmpty)
              .toList();
        }

        return {
          'job_title': exp.jobTitle.text.trim(),
          'company_name': exp.company.text.trim(),
          'work_start_date': exp.startDate != null
              ? DateHelpers.formatToApiDate(exp.startDate)
              : null,
          'work_end_date': exp.currentJob || exp.endDate == null
              ? null
              : DateHelpers.formatToApiDate(exp.endDate),
          'key_responsibilities': responsibilitiesList,
          'is_current_job': exp.currentJob,
        };
      }).toList();

      // Send the work experience array
      updateData['work_experience'] = workExperienceArray;

      // Use profile provider to update
      final profileNotifier = ref.read(profileProvider.notifier);
      final success = await profileNotifier.updateProfileFields(updateData);

      if (success && mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Work experience updated successfully!',
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(profileProvider).error;
        showErrorSnackBar(
          context: context,
          message:
              error ?? 'Failed to update work experience. Please try again.',
        );
      }
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
              'Work Experience',
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
                              // Work experiences
                              ...List.generate(_workExperiences.length, (
                                index,
                              ) {
                                return Column(
                                  children: [
                                    _buildWorkExperienceForm(index),
                                    if (index < _workExperiences.length - 1)
                                      const SizedBox(height: 24),
                                  ],
                                );
                              }),

                              const SizedBox(height: 24),

                              // Add more experience button
                              _buildAddMoreButton(),

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

  Widget _buildWorkExperienceForm(int index) {
    final experience = _workExperiences[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with remove button (if more than one experience)
        if (_workExperiences.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Experience ${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => _removeExperience(index),
                icon: const Icon(Icons.close, color: AppColors.error),
              ),
            ],
          ),

        // Job title
        CustomTextField(
          controller: experience.jobTitle,
          labelText: 'Job title',
          hintText: 'Type here',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter Job title';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Company
        CustomTextField(
          controller: experience.company,
          labelText: 'Company',
          hintText: 'Type here',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter Company';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Start Date
        _buildDatePicker(
          label: 'Start Date',
          isRequired: true,
          selectedDate: experience.startDate,
          errorText: experience.startDateError,
          onDateSelected: (date) {
            setState(() {
              experience.startDate = date;
              experience.startDateError = null;
            });
          },
        ),
        const SizedBox(height: 20),

        // End Date
        _buildDatePicker(
          label: 'End Date',
          isRequired: !experience.currentJob,
          selectedDate: experience.endDate,
          errorText: experience.endDateError,
          onDateSelected: (date) {
            setState(() {
              experience.endDate = date;
              experience.endDateError = null;
            });
          },
          isDisabled: experience.currentJob,
        ),
        const SizedBox(height: 16),

        // I still work here checkbox
        _buildCheckbox(
          value: experience.currentJob,
          onChanged: (value) {
            setState(() {
              experience.currentJob = value ?? false;
              if (experience.currentJob) {
                experience.endDate = null;
                experience.endDateError = null;
              }
            });
          },
        ),
        const SizedBox(height: 20),

        // Key Responsibilities
        CustomTextField(
          controller: experience.responsibilities,
          labelText: 'Key Responsibilities (Optional)',
          hintText: 'Enter a description...',
          maxLines: 7,
          maxLength: 1000,
          showCharacterCount: true,
        ),
      ],
    );
  }

  /// Shows a month/year picker using CupertinoDatePicker
  Future<DateTime?> _showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime selectedDate = initialDate;

    return await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(selectedDate),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePicker({
    required String label,
    required bool isRequired,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    String? errorText,
    bool isDisabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            if (isRequired && !isDisabled)
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isDisabled
              ? null
              : () async {
                  final DateTime? picked = await _showMonthYearPicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDisabled
                    ? AppColors.grey.withValues(alpha: 0.3)
                    : errorText != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isDisabled ? AppColors.grey.withValues(alpha: 0.1) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null && !isDisabled
                        ? '${_getMonthName(selectedDate.month)} ${selectedDate.year}'
                        : 'MM/YYYY',
                    style: TextStyle(
                      color: isDisabled
                          ? AppColors.grey.withValues(alpha: 0.5)
                          : selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: isDisabled
                      ? AppColors.grey.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null && !isDisabled) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            checkColor: AppColors.white,
            side: BorderSide(
              color: value
                  ? AppColors.primary
                  : AppColors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'I still work here',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _addMoreExperience,
        icon: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textPrimary),
          ),
          child: const Icon(Icons.add, color: AppColors.textPrimary),
        ),
        label: const Text(
          'Add more work experience',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.inputBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class WorkExperienceEntry {
  final TextEditingController jobTitle = TextEditingController();
  final TextEditingController company = TextEditingController();
  final TextEditingController responsibilities = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool currentJob = false;
  String? startDateError;
  String? endDateError;

  WorkExperienceEntry();

  WorkExperienceEntry.fromMap(Map<String, dynamic> map) {
    jobTitle.text = map['jobTitle'] ?? '';
    company.text = map['company'] ?? '';
    responsibilities.text = map['responsibilities'] ?? '';
    startDate = map['startDate'] != null
        ? DateTime.parse(map['startDate'])
        : null;
    endDate = map['endDate'] != null ? DateTime.parse(map['endDate']) : null;
    currentJob = map['currentJob'] ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      'jobTitle': jobTitle.text.trim(),
      'company': company.text.trim(),
      'responsibilities': responsibilities.text.trim(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'currentJob': currentJob,
    };
  }

  void dispose() {
    jobTitle.dispose();
    company.dispose();
    responsibilities.dispose();
  }
}
