import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/documents_provider.dart' hide FileType;
import '../../widgets/common/custom_app_bar.dart';

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
    final allDocuments = ref.watch(documentsProvider);
    final documents = allDocuments
        .where((document) => document.lectureId == lectureId)
        .toList();
    final hasDocuments = documents.isNotEmpty;

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
        child: hasDocuments
            ? _buildDocumentsList(context, ref, documents)
            : _buildEmptyState(context, ref),
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
    List<Document> documents,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final document = documents[index];
        return _buildDocumentCard(
          context: context,
          icon: document.fileTypeIcon,
          name: document.name,
          size: document.fileSizeFormatted,
          date: DateFormat('MMM dd, yyyy').format(document.uploadedAt),
          onTap: () {
            // TODO: Open/preview document
          },
          onLongPress: () {
            // TODO: Show options menu (Rename/Delete)
          },
        );
      },
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      );

      if (result != null) {
        final file = result.files.first;
        final fileName = file.name;
        final filePath = file.path ?? '';
        final fileSize = file.size;

        // Add document to provider
        ref
            .read(documentsProvider.notifier)
            .addDocument(
              name: fileName,
              lectureId: lectureId,
              filePath: filePath,
              fileSize: fileSize,
            );

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
