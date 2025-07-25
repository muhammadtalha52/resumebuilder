import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/onboarding_provider.dart';

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
  List<String> _selectedCertifications = [];

  // Dropdown options
  final List<String> _degreeTypes = [
    'High School Diploma',
    'Associate Degree',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctoral Degree (PhD)',
    'Professional Degree',
    'Certificate',
    'Other',
  ];

  final List<String> _majors = [
    'Computer Science',
    'Information Technology',
    'Software Engineering',
    'Business Administration',
    'Marketing',
    'Finance',
    'Accounting',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Civil Engineering',
    'Psychology',
    'Biology',
    'Chemistry',
    'Physics',
    'Mathematics',
    'English',
    'Communications',
    'Graphic Design',
    'Art',
    'History',
    'Political Science',
    'Economics',
    'Other',
  ];

  final List<String> _institutions = [
    'Harvard University',
    'Stanford University',
    'MIT',
    'University of California, Berkeley',
    'Yale University',
    'Princeton University',
    'Columbia University',
    'University of Chicago',
    'University of Pennsylvania',
    'California Institute of Technology',
    'Johns Hopkins University',
    'Northwestern University',
    'Duke University',
    'Dartmouth College',
    'Brown University',
    'Vanderbilt University',
    'Rice University',
    'Washington University in St. Louis',
    'Cornell University',
    'University of Notre Dame',
    'Other',
  ];

  final List<String> _certifications = [
    'AWS Certified Solutions Architect',
    'Google Cloud Professional',
    'Microsoft Azure Fundamentals',
    'Certified Information Systems Security Professional (CISSP)',
    'Project Management Professional (PMP)',
    'Certified Public Accountant (CPA)',
    'Chartered Financial Analyst (CFA)',
    'Certified Information Systems Auditor (CISA)',
    'Cisco Certified Network Associate (CCNA)',
    'CompTIA Security+',
    'Certified Scrum Master (CSM)',
    'Google Analytics Certified',
    'HubSpot Content Marketing',
    'Adobe Certified Expert',
    'Other',
  ];

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
        _selectedCertifications = List<String>.from(
          education['certifications'] ?? [],
        );
      });
    }
  }

  Widget _buildDropdown({
    required String label,
    required bool isRequired,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool multiSelect = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text(
                'Select Options',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _graduationDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _graduationDate = picked;
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

  Widget _buildMultiSelectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Certifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text(
                'Select Options',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              isExpanded: true,
              items: _certifications.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      final isSelected = _selectedCertifications.contains(item);
                      return Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (!_selectedCertifications.contains(item)) {
                                    _selectedCertifications.add(item);
                                  }
                                } else {
                                  _selectedCertifications.remove(item);
                                }
                              });
                              this.setState(() {});
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(child: Text(item)),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
        if (_selectedCertifications.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCertifications.map((cert) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEEFF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF7777F8),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        cert,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCertifications.remove(cert);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _handleSubmit() {
    // Validation
    if (_selectedDegreeType == null ||
        _selectedMajor == null ||
        _selectedInstitution == null ||
        (!_degreeNotCompleted && _graduationDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Save data
    ref
        .read(onboardingProvider.notifier)
        .updateEducation(
          degreeType: _selectedDegreeType,
          major: _selectedMajor,
          institution: _selectedInstitution,
          graduationDate: _graduationDate,
          degreeNotCompleted: _degreeNotCompleted,
          certifications: _selectedCertifications,
        );

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Degree Type',
          isRequired: true,
          value: _selectedDegreeType,
          items: _degreeTypes,
          onChanged: (value) {
            setState(() {
              _selectedDegreeType = value;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Major',
          isRequired: true,
          value: _selectedMajor,
          items: _majors,
          onChanged: (value) {
            setState(() {
              _selectedMajor = value;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Institution',
          isRequired: true,
          value: _selectedInstitution,
          items: _institutions,
          onChanged: (value) {
            setState(() {
              _selectedInstitution = value;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildCheckbox(),
        const SizedBox(height: 20),
        _buildMultiSelectDropdown(),
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
