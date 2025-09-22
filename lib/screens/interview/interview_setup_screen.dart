import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_picker_field.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/interview_session_provider.dart';
import '../../providers/auth_provider.dart';
import 'interview_session_screen.dart';

class InterviewSetupScreen extends ConsumerStatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  ConsumerState<InterviewSetupScreen> createState() =>
      _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends ConsumerState<InterviewSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _roleIndustryController = TextEditingController();
  final TextEditingController _meetingAgendaController =
      TextEditingController();

  String? _selectedSessionType;
  String? _selectedLanguage = 'English'; // Default to English for now
  bool _realTimeTranscription = true;
  bool _liveCoaching = false;
  bool _followUpQuestions = false;
  bool _summaryGeneration = true;

  // Error state variables
  String? _sessionTypeError;
  String? _roleIndustryError;
  String? _companyError;
  String? _jobDescriptionError;
  String? _meetingAgendaError;
  String? _languageError;

  final List<String> _sessionTypes = ['Interview', 'Meeting'];

  final List<String> _languages = ['English'];

  @override
  void initState() {
    super.initState();
    // Prefill form fields for testing
    _selectedSessionType = 'Interview';
    _roleIndustryController.text = 'Senior Flutter Developer';
    _companyController.text = 'Proxify';
    _jobDescriptionController.text =
        '''Talent has no borders. Proxify's mission is to connect top developers around the world with opportunities they deserve. So, it doesn't matter where you are; we are here to help you fast-track your independent career in the right direction. 🙂

Since our launch, Proxify's developers have successfully worked with 1200+ happy clients to build their products and growth features. 5000+ talented developers trust Proxify and its network to fulfill their dreams and objectives.

Proxify is shaped by a global network of supportive, talented developers interested in remote full-time jobs. Our Glassdoor (4.5/5) and Trustpilot (4.8/5) ratings reflect the trust developers place in us and our commitment to our members' success.

The Role:

We are looking for a Senior Flutter Developer for one of our clients. You are a perfect candidate if you are growth-oriented, you love what you do, and you enjoy working on new ideas to develop exciting products and growth features.

What we are looking for:

* 3 years of concentrated experience in Flutter
* 5+ years of experience in software development with a robust background in any framework/language/OS such as React Native, iOS (Swift), Android (Kotlin)
* Proven track record of deploying applications on Google Play/App Store using Flutter.
* Profound knowledge of front-end languages like HTML, CSS3, and JavaScript.
* Comprehensive understanding of Object-Oriented programming languages like Java and C++.
* Experience with version control tools (Git, Subversion, etc.) and IDEs (Android Studio, VS Code, etc.).
* A commitment to following best practices and conventions in software development.
* Ability to work independently with minimal supervision.
* Intermediate-advanced English level, with excellent communication skills for both technical and non-technical clients.
* Located in CET timezone (+/- 3 hours), we are unable to consider applications from candidates in other time zones.

Responsibilities:

* You will be building and shipping robust apps to Android/ iOS devices (using a single codebase).
* You will be running and designing product application features across various cross platform devices.
* You will be writing readable and clear code that will be extensively documented for future use and upgrades.
* You will be sharing feedback and brainstorming ideas with teams to improve the development process.
* You will put effort in staying up-to-date with the latest technologies.

What we offer:

Get paid, not played
No more unreliable clients. Enjoy on-time monthly payments with flexible withdrawal options.

Predictable project hours
Enjoy a harmonious work-life balance with consistent 8-hour working days with clients.

Flex days, so you can recharge
Enjoy up to 24 flex days off per year without losing pay, for full-time positions found through Proxify.

Career-accelerating positions at cutting-edge companies
Discover exclusive long-term remote positions at the world's most exciting companies.

Hand-picked opportunities, just for you
Skip the typical recruitment roadblocks and biases with personally matched positions.

One seamless process, multiple opportunities
A one-time contracting process for endless opportunities, with no extra assessments.

Compensation
Enjoy the same pay, every month with positions landed through Proxify.''';
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobDescriptionController.dispose();
    _roleIndustryController.dispose();
    _meetingAgendaController.dispose();
    super.dispose();
  }

  void _unfocusAllFields() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _validateAndContinue() async {
    setState(() {
      // Clear all errors first
      _sessionTypeError = null;
      _roleIndustryError = null;
      _companyError = null;
      _jobDescriptionError = null;
      _meetingAgendaError = null;
      _languageError = null;

      // Check all required fields and set errors
      if (_selectedSessionType == null || _selectedSessionType!.isEmpty) {
        _sessionTypeError = 'Please select a session type';
      }

      if (_roleIndustryController.text.trim().isEmpty) {
        _roleIndustryError = 'Please enter your role/industry';
      }

      // Conditional validation based on session type
      if (_selectedSessionType?.toLowerCase() == 'interview') {
        if (_companyController.text.trim().isEmpty) {
          _companyError = 'Please enter company name';
        }

        if (_jobDescriptionController.text.trim().isEmpty) {
          _jobDescriptionError = 'Please enter job description';
        }
      } else if (_selectedSessionType?.toLowerCase() == 'meeting') {
        if (_meetingAgendaController.text.trim().isEmpty) {
          _meetingAgendaError = 'Please enter meeting agenda';
        }
      }
    });

    // If any errors exist, don't proceed (language error removed)
    if (_sessionTypeError != null ||
        _roleIndustryError != null ||
        _companyError != null ||
        _jobDescriptionError != null ||
        _meetingAgendaError != null) {
      return;
    }

    // All validation passed, save data to provider and navigate
    final provider = ref.read(interviewSessionProvider.notifier);

    // Save the setup data to the provider
    provider.updateSetupData(
      positionTitle: _roleIndustryController.text.trim(),
      companyName: _selectedSessionType?.toLowerCase() == 'interview'
          ? _companyController.text.trim()
          : '',
      jobDescription: _selectedSessionType?.toLowerCase() == 'interview'
          ? _jobDescriptionController.text.trim()
          : '',
      meetingAgenda: _selectedSessionType?.toLowerCase() == 'meeting'
          ? _meetingAgendaController.text.trim()
          : '',
      languageSelector: _selectedLanguage ?? 'English',
      interviewType: _selectedSessionType,
      roleIndustry: _roleIndustryController.text.trim(),
    );

    // Navigate to session screen without API call
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const InterviewSessionScreen()),
      );
    }
  }

  void _clearFieldError(String field) {
    setState(() {
      switch (field) {
        case 'sessionType':
          _sessionTypeError = null;
          break;
        case 'roleIndustry':
          _roleIndustryError = null;
          break;
        case 'company':
          _companyError = null;
          break;
        case 'jobDescription':
          _jobDescriptionError = null;
          break;
        case 'meetingAgenda':
          _meetingAgendaError = null;
          break;
        case 'language':
          _languageError = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: const BackNavigationAppBar(title: 'Start Interview Assistant'),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 10),
                      _buildFormFields(),
                      SizedBox(height: 20),
                      _buildScoutTipBanner(),
                      // SizedBox(height: 20),
                      // _buildSessionSettings(),
                      SizedBox(height: 20),
                      _buildStartSessionButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Boost Your Interview\nSkills with AI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your session — real-time coaching,smart feedback, and role-based insights included.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session Type
        GestureDetector(
          onTap: () {
            _unfocusAllFields();
          },
          child: CustomPickerField(
            labelText: 'Session Type',
            value: _selectedSessionType,
            items: _sessionTypes,
            hintText: 'Select Options',
            errorText: _sessionTypeError,
            onChanged: (value) {
              _unfocusAllFields();
              _clearFieldError('sessionType');
              setState(() {
                _selectedSessionType = value;
                // Clear fields when session type changes
                if (value?.toLowerCase() == 'meeting') {
                  _companyController.clear();
                  _jobDescriptionController.clear();
                  _companyError = null;
                  _jobDescriptionError = null;
                } else if (value?.toLowerCase() == 'interview') {
                  _meetingAgendaController.clear();
                  _meetingAgendaError = null;
                }
              });
            },
          ),
        ),
        const SizedBox(height: 10),

        // Role/Industry
        CustomTextField(
          controller: _roleIndustryController,
          hintText: 'Type here',
          labelText: 'Role / Industry',
          errorText: _roleIndustryError,
          onChanged: (value) {
            _clearFieldError('roleIndustry');
          },
        ),
        const SizedBox(height: 10),

        // Conditional fields based on session type
        if (_selectedSessionType?.toLowerCase() == 'interview')
          ..._buildInterviewFields(),
        if (_selectedSessionType?.toLowerCase() == 'meeting')
          ..._buildMeetingFields(),

        // Language Selector - Commented out for now as we only support English
        // GestureDetector(
        //   onTap: () {
        //     FocusScope.of(context).requestFocus(FocusNode());
        //   },
        //   child: CustomPickerField(
        //     labelText: 'Language Selector',
        //     value: _selectedLanguage,
        //     items: _languages,
        //     hintText: 'Type here or select option',
        //     enableSearch: true,
        //     errorText: _languageError,
        //     onChanged: (value) {
        //       FocusScope.of(context).requestFocus(FocusNode());
        //       _clearFieldError('language');
        //       setState(() {
        //         _selectedLanguage = value;
        //       });
        //     },
        //   ),
        // ),
      ],
    );
  }

  List<Widget> _buildInterviewFields() {
    return [
      // Company Name
      CustomTextField(
        controller: _companyController,
        hintText: 'Type here',
        labelText: 'Company Name',
        errorText: _companyError,
        onChanged: (value) {
          _clearFieldError('company');
        },
      ),
      const SizedBox(height: 10),

      // Job Description
      CustomTextField(
        controller: _jobDescriptionController,
        hintText: 'Enter job description',
        labelText: 'Job Description',
        maxLines: 6,
        maxLength: 500,
        errorText: _jobDescriptionError,
        onChanged: (value) {
          _clearFieldError('jobDescription');
        },
      ),
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _buildMeetingFields() {
    return [
      // Meeting Agenda
      CustomTextField(
        controller: _meetingAgendaController,
        hintText: 'Enter meeting agenda',
        labelText: 'Meeting Agenda',
        maxLines: 4,
        maxLength: 300,
        errorText: _meetingAgendaError,
        onChanged: (value) {
          _clearFieldError('meetingAgenda');
        },
      ),
      const SizedBox(height: 10),
    ];
  }

  Widget _buildScoutTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF9800)], // Orange gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.zero,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/icons/fox-mascot.png', width: 30, height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text:
                        'Scout the Fox tip: Enable coaching for in-the-moment support!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSettingToggle(
                icon: Icons.mic,
                title: 'Real-Time Transcription',
                subtitle: 'Live voice-to-text display during your session',
                value: _realTimeTranscription,
                onChanged: (value) {
                  setState(() {
                    _realTimeTranscription = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              // _buildSettingToggle(
              //   icon: Icons.chat_bubble_outline,
              //   title: 'Live Coaching',
              //   subtitle: 'Get guidance and structure in real time',
              //   value: _liveCoaching,
              //   onChanged: (value) {
              //     setState(() {
              //       _liveCoaching = value;
              //     });
              //   },
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              _buildSettingToggle(
                icon: Icons.help_outline,
                title: 'Follow-Up Questions',
                subtitle: 'AI will prompt deeper questions when needed',
                value: _followUpQuestions,
                onChanged: (value) {
                  setState(() {
                    _followUpQuestions = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              _buildSettingToggle(
                icon: Icons.description_outlined,
                title: 'Summary Generation',
                subtitle: 'We\'ll wrap up your session with a smart overview',
                value: _summaryGeneration,
                onChanged: (value) {
                  setState(() {
                    _summaryGeneration = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (value) {
              FocusScope.of(context).requestFocus(FocusNode());
              onChanged(value);
            },
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.textSecondary.withValues(alpha: 0.3),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildStartSessionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _validateAndContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Continue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
