import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart' as button;
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';

class ResumeReviewScreen extends ConsumerStatefulWidget {
  const ResumeReviewScreen({super.key});

  @override
  ConsumerState<ResumeReviewScreen> createState() => _ResumeReviewScreenState();
}

class _ResumeReviewScreenState extends ConsumerState<ResumeReviewScreen> {
  final List<bool> _expandedSections = List.generate(6, (_) => false);

  // Controllers for form fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();

  // Career goals controllers
  final _desiredJobTitleController = TextEditingController();
  final _preferredIndustryController = TextEditingController();

  // Work experience controllers
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  bool _stillWorkHere = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final onboardingData = ref.read(onboardingProvider);

    // Load personal details
    _fullNameController.text = onboardingData.fullName ?? '';
    _emailController.text = onboardingData.email ?? '';
    _phoneController.text = onboardingData.phone ?? '';
    _linkedInController.text = onboardingData.linkedIn ?? '';

    // Load career goals if available
    if (onboardingData.careerGoals != null) {
      _desiredJobTitleController.text =
          onboardingData.careerGoals!['desiredJobTitle'] ?? '';
      _preferredIndustryController.text =
          onboardingData.careerGoals!['preferredIndustry'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _desiredJobTitleController.dispose();
    _preferredIndustryController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _responsibilitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxLogo(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStepIndicator(1, true),
                        _buildStepLine(false),
                        _buildStepIndicator(2, false),
                        _buildStepLine(false),
                        _buildStepIndicator(3, false),
                        _buildStepLine(false),
                        _buildStepIndicator(4, false),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Review & Edit Your Profile information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s an overview of your skills. Please feel free to edit or add at any time!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Expandable sections
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildExpandableSection(
                        index: 0,
                        icon: Icons.person,
                        title: 'Personal Details',
                        content: _buildPersonalDetailsContent(),
                      ),
                      _buildExpandableSection(
                        index: 1,
                        icon: Icons.flag,
                        iconColor: Colors.red,
                        title: 'Career Goals',
                        content: _buildCareerGoalsContent(),
                      ),
                      _buildExpandableSection(
                        index: 2,
                        icon: Icons.school,
                        title: 'Education',
                        content: _buildEducationContent(),
                      ),
                      _buildExpandableSection(
                        index: 3,
                        icon: Icons.work,
                        iconColor: Colors.amber,
                        title: 'Work Experience',
                        content: _buildWorkExperienceContent(),
                      ),
                      _buildExpandableSection(
                        index: 4,
                        icon: Icons.build,
                        title: 'Skills & Tools',
                        content: _buildSkillsContent(),
                      ),
                      _buildExpandableSection(
                        index: 5,
                        icon: Icons.info_outline,
                        iconColor: Colors.blue,
                        title: 'Optional Info',
                        content: _buildOptionalInfoContent(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Continue button
              Container(
                padding: const EdgeInsets.all(20),
                child: button.CustomButton(
                  text: 'Continue',
                  onPressed: _handleContinue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : AppColors.white,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.inputBorder,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : AppColors.inputBorder,
      ),
    );
  }

  Widget _buildExpandableSection({
    required int index,
    required IconData icon,
    Color? iconColor,
    required String title,
    required Widget content,
  }) {
    final isExpanded = _expandedSections[index];

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSections[index] = !_expandedSections[index];
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 16),
            child: content,
          ),
        const Divider(height: 1, color: AppColors.inputBorder),
      ],
    );
  }

  Widget _buildPersonalDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _fullNameController,
          labelText: 'Full Name',
          prefixIcon: const Icon(Icons.person_outline, size: 20),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, size: 20),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          labelText: 'Phone Number',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _linkedInController,
          labelText: 'LinkedIn Profile',
          prefixIcon: const Icon(Icons.link, size: 20),
        ),
      ],
    );
  }

  Widget _buildCareerGoalsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _desiredJobTitleController,
          labelText: 'Desired Job Title',
          hintText: 'e.g., Software Engineer',
        ),
        const SizedBox(height: 16),
        CustomDropdown<String>(
          value: null,
          labelText: 'Preferred Industries',
          hintText: 'Select industries',
          items: [
            'IT Companies',
            'Software House',
            'Tech Startups',
            'Consulting',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        CustomDropdown<String>(
          value: null,
          labelText: 'Product Design',
          hintText: 'UX Design',
          items: [
            'UX Design',
            'UI Design',
            'Product Management',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildEducationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'School/University',
          hintText: 'Enter your school name',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'Degree',
          hintText: 'e.g., Bachelor of Science',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: TextEditingController(),
                labelText: 'Start Date',
                hintText: 'MM/YYYY',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: TextEditingController(),
                labelText: 'End Date',
                hintText: 'MM/YYYY',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkExperienceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _jobTitleController,
          labelText: 'Job Title',
          hintText: 'Senior Software Engineer',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _companyController,
          labelText: 'Company',
          hintText: 'Apple Inc',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _startDateController),
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: _startDateController,
                    labelText: 'Start Date',
                    hintText: '01/01/2022',
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: !_stillWorkHere
                    ? () => _selectDate(context, _endDateController)
                    : null,
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: _endDateController,
                    labelText: 'End Date',
                    hintText: '01/01/2024',
                    enabled: !_stillWorkHere,
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _responsibilitiesController,
          labelText: 'Key Responsibilities',
          hintText:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry...',
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _stillWorkHere,
              onChanged: (value) {
                setState(() {
                  _stillWorkHere = value ?? false;
                  if (_stillWorkHere) {
                    _endDateController.clear();
                  }
                });
              },
              activeColor: AppColors.primary,
            ),
            const Text(
              'I still work here',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implement AI suggestions
          },
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('AI Suggestions'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'Technical Skills',
          hintText: 'e.g., JavaScript, React, Node.js',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'Tools & Technologies',
          hintText: 'e.g., Git, Docker, AWS',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'Soft Skills',
          hintText: 'e.g., Leadership, Communication',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildOptionalInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdown<String>(
          value: null,
          labelText: 'Languages',
          hintText: 'Select languages',
          items: [
            'English',
            'Spanish',
            'French',
            'German',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'Hobbies & Interests',
          hintText: 'e.g., Reading, Coding, Gaming',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: TextEditingController(),
          labelText: 'References',
          hintText: 'Available upon request',
          maxLines: 2,
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text =
          "${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  void _handleContinue() {
    // TODO: Navigate to next step with collected data
    context.push('/resume/generate');
  }
}
