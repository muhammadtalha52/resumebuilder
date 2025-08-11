import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/education_data_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_picker_field.dart';

class EditEducationScreen extends ConsumerStatefulWidget {
  const EditEducationScreen({super.key});

  @override
  ConsumerState<EditEducationScreen> createState() =>
      _EditEducationScreenState();
}

class _EditEducationScreenState extends ConsumerState<EditEducationScreen> {
  final _formKey = GlobalKey<FormState>();

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

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Store original values for comparison
  String? _originalDegreeType;
  String? _originalMajor;
  String? _originalInstitution;
  DateTime? _originalGraduationDate;
  bool _originalDegreeNotCompleted = false;
  String? _originalCertification;

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
      // Get degree type name from ID
      final degreeTypeName = ref.read(
        getDegreeTypeNameProvider(user.degreeType),
      );

      // Get major name from ID
      final majorName = ref.read(getMajorNameProvider(user.major));

      // Get institution name from ID
      final institutionName = ref.read(
        getInstitutionNameProvider(user.institution),
      );

      // Get certification name from ID
      final certificationName = ref.read(
        getCertificationNameProvider(user.certificationsTraining),
      );

      setState(() {
        _selectedDegreeType = degreeTypeName;
        _originalDegreeType = degreeTypeName;

        _selectedMajor = majorName;
        _originalMajor = majorName;

        _selectedInstitution = institutionName;
        _originalInstitution = institutionName;

        _selectedCertification = certificationName;
        _originalCertification = certificationName;

        if (user.graduationDate != null && user.graduationDate!.isNotEmpty) {
          try {
            _graduationDate = DateTime.parse(user.graduationDate!);
            _originalGraduationDate = _graduationDate;
          } catch (e) {
            // Handle parse error
            _graduationDate = null;
            _originalGraduationDate = null;
          }
        }

        // Check if degree is not completed (can be inferred if graduation date is null)
        _degreeNotCompleted = _graduationDate == null;
        _originalDegreeNotCompleted = _degreeNotCompleted;
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

  bool _hasChanges() {
    // Check if any field has changed
    final degreeTypeChanged = _selectedDegreeType != _originalDegreeType;
    final majorChanged = _selectedMajor != _originalMajor;
    final institutionChanged = _selectedInstitution != _originalInstitution;
    final graduationDateChanged = _graduationDate != _originalGraduationDate;
    final degreeNotCompletedChanged =
        _degreeNotCompleted != _originalDegreeNotCompleted;
    final certificationChanged =
        _selectedCertification != _originalCertification;

    return degreeTypeChanged ||
        majorChanged ||
        institutionChanged ||
        graduationDateChanged ||
        degreeNotCompletedChanged ||
        certificationChanged;
  }

  void _handleSave() async {
    bool hasErrors = false;

    // Validate all fields and set error states
    setState(() {
      _degreeTypeError = null;
      _majorError = null;
      _institutionError = null;
      _graduationDateError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;

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
      // Check if there are any changes
      if (!_hasChanges()) {
        showErrorSnackBar(context: context, message: 'No changes to save');
        return;
      }

      // Prepare the update data
      final updateData = <String, dynamic>{};

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

      // Only add fields that have changed
      if (_selectedDegreeType != _originalDegreeType) {
        updateData['degree_type'] = degreeTypeId;
      }

      if (_selectedMajor != _originalMajor) {
        updateData['major'] = majorId;
      }

      if (_selectedInstitution != _originalInstitution) {
        updateData['institution'] = institutionId;
      }

      if (_graduationDate != _originalGraduationDate) {
        updateData['graduation_date'] = _graduationDate?.toIso8601String();
      }

      if (_selectedCertification != _originalCertification) {
        updateData['certification'] = certificationId;
      }

      // Use profile provider to update
      final profileNotifier = ref.read(profileProvider.notifier);
      final success = await profileNotifier.updateProfileFields(updateData);

      if (success && mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Education updated successfully!',
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(profileProvider).error;
        showErrorSnackBar(
          context: context,
          message: error ?? 'Failed to update education. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers
    final degreeTypes = ref.watch(degreeTypesProvider);
    final majors = ref.watch(majorsProvider);
    final institutions = ref.watch(institutionsProvider);
    final certifications = ref.watch(certificationsProvider);
    final educationDataAsync = ref.watch(educationDataProvider);

    // Show loading indicator if data is still being fetched
    if (educationDataAsync.isLoading) {
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
                'Education',
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
        body: Center(
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
        ),
      );
    }

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
              'Education',
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
