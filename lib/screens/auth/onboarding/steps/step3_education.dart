import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../providers/onboarding_provider.dart';
import '../../../../providers/education_data_provider.dart';
import '../../../../widgets/common/custom_picker_field.dart';

class Step3Education extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step3Education({super.key, required this.onNext});

  @override
  ConsumerState<Step3Education> createState() => _Step3EducationState();
}

class _Step3EducationState extends ConsumerState<Step3Education> {
  String? _selectedDegreeType;
  String? _selectedMajor;
  String? _selectedInstitution;
  DateTime? _graduationDate;
  bool _degreeNotCompleted = false;
  String? _selectedCertification;

  // Error state variables
  String? _degreeTypeError;
  String? _majorError;
  String? _institutionError;
  String? _graduationDateError;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final education = ref.read(onboardingProvider).education;
    if (education != null) {
      setState(() {
        _selectedDegreeType = education['degreeType'];
        _selectedMajor = education['major'];
        _selectedInstitution = education['institution'];
        _graduationDate = education['graduationDate'] != null
            ? DateTime.parse(education['graduationDate'])
            : null;
        _degreeNotCompleted = education['degreeNotCompleted'] ?? false;
        _selectedCertification = education['certification'];
      });
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Graduation Date',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: _degreeNotCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            if (!_degreeNotCompleted)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _degreeNotCompleted
              ? null
              : () async {
                  // Ensure initialDate is not in the future
                  final now = DateTime.now();
                  final initialDate =
                      _graduationDate != null && _graduationDate!.isAfter(now)
                      ? now
                      : _graduationDate ?? now;

                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1950),
                    lastDate: now, // Prevent future date selection
                  );
                  if (picked != null) {
                    // Additional validation to ensure no future dates
                    if (picked.isAfter(DateTime.now())) {
                      setState(() {
                        _graduationDateError =
                            'Graduation date cannot be in the future';
                      });
                    } else {
                      setState(() {
                        _graduationDate = picked;
                        _graduationDateError = null;
                      });
                    }
                  }
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: _degreeNotCompleted
                    ? AppColors.grey.withValues(alpha: 0.3)
                    : _graduationDateError != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _degreeNotCompleted
                  ? AppColors.grey.withValues(alpha: 0.1)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _graduationDate != null && !_degreeNotCompleted
                        ? '${_graduationDate!.day.toString().padLeft(2, '0')}/${_graduationDate!.month.toString().padLeft(2, '0')}/${_graduationDate!.year}'
                        : 'DD/MM/YYYY',
                    style: TextStyle(
                      color: _degreeNotCompleted
                          ? AppColors.grey.withValues(alpha: 0.5)
                          : _graduationDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: _degreeNotCompleted
                      ? AppColors.grey.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Error message
        if (_graduationDateError != null && !_degreeNotCompleted) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              _graduationDateError!,
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

  Widget _buildCheckbox() {
    return Row(
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: _degreeNotCompleted,
            onChanged: (value) {
              setState(() {
                _degreeNotCompleted = value ?? false;
                if (_degreeNotCompleted) {
                  _graduationDate = null;
                  _graduationDateError = null;
                }
              });
            },
            activeColor: AppColors.primary,
            checkColor: AppColors.white,
            side: BorderSide(
              color: _degreeNotCompleted
                  ? AppColors.primary
                  : AppColors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
        ),
        SizedBox(width: 5),
        const Text(
          'Degree not completed',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  void _handleSubmit() {
    bool hasErrors = false;

    // Validate all fields and set error states
    setState(() {
      _degreeTypeError = null;
      _majorError = null;
      _institutionError = null;
      _graduationDateError = null;

      if (_selectedDegreeType == null) {
        _degreeTypeError = 'Please select degree type';
        hasErrors = true;
      }

      if (_selectedMajor == null) {
        _majorError = 'Please select major';
        hasErrors = true;
      }

      if (_selectedInstitution == null) {
        _institutionError = 'Please select institution';
        hasErrors = true;
      }

      if (!_degreeNotCompleted && _graduationDate == null) {
        _graduationDateError = 'Please select graduation date';
        hasErrors = true;
      } else if (!_degreeNotCompleted &&
          _graduationDate != null &&
          _graduationDate!.isAfter(DateTime.now())) {
        _graduationDateError = 'Graduation date cannot be in the future';
        hasErrors = true;
      }
    });

    if (!hasErrors) {
      // Get IDs for selected items
      final degreeTypeId = ref.read(
        getDegreeTypeIdProvider(_selectedDegreeType),
      );
      final majorId = ref.read(getMajorIdProvider(_selectedMajor));
      final institutionId = ref.read(
        getInstitutionIdProvider(_selectedInstitution),
      );
      final certificationId = ref.read(
        getCertificationIdProvider(_selectedCertification),
      );

      // Save data with both names and IDs
      ref
          .read(onboardingProvider.notifier)
          .updateEducation(
            degreeType: _selectedDegreeType,
            degreeTypeId: degreeTypeId,
            major: _selectedMajor,
            majorId: majorId,
            institution: _selectedInstitution,
            institutionId: institutionId,
            graduationDate: _graduationDate,
            degreeNotCompleted: _degreeNotCompleted,
            certification: _selectedCertification,
            certificationId: certificationId,
          );

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers (already cached from GetStartedScreen)
    final degreeTypes = ref.watch(degreeTypesProvider);
    final majors = ref.watch(majorsProvider);
    final institutions = ref.watch(institutionsProvider);
    final certifications = ref.watch(certificationsProvider);
    final educationDataAsync = ref.watch(educationDataProvider);

    // Show loading indicator if data is still being fetched
    if (educationDataAsync.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading education options...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPickerField(
          labelText: 'Degree Type',
          isRequired: true,
          value: _selectedDegreeType,
          items: degreeTypes,
          hintText: 'Select degree type',
          errorText: _degreeTypeError,
          pickerTitle: 'Select Degree Type',
          searchHint: 'Search degree types...',
          onChanged: (value) {
            setState(() {
              _selectedDegreeType = value;
              _degreeTypeError = null;
            });
          },
        ),
        const SizedBox(height: 20),
        CustomPickerField(
          labelText: 'Major',
          isRequired: true,
          value: _selectedMajor,
          items: majors,
          hintText: 'Select major',
          errorText: _majorError,
          pickerTitle: 'Select Major',
          searchHint: 'Search majors...',
          onChanged: (value) {
            setState(() {
              _selectedMajor = value;
              _majorError = null;
            });
          },
        ),
        const SizedBox(height: 20),
        CustomPickerField(
          labelText: 'Institution',
          isRequired: true,
          value: _selectedInstitution,
          items: institutions,
          hintText: 'Select institution',
          errorText: _institutionError,
          pickerTitle: 'Select Institution',
          searchHint: 'Search institutions...',
          onChanged: (value) {
            setState(() {
              _selectedInstitution = value;
              _institutionError = null;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildCheckbox(),
        const SizedBox(height: 20),
        CustomPickerField(
          labelText: 'Certification',
          isRequired: false,
          value: _selectedCertification,
          items: certifications,
          hintText: 'Select certification (optional)',
          pickerTitle: 'Select Certification',
          searchHint: 'Search certifications...',
          onChanged: (value) {
            setState(() {
              _selectedCertification = value;
            });
          },
        ),
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
    );
  }
}
