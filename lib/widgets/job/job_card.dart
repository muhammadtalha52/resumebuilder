import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/job_listing_model.dart';
import '../dialogs/confirmation_dialog.dart';

class JobCard extends StatelessWidget {
  final JobListing jobListing;
  final bool isApplying;
  final bool isApplied;
  final VoidCallback onApply;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.jobListing,
    required this.isApplying,
    required this.isApplied,
    required this.onApply,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company logo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _companyInitial(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Job details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jobListing.jobTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jobListing.companyName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.greyDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jobListing.location,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (jobListing.postedDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          jobListing.postedDate!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildActionWidget(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _companyInitial() {
    if (jobListing.companyName.isEmpty) return '?';
    return jobListing.companyName[0].toUpperCase();
  }

  Widget _buildActionWidget(BuildContext context) {
    if (isApplied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Applied',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: isApplying ? null : () => _confirmApply(context),
        icon: isApplying
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : const Icon(Icons.send, size: 14),
        label: Text(
          isApplying ? 'Applying...' : 'Quick Apply',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Future<void> _confirmApply(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Quick Apply',
      subtitle:
          'Apply to ${jobListing.jobTitle} at '
          '${jobListing.companyName} with your resume?',
      icon: Icons.send,
      iconBackgroundColor: AppColors.primary,
      confirmText: 'Apply',
      cancelText: 'Cancel',
      confirmButtonColor: AppColors.primary,
      confirmTextColor: Colors.white,
    );

    if (confirmed == true && context.mounted) {
      onApply();
    }
  }
}
