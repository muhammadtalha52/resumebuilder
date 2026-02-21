import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/meeting_history_response.dart';
import '../../../providers/meeting_history_provider.dart';
import '../../../utils/date_helpers.dart';
import '../../../utils/snackbar_utils.dart';
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
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: false,
        itemCount: historyState.meetings.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final meeting = historyState.meetings[index];
          return Slidable(
            key: ValueKey(meeting.id),
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.2,
              children: [
                CustomSlidableAction(
                  onPressed: (_) => _deleteMeeting(meeting),
                  backgroundColor: AppColors.error,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            child: _buildMeetingCard(meeting, context),
          );
        },
      ),
    );
  }

  Future<void> _deleteMeeting(MeetingHistoryItem meeting) async {
    try {
      await ref.read(meetingHistoryProvider.notifier).deleteMeeting(meeting.id);
      if (mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Meeting deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'Failed to delete meeting',
        );
      }
    }
  }

  Widget _buildMeetingCard(MeetingHistoryItem meeting, BuildContext context) {
    // Determine title and subtitle based on meeting type
    String title;
    String subtitle;

    if (meeting.isInterview) {
      title = meeting.companyName ?? 'Interview';
      subtitle = meeting.positionTitle ?? 'Position Interview';
    } else {
      title = meeting.roleIndustry ?? 'Meeting';
      subtitle = 'Meeting Session';
    }

    // Format duration
    String durationText = '';
    if (meeting.durationMinutes != null && meeting.durationMinutes! > 0) {
      final duration = meeting.durationMinutes!;
      if (duration >= 60) {
        final hours = duration ~/ 60;
        final minutes = duration % 60;
        if (minutes > 0) {
          durationText = '$hours hr $minutes min';
        } else {
          durationText = '$hours hr';
        }
      } else {
        durationText = '$duration min';
      }
    }

    return InkWell(
      onTap: () {
        context.push('/meeting/detail', extra: meeting);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (durationText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    meeting.createdAt != null
                        ? DateHelpers.formatToDisplayDate(meeting.createdAt!)
                        : '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/icons/session.png',
              width: 22,
              height: 22,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
