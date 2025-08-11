import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_text_field.dart';

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

    if (user != null) {
      // Parse work experience data from comma-separated strings
      final jobTitles = _parseCommaSeparatedStringToList(user.jobTitles);
      final companyNames = _parseCommaSeparatedStringToList(user.companyNames);
      final workDuration = _parseCommaSeparatedStringToList(user.workDuration);
      final keyResponsibilities = _parseCommaSeparatedStringToList(
        user.keyResponsibilities,
      );

      // Create work experience entries
      final maxLength = [
        jobTitles.length,
        companyNames.length,
        workDuration.length,
        keyResponsibilities.length,
      ].reduce((a, b) => a > b ? a : b);

      if (maxLength > 0) {
        _workExperiences.clear();
        for (int i = 0; i < maxLength; i++) {
          final workExp = WorkExperienceEntry();

          // Set job title
          if (i < jobTitles.length) {
            workExp.jobTitle.text = jobTitles[i];
          }

          // Set company
          if (i < companyNames.length) {
            workExp.company.text = companyNames[i];
          }

          // Set responsibilities
          if (i < keyResponsibilities.length) {
            workExp.responsibilities.text = keyResponsibilities[i];
          }

          // Parse work duration to dates (assuming format like "Jan 2020 - Dec 2022" or "Jan 2020 - Present")
          if (i < workDuration.length) {
            _parseDurationString(workDuration[i], workExp);
          }

          _workExperiences.add(workExp);
        }
      }

      // Create deep copy for original values comparison
      _originalWorkExperiences = _workExperiences
          .map((exp) => WorkExperienceEntry.fromMap(exp.toMap()))
          .toList();

      setState(() {});
    }
  }

  List<String> _parseCommaSeparatedStringToList(String? input) {
    if (input == null || input.trim().isEmpty) {
      return [];
    }

    return input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _parseDurationString(String duration, WorkExperienceEntry workExp) {
    // This is a basic parser for duration strings like "Jan 2020 - Dec 2022" or "Jan 2020 - Present"
    // You might need to adjust this based on how dates are stored in your system
    try {
      final parts = duration.split(' - ');
      if (parts.length == 2) {
        final startPart = parts[0].trim();
        final endPart = parts[1].trim();

        // For now, we'll just store the original string as we don't have a reliable date parser
        // In a real app, you'd want to implement proper date parsing or store dates as ISO strings

        if (endPart.toLowerCase().contains('present') ||
            endPart.toLowerCase().contains('current')) {
          workExp.currentJob = true;
        }
      }
    } catch (e) {
      // If parsing fails, just continue without dates
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

      // Convert work experiences to comma-separated strings
      final jobTitles = _workExperiences
          .map((exp) => exp.jobTitle.text.trim())
          .toList();
      final companyNames = _workExperiences
          .map((exp) => exp.company.text.trim())
          .toList();
      final keyResponsibilities = _workExperiences
          .map((exp) => exp.responsibilities.text.trim())
          .toList();

      // Create duration strings
      final workDurations = _workExperiences.map((exp) {
        if (exp.startDate == null) return '';

        String startStr =
            '${_monthName(exp.startDate!.month)} ${exp.startDate!.year}';
        String endStr = exp.currentJob
            ? 'Present'
            : exp.endDate != null
            ? '${_monthName(exp.endDate!.month)} ${exp.endDate!.year}'
            : 'Present';

        return '$startStr - $endStr';
      }).toList();

      // Only add fields that have changed
      updateData['job_titles'] = jobTitles.join(', ');
      updateData['company_names'] = companyNames.join(', ');
      updateData['work_duration'] = workDurations.join(', ');
      updateData['key_responsibilities'] = keyResponsibilities.join(', ');

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
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                        : 'DD/MM/YYYY',
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
