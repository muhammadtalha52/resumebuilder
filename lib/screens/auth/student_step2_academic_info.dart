import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/student_signup_provider.dart';
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedGraduationDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedGraduationDate) {
      setState(() {
        _selectedGraduationDate = picked;
        _graduationDateError = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
            labelText: 'Hometown',
            hintText: 'Enter your hometown',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your hometown';
              }
              return null;
            },
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
                    'Expected Graduation Date',
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
                              : 'Select graduation date',
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
                onChanged: (value) async {
                  if (value == true) {
                    // Show privacy policy before allowing user to check
                    await context.push('/privacy-policy');
                    // After user returns from privacy policy, check the box
                    setState(() {
                      _agreedToTerms = true;
                      _termsError = null;
                    });
                  } else {
                    setState(() {
                      _agreedToTerms = false;
                    });
                  }
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
                          context.push('/privacy-policy');
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
                          context.push('/terms-of-use');
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
                'Signup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
