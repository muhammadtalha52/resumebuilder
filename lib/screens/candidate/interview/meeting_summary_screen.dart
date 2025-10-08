import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/interview_summary_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(interviewSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Meeting Summary',
        onBackPressed: () => context.go('/home'),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                                  color: Colors.orange.shade300,
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
                                        value: _formatDuration(widget.duration),
                                      ),
                                    ],
                                  ),
                                ),
                                if (summaryState.meetingSummaryModel != null &&
                                    summaryState.meetingSummaryModel!.summary !=
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
                                      if (summaryData.actionItems != null &&
                                          summaryData
                                              .actionItems!
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        _buildSection(
                                          'Action Items',
                                          summaryData.actionItems!,
                                          Colors.purple,
                                          isCheckmark: true,
                                        ),
                                      ],
                                    ];
                                  }(),
                                const SizedBox(height: 24),
                                // Container(
                                //   padding: const EdgeInsets.all(16),
                                //   decoration: BoxDecoration(
                                //     color: Colors.grey[50],
                                //     borderRadius: BorderRadius.circular(12),
                                //     border: Border.all(
                                //       color: Colors.grey[300]!,
                                //     ),
                                //   ),
                                //   child: Column(
                                //     crossAxisAlignment:
                                //         CrossAxisAlignment.start,
                                //     children: [
                                //       Row(
                                //         children: [
                                //           Image.asset(
                                //             'assets/icons/scout_avatar.png',
                                //             height: 32,
                                //             width: 32,
                                //             errorBuilder:
                                //                 (context, error, stackTrace) {
                                //                   return Container(
                                //                     height: 32,
                                //                     width: 32,
                                //                     decoration:
                                //                         const BoxDecoration(
                                //                           color: Colors.orange,
                                //                           shape:
                                //                               BoxShape.circle,
                                //                         ),
                                //                     child: const Icon(
                                //                       Icons.smart_toy,
                                //                       size: 20,
                                //                       color: Colors.white,
                                //                     ),
                                //                   );
                                //                 },
                                //           ),
                                //           const SizedBox(width: 8),
                                //           const Text(
                                //             'Ask Scout the fox',
                                //             style: TextStyle(
                                //               fontSize: 16,
                                //               fontWeight: FontWeight.bold,
                                //               color: Colors.black87,
                                //             ),
                                //           ),
                                //         ],
                                //       ),
                                //       const SizedBox(height: 12),
                                //       TextField(
                                //         controller: _questionController,
                                //         decoration: InputDecoration(
                                //           hintText:
                                //               'Ask me anything about session...',
                                //           hintStyle: TextStyle(
                                //             color: Colors.grey[400],
                                //             fontSize: 14,
                                //           ),
                                //           filled: true,
                                //           fillColor: Colors.white,
                                //           border: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               8,
                                //             ),
                                //             borderSide: BorderSide(
                                //               color: Colors.grey[300]!,
                                //             ),
                                //           ),
                                //           enabledBorder: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               8,
                                //             ),
                                //             borderSide: BorderSide(
                                //               color: Colors.grey[300]!,
                                //             ),
                                //           ),
                                //           focusedBorder: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               8,
                                //             ),
                                //             borderSide: const BorderSide(
                                //               color: Colors.orange,
                                //               width: 2,
                                //             ),
                                //           ),
                                //           suffixIcon: Container(
                                //             margin: const EdgeInsets.all(4),
                                //             decoration: BoxDecoration(
                                //               color: Colors.orange,
                                //               borderRadius:
                                //                   BorderRadius.circular(6),
                                //             ),
                                //             child: IconButton(
                                //               onPressed: () {
                                //                 // TODO: Implement Scout chat functionality
                                //               },
                                //               icon: const Icon(
                                //                 Icons.send,
                                //                 color: Colors.white,
                                //                 size: 20,
                                //               ),
                                //             ),
                                //           ),
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                // const SizedBox(height: 24),
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
                'Interview Saved Successfully',
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

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: summaryState.isSaving
            ? null
            : () async {
                await ref
                    .read(interviewSummaryProvider.notifier)
                    .saveInterviewData();

                if (mounted) {
                  final updatedState = ref.read(interviewSummaryProvider);

                  if (updatedState.hasSaved) {
                    // Show success message and navigate home
                    showSuccessSnackBar(
                      context: context,
                      message: 'Meeting saved successfully!',
                    );

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
        style: ElevatedButton.styleFrom(
          backgroundColor: summaryState.isSaving
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: summaryState.isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Saving Meeting...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Save Meeting',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
