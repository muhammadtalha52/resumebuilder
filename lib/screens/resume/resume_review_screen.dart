import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../constants/app_colors.dart';
import '../../constants/salary_ranges.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart' as button;
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_picker_field.dart';
import '../../widgets/common/tag_field.dart';

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

class ResumeReviewScreen extends ConsumerStatefulWidget {
  const ResumeReviewScreen({super.key});

  @override
  ConsumerState<ResumeReviewScreen> createState() => _ResumeReviewScreenState();
}

class _ResumeReviewScreenState extends ConsumerState<ResumeReviewScreen> {
  // Step management
  int _currentStep = 1;
  final int _totalSteps = 4;

  // Existing state
  final List<bool> _expandedSections = List.generate(6, (_) => false);
  bool _isDataLoaded = false;
  bool _hasDataFromParsing = false;

  // Controllers for form fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _websiteController = TextEditingController();
  String _completePhoneNumber = '';
  String _selectedCountryCode = 'US';

  // Career goals
  final _jobTitlesController = TextEditingController();
  final _industriesController = TextEditingController();
  final _longTermGoalsController = TextEditingController();
  List<String> _jobTitles = [];
  List<String> _industries = [];
  String? _locationPreference;
  String? _desiredSalaryRange;

  // Work experience
  List<WorkExperienceEntry> _workExperiences = [WorkExperienceEntry()];

  // Skills
  final _hardSkillsController = TextEditingController();
  final _softSkillsController = TextEditingController();
  final _toolsController = TextEditingController();
  List<String> _hardSkills = [];
  List<String> _softSkills = [];
  List<String> _tools = [];

  // Education controllers
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _educationStartDateController = TextEditingController();
  final _educationEndDateController = TextEditingController();

  // Optional info
  List<String> _languages = [];
  final _languagesController = TextEditingController();
  final _hobbiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final resumeState = ref.read(resumeProvider);

    // Check for newly parsed resume data
    if (resumeState.parsedResumeData != null) {
      print('📄 Found parsed resume data - loading...');
      _hasDataFromParsing = true;
      _loadParsedResumeData(resumeState);
      return;
    }

    // Check for profile data mode
    if (resumeState.isUsingProfileData) {
      print('👤 Profile data mode detected - loading existing profile...');
      _loadExistingProfileData();
      return;
    }

