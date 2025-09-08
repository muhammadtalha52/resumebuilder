import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_picker_field.dart';
import '../../widgets/common/custom_text_field.dart';
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
  String? _languageError;

  final List<String> _sessionTypes = ['Interview', 'Meeting'];

  final List<String> _languages = ['English'];

  @override
  void dispose() {
    _companyController.dispose();
    _jobDescriptionController.dispose();
    _roleIndustryController.dispose();
    super.dispose();
  }

  void _unfocusAllFields() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _validateAndContinue() {
    setState(() {
      // Clear all errors first
      _sessionTypeError = null;
      _roleIndustryError = null;
      _companyError = null;
      _jobDescriptionError = null;
      _languageError = null;

      // Check all required fields and set errors
      if (_selectedSessionType == null || _selectedSessionType!.isEmpty) {
        _sessionTypeError = 'Please select a session type';
      }

      if (_roleIndustryController.text.trim().isEmpty) {
        _roleIndustryError = 'Please enter your role/industry';
      }

      if (_companyController.text.trim().isEmpty) {
        _companyError = 'Please enter company name';
      }

      if (_jobDescriptionController.text.trim().isEmpty) {
        _jobDescriptionError = 'Please enter job description';
      }

      // Language validation commented out - defaulting to English
      // if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      //   _languageError = 'Please select a language';
      // }
    });

    // If any errors exist, don't proceed (language error removed)
    if (_sessionTypeError != null ||
        _roleIndustryError != null ||
        _companyError != null ||
        _jobDescriptionError != null) {
      return;
    }

    // All validation passed, navigate to next screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InterviewSessionScreen(
          sessionType: _selectedSessionType!,
          roleIndustry: _roleIndustryController.text.trim(),
          company: _companyController.text.trim(),
          jobDescription: _jobDescriptionController.text.trim(),
          language: _selectedLanguage!,
          realTimeTranscription: _realTimeTranscription,
          liveCoaching: _liveCoaching,
          followUpQuestions: _followUpQuestions,
          summaryGeneration: _summaryGeneration,
        ),
      ),
    );
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
                      SizedBox(height: 20),
                      _buildSessionSettings(),
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
              _buildSettingToggle(
                icon: Icons.chat_bubble_outline,
                title: 'Live Coaching',
                subtitle: 'Get guidance and structure in real time',
                value: _liveCoaching,
                onChanged: (value) {
                  setState(() {
                    _liveCoaching = value;
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
