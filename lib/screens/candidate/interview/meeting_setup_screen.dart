import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/continuous_transcription_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/interview_session_provider.dart';
import '../../../providers/resume_provider.dart';
import '../../../providers/usage_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_picker_field.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/dialogs/ai_consent_dialog.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';

class MeetingSetupScreen extends ConsumerStatefulWidget {
  const MeetingSetupScreen({super.key});

  @override
  ConsumerState<MeetingSetupScreen> createState() => _State();
}

class _State extends ConsumerState<MeetingSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _roleIndustryController = TextEditingController();
  final TextEditingController _meetingAgendaController =
      TextEditingController();

  String? _selectedSessionType = 'Meeting'; // Default to Meeting
  final String _selectedLanguage = 'English'; // Default to English for now
  bool _realTimeTranscription = true;
  bool _followUpQuestions = false;
  bool _summaryGeneration = true;
  bool _isCheckingCredits = false; // Loading state for credit check

  // Error state variables
  String? _sessionTypeError;
  String? _roleIndustryError;
  String? _companyError;
  String? _jobDescriptionError;
  String? _meetingAgendaError;
  String? _languageError;
  String? _resumeError;

  final List<String> _sessionTypes = ['Interview', 'Meeting'];

  final List<String> _languages = ['English'];

  @override
  void initState() {
    super.initState();

    // CLEAN STATE: Invalidate providers to ensure fresh start
    // This is the entry point for starting a NEW session
    // User's intent to start new session is clear when they reach this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(continuousTranscriptionProvider);
      ref.invalidate(interviewSessionProvider);
      print(
        '[SETUP-SCREEN] ✅ Providers invalidated - fresh start for new session',
      );
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobDescriptionController.dispose();
    _roleIndustryController.dispose();
    _meetingAgendaController.dispose();
    super.dispose();
  }

  void unFocusAllFields() {
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
      _resumeError = null;

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

    // Show loading state
    setState(() {
      _isCheckingCredits = true;
    });

    try {
      // Always fetch latest usage from API
      await ref.read(usageProvider.notifier).fetchUsageAllocation();

      // Get remaining interview count
      final remainingInterviews =
          ref.read(usageProvider).usageAllocation?.remainingInterviewCount ?? 0;

      // Hide loading state
      if (mounted) {
        setState(() {
          _isCheckingCredits = false;
        });
      }

      if (remainingInterviews <= 0) {
        // Show dialog and redirect to plans
        if (mounted) {
          final shouldBuyPlan = await showConfirmationDialog(
            context: context,
            title: 'No Meeting Credits',
            subtitle:
                'You need meeting credits to start a session. Purchase a plan to continue.',
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
        return; // Stop here, don't proceed to session
      }

      // All validation passed, save data to provider and navigate
      final provider = ref.read(interviewSessionProvider.notifier);

      // Save the setup data to the provider (resume data is already in provider)
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
        languageSelector: _selectedLanguage,
        interviewType: _selectedSessionType,
        roleIndustry: _roleIndustryController.text.trim(),
      );

      // Check AI third-party data consent compliance before proceeding to session
      if (!mounted) return;
      final consentGranted = await AIConsentDialog.showIfNeeded(context, isResume: false);
      if (!consentGranted) {
        if (mounted) {
          setState(() {
            _isCheckingCredits = false;
          });
        }
        return;
      }

      // Navigate to session screen
      if (mounted) {
        context.push('/meeting/session');
      }
    } catch (e) {
      // Hide loading state on error
      if (mounted) {
        setState(() {
          _isCheckingCredits = false;
        });
      }
      // Error will be handled by the provider
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
        case 'resume':
          _resumeError = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: const BackNavigationAppBar(title: 'Start Meeting Assistant'),
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
                      //_buildScoutTipBanner(),
                      // SizedBox(height: 20),
                      //_buildSessionSettings(),
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
          'Boost Your Meeting\nSkills with AI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your session real-time coaching,smart feedback, and role-based insights included.',
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
            unFocusAllFields();
          },
          child: CustomPickerField(
            labelText: 'Session Type',
            value: _selectedSessionType,
            items: _sessionTypes,
            hintText: 'Select Options',
            errorText: _sessionTypeError,
            onChanged: (value) {
              unFocusAllFields();
              _clearFieldError('sessionType');
              _selectedSessionType = value;
              // Clear fields when session type changes
              if (value?.toLowerCase() == 'meeting') {
                _companyController.clear();
                _jobDescriptionController.clear();
                _companyError = null;
                _jobDescriptionError = null;
                _resumeError = null;
                // Clear resume selection via provider
                ref
                    .read(interviewSessionProvider.notifier)
                    .clearResumeSelection();
              } else if (value?.toLowerCase() == 'interview') {
                _meetingAgendaController.clear();
                _meetingAgendaError = null;
              }
            },
          ),
        ),
        const SizedBox(height: 10),

        // Resume Selection - Only show for Interview type
        if (_selectedSessionType?.toLowerCase() == 'interview')
          ..._buildResumeSelector(),

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

  List<Widget> _buildResumeSelector() {
    final historyState = ref.watch(historyProvider);
    final sessionState = ref.watch(interviewSessionProvider);
    final selectedResumeTitle = sessionState.selectedResumeTitle;
    final isExtractingResume = sessionState.isExtractingResume;

    // Check if selected resume is the profile resume
    final user = ref.watch(authProvider).user;
    final profileResumeFileName = user?.resumeFileName?.toString();
    final isProfileResumeSelected =
        selectedResumeTitle != null &&
        profileResumeFileName != null &&
        selectedResumeTitle == profileResumeFileName;

    // Display "Profile Resume" if profile resume is selected, otherwise show the title
    final displayTitle = isProfileResumeSelected
        ? 'Profile Resume'
        : selectedResumeTitle;

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with info icon
          Row(
            children: [
              const Text(
                'Choose Resume',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message:
                    'Choose a resume to help the AI provide more personalized answers based on your experience.',
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 4),
                preferBelow: true,
                margin: EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.3,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Picker Field
          GestureDetector(
            onTap: () {
              unFocusAllFields();
              HapticFeedback.lightImpact();
              _showResumePickerBottomSheet();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _resumeError != null
                      ? AppColors.error
                      : AppColors.inputBorder,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  if (isExtractingResume)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      isExtractingResume
                          ? 'Analyzing your resume for personalized answers...'
                          : displayTitle ??
                                (historyState.isLoading
                                    ? 'Loading resumes...'
                                    : 'Select or upload a resume'),
                      style: TextStyle(
                        color: selectedResumeTitle != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Error message (validation error)
          if (_resumeError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                _resumeError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 10),
    ];
  }

  void _showResumePickerBottomSheet() {
    // Refresh history to get latest resumes
    ref.read(historyProvider.notifier).refreshHistory();

    // Get user's profile resume filename from auth provider
    final user = ref.read(authProvider).user;
    final profileResumeFileName = user?.resumeFileName?.toString();
    final sessionState = ref.read(interviewSessionProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResumePickerBottomSheet(
        selectedResumeTitle: sessionState.selectedResumeTitle,
        profileResumeFileName: profileResumeFileName,
        onResumeSelected: (resumeId, resumeTitle, resumeUrl) {
          _clearFieldError('resume');
          final provider = ref.read(interviewSessionProvider.notifier);

          // Update the selected resume in provider
          provider.updateSetupData(
            selectedResumeId: resumeId,
            selectedResumeTitle: resumeTitle,
          );

          // Trigger extraction based on resume type
          if (resumeUrl != null && resumeUrl.isNotEmpty) {
            // History resume - use the resumeUrl directly
            provider.extractResumeFromUrl(resumeUrl);
          } else if (resumeTitle != null &&
              profileResumeFileName == resumeTitle) {
            // Profile resume - construct URL from S3 filename
            provider.extractResumeFromS3FileName(resumeTitle);
          }
        },
        onUploadResume: () async {
          Navigator.pop(context);
          final resumeNotifier = ref.read(resumeProvider.notifier);
          final success = await resumeNotifier.pickResumeFile();
          if (success && mounted) {
            final file = ref.read(resumeProvider).uploadedFile;
            if (file != null) {
              final provider = ref.read(interviewSessionProvider.notifier);
              final fileName = file.path.split('/').last;

              // Update provider with uploaded file info
              provider.updateSetupData(
                selectedResumeId: null,
                selectedResumeTitle: fileName,
              );

              // Extract from the uploaded file
              provider.extractResumeFromFile(file);
              _clearFieldError('resume');
            }
          }
        },
      ),
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
        textInputAction: TextInputAction.done,
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
        maxLines: 6,
        textInputAction: TextInputAction.done,
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
    final isExtractingResume = ref
        .watch(interviewSessionProvider)
        .isExtractingResume;
    final isDisabled = _isCheckingCredits || isExtractingResume;

    return CustomButton(
      text: isExtractingResume ? 'Analyzing resume...' : 'Continue',
      onPressed: isDisabled ? null : _validateAndContinue,
      isLoading: _isCheckingCredits,
    );
  }
}

// Custom bottom sheet for resume picker with upload option
class _ResumePickerBottomSheet extends ConsumerWidget {
  final String? selectedResumeTitle;
  final String? profileResumeFileName;
  final Function(int?, String?, String?) onResumeSelected; // (id, title, url)
  final VoidCallback onUploadResume;

  const _ResumePickerBottomSheet({
    required this.selectedResumeTitle,
    required this.onResumeSelected,
    required this.onUploadResume,
    this.profileResumeFileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch history provider to get latest data and rebuild on changes
    final historyState = ref.watch(historyProvider);
    final resumes = historyState.resumes;
    final isLoading = historyState.isLoading;

    final screenHeight = MediaQuery.of(context).size.height;
    final hasProfileResume =
        profileResumeFileName != null && profileResumeFileName!.isNotEmpty;

    // Filter out history resumes that match the profile resume to avoid duplicates
    final filteredResumes = hasProfileResume
        ? resumes.where((r) => r.title != profileResumeFileName).toList()
        : resumes;

    final totalItems = filteredResumes.length + (hasProfileResume ? 1 : 0);
    final hasItems = totalItems > 0;

    return Container(
      height: screenHeight * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Resume',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  'Choose a resume to help the AI provide more personalized answers based on your experience.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Upload Resume Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onUploadResume();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Upload New Resume',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Divider with "Or select from your resumes" text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Or select from your resumes',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Resume list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasItems
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No resumes found',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a resume to get started',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      // First item: Profile resume (if exists)
                      if (hasProfileResume && index == 0) {
                        final isSelected =
                            selectedResumeTitle == profileResumeFileName;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            // Profile resume - pass null URL, will construct from S3 filename
                            onResumeSelected(null, profileResumeFileName, null);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Profile Resume',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Other items: Regular resumes
                      final resumeIndex = hasProfileResume ? index - 1 : index;
                      final resume = filteredResumes[resumeIndex];
                      final isSelected = resume.title == selectedResumeTitle;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // History resume - pass the resumeUrl
                          onResumeSelected(
                            resume.id,
                            resume.title,
                            resume.resumeUrl,
                          );
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resume.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (resume.jobTitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        resume.jobTitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