    print('📝 Loading existing onboarding data...');
    // Load existing onboarding data
    _loadOnboardingData();
    setState(() {
      _isDataLoaded = true;
    });
  }

  void _loadParsedResumeData(ResumeState resumeState) {
    // Show loading message for parsing data
    Future(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Loading parsed resume data...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );

      // Populate onboarding provider with parsed data
      ref
          .read(onboardingProvider.notifier)
          .populateFromParsedResume(resumeState.parsedResumeData!);

      // Clear the parsed data from resume provider to avoid re-processing
      ref.read(resumeProvider.notifier).clearParsedData();

      // Small delay for smooth loading experience
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _loadOnboardingData();
            _isDataLoaded = true;
          });

          // Clear loading message and show success
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Resume data loaded successfully!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  void _loadExistingProfileData() {
    print('🔄 Starting profile data loading...');

    // Show loading message for profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 Showing profile loading snackbar...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Loading your profile data...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 2500),
        ),
      );

      // Clear the profile data mode flag
      ref.read(resumeProvider.notifier).clearProfileDataMode();

      // Fetch education data first for ID resolution
      _fetchEducationDataAndLoadProfile();
    });
  }

  Future<void> _fetchEducationDataAndLoadProfile() async {
    try {
      print('🎓 Fetching education data for ID resolution...');
      await ref.read(resumeProvider.notifier).fetchEducationData();

      print('⏱️ Education data fetched, loading profile data...');
      if (mounted) {
        setState(() {
          _loadOnboardingData();
          _isDataLoaded = true;
        });

        print('✅ Profile data loaded, showing success message...');
        // Clear loading message and show success
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Profile data loaded successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Load profile data anyway, even if education data fetch failed
        setState(() {
          _loadOnboardingData();
          _isDataLoaded = true;
        });
      }
    }
  }

  void _loadOnboardingData() {
    // Load data from user object in auth provider
    final user = ref.read(authProvider).user!;

    // Load personal details from user object
    _fullNameController.text = user.fullName ?? '';
    _emailController.text = user.email ?? '';

    // Handle phone number
    final savedPhone = user.phoneNumber ?? '';
    if (savedPhone.isNotEmpty) {
      _completePhoneNumber = savedPhone;
      String phoneNumber = savedPhone;
      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }
      if (phoneNumber.startsWith('1') && phoneNumber.length > 10) {
        phoneNumber = phoneNumber.substring(1);
        _selectedCountryCode = 'US';
      }
      _phoneController.text = phoneNumber;
    }

    _linkedInController.text = user.linkedinUrl ?? '';
    _websiteController.text = user.portfolioUrl ?? '';

    // Load career goals from user object
    if (user.desiredJobTitles != null || user.industryPreferences != null) {
      _jobTitles = List.from(user.desiredJobTitles ?? []);
      _industries = List.from(user.industryPreferences ?? []);

      // Map salary range from user's desiredPayRange
      if (user.desiredPayRange != null) {
        // Convert int ID to salary range string if needed
        _desiredSalaryRange = SalaryRanges.ranges.firstWhere(
          (range) => range.contains(user.desiredPayRange.toString()),
          orElse: () => '',
        );
      }

      _locationPreference = user.locationPreferences?.toString();

      // Load long term goals from user's longTermCareerGoals
      if (user.longTermCareerGoals != null &&
          user.longTermCareerGoals!.isNotEmpty) {
        _longTermGoalsController.text = user.longTermCareerGoals!.join(', ');
      }
    }

    // Load education from user object using resume provider education resolution
    print(
      '🔍 User education IDs: institution=${user.institution}, degreeType=${user.degreeType}, major=${user.major}',
    );
    if (user.institution != null) {
      // Get institution name from ID using resume provider resolution
      final institutionName = ref
          .read(resumeProvider.notifier)
          .resolveInstitutionName(user.institution);
      _universityController.text =
          institutionName ?? 'Institution ID: ${user.institution}';
      print(
        '🏫 Institution resolved: ID ${user.institution} → ${institutionName ?? "Not found"}',
      );
    }

    // Combine degree type and major names if available
    String degreeText = '';
    if (user.degreeType != null || user.major != null) {
      final degreeTypeName = user.degreeType != null
          ? ref
                .read(resumeProvider.notifier)
                .resolveDegreeTypeName(user.degreeType)
          : null;
      final majorName = user.major != null
          ? ref.read(resumeProvider.notifier).resolveMajorName(user.major)
          : null;

      print(
        '🎓 Degree resolved: Type ID ${user.degreeType} → ${degreeTypeName ?? "Not found"}',
      );
      print(
        '📖 Major resolved: ID ${user.major} → ${majorName ?? "Not found"}',
      );

      if (degreeTypeName != null && majorName != null) {
        degreeText = '$degreeTypeName in $majorName';
      } else if (degreeTypeName != null) {
        degreeText = degreeTypeName;
      } else if (majorName != null) {
        degreeText = majorName;
      } else {
        // Fallback to IDs if names not found
        if (user.degreeType != null && user.major != null) {
          degreeText = 'Degree ID: ${user.degreeType}, Major ID: ${user.major}';
        } else if (user.degreeType != null) {
          degreeText = 'Degree ID: ${user.degreeType}';
        } else if (user.major != null) {
          degreeText = 'Major ID: ${user.major}';
        }
      }
    }
    _degreeController.text = degreeText;

    _educationEndDateController.text = user.graduationDate ?? '';

    print(
      '✅ Education loaded: university="${_universityController.text}", degree="${_degreeController.text}", graduation="${user.graduationDate}"',
    );

    // Load work experience from user object
    if (user.workExperience != null && user.workExperience!.isNotEmpty) {
      _workExperiences = user.workExperience!.map((exp) {
        final entry = WorkExperienceEntry();
        entry.jobTitle.text = exp.jobTitle ?? '';
        entry.company.text = exp.companyName ?? '';
        entry.responsibilities.text = (exp.keyResponsibilities ?? []).join(
          '\n',
        );

        // Parse dates
        if (exp.workStartDate != null) {
          try {
            entry.startDate = DateTime.parse(exp.workStartDate!);
          } catch (e) {
            print('⚠️ Error parsing start date: ${exp.workStartDate}');
          }
        }

        if (exp.workEndDate != null) {
          try {
            entry.endDate = DateTime.parse(exp.workEndDate!);
          } catch (e) {
            print('⚠️ Error parsing end date: ${exp.workEndDate}');
          }
        }

        entry.currentJob = exp.isCurrentJob ?? false;
        return entry;
      }).toList();
    }

    // Load skills from user object
    _hardSkills = List.from(user.hardSkills ?? []);
    _softSkills = List.from(user.softSkills ?? []);
    _tools = List.from(user.toolsTechnologies ?? []);

    // Load optional info from user object
    _languages = List.from(user.languages ?? []);
    if (user.hobbiesInterests != null && user.hobbiesInterests!.isNotEmpty) {
      _hobbiesController.text = user.hobbiesInterests!.join(', ');
    }

    print('✅ User data loaded successfully');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _websiteController.dispose();
    _jobTitlesController.dispose();
    _industriesController.dispose();
    _longTermGoalsController.dispose();
    // Dispose work experience entries
    for (final experience in _workExperiences) {
      experience.dispose();
    }
    _hardSkillsController.dispose();
    _softSkillsController.dispose();
    _toolsController.dispose();
    _languagesController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resumeState = ref.watch(resumeProvider);
    final isLoadingEducation = resumeState.isLoadingEducationData;

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
          // Loading overlay for education data
          if (isLoadingEducation)
            Positioned.fill(
              child: Container(
                color: AppColors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading education data...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        40, // Ensure minimum height minus padding
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width >= 600
                              ? 600
                              : double.infinity,
                        ),
                        child: Card(
                          elevation: 0,
                          color: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              // Progress indicator
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildStepIndicator(
                                          1,
                                          _currentStep == 1,
                                        ),
                                        _buildStepLine(_currentStep > 1),
                                        _buildStepIndicator(
                                          2,
                                          _currentStep == 2,
                                        ),
                                        _buildStepLine(_currentStep > 2),
                                        _buildStepIndicator(
                                          3,
                                          _currentStep == 3,
                                        ),
                                        _buildStepLine(_currentStep > 3),
                                        _buildStepIndicator(
                                          4,
                                          _currentStep == 4,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _getStepTitle(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getStepDescription(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Step content
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: _buildStepContent(),
                              ),
                              // Continue button
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: button.CustomButton(
                                  text: _getContinueButtonText(),
                                  onPressed: _handleContinue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1ReviewContent();
      case 2:
        return _buildStep2JobTargetingContent();
      case 3:
        return _buildStep3TemplateSelectionContent();
      case 4:
        return _buildStep4ResumePreviewContent();
      default:
        return _buildStep1ReviewContent();
    }
  }

  Widget _buildStep1ReviewContent() {
    return Column(
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
      ],
    );
  }

  Widget _buildStep2JobTargetingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Job targeting form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.work_outline, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Job Target',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: TextEditingController(),
                labelText: 'Job Title',
                hintText: 'e.g., Senior Software Engineer',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: TextEditingController(),
                labelText: 'Company Name (Optional)',
                hintText: 'e.g., Apple Inc.',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: TextEditingController(),
                labelText: 'Job Description/Requirements',
                hintText:
                    'Paste the job description here to tailor your resume...',
                maxLines: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // AI Enhancement toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Enhancement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Let AI optimize your resume for this specific job',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep3TemplateSelectionContent() {
    final templates = [
      {'name': 'Modern', 'preview': 'assets/templates/modern.png'},
      {'name': 'Classic', 'preview': 'assets/templates/classic.png'},
      {'name': 'Creative', 'preview': 'assets/templates/creative.png'},
      {'name': 'Professional', 'preview': 'assets/templates/professional.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Choose Your Template',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            final isSelected = index == 0; // Default first template selected

            return GestureDetector(
              onTap: () {
                // Handle template selection
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.description,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            template['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep4ResumePreviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Preview container
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, size: 64, color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Resume Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your resume is being generated...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: button.CustomButton(
                text: 'Share Resume',
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
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
            padding: const EdgeInsets.only(top: 16, bottom: 16),
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
          hintText: 'John Alex',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'john.alex@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Phone Number',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntlPhoneField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Phone Number',
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
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
                  borderSide: const BorderSide(
                    color: AppColors.inputBorderFocused,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                counterText: '',
              ),
              initialCountryCode: _selectedCountryCode,
              onChanged: (phone) {
                setState(() {
                  _completePhoneNumber = phone.completeNumber;
                });
              },
              showCountryFlag: true,
              showDropdownIcon: true,
              flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 12),
              dropdownIconPosition: IconPosition.trailing,
              dropdownIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _linkedInController,
          labelText: 'LinkedIn Profile',
          hintText: 'https://www.linkedin.com/in/yourprofile',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _websiteController,
          labelText: 'Personal Website',
          hintText: 'https://www.yourwebsite.com',
        ),
      ],
    );
  }

  Widget _buildCareerGoalsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagField(
          label: 'Desired Job Titles',
          isRequired: false,
          tags: _jobTitles,
          controller: _jobTitlesController,
          onAdd: (tag) => _addTag(tag, _jobTitles, _jobTitlesController),
          onRemove: (tag) => _removeTag(tag, _jobTitles),
        ),
        const SizedBox(height: 16),
        TagField(
          label: 'Preferred Industries',
          isRequired: false,
          tags: _industries,
          controller: _industriesController,
          onAdd: (tag) => _addTag(tag, _industries, _industriesController),
          onRemove: (tag) => _removeTag(tag, _industries),
        ),
        const SizedBox(height: 16),
        CustomPickerField(
          labelText: 'Location Preference',
          isRequired: false,
          value: _locationPreference,
          items: const ['On-site', 'Remote', 'Hybrid'],
          hintText: 'Select Options',
          enableSearch: false,
          pickerTitle: 'Select Location Preference',
          onChanged: (value) {
            setState(() {
              _locationPreference = value;
            });
          },
        ),
        const SizedBox(height: 16),
        CustomPickerField(
          labelText: 'Desired Salary Range',
          isRequired: false,
          value: _desiredSalaryRange,
          items: SalaryRanges.ranges,
          hintText: 'Select salary range',
          enableSearch: true,
          searchHint: 'Search salary ranges...',
          pickerTitle: 'Select Desired Salary Range',
          onChanged: (value) {
            setState(() {
              _desiredSalaryRange = value;
            });
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _longTermGoalsController,
          labelText: 'Long-term Goals',
          hintText:
              'e.g., Become a technical lead and mentor junior developers',
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildEducationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _universityController,
          labelText: 'School/University',
          hintText: 'Enter your school name',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _degreeController,
          labelText: 'Degree',
          hintText: 'e.g., Bachelor of Science',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _educationStartDateController,
                labelText: 'Start Date',
                hintText: 'MM/YYYY',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _educationEndDateController,
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
      ],
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
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        if (_workExperiences.length > 1) const SizedBox(height: 16),

        // Job title
        CustomTextField(
          controller: experience.jobTitle,
          labelText: 'Job Title',
          hintText: 'Senior Software Engineer',
        ),
        const SizedBox(height: 16),

        // Company
        CustomTextField(
          controller: experience.company,
          labelText: 'Company',
          hintText: 'Apple Inc',
        ),
        const SizedBox(height: 16),

        // Date fields
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
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
            ),
          ],
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
        const SizedBox(height: 16),

        // Key Responsibilities
        CustomTextField(
          controller: experience.responsibilities,
          labelText: 'Key Responsibilities (Optional)',
          hintText: 'Enter a description...',
          maxLines: 4,
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
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isDisabled
                  ? AppColors.grey.withValues(alpha: 0.1)
                  : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? "${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.year}"
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: 13,
                    color: selectedDate != null
                        ? (isDisabled
                              ? AppColors.textSecondary
                              : AppColors.textPrimary)
                        : AppColors.textLight,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: isDisabled
                      ? AppColors.grey.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
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
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        const Text(
          'I still work here',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addMoreExperience,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add More Experience'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
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

  Widget _buildSkillsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagField(
          label: 'Technical Skills',
          isRequired: false,
          tags: _hardSkills,
          controller: _hardSkillsController,
          onAdd: (tag) => _addTag(tag, _hardSkills, _hardSkillsController),
          onRemove: (tag) => _removeTag(tag, _hardSkills),
        ),
        const SizedBox(height: 16),
        TagField(
          label: 'Tools & Technologies',
          isRequired: false,
          tags: _tools,
          controller: _toolsController,
          onAdd: (tag) => _addTag(tag, _tools, _toolsController),
          onRemove: (tag) => _removeTag(tag, _tools),
        ),
        const SizedBox(height: 16),
        TagField(
          label: 'Soft Skills',
          isRequired: false,
          tags: _softSkills,
          controller: _softSkillsController,
          onAdd: (tag) => _addTag(tag, _softSkills, _softSkillsController),
          onRemove: (tag) => _removeTag(tag, _softSkills),
        ),
      ],
    );
  }

  Widget _buildOptionalInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagField(
          label: 'Languages',
          isRequired: false,
          tags: _languages,
          controller: _languagesController,
          onAdd: (tag) => _addTag(tag, _languages, _languagesController),
          onRemove: (tag) => _removeTag(tag, _languages),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _hobbiesController,
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

  void _addTag(
    String tag,
    List<String> list,
    TextEditingController controller,
  ) {
    if (tag.trim().isNotEmpty && !list.contains(tag.trim())) {
      setState(() {
        list.add(tag.trim());
      });
      controller.clear();
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Review & Edit Your Profile information';
      case 2:
        return 'Who\'s This Resume For?';
      case 3:
        return 'Choose Resume Style';
      case 4:
        return 'Final Resume Preview';
      default:
        return 'Step $_currentStep';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Here\'s an overview of your skills. Please feel free to edit or add at any time!';
      case 2:
        return 'Help us tailor your resume to land your dream job!';
      case 3:
        return 'Pick a design that fits your personality or profession.';
      case 4:
        return 'Your resume is ready! Download or make final adjustments.';
      default:
        return 'Complete this step to continue.';
    }
  }

  String _getContinueButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Continue';
      case 2:
        return 'Continue to Templates';
      case 3:
        return 'Generate Resume';
      case 4:
        return 'Download Resume';
      default:
        return 'Continue';
    }
  }

  void _handleContinue() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - generate resume
      context.push('/resume/generate');
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }
}
