import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/resume_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/profile_completion_banner.dart';
import '../../../widgets/dialogs/ai_consent_dialog.dart';

class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState = ref.watch(resumeProvider);

    ref.listen<ResumeState>(resumeProvider, (previous, next) {
      // Handle errors
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next.error!)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "Resumes"),
        actions: [
          InkWell(
            onTap: () {
              context.push('/resume/history');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProfileCompletionBanner(),
              const SizedBox(height: 16),
              const Text(
                'Ready to Out Fox your Resume?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                '"Scout the Fox will use AI magic to help you stand out"',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildUploadResumeCard(context, ref, resumeState),
              const SizedBox(height: 20),
              _buildCreateResumeCard(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadResumeCard(
    BuildContext context,
    WidgetRef ref,
    ResumeState resumeState,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 110,
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/icons/resume-upload.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Have a Resume? Upload It',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Upload PDF or DOCX to enhance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 45,
            child: OutlinedButton(
              onPressed: resumeState.isLoading
                  ? null
                  : () {
                      _handleUploadResume(context, ref);
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (resumeState.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  if (resumeState.isLoading) const SizedBox(width: 8),
                  Text(
                    _getButtonText(resumeState),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                  if (!resumeState.isLoading) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildCreateResumeCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/icons/resume-add.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "No Resume? We'll Build It",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Using your profile information',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              onPressed: () {
                _handleCreateResume(context, ref);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Create Resume',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        
        ],
      ),
    );
  }

  String _getButtonText(ResumeState resumeState) {
    if (resumeState.isLoading) {
      return 'Selecting File...';
    } else {
      return 'Create Resume';
    }
  }

  void _handleUploadResume(BuildContext context, WidgetRef ref) async {
    final consentGranted = await AIConsentDialog.showIfNeeded(context, isResume: true);
    if (!consentGranted) return;

    // Reset any previous state before starting fresh session
    ref.read(resumeProvider.notifier).resetResumeState();
    // Pick file without parsing and navigate directly to review screen
    final success = await ref.read(resumeProvider.notifier).pickResumeFile();
    if (success && context.mounted) {
      context.push('/resume/review?flow=upload');
    }
  }

  void _handleCreateResume(BuildContext context, WidgetRef ref) async {
    final consentGranted = await AIConsentDialog.showIfNeeded(context, isResume: true);
    if (!consentGranted) return;

    // Reset any previous state before starting fresh session
    ref.read(resumeProvider.notifier).resetResumeState();
    // Set profile data mode before navigation
    ref.read(resumeProvider.notifier).loadProfileDataMode();
    // Navigate to review screen to use existing profile data
    context.push('/resume/review?flow=create');
  }
}
