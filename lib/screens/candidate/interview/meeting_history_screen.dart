import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/meeting_history_response.dart';
import '../../../providers/meeting_history_provider.dart';
import '../../../utils/date_helpers.dart';
import '../../../widgets/common/custom_app_bar.dart';

class MeetingHistoryScreen extends ConsumerStatefulWidget {
  const MeetingHistoryScreen({super.key});

  @override
  ConsumerState<MeetingHistoryScreen> createState() =>
      _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState extends ConsumerState<MeetingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(meetingHistoryProvider.notifier).refreshMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(meetingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "Meetings History"),
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
              : historyState.meetings.isEmpty
              ? _buildEmptyState()
              : _buildMeetingList(historyState, context),
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
            Icons.groups_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No meetings yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your interview and meeting history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingList(
    MeetingHistoryState historyState,
    BuildContext context,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historyState.meetings.length,
      itemBuilder: (context, index) {
        final meeting = historyState.meetings[index];
        return meeting.isInterview
            ? _buildInterviewCard(meeting, context)
            : _buildMeetingCard(meeting, context);
      },
    );
  }

  Widget _buildInterviewCard(MeetingHistoryItem meeting, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/meeting/detail', extra: meeting);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateHelpers.formatDateTimeToLocal(
                        meeting.createdAt,
                        defaultValue: 'N/A',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (meeting.companyName != null &&
                    meeting.companyName!.isNotEmpty)
                  Text(
                    meeting.companyName!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (meeting.positionTitle != null &&
                    meeting.positionTitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      meeting.positionTitle!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                if (meeting.durationMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${meeting.durationMinutes} minutes',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(MeetingHistoryItem meeting, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/meeting/detail', extra: meeting);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.groups,
                        color: Colors.purple.shade700,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateHelpers.formatDateTimeToLocal(
                        meeting.createdAt,
                        defaultValue: 'N/A',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (meeting.roleIndustry != null &&
                    meeting.roleIndustry!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Role',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meeting.roleIndustry!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                if (meeting.durationMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${meeting.durationMinutes} minutes',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
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
