import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../../constants/app_colors.dart';
import '../../../../providers/onboarding_provider.dart';
import '../../../../widgets/common/custom_text_field.dart';
import '../../../../models/resume_parse_model.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../providers/resume_service_provider.dart';
import '../../../../services/resume_service.dart';

class Step4WorkExperience extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step4WorkExperience({super.key, required this.onNext});

  @override
  ConsumerState<Step4WorkExperience> createState() =>
      _Step4WorkExperienceState();
}

class _Step4WorkExperienceState extends ConsumerState<Step4WorkExperience> {
  final _formKey = GlobalKey<FormState>();
  List<WorkExperienceEntry> _workExperiences = [WorkExperienceEntry()];

  // Resume upload related
  File? _selectedResumeFile;
  String? _selectedFileName;
  bool _isParsingResume = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final workExperience = ref.read(onboardingProvider).workExperience;
    if (workExperience != null && workExperience['experiences'] != null) {
      final experiences = workExperience['experiences'] as List;
      if (experiences.isNotEmpty) {
        setState(() {
          _workExperiences = experiences
              .map((exp) => WorkExperienceEntry.fromMap(exp))
              .toList();
        });
      }
    }
  }

  void _addMoreExperience() {
    if (_isParsingResume) {
      _showParsingBlockedMessage();
      return;
    }
    setState(() {
      _workExperiences.add(WorkExperienceEntry());
    });
  }

  void _removeExperience(int index) {
    if (_isParsingResume) {
      _showParsingBlockedMessage();
      return;
    }
    if (_workExperiences.length > 1) {
      setState(() {
        _workExperiences.removeAt(index);
      });
    }
  }

  void _showParsingBlockedMessage() {
    showInfoSnackBar(
      context: context,
      message: 'Please wait while your resume is being processed...',
    );
  }

  Future<void> _pickAndParseResume() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Validate file first
        try {
          await ResumeService.validateFile(file);
        } on ResumeServiceException catch (e) {
          if (mounted) {
            showErrorSnackBar(context: context, message: e.message);
          }
          return;
        }

        setState(() {
          _selectedResumeFile = file;
          _selectedFileName = result.files.single.name;
          _isParsingResume = true;
        });


        try {
          // Call actual resume parsing API
          final resumeService = ref.read(resumeServiceProvider);
          final parsedData = await resumeService.extractResumeData(file);
          
          // Store parsed data in onboarding provider
          ref.read(onboardingProvider.notifier).storeParsedResumeData(parsedData);
          
          // Populate work experiences from parsed resume
          _populateWorkExperiencesFromResume(parsedData);

          setState(() {
            _isParsingResume = false;
          });

          if (mounted) {
            showSuccessSnackBar(
              context: context,
              message: 'Resume processed! Work experience and other details have been filled for upcoming steps.',
            );
          }
        } on ResumeServiceException catch (e) {
          setState(() {
            _isParsingResume = false;
          });
          
          if (mounted) {
            showErrorSnackBar(context: context, message: e.message);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isParsingResume = false;
      });
      
      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  void _populateWorkExperiencesFromResume(ResumeParse resumeData) {
    if (resumeData.workExperience.isNotEmpty) {
      setState(() {
        // Clear existing experiences if they're empty
        if (_workExperiences.length == 1 && _workExperiences[0].jobTitle.text.isEmpty) {
          _workExperiences.clear();
        }
        
        // Add work experiences from resume
        for (var exp in resumeData.workExperience) {
          final workExp = WorkExperienceEntry();
          workExp.jobTitle.text = exp.role ?? '';
          workExp.company.text = exp.company ?? '';
          workExp.responsibilities.text = exp.description.join('\n• ');
          
          // Parse dates
          if (exp.parsedFromDate != null) {
            workExp.startDate = exp.parsedFromDate;
          }
          if (exp.parsedToDate != null) {
            workExp.endDate = exp.parsedToDate;
          } else if (exp.isCurrent) {
            workExp.currentJob = true;
          }
          
          _workExperiences.add(workExp);
        }
        
        // Ensure we have at least one experience
        if (_workExperiences.isEmpty) {
          _workExperiences.add(WorkExperienceEntry());
        }
      });
    }
  }

  void _handleSubmit() {
    if (_isParsingResume) {
      _showParsingBlockedMessage();
      return;
    }
    
    bool isValid = _formKey.currentState!.validate();
    bool hasDateErrors = false;

    // Validate dates
    for (int i = 0; i < _workExperiences.length; i++) {
      final exp = _workExperiences[i];
      setState(() {
        exp.startDateError = null;
        exp.endDateError = null;

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
      // Save data
      final experiencesData = _workExperiences
          .map((exp) => exp.toMap())
          .toList();
      ref.read(onboardingProvider.notifier).updateWorkExperience({
        'experiences': experiencesData,
      });

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resume upload section
          _buildResumeUploadSection(),
          const SizedBox(height: 24),

          // Work experiences
          ...List.generate(_workExperiences.length, (index) {
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
                  if (_isParsingResume) {
                    _showParsingBlockedMessage();
                    return;
                  }
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

  Widget _buildResumeUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder, width: 1),
      ),
      child: _isParsingResume
          ? const Column(
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
                SizedBox(height: 12),
                Text(
                  'Processing your resume...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : _selectedResumeFile != null
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedFileName ?? 'Resume uploaded',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Work experience extracted successfully',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _pickAndParseResume,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Replace'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedResumeFile = null;
                          _selectedFileName = null;
                        });
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : GestureDetector(
              onTap: _pickAndParseResume,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.upload_file,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload resume to prefill',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'PDF or DOCX • Max 5MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            border: Border.all(color: AppColors.textPrimary)
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
