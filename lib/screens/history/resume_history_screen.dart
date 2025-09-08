import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../utils/s3_utils.dart';

class ResumeHistoryScreen extends ConsumerWidget {
  const ResumeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          historyState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : historyState.resumes.isEmpty
              ? _buildEmptyState()
              : _buildResumeList(historyState, context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No resume history yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your generated resumes will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeList(HistoryState historyState, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historyState.resumes.length,
      itemBuilder: (context, index) {
        final resume = historyState.resumes[index];
        return _buildResumeCard(resume, context);
      },
    );
  }

  Widget _buildResumeCard(ResumeHistory resume, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Open resume URL if available
            if (resume.resumeUrl.isNotEmpty) {
              // Check if it's an S3 filename or a full URL
              String urlString = resume.resumeUrl;
              if (!urlString.startsWith('http')) {
                // It's an S3 filename, construct the full URL
                urlString = S3Utils.constructAssetUrl(resume.resumeUrl);
              }

              final Uri url = Uri.parse(urlString);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open resume'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            } else {
              // Fallback to navigation if URL is not available
              context.push('/resume/review?id=${resume.id}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(resume),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(ResumeHistory resume) {
    final company = resume.companyName.isNotEmpty
        ? resume.companyName
        : resume.jobTitle.isNotEmpty
        ? resume.jobTitle
        : 'Resume';
    return '$company, ${_formatDate(resume.createdAt)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
