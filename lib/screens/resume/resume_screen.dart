import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/common/custom_app_bar.dart';

class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState = ref.watch(resumeProvider);

    ref.listen<ResumeState>(resumeProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }

      if (next.uploadedFile != null && previous?.uploadedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File selected: ${next.uploadedFile!.path.split('/').last}',
            ),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Upload',
              textColor: AppColors.white,
              onPressed: () {
                ref.read(resumeProvider.notifier).uploadResume();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxLogo(),
        actions: [
          AppBarWidgets.historyButton(
            onPressed: () {
              // TODO: Navigate to resume history
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Ready to Out Fox your Resume?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  '"Scout the Fox will use AI magic to help you stand out"',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _buildUploadResumeCard(context, ref, resumeState),
                const SizedBox(height: 20),
                _buildCreateResumeCard(context),
              ],
            ),
          ),
        ],
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
          const SizedBox(height: 24),
          const Text(
            'Choose resume file to upload',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported Files: pdf or docx (max. 10mb)',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
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
                  Text(
                    resumeState.isLoading ? 'Loading...' : 'Upload Resume',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
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

  Widget _buildCreateResumeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/icons/resume-add.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Build resume from scratch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your skills and Scout will guide you',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                _handleCreateResume(context);
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
                  Text(
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

  void _handleUploadResume(BuildContext context, WidgetRef ref) {
    ref.read(resumeProvider.notifier).pickResumeFile();
    // After file is selected, navigate to review screen
    context.push('/resume/review');
  }

  void _handleCreateResume(BuildContext context) {
    // Navigate to review screen to use existing profile data
    context.push('/resume/review');
  }
}
