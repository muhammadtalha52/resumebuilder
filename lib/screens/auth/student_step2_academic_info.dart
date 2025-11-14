import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/student_signup_provider.dart';
import '../../services/location_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/url_launcher_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/tag_field.dart';

class StudentStep2AcademicInfo extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const StudentStep2AcademicInfo({super.key, required this.onNext});

  @override
  ConsumerState<StudentStep2AcademicInfo> createState() =>
      _StudentStep2AcademicInfoState();
}

class _StudentStep2AcademicInfoState
    extends ConsumerState<StudentStep2AcademicInfo> {
  final _formKey = GlobalKey<FormState>();
  final _hometownController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _idealJobTitleController = TextEditingController();

  List<String> _idealJobTitles = [];
  DateTime? _selectedGraduationDate;
  String? _graduationDateError;
  String? _termsError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _agreedToTerms = false;
  bool _isDetectingLocation = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final state = ref.read(studentSignupProvider);
    _hometownController.text = state.hometown ?? '';
    _schoolController.text = state.school ?? '';
    _majorController.text = state.major ?? '';
    _idealJobTitles = List.from(state.idealJobTitles);
    _selectedGraduationDate = state.expectedGraduationDate;
  }

  @override
  void dispose() {
    _hometownController.dispose();
    _schoolController.dispose();
    _majorController.dispose();
    _idealJobTitleController.dispose();
    super.dispose();
  }

  Future<void> _selectGraduationDate() async {
    FocusScope.of(context).requestFocus(FocusNode());

    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedGraduationDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2040),
    );

    if (picked != null && picked != _selectedGraduationDate) {
      setState(() {
        _selectedGraduationDate = picked;
        _graduationDateError = null;
      });
    }
  }

  Future<DateTime?> showMonthYearPicker({
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

  String _formatDate(DateTime date) {
    // Format as "Month Year" (e.g., "December 2024")
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

  void _handleSubmit() {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      if (_selectedGraduationDate == null) {
        _graduationDateError = 'Please select your expected graduation date';
      }
      if (!_agreedToTerms) {
        _termsError = 'Please accept our terms to continue';
      }
    });

    if (_formKey.currentState!.validate() &&
        _selectedGraduationDate != null &&
        _agreedToTerms) {
      ref
          .read(studentSignupProvider.notifier)
          .updateStep2(
            hometown: _hometownController.text.trim(),
            school: _schoolController.text.trim(),
            expectedGraduationDate: _selectedGraduationDate!,
            major: _majorController.text.trim(),
            idealJobTitles: _idealJobTitles,
          );

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _hometownController,
            labelText: 'Hometown & State',
            hintText: 'e.g Austin, Texas',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your hometown';
              }
              return null;
            },
            suffixIcon: _isDetectingLocation
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Locate',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _schoolController,
            labelText: 'School',
            hintText: 'Enter your school name',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            maxLength: 150,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your school name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Expected Graduation Year',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
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
                onTap: _selectGraduationDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _graduationDateError != null
                          ? AppColors.error
                          : AppColors.inputBorder,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedGraduationDate != null
                              ? _formatDate(_selectedGraduationDate!)
                              : 'Select graduation year',
                          style: TextStyle(
                            color: _selectedGraduationDate != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_graduationDateError != null) ...[
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
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _majorController,
            labelText: 'Major',
            hintText: 'Enter your major',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your major';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TagField(
            label: 'Ideal Job Titles after Graduation',
            isRequired: false,
            tags: _idealJobTitles,
            controller: _idealJobTitleController,
            onAdd: (tag) {
              setState(() {
                if (!_idealJobTitles.contains(tag)) {
                  _idealJobTitles.add(tag);
                }
                _idealJobTitleController.clear();
              });
            },
            onRemove: (tag) {
              setState(() {
                _idealJobTitles.remove(tag);
              });
            },
          ),
          const SizedBox(height: 32),
          // Terms and Privacy Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                    if (_agreedToTerms) {
                      _termsError = null;
                    }
                  });
                },
                activeColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Wrap(
                    children: [
                      Text(
                        'I agree to the ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());

                          UrlLauncherUtils.launchPrivacyPolicy();
                          // Auto-check the checkbox when user views the policy
                          setState(() {
                            _agreedToTerms = true;
                            _termsError = null;
                          });
                        },
                        child: Text(
                          'Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                      Text(
                        ' and ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());

                          UrlLauncherUtils.launchTermsOfUse();
                          // Auto-check the checkbox when user views the terms
                          setState(() {
                            _agreedToTerms = true;
                            _termsError = null;
                          });
                        },
                        child: Text(
                          'Terms of Use',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_termsError != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Text(
                _termsError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Next button
          CustomButton(text: 'Next', onPressed: _handleSubmit, height: 56),
        ],
      ),
    );
  }
}
