import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../../constants/app_colors.dart';
import '../../../models/conversation_models.dart';
import '../../../models/meeting_history_response.dart';
import '../../../utils/date_helpers.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/scout_markdown_widget.dart';
import '../../../widgets/scout_chat_bottom_sheet.dart';

class MeetingDetailScreen extends ConsumerStatefulWidget {
  final MeetingHistoryItem meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
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
                                  value: DateHelpers.formatDateTimeToLocal(
                                    widget.meeting.createdAt,
                                    defaultValue: 'N/A',
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

                          // AI Meeting Summary (from notes field)
                          if (widget.meeting.notes != null &&
                              widget.meeting.notes!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildMeetingSummarySection(widget.meeting.notes!),
                          ],

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

                          // Transcript Section
                          if (widget.meeting.transcript != null &&
                              widget.meeting.transcript!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildTranscriptSection(),
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

  Widget _buildMeetingSummarySection(String meetingSummary) {
    return MarkdownBlock(
      data: meetingSummary.replaceAll('\\n', '\n'),
      config: MarkdownConfig(
        configs: [
          HrConfig(height: 0, color: Colors.transparent),
          PConfig(
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          H1Config(
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          H2Config(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          H3Config(
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          ListConfig(
            marker: (isOrdered, depth, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Text(
                  isOrdered ? '${index + 1}.' : '•',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              );
            },
          ),
          BlockquoteConfig(
            sideColor: Colors.orange.shade300,
            textColor: Colors.grey[600]!,
          ),
          CodeConfig(
            style: TextStyle(
              fontSize: 13,
              backgroundColor: Colors.grey[200],
              color: Colors.grey[800],
            ),
          ),
          PreConfig(decoration: const BoxDecoration(color: Colors.transparent)),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    // Try to parse as new ConversationEntry format first
    final entries = ConversationEntry.decodeList(widget.meeting.transcript);

    if (entries != null && entries.isNotEmpty) {
      // New format: Button to open bottom sheet with all entries
      return _buildTranscriptButton(entries);
    }

    // Try legacy TranscriptAnswerPair format and convert to ConversationEntry
    final pairs = TranscriptAnswerPair.decodeList(widget.meeting.transcript);
    if (pairs != null && pairs.isNotEmpty) {
      // Convert legacy pairs to ConversationEntry list
      final legacyEntries = <ConversationEntry>[];
      for (final pair in pairs) {
        if (pair.hasSegments && pair.segments != null) {
          for (final segment in pair.segments!) {
            legacyEntries.add(ConversationEntry.fromSpeakerSegment(segment));
          }
        }
        legacyEntries.add(ConversationEntry.scout(text: pair.answer));
      }
      return _buildTranscriptButton(legacyEntries);
    }

    // Legacy format: Display as plain text
    return _buildLegacyTranscriptSection();
  }

  /// Builds a button that opens the transcript bottom sheet
  Widget _buildTranscriptButton(List<ConversationEntry> entries) {
    return GestureDetector(
      onTap: () => _openTranscriptBottomSheet(entries),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.description_outlined,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transcript & Scout Responses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view full conversation',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the bottom sheet with all conversation entries
  void _openTranscriptBottomSheet(List<ConversationEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TranscriptBottomSheet(entries: entries),
    );
  }

  /// Legacy transcript display (plain text)
  Widget _buildLegacyTranscriptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Transcript',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              title: const Text(
                'View Transcript',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Tap to expand full conversation',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SelectableText(
                    widget.meeting.transcript!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet displaying all conversation entries as one continuous flow
class _TranscriptBottomSheet extends StatelessWidget {
  final List<ConversationEntry> entries;

  const _TranscriptBottomSheet({required this.entries});

  // Speaker colors - cycle through for different speakers
  static final speakerColors = [
    Colors.blue.shade700,
    Colors.green.shade700,
    Colors.purple.shade700,
    Colors.teal.shade700,
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Transcript & Scout Responses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey[200], height: 1),
              // Single continuous flowing conversation
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildConversationWidgets(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build conversation widgets - Text for speakers, Markdown for Scout
  List<Widget> _buildConversationWidgets() {
    final List<Widget> widgets = [];

    for (final entry in entries) {
      final label = entry.getDisplayLabel();
      final colorIndex = entry.isSpeaker
          ? (entry.speakerId ?? 0) % speakerColors.length
          : -1;
      final labelColor = entry.isScout
          ? Colors.orange.shade700
          : speakerColors[colorIndex];

      if (entry.isScout) {
        // Scout response - use common ScoutMarkdownWidget
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                ScoutMarkdownWidget(data: entry.text),
              ],
            ),
          ),
        );
      } else {
        // Speaker segment - use SelectableText.rich
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                      height: 1.6,
                    ),
                  ),
                  TextSpan(
                    text: entry.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
