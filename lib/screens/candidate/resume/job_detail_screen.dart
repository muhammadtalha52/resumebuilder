import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../models/job_listing_model.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../services/analytics_service.dart';

class JobDetailScreen extends ConsumerWidget {
  final JobListing jobListing;

  const JobDetailScreen({super.key, required this.jobListing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = jobListing;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Job Details',
        onBackPressed: () => context.pop(),
        showFoxIcon: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(job),
                        const SizedBox(height: 16),
                        _buildBadges(job),
                        if (job.salaryRange.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSalaryCard(job),
                        ],
                        if (job.description != null &&
                            job.description!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSection(
                            'Description',
                            child: Text(
                              job.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                        if (job.jobHighlights?.qualifications.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 20),
                          _buildBulletSection(
                            'Qualifications',
                            job.jobHighlights!.qualifications,
                            Icons.school_outlined,
                            AppColors.info,
                          ),
                        ],
                        if (job.jobHighlights?.responsibilities.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 20),
                          _buildBulletSection(
                            'Responsibilities',
                            job.jobHighlights!.responsibilities,
                            Icons.assignment_outlined,
                            AppColors.primary,
                          ),
                        ],
                        if (job.jobHighlights?.benefits.isNotEmpty == true) ...[
                          const SizedBox(height: 20),
                          _buildBulletSection(
                            'Benefits',
                            job.jobHighlights!.benefits,
                            Icons.card_giftcard,
                            AppColors.success,
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomBar(context, job),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(JobListing job) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmployerLogo(job),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.jobTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.companyName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployerLogo(JobListing job) {
    if (job.employerLogo != null && job.employerLogo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          job.employerLogo!,
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialAvatar(job),
        ),
      );
    }
    return _buildInitialAvatar(job);
  }

  Widget _buildInitialAvatar(JobListing job) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          job.companyName.isNotEmpty ? job.companyName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(JobListing job) {
    final badges = <Widget>[];

    if (job.employmentType != null && job.employmentType!.isNotEmpty) {
      badges.add(_buildBadge(job.employmentType!, AppColors.info));
    }

    if (job.isRemote) {
      badges.add(_buildBadge('Remote', AppColors.success));
    }

    if (job.postedDate != null && job.postedDate!.isNotEmpty) {
      badges.add(_buildBadge(job.postedDate!, AppColors.grey));
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSalaryCard(JobListing job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: AppColors.success, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salary Range',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.salaryRange,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                if (job.salaryPeriod != null && job.salaryPeriod!.isNotEmpty)
                  Text(
                    job.salaryPeriod!,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildBulletSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return _buildSection(
      title,
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, JobListing job) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradientHorizontal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MaterialButton(
            // onPressed: () => context.push(
            //   '/job/apply',
            //   extra: {
            //     'jobUrl': job.jobUrl,
            //     'jobTitle': job.jobTitle,
            //   },
            // ),
            onPressed: () async {
              final url = Uri.tryParse(job.jobUrl);
              if (url != null) {
                final success = await launchUrl(url, mode: LaunchMode.externalApplication);
                if (success) {
                  AnalyticsService.logBackendEvent('seeker_job_applied', properties: {
                    'job_title': job.jobTitle,
                    'company': job.companyName,
                  });
                }
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_new, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
