import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skillresy/screens/candidate/resume/resume_generation_loading_screen.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/salary_ranges.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/resume_provider.dart';
import '../../../providers/usage_provider.dart';
import '../../../utils/phone_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart' as button;
import '../../../widgets/common/custom_picker_field.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/tag_field.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';
import '../../../widgets/resume_edit_modal.dart';

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
  final String? flowType;

  const ResumeReviewScreen({super.key, this.flowType});

  @override
  ConsumerState<ResumeReviewScreen> createState() => _ResumeReviewScreenState();
}

class _ResumeReviewScreenState extends ConsumerState<ResumeReviewScreen> {
  // Step management
  int _currentStep = 1;
  int _totalSteps = 4;
  bool _isUploadedResumeFlow = false;

  // Existing state
  final List<bool> _expandedSections = List.generate(6, (_) => false);

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
  DateTime? _graduationDate;
  bool _degreeNotCompleted = false;
  String? _graduationDateError;

  // Optional info
  List<String> _languages = [];
  final _languagesController = TextEditingController();
  final _hobbiesController = TextEditingController();

  // Step 2 - Job targeting
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _linkedInJobLinkController = TextEditingController();
  final _jobDescriptionController = TextEditingController();

  // Validation errors for step 2
  String? _jobTitleError;
  String? _jobTargetingError;

  // Step 3 - Template selection
  int _selectedTemplateIndex = 0;
  final PageController _templatePageController = PageController(
    viewportFraction: 0.85,
  );

  // Loading state for credit check
  bool _isCheckingCredits = false;

  @override
  void initState() {
    super.initState();
    _determineFlowFromParameter();
    _loadUserData();
  }

  void _determineFlowFromParameter() {
    debugPrint('🔍 Determining flow from parameter: ${widget.flowType}');

    if (widget.flowType == 'upload') {
      debugPrint('✅ Upload flow - using 3-step flow (skip profile review)');
      _isUploadedResumeFlow = true;
      _totalSteps = 3;
      _currentStep = 1; // Job Targeting
    } else {
      debugPrint('✅ Create flow - using 4-step flow');
      _isUploadedResumeFlow = false;
      _totalSteps = 4;
      _currentStep = 1; // Profile Review
    }

    debugPrint(
      '🎯 Flow set: ${_isUploadedResumeFlow ? "3-step uploaded" : "4-step scratch"} (steps: $_totalSteps, current: $_currentStep)',
    );
  }

  void _loadUserData() {
    final resumeState = ref.read(resumeProvider);

    // Check for uploaded resume file (skip parsed data step)
    if (resumeState.uploadedFile != null) {
      debugPrint('📄 Resume file uploaded - loading profile data...');
      _loadExistingProfileData();
      return;
    }

    // Check for profile data mode
    if (resumeState.isUsingProfileData) {
      debugPrint('👤 Profile data mode detected - loading existing profile...');
      _loadExistingProfileData();
      return;
    }

    debugPrint('📝 Loading existing onboarding data...');
    // Load existing onboarding data
    _loadOnboardingData();
  }

