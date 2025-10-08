import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/meeting_history_response.dart';
import '../../../utils/date_helpers.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/scout_chat_bottom_sheet.dart';

class MeetingDetailScreen extends ConsumerStatefulWidget {
  final MeetingHistoryItem meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Meeting Details',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.only(top: 15, bottom: 15),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Success/Header Container
                          Container(
                            padding: const EdgeInsets.all(15),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.meeting.isInterview
                                    ? [
                                        const Color(0xFFE3F2FD),
                                        const Color(0xFFBBDEFB),
                                      ]
                                    : [
                                        const Color(0xFFF3E5F5),
                                        const Color(0xFFE1BEE7),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  widget.meeting.isInterview
                                      ? Icons.work_outline
                                      : Icons.groups,
                                  size: 60,
                                  color: widget.meeting.isInterview
                                      ? Colors.blue.shade700
                                      : Colors.purple.shade700,
                                ),
                                const SizedBox(height: 16),
                                if (widget.meeting.companyName != null &&
                                    widget.meeting.companyName!.isNotEmpty) ...[
                                  Text(
                                    widget.meeting.companyName!,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (widget.meeting.positionTitle != null &&
                                      widget.meeting.positionTitle!.isNotEmpty)
                                    Text(
                                      widget.meeting.positionTitle!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ] else if (widget.meeting.roleIndustry !=
                                        null &&
                                    widget
                                        .meeting
                                        .roleIndustry!
                                        .isNotEmpty) ...[
                                  Text(
                                    widget.meeting.roleIndustry!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  widget.meeting.isInterview
                                      ? 'Interview Session'
                                      : 'Meeting Session',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Meeting Overview
                          const Text(
                            'Session Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                _buildOverviewCard(
                                  icon: Icons.mic,
                                  label: 'Type',
                                  value:
                                      widget.meeting.interviewType
                                          ?.toUpperCase() ??
                                      'N/A',
                                ),
                                const SizedBox(width: 8),
                                _buildOverviewCard(
                                  icon: Icons.calendar_today,
                                  label: 'Date',
                                  value: DateHelpers.formatToReadableDateTime(
                                    widget.meeting.createdAt,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildOverviewCard(
                                  icon: Icons.timer,
                                  label: 'Duration',
                                  value: DateHelpers.formatDuration(
                                    widget.meeting.durationMinutes,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Key Topics
                          if (widget.meeting.keyTopics != null &&
                              widget.meeting.keyTopics!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Key Topics Discussed',
                              widget.meeting.keyTopics!,
                              Colors.blue,
                            ),
                          ],

                          // Top Moments
                          if (widget.meeting.topMomentsInInterview != null &&
                              widget
                                  .meeting
                                  .topMomentsInInterview!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Top Moments',
                              widget.meeting.topMomentsInInterview!,
                              Colors.indigo,
                            ),
                          ],

                          // Decisions Made
                          if (widget.meeting.decisionsMade != null &&
                              widget.meeting.decisionsMade!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Decisions Made',
                              widget.meeting.decisionsMade!,
                              Colors.teal,
                              isCheckmark: true,
                            ),
                          ],

                          // Strengths Highlighted
                          if (widget.meeting.strengthHighlight != null &&
                              widget.meeting.strengthHighlight!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Strengths Highlighted',
                              widget.meeting.strengthHighlight!,
                              Colors.green,
                              isCheckmark: true,
                            ),
                          ],

                          // Weaknesses
                          if (widget.meeting.weaknessHighlight != null &&
                              widget.meeting.weaknessHighlight!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Areas for Improvement',
                              widget.meeting.weaknessHighlight!,
                              Colors.orange,
                              isWarning: true,
                            ),
                          ],

                          // Areas of Improvement
                          if (widget.meeting.areasOfImprovement != null &&
                              widget
                                  .meeting
                                  .areasOfImprovement!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Development Areas',
                              widget.meeting.areasOfImprovement!,
                              Colors.amber,
                              isWarning: true,
                            ),
                          ],

                          // AI Analytics
                          if (widget.meeting.aiDrivenInterviewAnalytics !=
                                  null &&
                              widget
                                  .meeting
                                  .aiDrivenInterviewAnalytics!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'AI-Driven Analytics',
                              widget.meeting.aiDrivenInterviewAnalytics!,
                              Colors.deepPurple,
                            ),
                          ],

                          // Action Items
                          if (widget.meeting.actionItems != null &&
                              widget.meeting.actionItems!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Action Items',
                              widget.meeting.actionItems!,
                              Colors.purple,
                              isCheckmark: true,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Ask Scout the fox - Tappable container
                          GestureDetector(
                            onTap: _openScoutChat,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Scout avatar
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Image.asset(
                                      'assets/icons/fox-mascot.png',
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ask Scout the fox',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Get AI-powered insights about your ${widget.meeting.isInterview ? 'interview' : 'meeting'} session',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Arrow icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openScoutChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScoutChatBottomSheet(meeting: widget.meeting),
    );
  }

  Widget _buildSection(
    String title,
    List<String> items,
    Color color, {
    bool isCheckmark = false,
    bool isWarning = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (title == 'Key Topics Discussed')
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEEFF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF7777F8), width: 1),
                ),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                ),
              );
            }).toList(),
          )
        else
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isWarning
                          ? Colors.orange
                          : isCheckmark
                          ? Colors.green
                          : color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWarning
                          ? Icons.warning
                          : isCheckmark
                          ? Icons.check
                          : Icons.circle,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
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
            );
          }),
      ],
    );
  }
}
