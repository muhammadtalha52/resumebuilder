import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to Out Fox your Resume?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '"Scout the Fox will use AI magic to help you stand out"',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 70,
                height: 85,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  size: 36,
                  color: AppColors.accent,
                ),
              ),
              Positioned(
                bottom: 15,
                right: 25,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose resume file to upload',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Supported Files: pdf or docx (max. 10mb)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: resumeState.isLoading ? 'Loading...' : 'Upload Resume',
            onPressed: resumeState.isLoading
                ? null
                : () {
                    _handleUploadResume(context, ref);
                  },
            isOutlined: true,
            icon: Icons.arrow_forward_ios,
            isLoading: resumeState.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateResumeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 70,
                height: 85,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description,
                  size: 36,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                bottom: 15,
                right: 25,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Build resume from scratch',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your skills and Scout will guide you',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Create Resume',
            onPressed: () {
              _handleCreateResume(context);
            },
            isOutlined: true,
            icon: Icons.arrow_forward_ios,
          ),
        ],
      ),
    );
  }

  void _handleUploadResume(BuildContext context, WidgetRef ref) {
    ref.read(resumeProvider.notifier).pickResumeFile();
  }

  void _handleCreateResume(BuildContext context) {
    // TODO: Navigate to create resume screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Resume functionality coming soon')),
    );
  }
}
