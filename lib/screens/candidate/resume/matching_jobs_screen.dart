import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/job_listing_model.dart';
import '../../../providers/job_listings_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/job/job_card.dart';

class MatchingJobsScreen extends ConsumerStatefulWidget {
  final String jobTitle;
  final String pdfBase64;
  final String? location;

  const MatchingJobsScreen({
    super.key,
    required this.jobTitle,
    required this.pdfBase64,
    this.location,
  });

  @override
  ConsumerState<MatchingJobsScreen> createState() => _MatchingJobsScreenState();
}

class _MatchingJobsScreenState extends ConsumerState<MatchingJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(jobListingsProvider.notifier)
          .fetchJobs(widget.jobTitle, location: widget.location);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "Recommended Jobs"),
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
          _buildBody(state),
        ],
      ),
    );
  }

  Widget _buildBody(JobListingsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.jobs.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.jobs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = state.jobs[index];
        return JobCard(
          jobListing: job,
          isApplying: state.applyingJobIds.contains(job.id),
          isApplied: state.appliedJobIds.contains(job.id),
          onApply: () {
            ref
                .read(jobListingsProvider.notifier)
                .applyToJob(job.id, widget.pdfBase64);
          },
          onTap: () {
            context.push(
              '/job/detail',
              extra: {'jobListing': job, 'pdfBase64': widget.pdfBase64},
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching jobs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your job title or\n'
            'check back later for new listings',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              ref
                  .read(jobListingsProvider.notifier)
                  .fetchJobs(widget.jobTitle, location: widget.location);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
