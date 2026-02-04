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
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';

class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  ConsumerState<PracticeSetupScreen> createState() =>
      _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _roleIndustryController = TextEditingController();

  bool _isCheckingCredits = false;

  // Error state variables
  String? _roleIndustryError;
  String? _companyError;
  String? _jobDescriptionError;
  String? _resumeError;

  @override
  void initState() {
    super.initState();

    // CLEAN STATE: Invalidate providers to ensure fresh start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(continuousTranscriptionProvider);
      ref.invalidate(interviewSessionProvider);
      print(
        '[PRACTICE-SETUP] Providers invalidated - fresh start for practice session',
      );
    });
  }

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

  Future<void> _validateAndContinue() async {
    setState(() {
      // Clear all errors first
      _roleIndustryError = null;
      _companyError = null;
      _jobDescriptionError = null;
      _resumeError = null;

      // Check required fields - only Job Title is required
      if (_roleIndustryController.text.trim().isEmpty) {
        _roleIndustryError = 'Please enter your job title';
      }
    });

    // If any errors exist, don't proceed
    if (_roleIndustryError != null) {
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
            title: 'No Practice Credits',
            subtitle:
                'You need credits to start a practice session. Purchase a plan to continue.',
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
        return;
      }

      // All validation passed, save data to provider and navigate
      final provider = ref.read(interviewSessionProvider.notifier);

      // Save the setup data to the provider
      // Use 'interview-prep' type for practice mode
      provider.updateSetupData(
        positionTitle: _roleIndustryController.text.trim(),
        companyName: _companyController.text.trim(),
        jobDescription: _jobDescriptionController.text.trim(),
        meetingAgenda: '',
        languageSelector: 'English',
        interviewType: 'interview-prep',
        roleIndustry: _roleIndustryController.text.trim(),
      );

      // Navigate to practice session screen
      if (mounted) {
        context.push('/practice/session');
      }
    } catch (e) {
      // Hide loading state on error
      if (mounted) {
        setState(() {
          _isCheckingCredits = false;
        });
      }
    }
  }

  void _clearFieldError(String field) {
    setState(() {
      switch (field) {
        case 'roleIndustry':
          _roleIndustryError = null;
          break;
        case 'company':
          _companyError = null;
          break;
        case 'jobDescription':
          _jobDescriptionError = null;
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
      appBar: const BackNavigationAppBar(title: 'Practice with Scout'),
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
                      const SizedBox(height: 20),
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
          'Practice Interview\nwith Scout',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scout will ask you interview questions and provide feedback on your answers to help you improve.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The more details you provide, the more tailored your practice will be. Add company and job description for best results!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resume Selection
        ..._buildResumeSelector(),

        // Job Title (Required)
        CustomTextField(
          controller: _roleIndustryController,
          hintText: 'e.g. Software Engineer, Product Manager',
          labelText: 'Job Title *',
          errorText: _roleIndustryError,
          onChanged: (value) {
            _clearFieldError('roleIndustry');
          },
        ),
        const SizedBox(height: 10),

        // Company Name (Optional)
        CustomTextField(
          controller: _companyController,
          hintText: 'e.g. Google, Amazon, Startup',
          labelText: 'Company Name (Optional)',
          errorText: _companyError,
          onChanged: (value) {
            _clearFieldError('company');
          },
        ),
        const SizedBox(height: 10),

        // Job Description (Optional)
        CustomTextField(
          controller: _jobDescriptionController,
          hintText: 'Paste the job description for more tailored questions',
          labelText: 'Job Description (Optional)',
          maxLines: 6,
          textInputAction: TextInputAction.done,
          errorText: _jobDescriptionError,
          onChanged: (value) {
            _clearFieldError('jobDescription');
          },
        ),
        const SizedBox(height: 10),
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

    // Display "Profile Resume" if profile resume is selected
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
                    'Choose a resume to help Scout ask more relevant questions based on your experience.',
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 4),
                preferBelow: true,
                margin: const EdgeInsets.symmetric(horizontal: 10),
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
              _unfocusAllFields();
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
                          ? 'Analyzing your resume...'
                          : displayTitle ??
                                (historyState.isLoading
                                    ? 'Loading resumes...'
                                    : 'Select or upload a resume (optional)'),
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

          // Error message
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
            provider.extractResumeFromUrl(resumeUrl);
          } else if (resumeTitle != null &&
              profileResumeFileName == resumeTitle) {
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

              provider.updateSetupData(
                selectedResumeId: null,
                selectedResumeTitle: fileName,
              );

              provider.extractResumeFromFile(file);
              _clearFieldError('resume');
            }
          }
        },
      ),
    );
  }

  Widget _buildStartSessionButton() {
    final isExtractingResume = ref
        .watch(interviewSessionProvider)
        .isExtractingResume;
    final isDisabled = _isCheckingCredits || isExtractingResume;

    return CustomButton(
      text: isExtractingResume ? 'Analyzing resume...' : 'Start Practice',
      onPressed: isDisabled ? null : _validateAndContinue,
      isLoading: _isCheckingCredits,
    );
  }
}

// Reusable bottom sheet for resume picker
class _ResumePickerBottomSheet extends ConsumerWidget {
  final String? selectedResumeTitle;
  final String? profileResumeFileName;
  final Function(int?, String?, String?) onResumeSelected;
  final VoidCallback onUploadResume;

  const _ResumePickerBottomSheet({
    required this.selectedResumeTitle,
    required this.onResumeSelected,
    required this.onUploadResume,
    this.profileResumeFileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final resumes = historyState.resumes;
    final isLoading = historyState.isLoading;

    final screenHeight = MediaQuery.of(context).size.height;
    final hasProfileResume =
        profileResumeFileName != null && profileResumeFileName!.isNotEmpty;

    // Filter out duplicates
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
                  'Choose a resume to help Scout ask more relevant questions based on your experience.',
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

          // Divider
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
