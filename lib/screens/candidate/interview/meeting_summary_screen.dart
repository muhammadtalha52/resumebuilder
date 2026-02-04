import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../../constants/app_colors.dart';
import '../../../models/conversation_models.dart';
import '../../../providers/continuous_transcription_provider.dart';
import '../../../providers/interview_summary_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/scout_markdown_widget.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';

class MeetingSummaryScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String sessionType;
  final DateTime startTime;
  final Duration duration;

  const MeetingSummaryScreen({
    super.key,
    required this.sessionId,
    required this.sessionType,
    required this.startTime,
    required this.duration,
  });

  @override
  ConsumerState<MeetingSummaryScreen> createState() =>
      _InterviewSummaryScreenState();
}

class _InterviewSummaryScreenState extends ConsumerState<MeetingSummaryScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset provider state for new meeting session
      ref.read(interviewSummaryProvider.notifier).reset();

      // Load new meeting summary
      ref
          .read(interviewSummaryProvider.notifier)
          .endSessionAndGetSummary(
            sessionId: widget.sessionId,
            sessionType: widget.sessionType,
            startTime: widget.startTime,
            duration: widget.duration,
          );
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes minutes${seconds > 0 ? ', $seconds seconds' : ''}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'pm' : 'am';
    return 'Today, $hour:${dateTime.minute.toString().padLeft(2, '0')}$period';
  }

  /// Returns the appropriate summary content based on session type
  /// Uses interviewPrepSummary for practice, interviewSummary for interview, meetingSummary for meeting
  String? _getSummaryContent(InterviewSummaryState summaryState) {
    final model = summaryState.meetingSummaryModel;
    if (model == null) return null;

    final sessionTypeLower = widget.sessionType.toLowerCase();

    // Check if session type is practice (interview-prep)
    if (sessionTypeLower.contains('practice') ||
        sessionTypeLower.contains('prep')) {
      return model.interviewPrepSummary;
    }

    // Check if session type is interview
    if (sessionTypeLower.contains('interview')) {
      return model.interviewSummary;
    }

    // Default to meeting summary
    return model.meetingSummary;
  }

  void _handleBackNavigation() async {
    final summaryState = ref.read(interviewSummaryProvider);

    // If meeting is already saved, just go back
    if (summaryState.hasSaved) {
      context.go('/home');
      return;
    }

    // If meeting summary exists but not saved, show confirmation dialog
    if (summaryState.meetingSummaryModel != null) {
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'Save Meeting?',
        subtitle: 'Would you like to save your meeting before leaving?',
        icon: Icons.save_outlined,
        iconBackgroundColor: AppColors.primary,
        confirmText: 'Save & Exit',
        cancelText: "Don't Save",
        confirmButtonColor: AppColors.primary,
        confirmTextColor: Colors.white,
      );

      if (confirmed == true && mounted) {
        // Save the meeting
        await ref.read(interviewSummaryProvider.notifier).saveInterviewData();

        if (mounted) {
          final updatedState = ref.read(interviewSummaryProvider);

          if (updatedState.hasSaved) {
            showSuccessSnackBar(
              context: context,
              message: 'Meeting saved successfully!',
            );
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                context.go('/home');
              }
            });
          } else if (updatedState.error != null) {
            showErrorSnackBar(
              context: context,
              message: 'Error: ${updatedState.error}',
            );
          }
        }
      } else if (confirmed == false && mounted) {
        // Don't Save clicked - navigate back without saving
        context.go('/home');
      }
      // If confirmed == null (dialog dismissed), user stays on screen
    } else {
      // No summary data, just go back
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(interviewSummaryProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: BackNavigationAppBar(
          title: 'Meeting Summary',
          onBackPressed: _handleBackNavigation,
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
                child: summaryState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : summaryState.error != null &&
                          summaryState.meetingSummaryModel == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error Loading Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                summaryState.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => context.go('/home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Go to Home'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF3E0),
                                          Color(0xFFFFE0B2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/icons/fox-for-success.png',
                                          height: 130,
                                          width: 130,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  height: 130,
                                                  width: 130,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade300,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.celebration,
                                                    size: 40,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Meeting Completed',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Text(
                                          'Your meeting summary is ready to view',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  const Text(
                                    'Meeting Overview',
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
                                          value: widget.sessionType,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildOverviewCard(
                                          icon: Icons.calendar_today,
                                          label: 'Date & Time',
                                          value: _formatDateTime(
                                            widget.startTime,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildOverviewCard(
                                          icon: Icons.timer,
                                          label: 'Duration',
                                          value: _formatDuration(
                                            widget.duration,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Meeting/Interview Summary Markdown Section
                                  // Use interviewSummary for interview type, meetingSummary for meeting type
                                  if (_getSummaryContent(summaryState) !=
                                          null &&
                                      _getSummaryContent(
                                        summaryState,
                                      )!.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    _buildMeetingSummarySection(
                                      _getSummaryContent(summaryState)!,
                                    ),
                                  ],
                                  if (summaryState.meetingSummaryModel !=
                                          null &&
                                      summaryState
                                              .meetingSummaryModel!
                                              .summary !=
                                          null)
                                    ...() {
                                      final summaryData = summaryState
                                          .meetingSummaryModel!
                                          .summary!;
                                      return [
                                        // Key Discussion Points (for meetings) or Top Moments (for interviews)
                                        if (summaryData.keyDiscussionPoints !=
                                                null &&
                                            summaryData
                                                .keyDiscussionPoints!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            widget.sessionType
                                                    .toLowerCase()
                                                    .contains('meeting')
                                                ? 'Key Discussion Points'
                                                : 'Key Topics Discussed',
                                            summaryData.keyDiscussionPoints!,
                                            Colors.blue,
                                          ),
                                        ],

                                        // Top Moments in Interview
                                        if (summaryData.topMomentsInInterview !=
                                                null &&
                                            summaryData
                                                .topMomentsInInterview!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'Top Moments in Interview',
                                            summaryData.topMomentsInInterview!,
                                            Colors.indigo,
                                          ),
                                        ],

                                        // Decisions Made (mainly for meetings)
                                        if (summaryData.decisionsMade != null &&
                                            summaryData
                                                .decisionsMade!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'Decisions Made',
                                            summaryData.decisionsMade!,
                                            Colors.teal,
                                            isCheckmark: true,
                                          ),
                                        ],

                                        // Strengths Highlighted
                                        if (summaryData.strengthsHighlighted !=
                                                null &&
                                            summaryData
                                                .strengthsHighlighted!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'Strengths Highlighted',
                                            summaryData.strengthsHighlighted!,
                                            Colors.green,
                                            isCheckmark: true,
                                          ),
                                        ],

                                        // Potential Weaknesses or Strengths
                                        if (summaryData
                                                    .potentialWeaknessOrStrengths !=
                                                null &&
                                            summaryData
                                                .potentialWeaknessOrStrengths!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'Potential Weaknesses or Strengths',
                                            summaryData
                                                .potentialWeaknessOrStrengths!,
                                            Colors.amber,
                                            isCheckmark: false,
                                          ),
                                        ],

                                        // Areas for Improvement
                                        if (summaryData.areasOfImprovement !=
                                                null &&
                                            summaryData
                                                .areasOfImprovement!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'Areas for Improvement',
                                            summaryData.areasOfImprovement!,
                                            Colors.orange,
                                            isCheckmark: false,
                                            isWarning: true,
                                          ),
                                        ],

                                        // AI-Driven Interview Analytics
                                        if (summaryData
                                                    .aiDrivenInterviewAnalytics !=
                                                null &&
                                            summaryData
                                                .aiDrivenInterviewAnalytics!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'AI-Driven Interview Analytics',
                                            summaryData
                                                .aiDrivenInterviewAnalytics!,
                                            Colors.deepPurple,
                                          ),
                                        ],

                                        // Action Items
                                        if ((summaryData.candidateActionItems !=
                                                    null &&
                                                summaryData
                                                    .candidateActionItems!
                                                    .isNotEmpty) ||
                                            (summaryData.actionItems != null &&
                                                summaryData
                                                    .actionItems!
                                                    .isNotEmpty)) ...[
                                          const SizedBox(height: 24),
                                          _buildSection(
                                            'Action Items',
                                            summaryData.candidateActionItems !=
                                                        null &&
                                                    summaryData
                                                        .candidateActionItems!
                                                        .isNotEmpty
                                                ? summaryData
                                                      .candidateActionItems!
                                                : summaryData.actionItems!,
                                            Colors.purple,
                                            isCheckmark: true,
                                          ),
                                        ],
                                      ];
                                    }(),
                                  // Transcript Section
                                  _buildTranscriptSection(),
                                  const SizedBox(height: 24),
                                  // Save Button
                                  _buildSaveButton(summaryState),
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
        if (title == 'Key Topics Discussed' || title == 'Key Discussion Points')
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

  Widget _buildSaveButton(InterviewSummaryState summaryState) {
    if (summaryState.hasSaved) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Meeting Saved Successfully',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomButton(
      text: 'Save Meeting',
      height: 56,
      isLoading: summaryState.isSaving,
      onPressed: () async {
        await ref.read(interviewSummaryProvider.notifier).saveInterviewData();

        if (mounted) {
          final updatedState = ref.read(interviewSummaryProvider);

          if (updatedState.hasSaved) {
            // Navigate back to home like the back button does
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/home');
              }
            });
          } else if (updatedState.error != null) {
            showErrorSnackBar(
              context: context,
              message: 'Error: ${updatedState.error}',
            );
          }
        }
      },
    );
  }

  /// Builds the transcript section with button to open bottom sheet
  Widget _buildTranscriptSection() {
    final transcriptionData = ref.watch(continuousTranscriptionProvider);
    final entries = transcriptionData.conversationEntries;

    // Don't show if no conversation entries
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        GestureDetector(
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
        ),
      ],
    );
  }

  /// Opens the bottom sheet with all conversation entries
  void _openTranscriptBottomSheet(List<ConversationEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SummaryTranscriptBottomSheet(entries: entries),
    );
  }
}

/// Bottom sheet displaying all conversation entries as one continuous flow
class _SummaryTranscriptBottomSheet extends StatelessWidget {
  final List<ConversationEntry> entries;

  const _SummaryTranscriptBottomSheet({required this.entries});

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