  void _loadExistingProfileData() {
    debugPrint('🔄 Starting profile data loading...');

    // Show loading message for profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear the profile data mode flag
      ref.read(resumeProvider.notifier).clearProfileDataMode();

      // Fetch education data first for ID resolution
      _fetchEducationDataAndLoadProfile();
    });
  }

  Future<void> _fetchEducationDataAndLoadProfile() async {
    try {
      debugPrint('🎓 Fetching education data for ID resolution...');
      await ref.read(resumeProvider.notifier).fetchEducationData();

      debugPrint('⏱️ Education data fetched, loading profile data...');
      if (mounted) {
        setState(() {
          _loadOnboardingData();
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading profile data: $e');
      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'Error loading profile data: ${e.toString()}',
        );

        // Load profile data anyway, even if education data fetch failed
        setState(() {
          _loadOnboardingData();
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

    // Handle phone number using PhoneUtils
    final savedPhone = user.phoneNumber ?? '';
    if (savedPhone.isNotEmpty) {
      _completePhoneNumber = savedPhone;

      // Detect country code from saved phone number using PhoneUtils
      _selectedCountryCode = PhoneUtils.detectCountryCode(savedPhone);

      // Extract phone number without country code using PhoneUtils
      String phoneNumber = PhoneUtils.extractPhoneNumber(savedPhone);

      _phoneController.text = phoneNumber;
    }

    _linkedInController.text = user.linkedinUrl ?? '';
    _websiteController.text = user.portfolioUrl ?? '';

    // Load career goals from user object
    if (user.desiredJobTitles != null || user.industryPreferences != null) {
      // Extract titles from DesiredJobTitle objects
      if (user.desiredJobTitles != null) {
        _jobTitles = user.desiredJobTitles!
            .map((job) => job.title ?? '')
            .where((title) => title.isNotEmpty)
            .toList();
      }

      // Extract industries from IndustryPreference objects
      if (user.industryPreferences != null) {
        _industries = user.industryPreferences!
            .map((industry) => industry.industry ?? '')
            .where((industry) => industry.isNotEmpty)
            .toList();
      }

      // Map salary range from user's desiredPayRange
      if (user.desiredPayRange != null) {
        // Convert int ID to salary range string if needed
        _desiredSalaryRange = SalaryRanges.ranges.firstWhere(
          (range) => range.contains(user.desiredPayRange.toString()),
          orElse: () => '',
        );
      }

      // Extract location preferences from LocationPreference objects
      if (user.locationPreferences != null &&
          user.locationPreferences!.isNotEmpty) {
        // Join location names
        final locations = user.locationPreferences!
            .map((loc) => loc.location ?? '')
            .where((loc) => loc.isNotEmpty)
            .toList();
        _locationPreference = locations.join(', ');
      }

      // Load long term goals from CareerGoal objects
      if (user.careerGoals != null && user.careerGoals!.isNotEmpty) {
        final goals = user.careerGoals!
            .map((goal) => goal.goal ?? '')
            .where((goal) => goal.isNotEmpty)
            .toList();
        _longTermGoalsController.text = goals.join(', ');
      }
    }

    // Load education from user object using resume provider education resolution
    debugPrint(
      '🔍 User education IDs: institution=${user.institution}, degreeType=${user.degreeType}, major=${user.major}',
    );
    if (user.institution != null) {
      // Get institution name from ID using resume provider resolution
      final institutionName = user.institution ?? '';
      _universityController.text =
          institutionName ?? 'Institution ID: ${user.institution}';
      debugPrint(
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

      debugPrint(
        '🎓 Degree resolved: Type ID ${user.degreeType} → ${degreeTypeName ?? "Not found"}',
      );
      debugPrint(
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

    // Parse graduation date
    if (user.graduationDate != null && user.graduationDate!.isNotEmpty) {
      try {
        _graduationDate = DateTime.parse(user.graduationDate!);
      } catch (e) {
        debugPrint('⚠️ Error parsing graduation date: ${user.graduationDate}');
      }
    }

    // Set degree not completed flag - if no graduation date, assume not completed
    _degreeNotCompleted = _graduationDate == null;

    debugPrint(
      '✅ Education loaded: university="${_universityController.text}", degree="${_degreeController.text}", graduation="${user.graduationDate}", degreeNotCompleted=$_degreeNotCompleted',
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
            debugPrint('⚠️ Error parsing start date: ${exp.workStartDate}');
          }
        }

        if (exp.workEndDate != null) {
          try {
            entry.endDate = DateTime.parse(exp.workEndDate!);
          } catch (e) {
            debugPrint('⚠️ Error parsing end date: ${exp.workEndDate}');
          }
        }

        entry.currentJob = exp.isCurrentJob ?? false;
        return entry;
      }).toList();
    }

    // Load skills from user object
    if (user.hardSkills != null) {
      _hardSkills = user.hardSkills!
          .map((skill) => skill.skill ?? '')
          .where((skill) => skill.isNotEmpty)
          .toList();
    }
    if (user.softSkills != null) {
      _softSkills = user.softSkills!
          .map((skill) => skill.skill ?? '')
          .where((skill) => skill.isNotEmpty)
          .toList();
    }
    if (user.toolsTechnologies != null) {
      _tools = user.toolsTechnologies!
          .map((tool) => tool.tool ?? '')
          .where((tool) => tool.isNotEmpty)
          .toList();
    }

    // Load optional info from user object
    if (user.languages != null) {
      _languages = user.languages!
          .map((lang) => lang.language ?? '')
          .where((lang) => lang.isNotEmpty)
          .toList();
    }
    if (user.hobbiesInterests != null && user.hobbiesInterests!.isNotEmpty) {
      final hobbies = user.hobbiesInterests!
          .map((hobby) => hobby.hobbyInterest ?? '')
          .where((hobby) => hobby.isNotEmpty)
          .toList();
      _hobbiesController.text = hobbies.join(', ');
    }

    debugPrint('✅ User data loaded successfully');
  }

  @override
  void dispose() {
    // Clean up all text controllers
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
    // Dispose step 2 controllers
    _companyController.dispose();
    _jobTitleController.dispose();
    _linkedInJobLinkController.dispose();
    _jobDescriptionController.dispose();
    // Dispose template page controller
    _templatePageController.dispose();

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
          onPressed: () => _handleBackNavigation(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          40, // Ensure minimum height minus padding
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Card(
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
                                    _buildStepIndicatorRow(),
                                    const SizedBox(height: 5),
                                    Text(
                                      _getStepTitle(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
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
                                  horizontal: 10,
                                ),
                                child: _buildStepContent(),
                              ),
                              // Navigation buttons - only show Continue button for steps before final
                              if (_currentStep < _totalSteps)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: button.CustomButton(
                                    text: "Continue",
                                    onPressed: _isCheckingCredits
                                        ? null
                                        : _handleContinue,
                                    isLoading: _isCheckingCredits,
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
          ],
        ),
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

  Widget _buildStepIndicatorRow() {
    if (_isUploadedResumeFlow) {
      // Uploaded resume flow: 3 steps
      return Row(
        children: [
          _buildStepIndicator(1, _currentStep == 1),
          _buildStepLine(_currentStep > 1),
          _buildStepIndicator(2, _currentStep == 2),
          _buildStepLine(_currentStep > 2),
          _buildStepIndicator(3, _currentStep == 3),
        ],
      );
    } else {
      // From scratch flow: 4 steps
      return Row(
        children: [
          _buildStepIndicator(1, _currentStep == 1),
          _buildStepLine(_currentStep > 1),
          _buildStepIndicator(2, _currentStep == 2),
          _buildStepLine(_currentStep > 2),
          _buildStepIndicator(3, _currentStep == 3),
          _buildStepLine(_currentStep > 3),
          _buildStepIndicator(4, _currentStep == 4),
        ],
      );
    }
  }

  Widget _buildStepContent() {
    if (_isUploadedResumeFlow) {
      // Uploaded resume flow: 3 steps
      switch (_currentStep) {
        case 1:
          return _buildStep2JobTargetingContent(); // Job Targeting
        case 2:
          return _buildStep3TemplateSelectionContent(); // Template Selection
        case 3:
          return _buildStep4ResumePreviewContent(); // Resume Preview
        default:
          return _buildStep2JobTargetingContent();
      }
    } else {
      // From scratch flow: 4 steps
      switch (_currentStep) {
        case 1:
          return _buildStep1ReviewContent(); // Profile Review
        case 2:
          return _buildStep2JobTargetingContent(); // Job Targeting
        case 3:
          return _buildStep3TemplateSelectionContent(); // Template Selection
        case 4:
          return _buildStep4ResumePreviewContent(); // Resume Preview
        default:
          return _buildStep1ReviewContent();
      }
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
        CustomTextField(
          controller: _companyController,
          labelText: 'Company Name',
          hintText: 'Apple',
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _jobTitleController,
          labelText: 'Job Title',
          hintText: 'Senior Engineer',
          isRequired: true,
          errorText: _jobTitleError,
          onChanged: (value) {
            if (_jobTitleError != null) {
              setState(() {
                _jobTitleError = null;
              });
            }
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _linkedInJobLinkController,
          labelText: 'Paste LinkedIn job link',
          hintText: 'Paste here',
          suffixIcon: const Icon(Icons.link, color: AppColors.textSecondary),
          onChanged: (value) {
            if (_jobTargetingError != null) {
              setState(() {
                _jobTargetingError = null;
              });
            }
          },
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _jobDescriptionController,
          labelText: 'Paste Job Description',
          hintText: 'Enter a description...',
          maxLines: 7,
          maxLength: 5000,
          showCharacterCount: true,
          onChanged: (value) {
            if (_jobTargetingError != null) {
              setState(() {
                _jobTargetingError = null;
              });
            }
          },
        ),
        if (_jobTargetingError != null) ...[
          const SizedBox(height: 8),
          Text(
            _jobTargetingError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep3TemplateSelectionContent() {
    final templates = [
      {'name': 'ATS Friendly', 'preview': 'assets/icons/ats.png'},
      {'name': 'Modern', 'preview': 'assets/icons/modern.png'},
      {'name': 'Professional', 'preview': 'assets/icons/resume-template.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 450,
          child: PageView.builder(
            controller: _templatePageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTemplateIndex = index;
              });
            },
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = index == _selectedTemplateIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () {
                    _templatePageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                template['preview']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.grey.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.description,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
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
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            templates.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _selectedTemplateIndex == index ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _selectedTemplateIndex == index
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep4ResumePreviewContent() {
    final resumeState = ref.watch(resumeProvider);
    final generatedResumeData = resumeState.generatedResumeData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 500,
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
          child: generatedResumeData != null
              ? _buildPdfPreview(generatedResumeData)
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: AppColors.primary,
                      ),
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
                        'Your resume will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 15),
        // Action buttons
        Row(
          children: [
            // Edit Resume button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: generatedResumeData != null ? _editResume : null,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'Edit Resume',
                  style: TextStyle(fontSize: 13),
                ),
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
            const SizedBox(width: 12),
            // Download button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradientHorizontal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: generatedResumeData != null
                      ? _downloadResume
                      : null,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text(
                    'Download PDF',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Done button - matches Edit Resume style
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showSaveDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  String _getTemplateName() {
    switch (_selectedTemplateIndex) {
      case 0:
        return 'ATS Friendly';
      case 1:
        return 'Modern';
      case 2:
        return 'Professional';
      default:
        return 'Professional';
    }
  }

  Future<void> _downloadResume() async {
    final resumeState = ref.read(resumeProvider);
    final generatedResumeData = resumeState.generatedResumeData;

    if (generatedResumeData != null && generatedResumeData.pdfBase64 != null) {
      try {
        // Decode base64 PDF
        final pdfBytes = base64Decode(generatedResumeData.pdfBase64!);

        // Generate unique filename with company, job title, and timestamp
        final companyName = _companyController.text.trim().replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '_',
        );
        final jobTitle = _jobTitleController.text.trim().replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '_',
        );
        final dateStr = DateTime.now().toString().split(' ')[0];
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        String fileName;
        if (companyName.isNotEmpty && jobTitle.isNotEmpty) {
          fileName =
              'resume_${companyName}_${jobTitle}_${dateStr}_$timestamp.pdf';
        } else if (jobTitle.isNotEmpty) {
          fileName = 'resume_${jobTitle}_${dateStr}_$timestamp.pdf';
        } else {
          fileName = 'resume_${dateStr}_$timestamp.pdf';
        }

        // Platform-specific handling
        if (kIsWeb) {
          // For web, we'll need to use a different approach
          // This is a placeholder - web download would need html library
          if (mounted) {
            showErrorSnackBar(
              context: context,
              message: 'Web download not yet implemented',
            );
          }
        } else if (Platform.isIOS || Platform.isAndroid) {
          // For mobile platforms, save to temp directory and share
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(pdfBytes);

          // Use share_plus to let user save or share the file
          final result = await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Resume - ${_getTemplateName()}',
            text: jobTitle.isNotEmpty
                ? 'Resume for $jobTitle position${companyName.isNotEmpty ? " at $companyName" : ""}'
                : 'My Resume',
            sharePositionOrigin: context.mounted
                ? Rect.fromLTWH(
                    0,
                    0,
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height / 2,
                  )
                : null,
          );

          if (mounted) {
            if (result.status == ShareResultStatus.success) {
              showSuccessSnackBar(
                context: context,
                message: 'Resume shared successfully!',
              );
            } else if (result.status == ShareResultStatus.dismissed) {
              // User dismissed the share sheet - this is not an error
              debugPrint('Share sheet dismissed');
            }
          }
        } else {
          // For desktop platforms (macOS, Windows, Linux)
          // Try to save to Downloads folder
          Directory? downloadsDir;

          if (Platform.isMacOS || Platform.isLinux) {
            final home = Platform.environment['HOME'];
            if (home != null) {
              downloadsDir = Directory('$home/Downloads');
            }
          } else if (Platform.isWindows) {
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null) {
              downloadsDir = Directory('$userProfile\\Downloads');
            }
          }

          // Fallback to documents directory if Downloads not found
          downloadsDir ??= await getApplicationDocumentsDirectory();

          final file = File(
            '${downloadsDir.path}${Platform.pathSeparator}$fileName',
          );
          await file.writeAsBytes(pdfBytes);

          if (mounted) {
            showSuccessSnackBar(
              context: context,
              message: 'Resume saved to: ${file.path}',
            );
          }
        }
      } catch (e) {
        debugPrint('Download error: $e');
        if (mounted) {
          showErrorSnackBar(
            context: context,
            message: 'Failed to download resume: ${e.toString()}',
          );
        }
      }
    } else {
      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'No resume data available',
        );
      }
    }
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
        // Graduation Date Picker
        Column(
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

                      // Ensure initialDate is not in the future
                      final now = DateTime.now();
                      final initialDate =
                          _graduationDate != null &&
                              _graduationDate!.isAfter(now)
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
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
        ),
        const SizedBox(height: 16),
        // Degree not completed checkbox
        Row(
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
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Degree not completed',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
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
    if (_isUploadedResumeFlow) {
      // Uploaded resume flow: 3 steps
      switch (_currentStep) {
        case 1:
          return 'Who\'s This Resume For?'; // Job Targeting
        case 2:
          return 'Choose Resume Style'; // Template Selection
        case 3:
          return 'Final Resume Preview'; // Resume Preview
        default:
          return 'Step $_currentStep';
      }
    } else {
      // From scratch flow: 4 steps
      switch (_currentStep) {
        case 1:
          return 'Review & Edit Your Profile information'; // Profile Review
        case 2:
          return 'Who\'s This Resume For?'; // Job Targeting
        case 3:
          return 'Choose Resume Style'; // Template Selection
        case 4:
          return 'Final Resume Preview'; // Resume Preview
        default:
          return 'Step $_currentStep';
      }
    }
  }

  String _getStepDescription() {
    if (_isUploadedResumeFlow) {
      // Uploaded resume flow: 3 steps
      switch (_currentStep) {
        case 1:
          return 'Help us tailor your resume to land your dream job!'; // Job Targeting
        case 2:
          return 'Pick a design that fits your personality or profession.'; // Template Selection
        case 3:
          return 'Your resume is ready! Download or make final adjustments.'; // Resume Preview
        default:
          return 'Complete this step to continue.';
      }
    } else {
      // From scratch flow: 4 steps
      switch (_currentStep) {
        case 1:
          return 'Here\'s an overview of your skills. Please feel free to edit or add at any time!'; // Profile Review
        case 2:
          return 'Help us tailor your resume to land your dream job!'; // Job Targeting
        case 3:
          return 'Pick a design that fits your personality or profession.'; // Template Selection
        case 4:
          return 'Your resume is ready! Download or make final adjustments.'; // Resume Preview
        default:
          return 'Complete this step to continue.';
      }
    }
  }

  bool _validateStep2() {
    setState(() {
      _jobTitleError = null;
      _jobTargetingError = null;
    });

    bool isValid = true;

    // Validate job title is mandatory
    if (_jobTitleController.text.trim().isEmpty) {
      setState(() {
        _jobTitleError = 'Job title is required';
      });
      isValid = false;
    }

    // Validate either LinkedIn link or job description is provided
    final hasLinkedInLink = _linkedInJobLinkController.text.trim().isNotEmpty;
    final hasJobDescription = _jobDescriptionController.text.trim().isNotEmpty;

    if (!hasLinkedInLink && !hasJobDescription) {
      setState(() {
        _jobTargetingError =
            'Please provide either a LinkedIn job link or job description';
      });
      isValid = false;
    }

    return isValid;
  }

  void _handleContinue() async {
    // Validate Job Targeting step before proceeding
    bool needsJobTargetingValidation = false;
    if (_isUploadedResumeFlow && _currentStep == 1) {
      // In uploaded flow, step 1 is Job Targeting
      needsJobTargetingValidation = true;
    } else if (!_isUploadedResumeFlow && _currentStep == 2) {
      // In scratch flow, step 2 is Job Targeting
      needsJobTargetingValidation = true;
    }

    if (needsJobTargetingValidation) {
      if (!_validateStep2()) {
        return;
      }
    }

    // When moving to resume preview step, generate the resume
    bool needsResumeGeneration = false;
    if (_isUploadedResumeFlow && _currentStep == 2) {
      // In uploaded flow, moving from step 2 (Template Selection) to step 3 (Resume Preview)
      needsResumeGeneration = true;
    } else if (!_isUploadedResumeFlow && _currentStep == 3) {
      // In scratch flow, moving from step 3 (Template Selection) to step 4 (Resume Preview)
      needsResumeGeneration = true;
    }

    if (needsResumeGeneration) {
      // Show loading state
      setState(() {
        _isCheckingCredits = true;
      });

      try {
        // Always fetch latest usage from API
        await ref.read(usageProvider.notifier).fetchUsageAllocation();

        // Get remaining resume count
        final remainingResumes =
            ref.read(usageProvider).usageAllocation?.remainingResumeCount ?? 0;

        // Hide loading state
        if (mounted) {
          setState(() {
            _isCheckingCredits = false;
          });
        }

        if (remainingResumes <= 0) {
          // Show dialog and redirect to plans
          if (mounted) {
            final shouldBuyPlan = await showConfirmationDialog(
              context: context,
              title: 'No Resume Credits',
              subtitle:
                  'You need resume credits to generate a resume. Purchase a plan to continue.',
              icon: Icons.info_outline,
              iconBackgroundColor: AppColors.primary,
              confirmText: 'View Plans',
              cancelText: 'Cancel',
              confirmButtonColor: AppColors.primary,
              confirmTextColor: AppColors.white,
            );

            if (shouldBuyPlan == true && mounted) {
              await context.push('/plans');
              // Refresh usage after returning from plans
              if (mounted) {
                await ref.read(usageProvider.notifier).fetchUsageAllocation();
              }
            }
          }
          return; // Stop here, don't generate resume
        }

        // Has credits, proceed with resume generation
        await _generateResume();
      } catch (e) {
        // Hide loading state on error
        if (mounted) {
          setState(() {
            _isCheckingCredits = false;
          });
        }
        if (mounted) {
          showErrorSnackBar(
            context: context,
            message: 'Failed to check credits: ${e.toString()}',
          );
        }
        return; // Stop here on error
      }
    }

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - navigate to generated resume
      final resumeState = ref.read(resumeProvider);
      if (resumeState.generatedResumeData != null) {
        // Navigate to resume display/download screen with the generated data
        if (mounted) {
          context.push(
            '/resume/preview',
            extra: resumeState.generatedResumeData,
          );
        }
      } else {
        // Show error if resume generation failed
        if (mounted) {
          showErrorSnackBar(
            context: context,
            message: 'Failed to generate resume. Please try again.',
          );
        }
      }
    }
  }

  // Helper function to format date as "Month YYYY"
  String _formatDateToMonthYear(DateTime? date) {
    if (date == null) return '';
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<File> _createUserDataJsonFile() async {
    // Compile all user data into a map
    final userData = <String, dynamic>{};
    final user = ref.read(authProvider).user!;

    // Personal details - only include non-empty fields
    final personalDetails = <String, dynamic>{};
    if (_fullNameController.text.trim().isNotEmpty) {
      personalDetails['name'] = _fullNameController.text.trim();
    }
    if (_completePhoneNumber.isNotEmpty) {
      personalDetails['phone'] = _completePhoneNumber;
    }
    if (_emailController.text.trim().isNotEmpty) {
      personalDetails['email'] = _emailController.text.trim();
    }
    if (_linkedInController.text.trim().isNotEmpty) {
      personalDetails['linkedin'] = _linkedInController.text.trim();
    }
    if (_websiteController.text.trim().isNotEmpty) {
      personalDetails['personal_website'] = _websiteController.text.trim();
    }
    if (personalDetails.isNotEmpty) {
      userData['personal'] = personalDetails;
    }

    // Summary - only include if not empty
    final summary = user.professionalSummary ?? '';
    if (summary.isNotEmpty) {
      userData['summary'] = summary;
    }

    // Work experience - only include entries with actual data
    final workExperienceList = _workExperiences
        .where((exp) {
          // Only include if has job title or company
          return exp.jobTitle.text.trim().isNotEmpty ||
              exp.company.text.trim().isNotEmpty;
        })
        .map((exp) {
          final workExp = <String, dynamic>{};

          // Only include non-empty fields
          final role = exp.jobTitle.text.trim();
          if (role.isNotEmpty) {
            workExp['role'] = role;
          }

          final company = exp.company.text.trim();
          if (company.isNotEmpty) {
            workExp['company'] = company;
          }

          // Don't include location if empty

          final fromDate = _formatDateToMonthYear(exp.startDate);
          if (fromDate.isNotEmpty) {
            workExp['from_date'] = fromDate;
          }

          final toDate = exp.currentJob
              ? 'Current'
              : _formatDateToMonthYear(exp.endDate);
          if (toDate.isNotEmpty) {
            workExp['to_date'] = toDate;
          }

          // Split responsibilities by newline to create array
          final responsibilitiesText = exp.responsibilities.text.trim();
          if (responsibilitiesText.isNotEmpty) {
            final descriptionArray = responsibilitiesText
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList();
            if (descriptionArray.isNotEmpty) {
              workExp['description'] = descriptionArray;
            }
          }

          return workExp;
        })
        .toList();

    if (workExperienceList.isNotEmpty) {
      userData['work_experience'] = workExperienceList;
    }

    // Projects - only include if we have project data (currently not collected)
    // Don't include empty projects array

    // Skills - only include non-empty skill categories
    final skillsMap = <String, dynamic>{};
    if (_softSkills.isNotEmpty) {
      skillsMap['soft_skills'] = _softSkills;
    }
    if (_hardSkills.isNotEmpty) {
      skillsMap['hard_skills'] = _hardSkills;
    }
    if (_tools.isNotEmpty) {
      skillsMap['tools_and_technologies'] = _tools;
    }
    if (skillsMap.isNotEmpty) {
      userData['skills'] = skillsMap;
    }

    // Education - only include if has data
    if (_universityController.text.trim().isNotEmpty ||
        _degreeController.text.trim().isNotEmpty) {
      final educationEntry = <String, dynamic>{};

      final degree = _degreeController.text.trim();
      if (degree.isNotEmpty) {
        educationEntry['degree'] = degree;
      }

      final university = _universityController.text.trim();
      if (university.isNotEmpty) {
        educationEntry['university'] = university;
      }

      // Only include dates if graduation date exists
      if (_graduationDate != null) {
        final toDate = '${_graduationDate!.year}';
        final fromDate = '${_graduationDate!.year - 4}';
        educationEntry['from_date'] = fromDate;
        educationEntry['to_date'] = toDate;
      }

      // Don't include empty courses array

      if (educationEntry.isNotEmpty) {
        userData['education'] = [educationEntry];
      }
    }

    // Don't include certifications if empty
    // Don't include achievements if empty

    // Optional info - only include if has non-empty fields
    final optionalInfo = <String, dynamic>{};

    // Languages - only include if not empty
    if (_languages.isNotEmpty) {
      optionalInfo['languages'] = _languages;
    }

    // Volunteer work - only include if has data
    if (user.volunteerWork != null && user.volunteerWork!.isNotEmpty) {
      final volunteerWorkList = <String>[];
      for (var work in user.volunteerWork!) {
        final role = work.role ?? '';
        final org = work.organization ?? '';
        if (role.isNotEmpty && org.isNotEmpty) {
          volunteerWorkList.add('$role, $org');
        } else if (org.isNotEmpty) {
          volunteerWorkList.add(org);
        }
      }
      if (volunteerWorkList.isNotEmpty) {
        optionalInfo['volunteer_work'] = volunteerWorkList;
      }
    }

    // Hobbies - only include if not empty
    final hobbiesText = _hobbiesController.text.trim();
    if (hobbiesText.isNotEmpty) {
      final hobbiesArray = hobbiesText
          .split(',')
          .map((hobby) => hobby.trim())
          .where((hobby) => hobby.isNotEmpty)
          .toList();
      if (hobbiesArray.isNotEmpty) {
        optionalInfo['hobbies_and_interests'] = hobbiesArray;
      }
    }

    // References - only include if user has references (don't add default)
    if (user.references != null && user.references!.isNotEmpty) {
      optionalInfo['references'] = [user.references!];
    }

    // Only include optional_info if it has any data
    if (optionalInfo.isNotEmpty) {
      userData['optional_info'] = optionalInfo;
    }

    // Keywords - only include if has skills
    final allSkills = <String>[];
    allSkills.addAll(_hardSkills);
    allSkills.addAll(_softSkills);
    allSkills.addAll(_tools);
    if (allSkills.isNotEmpty) {
      final keywords = allSkills.join(', ');
      if (keywords.isNotEmpty) {
        userData['keywords'] = keywords;
      }
    }

    // Convert to JSON string
    final jsonString = jsonEncode(userData);

    debugPrint('📄 Resume JSON created: ${jsonString.substring(0, 200)}...');

    // Create a temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/user_resume_data.json');
    await file.writeAsString(jsonString);

    return file;
  }

  Future<void> _generateResume() async {
    try {
      // Show loading screen with animation
      final loadingKey = GlobalKey<ResumeGenerationLoadingScreenState>();
      final loadingRoute = PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ResumeGenerationLoadingScreen(
              key: loadingKey,
              onAnimationComplete: () {
                // Animation complete callback - do nothing here as we handle it manually
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        barrierDismissible: false,
        opaque: false,
        barrierColor: Colors.black54,
      );

      Navigator.of(context).push(loadingRoute);

      // Get the file to use for resume generation
      File resumeFile;
      final resumeState = ref.read(resumeProvider);

      if (_isUploadedResumeFlow && resumeState.uploadedFile != null) {
        // Use the uploaded PDF/DOCX file directly
        resumeFile = resumeState.uploadedFile!;
      } else {
        // Create JSON file from user data for scratch flow
        resumeFile = await _createUserDataJsonFile();
      }

      // Map template index to API template value
      String templateValue = 'resume'; // default
      switch (_selectedTemplateIndex) {
        case 0:
          templateValue = 'ats';
          break;
        case 1:
          templateValue = 'modern';
          break;
        case 2:
          templateValue = 'resume';
          break;
      }

      // Get job URL or description
      final jobUrl = _linkedInJobLinkController.text.trim();
      final jobDescription = _jobDescriptionController.text.trim();

      // Call the API to generate resume
      final result = await ref
          .read(resumeProvider.notifier)
          .generateResume(
            file: resumeFile,
            jobUrl: jobUrl.isNotEmpty ? jobUrl : null,
            jobDescription: jobDescription.isNotEmpty ? jobDescription : null,
            template: templateValue,
          );

      // Complete the loading animation before closing
      if (mounted && loadingKey.currentState != null) {
        loadingKey.currentState!.completeAnimation();
        // Wait for animation to complete
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result != null) {
        // Success - the resume data is stored in the provider
        if (mounted) {
          showSuccessSnackBar(
            context: context,
            message: '${_getTemplateName()} resume generated successfully!',
          );
        }
      } else {
        // Error occurred
        final error = ref.read(resumeProvider).error;
        if (mounted) {
          showErrorSnackBar(
            context: context,
            message: error ?? 'Failed to generate resume',
          );
        }
      }

      // Clean up temp file (only for scratch flow - uploaded files should not be deleted)
      if (!_isUploadedResumeFlow) {
        try {
          await resumeFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        showErrorSnackBar(context: context, message: 'Error: ${e.toString()}');
      }
    }
  }

  Widget _buildPdfPreview(dynamic generatedResumeData) {
    try {
      if (generatedResumeData != null &&
          generatedResumeData.pdfBase64 != null &&
          generatedResumeData.pdfBase64!.isNotEmpty) {
        final pdfBytes = base64Decode(generatedResumeData.pdfBase64!);
        // Get version from provider for unique keys
        final resumeVersion = ref.watch(resumeProvider).resumeVersion;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: Column(
            children: [
              // Header with template info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getTemplateName()} Resume Generated!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // PDF preview area with gesture detector for full screen
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFullScreenPdf(pdfBytes),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          // PDF viewer widget - Use version as key to force rebuild
                          _DynamicPdfViewer(
                            key: ValueKey('resume_v$resumeVersion'),
                            pdfBytes: pdfBytes,
                            version: resumeVersion,
                          ),
                          // Overlay with PDF info and tap hint
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Size: ${_formatFileSize(pdfBytes.length)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.fullscreen,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tap to view',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error displaying PDF preview: $e');
    }

    // Fallback if PDF preview fails
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          SizedBox(height: 12),
          Text(
            'PDF Preview Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Unable to preview PDF. Download to view.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFullScreenPdf(Uint8List pdfBytes) {
    // Create a controller outside the dialog for proper control
    final pdfController = PdfViewerController();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    // Full screen PDF viewer
                    SfPdfViewer.memory(
                      pdfBytes,
                      key: ValueKey(pdfBytes.hashCode),
                      controller: pdfController,
                      canShowPaginationDialog: false,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                      pageSpacing: 4.0,
                    ),
                    // Top bar with close and download buttons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Close button
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            // Title
                            Text(
                              '${_getTemplateName()} Resume',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Download button
                            IconButton(
                              onPressed: _downloadResume,
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Zoom controls - bottom right
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Zoom in button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                                onTap: () {
                                  // Zoom in using Syncfusion API
                                  final newZoom =
                                      (pdfController.zoomLevel * 1.2).clamp(
                                        0.5,
                                        3.0,
                                      );
                                  pdfController.zoomLevel = newZoom;
                                  setState(
                                    () {},
                                  ); // Trigger UI update for zoom indicator
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              width: 48,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            // Reset zoom button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Reset to 100% zoom using Syncfusion API
                                  pdfController.zoomLevel = 1.0;
                                  setState(
                                    () {},
                                  ); // Trigger UI update for zoom indicator
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.fit_screen,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              width: 48,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            // Zoom out button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                                onTap: () {
                                  // Zoom out using Syncfusion API
                                  final newZoom =
                                      (pdfController.zoomLevel / 1.2).clamp(
                                        0.5,
                                        3.0,
                                      );
                                  pdfController.zoomLevel = newZoom;
                                  setState(
                                    () {},
                                  ); // Trigger UI update for zoom indicator
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Zoom indicator - bottom left
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${(pdfController.zoomLevel * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _editResume() {
    final resumeState = ref.read(resumeProvider);
    final generatedResumeData = resumeState.generatedResumeData;

    if (generatedResumeData != null) {
      // Get job context from the form fields
      final jobUrl = _linkedInJobLinkController.text.trim();
      final jobDescription = _jobDescriptionController.text.trim();

      // Map template index to API template value
      String templateValue = 'resume'; // default
      switch (_selectedTemplateIndex) {
        case 0:
          templateValue = 'ats';
          break;
        case 1:
          templateValue = 'modern';
          break;
        case 2:
          templateValue = 'resume';
          break;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        isDismissible: false,
        builder: (context) => ResumeEditModal(
          resumeData: generatedResumeData,
          jobUrl: jobUrl.isNotEmpty ? jobUrl : null,
          jobDescription: jobDescription.isNotEmpty ? jobDescription : null,
          template: templateValue,
          onResumeUpdated: (updatedResume) {
            // Update the resume data and regenerate PDF
            _handleResumeUpdate(updatedResume);
          },
        ),
      );
    }
  }

  void _handleResumeUpdate(dynamic updatedResumeData) {
    print('🔄 _handleResumeUpdate called');
    print('📋 Updated PDF length: ${updatedResumeData.pdfBase64?.length ?? 0}');

    // Update the provider with new data (already contains updated PDF)
    ref.read(resumeProvider.notifier).updateGeneratedResume(updatedResumeData);

    print('✅ Provider updated with new resume data');

    // Refresh the UI to show updated data
    setState(() {});

    // Show success message
    showSuccessSnackBar(
      context: context,
      message: 'Resume updated successfully',
    );
  }

  void _handleBackNavigation() {
    // Check if we're on the final step with a generated resume
    final isOnFinalStep = _currentStep == _totalSteps;
    final resumeState = ref.read(resumeProvider);
    final hasGeneratedResume = resumeState.generatedResumeData != null;

    if (isOnFinalStep && hasGeneratedResume) {
      // Show save dialog before leaving
      _showSaveDialog(context);
    } else if (_currentStep > 1) {
      // Go to previous step
      setState(() {
        _currentStep--;
      });
    } else {
      // At step 1, go back to previous screen
      context.pop();
    }
  }

  void _showSaveDialog(BuildContext parentContext) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside
      builder: (BuildContext dialogContext) {
        return _SaveDialog(
          onSave: () async {
            final success = await _saveResumeAndNavigateBack();
            if (mounted && success && parentContext.mounted) {
              Navigator.of(dialogContext).pop(); // Close dialog
              parentContext.pop(); // Navigate back
            }
          },
          onDontSave: () {
            Navigator.of(dialogContext).pop(); // Close dialog
            if (parentContext.mounted) {
              parentContext.pop(); // Navigate back without saving
            }
          },
        );
      },
    );
  }

  Future<bool> _saveResumeAndNavigateBack() async {
    // Call save API
    final result = await ref
        .read(resumeProvider.notifier)
        .saveGeneratedResume(
          companyName: _companyController.text.trim(),
          jobTitle: _jobTitleController.text.trim(),
          linkedinJobUrl: _linkedInJobLinkController.text.trim(),
          jobDescription: _jobDescriptionController.text.trim(),
        );

    if (result != null && mounted) {
      // Success
      showSuccessSnackBar(
        context: context,
        message: 'Resume saved successfully!',
      );
      return true;
    } else if (mounted) {
      // Error
      final error = ref.read(resumeProvider).error;
      showErrorSnackBar(
        context: context,
        message: error ?? 'Failed to save resume',
      );
      return false;
    }
    return false;
  }
}

class _SaveDialog extends StatefulWidget {
  final Future<void> Function() onSave;
  final VoidCallback onDontSave;

  const _SaveDialog({required this.onSave, required this.onDontSave});

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.save_outlined, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Text(
            'Save Your Resume?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Would you like to save your resume for future use?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'You can access it later from your saved resumes.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      actions: [
        // Don't Save button
        TextButton(
          onPressed: _isLoading ? null : widget.onDontSave,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(100, 44),
          ),
          child: Text(
            "Don't Save",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        // Save & Exit button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLoading
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(120, 44),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save & Exit',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave();
    } catch (e) {
      // If error occurs, stop loading but keep dialog open
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _DynamicPdfViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  final int version;

  const _DynamicPdfViewer({
    super.key,
    required this.pdfBytes,
    required this.version,
  });

  @override
  State<_DynamicPdfViewer> createState() => _DynamicPdfViewerState();
}

class _DynamicPdfViewerState extends State<_DynamicPdfViewer> {
  late final PdfViewerController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 Building PDF viewer with version: ${widget.version}');
    print('📄 PDF bytes length: ${widget.pdfBytes.length}');

    return Container(
      color: Colors.grey[100],
      child: SfPdfViewer.memory(
        widget.pdfBytes,
        key: ValueKey(
          'pdf_viewer_v${widget.version}_${widget.pdfBytes.hashCode}',
        ),
        controller: _pdfController,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        pageSpacing: 4.0,
      ),
    );
  }
}
