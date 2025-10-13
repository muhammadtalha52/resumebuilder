import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/documents_provider.dart';
import '../../providers/resume_provider.dart';
import '../../models/documents_response.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../utils/s3_utils.dart';
import 'document_viewer_screen.dart';

class DocumentsScreen extends ConsumerWidget {
  final String lectureId;
  final String lectureName;

  const DocumentsScreen({
    super.key,
    required this.lectureId,
    required this.lectureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse lectureId to int for API call
    final folderId = int.tryParse(lectureId) ?? 0;
    final documentsAsync = ref.watch(folderDocumentsProvider(folderId));

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: lectureName,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: documentsAsync.when(
          data: (documentsResponse) {
            final documents = documentsResponse.data ?? [];
            final hasDocuments = documents.isNotEmpty;

            return hasDocuments
                ? _buildDocumentsList(context, ref, documents)
                : _buildEmptyState(context, ref);
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error.toString()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadFile(context, ref),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildDocumentsList(
    BuildContext context,
    WidgetRef ref,
    List<Data> documents,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final document = documents[index];
        final icon = _getFileIcon(document.fileType ?? '');
        final size = _formatFileSize(document.fileSize ?? 0);
        final date = document.createdAt != null
            ? DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(document.createdAt!))
            : '';

        return _buildDocumentCard(
          context: context,
          icon: icon,
          name: document.name ?? 'Untitled',
          size: size,
          date: date,
          onTap: () {
            if (document.s3Filename != null &&
                document.s3Filename!.isNotEmpty) {
              final urlString = S3Utils.constructAssetUrl(document.s3Filename!);

              // Debug: Log the final URL
              print('📄 Opening document: ${document.name}');
              print('🔗 S3 Filename: ${document.s3Filename}');
              print('🌐 Final URL: $urlString');

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    documentUrl: urlString,
                    documentName: document.name ?? 'Document',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document URL not available'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onLongPress: () {
            // TODO: Show options menu (Rename/Delete)
          },
        );
      },
    );
  }

  String _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'txt':
        return '📋';
      default:
        return '📁';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load documents',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required String icon,
    required String name,
    required String size,
    required String date,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // File icon
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$size • $date',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scout fox image
            Image.asset('assets/icons/interview-fox.png'),
            const SizedBox(height: 32),
            const Text(
              'No Documents Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload your study materials like PDFs,\nDOCs, PPTs, and TXTs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => _pickAndUploadFile(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    const Text(
                      'Upload Your First Document',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context, WidgetRef ref) async {
    try {
      // Step 1: Pick file
      file_picker.FilePickerResult? result = await file_picker
          .FilePicker
          .platform
          .pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
          );

      if (result != null) {
        final pickedFile = result.files.first;
        final fileName = pickedFile.name;
        final filePath = pickedFile.path ?? '';
        final fileSize = pickedFile.size;

        if (filePath.isEmpty) {
          throw Exception('File path is empty');
        }

        // Show loading dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading $fileName...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Step 2: Upload file to S3 using ResumeService
        final resumeService = ref.read(resumeServiceProvider);
        final documentsService = ref.read(documentsServiceProvider);
        final file = File(filePath);
        final saveDocResponse = await resumeService.uploadDocsToS3(file);

        // Step 3: Save document metadata to API
        final folderId = int.tryParse(lectureId) ?? 0;
        await documentsService.saveFolderItem(
          folderId: folderId,
          name: fileName,
          s3Filename: saveDocResponse.s3FileName ?? '',
          fileType: saveDocResponse.fileType ?? '',
          fileSize: fileSize,
        );

        // Step 4: Refresh documents list
        ref.invalidate(folderDocumentsProvider(folderId));

        // Dismiss loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileName uploaded successfully'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog if it's showing
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
