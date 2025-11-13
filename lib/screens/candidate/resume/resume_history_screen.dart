import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class ResumeHistoryScreen extends ConsumerStatefulWidget {
  const ResumeHistoryScreen({super.key});

  @override
  ConsumerState<ResumeHistoryScreen> createState() =>
      _ResumeHistoryScreenState();
}

class _ResumeHistoryScreenState extends ConsumerState<ResumeHistoryScreen> {
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
        shrinkWrap: true,
        itemCount: historyState.resumes.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final resume = historyState.resumes[index];
          return _buildResumeCard(resume, context);
        },
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
        child: Row(
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (resume.resumeUrl.isNotEmpty)
                  IconButton(
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
          ],
        ),
      ),
    );
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
    try {
      // Show loading indicator
      if (context.mounted) {
        showInfoSnackBar(context: context, message: 'Downloading resume...');
      }

      // Construct the full URL
      String urlString = resume.resumeUrl;
      if (!urlString.startsWith('http')) {
        urlString = S3Utils.constructAssetUrl(resume.resumeUrl);
      }

      // Debug: Print the URL and token
      print('📱 Download URL: $urlString');
      print('🔑 Token: ${appLogic.accessToken.substring(0, 20)}...');

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
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        String fileName = '';
        if (companyName.isNotEmpty && jobTitle.isNotEmpty) {
          fileName = '${companyName}_${jobTitle}_Resume_$timestamp.pdf';
        } else if (jobTitle.isNotEmpty) {
          fileName = '${jobTitle}_Resume_$timestamp.pdf';
        } else {
          fileName = 'Resume_$timestamp.pdf';
        }

        // Save to permanent storage
        Directory? permanentDir;

        if (Platform.isAndroid) {
          // On Android, use app-specific external storage (no permissions needed)
          // This will save to /storage/emulated/0/Android/data/com.skillresy.app/files/Download
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (dirs != null && dirs.isNotEmpty) {
            permanentDir = dirs.first;
          } else {
            // Fallback to external storage directory
            permanentDir = await getExternalStorageDirectory();
            if (permanentDir != null) {
              // Create a Download subfolder in app's external storage
              permanentDir = Directory('${permanentDir.path}/Download');
              if (!await permanentDir.exists()) {
                await permanentDir.create(recursive: true);
              }
            } else {
              // Last resort: use app documents directory
              permanentDir = await getApplicationDocumentsDirectory();
            }
          }
        } else if (Platform.isIOS) {
          // On iOS, save to Documents directory (accessible via Files app)
          permanentDir = await getApplicationDocumentsDirectory();
        } else {
          // For other platforms, use temporary directory
          permanentDir = await getTemporaryDirectory();
        }

        // Save the file permanently
        final permanentFile = File('${permanentDir!.path}/$fileName');
        await permanentFile.writeAsBytes(bytes);

        // Also create a temporary file for sharing
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(bytes);

        // Share the file using latest SharePlus v12.0.0 API
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempFile.path)],
            text: 'Resume - ${resume.title}',
            sharePositionOrigin: context.mounted
                ? Rect.fromLTWH(
                    0,
                    0,
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height / 2,
                  )
                : const Rect.fromLTWH(0, 0, 100, 100),
          ),
        );

        if (context.mounted) {
          showSuccessSnackBar(
            context: context,
            message: Platform.isIOS
                ? 'Resume saved to Files app and ready to share!'
                : 'Resume saved to Downloads folder!',
          );
        }
      } else {
        throw Exception('Failed to download resume');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context: context, message: e.toString());
      }
    }
  }
}
