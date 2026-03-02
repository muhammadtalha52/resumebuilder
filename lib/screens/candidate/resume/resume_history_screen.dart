import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../main.dart';
import '../../../providers/history_provider.dart';
import '../../../utils/date_helpers.dart';
import '../../../utils/endpoint_headers.dart';
import '../../../utils/s3_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ResumeHistoryScreen extends ConsumerStatefulWidget {
  const ResumeHistoryScreen({super.key});

  @override
  ConsumerState<ResumeHistoryScreen> createState() =>
      _ResumeHistoryScreenState();
}

class _ResumeHistoryScreenState extends ConsumerState<ResumeHistoryScreen> {
  // Track which resume IDs are currently downloading
  final Set<int> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "Resume History"),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
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
          itemCount: historyState.resumes.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          itemBuilder: (context, index) {
            final resume = historyState.resumes[index];
            return Slidable(
              key: ValueKey(resume.id),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.2,
                children: [
                  CustomSlidableAction(
                    onPressed: (_) => _deleteResume(resume),
                    backgroundColor: AppColors.error,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              child: _buildResumeCard(resume, context),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumeCard(ResumeHistory resume, BuildContext context) {
    return InkWell(
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
              showErrorSnackBar(
                context: context,
                message: 'Could not open resume',
              );
            }
          }
        } else {
          // Fallback to navigation if URL is not available
          context.push('/resume/review?id=${resume.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildCompanyOrJob(resume),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateHelpers.formatDateTimeToLocal(
                          resume.createdAt,
                          defaultValue: 'N/A',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (resume.resumeUrl.isNotEmpty)
                  _downloadingIds.contains(resume.id)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: () => _downloadResume(resume, context),
                          icon: const Icon(
                            Icons.download,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          tooltip: 'Download Resume',
                        ),
              ],
            ),
            if (resume.jobTitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      '/resume/matching-jobs',
                      extra: {'jobTitle': resume.jobTitle},
                    );
                  },
                  icon: const Icon(Icons.work_outline, size: 14),
                  label: const Text(
                    'Ask Scout to find Jobs for you',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteResume(ResumeHistory resume) async {
    try {
      await ref.read(historyProvider.notifier).deleteResume(resume.id);
      if (mounted) {
        showSuccessSnackBar(
          context: context,
          message: 'Resume deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context: context, message: 'Failed to delete resume');
      }
    }
  }

  String _buildCompanyOrJob(ResumeHistory resume) {
    if (resume.companyName.isNotEmpty) {
      return resume.companyName;
    } else if (resume.jobTitle.isNotEmpty) {
      return resume.jobTitle;
    }
    return 'Resume';
  }

  Future<void> _downloadResume(
    ResumeHistory resume,
    BuildContext context,
  ) async {
    // Prevent duplicate taps
    if (_downloadingIds.contains(resume.id)) return;

    setState(() {
      _downloadingIds.add(resume.id);
    });

    try {
      // Construct the full URL
      String urlString = resume.resumeUrl;
      if (!urlString.startsWith('http')) {
        urlString = S3Utils.constructAssetUrl(resume.resumeUrl);
      }

      debugPrint('📱 Download URL: $urlString');

      // Download with authentication using apiClient with bytes response type
      final response = await apiClient.dio.get(
        urlString,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {WAInterceptorHeaders.requiresToken: true},
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;

        // Generate filename
        final companyName = resume.companyName.replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '_',
        );
        final jobTitle = resume.jobTitle.replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '_',
        );
        final dateStr = DateTime.now().toString().split(' ')[0];
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        String fileName;
        if (companyName.isNotEmpty && jobTitle.isNotEmpty) {
          fileName =
              'resume_${companyName}_${jobTitle}_${dateStr}_$timestamp.pdf';
        } else if (jobTitle.isNotEmpty) {
          fileName = 'resume_${jobTitle}_${dateStr}_$timestamp.pdf';
        } else {
          fileName = 'resume_${dateStr}_$timestamp.pdf';
        }

        // Platform-specific handling
        if (kIsWeb) {
          if (mounted) {
            showErrorSnackBar(
              context: context,
              message: 'Web download not yet implemented',
            );
          }
        } else if (Platform.isIOS || Platform.isAndroid) {
          // For mobile platforms, save to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final resumesDir = Directory('${appDir.path}/Resumes');

          // Create Resumes folder if it doesn't exist
          if (!await resumesDir.exists()) {
            await resumesDir.create(recursive: true);
          }

          final file = File('${resumesDir.path}/$fileName');
          await file.writeAsBytes(bytes);

          // Auto-open after download
          await _openSavedFile(file.path);
        } else {
          // For desktop platforms (macOS, Windows, Linux)
          Directory? downloadsDir;

          if (Platform.isMacOS || Platform.isLinux) {
            final home = Platform.environment['HOME'];
            if (home != null) {
              downloadsDir = Directory('$home/Downloads');
            }
          } else if (Platform.isWindows) {
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null) {
              downloadsDir = Directory('$userProfile\\Downloads');
            }
          }

          // Fallback to documents directory if Downloads not found
          downloadsDir ??= await getApplicationDocumentsDirectory();

          final file = File(
            '${downloadsDir.path}${Platform.pathSeparator}$fileName',
          );
          await file.writeAsBytes(bytes);

          // Auto-open after download
          await _openSavedFile(file.path);
        }
      } else {
        throw Exception('Failed to download resume');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        showErrorSnackBar(
          context: context,
          message: 'Failed to download resume: ${e.toString()}',
        );
      }
    } finally {
      // Reset downloading state
      if (mounted) {
        setState(() {
          _downloadingIds.remove(resume.id);
        });
      }
    }
  }

  /// Open saved PDF file with device's default PDF viewer
  /// Falls back to share if opening fails
  Future<void> _openSavedFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('Failed to open file: ${result.message}');
        // Fallback to share if open fails
        await _shareFile(filePath);
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      // Fallback to share if open fails
      await _shareFile(filePath);
    }
  }

  /// Share the saved PDF file (fallback when open fails)
  Future<void> _shareFile(String filePath) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          sharePositionOrigin: mounted
              ? Rect.fromLTWH(
                  0,
                  0,
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height / 2,
                )
              : const Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
      if (mounted) {
        showErrorSnackBar(context: context, message: 'Failed to share file');
      }
    }
  }
}
