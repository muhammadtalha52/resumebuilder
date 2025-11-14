import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/education_data_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_picker_field.dart';
import '../../widgets/common/custom_text_field.dart';

class Step3Education extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step3Education({super.key, required this.onNext});

  @override
  ConsumerState<Step3Education> createState() => _Step3EducationState();
}

class _Step3EducationState extends ConsumerState<Step3Education> {
  String? _selectedDegreeType;
  String? _selectedMajor;
  final TextEditingController _institutionController = TextEditingController();
  DateTime? _graduationDate;
  bool _degreeNotCompleted = false;
  List<String> _selectedCertifications = [];

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
        _institutionController.text = education['institution'] ?? '';
        _graduationDate = education['graduationDate'] != null
            ? DateTime.parse(education['graduationDate'])
            : null;
        _degreeNotCompleted = education['degreeNotCompleted'] ?? false;
        _selectedCertifications = List<String>.from(
          education['certifications'] ?? [],
        );
      });
    }
  }

  @override
  void deactivate() {
    // Unfocus any active focus nodes before deactivation
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  Future<DateTime?> _showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime selectedDate = initialDate;
    final scrollController = ScrollController();

    // Calculate initial scroll position to show selected year
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIndex = lastDate.year - selectedDate.year;
      final itemHeight = 56.0; // Approximate height of ListTile
      scrollController.jumpTo(selectedIndex * itemHeight);
    });

    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Graduation Year',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    // Year Selector
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: lastDate.year - firstDate.year + 1,
                        itemBuilder: (context, index) {
                          final year = lastDate.year - index;
                          final isSelected = year == selectedDate.year;
                          return ListTile(
                            title: Text(
                              year.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            tileColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () {
                              setDialogState(() {
                                selectedDate = DateTime(
                                  year,
                                  selectedDate.month,
                                );
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Month Selector
                    const Text(
                      'Select Month',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final isSelected = month == selectedDate.month;
                        final monthNames = [
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
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedDate = DateTime(selectedDate.year, month);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.inputBorder,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              monthNames[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedDate),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatGraduationDate(DateTime date) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Graduation Year',
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
                  // Dismiss keyboard before opening date picker
                  FocusScope.of(context).requestFocus(FocusNode());

                  final initialDate = _graduationDate ?? DateTime.now();

                  final DateTime? picked = await _showMonthYearPicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2040),
                  );

                  if (picked != null) {
                    setState(() {
                      _graduationDate = picked;
                      _graduationDateError = null;
                    });
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
                        ? _formatGraduationDate(_graduationDate!)
                        : 'Select graduation year',
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
              // Dismiss keyboard when checkbox is clicked
              FocusScope.of(context).requestFocus(FocusNode());
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
    // Dismiss keyboard before validation
    FocusScope.of(context).requestFocus(FocusNode());

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

      if (_institutionController.text.trim().isEmpty) {
        _institutionError = 'Please enter institution name';
        hasErrors = true;
      }

      if (!_degreeNotCompleted && _graduationDate == null) {
        _graduationDateError = 'Please select graduation date';
        hasErrors = true;
      }
    });

    if (!hasErrors) {
      // Get IDs for selected items
      final degreeTypeId = ref.read(
        getDegreeTypeIdProvider(_selectedDegreeType),
      );
      final majorId = ref.read(getMajorIdProvider(_selectedMajor));
      final certificationIds = ref.read(
        getCertificationIdsProvider(_selectedCertifications),
      );

      // Save data with both names and IDs
      ref
          .read(onboardingProvider.notifier)
          .updateEducation(
            degreeType: _selectedDegreeType,
            degreeTypeId: degreeTypeId,
            major: _selectedMajor,
            majorId: majorId,
            institution: _institutionController.text.trim(),
            graduationDate: _graduationDate,
            degreeNotCompleted: _degreeNotCompleted,
            certifications: _selectedCertifications,
            certificationIds: certificationIds,
          );

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers (should be cached from Step 1 prefetch)
    final educationDataAsync = ref.watch(educationDataProvider);
    final degreeTypes = ref.watch(degreeTypesProvider);
    final majors = ref.watch(majorsProvider);
    final certifications = ref.watch(certificationsProvider);

    // Show loading if data not ready yet (shouldn't happen if Step 1 prefetch worked)
    if (educationDataAsync.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
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
        CustomTextField(
          controller: _institutionController,
          labelText: 'Institution',
          hintText: 'e.g., Harvard University',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          isRequired: true,
          errorText: _institutionError,
          onChanged: (value) {
            setState(() {
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
          labelText: 'Certifications',
          isRequired: false,
          isMultiSelect: true,
          selectedValues: _selectedCertifications,
          items: certifications,
          hintText: 'Select certifications (optional)',
          pickerTitle: 'Select Certifications',
          searchHint: 'Search certifications...',
          onMultiChanged: (values) {
            setState(() {
              _selectedCertifications = values;
            });
          },
        ),
        const SizedBox(height: 32),
        // Next button
        CustomButton(text: 'Next', onPressed: _handleSubmit, height: 56),
      ],
    );
  }
}
