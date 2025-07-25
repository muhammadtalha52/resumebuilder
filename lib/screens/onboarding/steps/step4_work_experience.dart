import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/onboarding_provider.dart';

class Step4WorkExperience extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const Step4WorkExperience({super.key, required this.onNext});

  @override
  ConsumerState<Step4WorkExperience> createState() =>
      _Step4WorkExperienceState();
}

class _Step4WorkExperienceState extends ConsumerState<Step4WorkExperience> {
  List<WorkExperienceEntry> _workExperiences = [WorkExperienceEntry()];

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
    setState(() {
      _workExperiences.add(WorkExperienceEntry());
    });
  }

  void _removeExperience(int index) {
    if (_workExperiences.length > 1) {
      setState(() {
        _workExperiences.removeAt(index);
      });
    }
  }

  void _handleSubmit() {
    // Validate required fields for all experiences
    for (int i = 0; i < _workExperiences.length; i++) {
      final exp = _workExperiences[i];
      if (exp.jobTitle.text.trim().isEmpty ||
          exp.company.text.trim().isEmpty ||
          exp.startDate == null ||
          (!exp.currentJob && exp.endDate == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill in all required fields for experience ${i + 1}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Save data
    final experiencesData = _workExperiences.map((exp) => exp.toMap()).toList();
    ref.read(onboardingProvider.notifier).updateWorkExperience({
      'experiences': experiencesData,
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File upload section
        _buildFileUploadSection(),
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
    );
  }

  Widget _buildFileUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0FF), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Attached Resume Here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              children: [
                TextSpan(text: 'Supported files '),
                TextSpan(
                  text: 'pdf',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: AppColors.primary,
                  ),
                ),
                TextSpan(text: ' or '),
                TextSpan(
                  text: 'docx',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: AppColors.primary,
                  ),
                ),
              ],
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
        _buildTextField(
          label: 'Job title',
          isRequired: true,
          controller: experience.jobTitle,
          hintText: 'Type here',
        ),
        const SizedBox(height: 20),

        // Company
        _buildTextField(
          label: 'Company',
          isRequired: true,
          controller: experience.company,
          hintText: 'Type here',
        ),
        const SizedBox(height: 20),

        // Start Date
        _buildDatePicker(
          label: 'Start Date',
          isRequired: true,
          selectedDate: experience.startDate,
          onDateSelected: (date) {
            setState(() {
              experience.startDate = date;
            });
          },
        ),
        const SizedBox(height: 20),

        // End Date
        _buildDatePicker(
          label: 'End Date',
          isRequired: !experience.currentJob,
          selectedDate: experience.endDate,
          onDateSelected: (date) {
            setState(() {
              experience.endDate = date;
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
              }
            });
          },
        ),
        const SizedBox(height: 20),

        // Key Responsibilities
        _buildResponsibilitiesField(experience),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorderFocused),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required bool isRequired,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            if (isRequired && !isDisabled)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
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

  Widget _buildResponsibilitiesField(WorkExperienceEntry experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Responsibilities (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: experience.responsibilities,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Enter a description...',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorderFocused),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
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
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
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
