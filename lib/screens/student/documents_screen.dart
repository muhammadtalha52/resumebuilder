import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/documents_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/usage_provider.dart';
import '../../models/documents_response.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/dialogs/delete_confirmation_dialog.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/s3_utils.dart';
import '../../providers/quiz_provider.dart';
import '../../services/api_client.dart';
import '../../services/subscription_service.dart';
import 'document_viewer_screen.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final String lectureId;
  final String lectureName;

  const DocumentsScreen({
    super.key,
    required this.lectureId,
    required this.lectureName,
  });

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch usage allocation when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parse lectureId to int for API call
    final folderId = int.tryParse(widget.lectureId) ?? 0;
    final documentsAsync = ref.watch(folderDocumentsProvider(folderId));
    final selectionState = ref.watch(documentSelectionProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: selectionState.isSelectionMode
          ? AppBar(
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white),
                onPressed: () {
                  ref.read(documentSelectionProvider.notifier).clearSelection();
                },
              ),
              title: Text(
                '${selectionState.selectionCount} selected',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: selectionState.selectionCount >= 1
                      ? () => _generateQuiz(context, ref, selectionState)
                      : null,
                  icon: const Icon(
                    Icons.quiz,
                    color: AppColors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Generate Quiz',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : BackNavigationAppBar(
              title: widget.lectureName,
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
                ? _buildDocumentsList(context, ref, documents, selectionState)
                : _buildEmptyState(context, ref);
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error.toString()),
        ),
      ),
      floatingActionButton: selectionState.isSelectionMode
          ? null
          : documentsAsync.maybeWhen(
              data: (documentsResponse) {
                final documents = documentsResponse.data ?? [];
                final hasDocuments = documents.isNotEmpty;
                return hasDocuments
                    ? FloatingActionButton(
                        onPressed: () => _checkCreditsAndUpload(context, ref),
                        backgroundColor: AppColors.primary,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add, color: AppColors.white),
                      )
                    : null;
              },
              orElse: () => null,
            ),
    );
  }

  Widget _buildDocumentsList(
    BuildContext context,
    WidgetRef ref,
    List<Data> documents,
    DocumentSelectionState selectionState,
  ) {
    final folderId = int.tryParse(widget.lectureId) ?? 0;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: selectionState.isSelectionMode
          ? documents.length
          : documents.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // First item is the Create Quiz button (only when NOT in selection mode)
        if (index == 0 && !selectionState.isSelectionMode) {
          return _buildCreateQuizButton(ref);
        }

        // Adjust index for documents (skip the button when not in selection mode)
        final documentIndex = selectionState.isSelectionMode
            ? index
            : index - 1;
        final document = documents[documentIndex];
        final icon = _getFileIcon(document.fileType ?? '');
        final size = _formatFileSize(document.fileSize ?? 0);
        final date = document.createdAt != null
            ? DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(document.createdAt!))
            : '';

        return Slidable(
          key: ValueKey(document.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) async {
                  final confirmed = await showDeleteConfirmationDialog(
                    context: context,
                    itemName: document.name ?? 'Document',
                    itemType: 'Document',
                    onDelete: () async {
                      // Call the API to delete document
                      final documentsService = ref.read(
                        documentsServiceProvider,
                      );
                      await documentsService.deleteFolderItem(
                        itemId: document.id!,
                      );
                      // Refresh documents list
                      ref.invalidate(folderDocumentsProvider(folderId));
                    },
                  );
                  // Show success snackbar if dialog returned true
                  if (confirmed && context.mounted) {
                    showSuccessSnackBar(
                      context: context,
                      message: 'Document deleted successfully',
                    );
                  }
                },
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: _buildDocumentCard(
            context: context,
            ref: ref,
            icon: icon,
            name: document.name ?? 'Untitled',
            size: size,
            date: date,
            document: document,
            selectionState: selectionState,
          ),
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
    required WidgetRef ref,
    required String icon,
    required String name,
    required String size,
    required String date,
    required Data document,
    required DocumentSelectionState selectionState,
  }) {
    final isSelected = selectionState.isSelected(document.s3Filename ?? '');

    return GestureDetector(
      onTap: () {
        // If in selection mode, toggle selection
        if (selectionState.isSelectionMode) {
          if (document.s3Filename != null) {
            final result = ref
                .read(documentSelectionProvider.notifier)
                .toggleSelection(document.s3Filename!, document.fileSize ?? 0);

            // Show feedback if limit reached
            if (result == SelectionToggleResult.maxLimitReached) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Maximum $kMaxQuizDocuments documents allowed for quiz generation',
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (result == SelectionToggleResult.sizeLimitReached) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Total file size cannot exceed $kMaxQuizTotalSizeMB MB. Current: ${selectionState.totalSizeFormatted}',
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
          return;
        }

        // Normal tap - open document
        if (document.s3Filename != null && document.s3Filename!.isNotEmpty) {
          final urlString = S3Utils.constructAssetUrl(document.s3Filename!);

          print('📄 Opening document: ${document.name}');
          print('🔗 S3 Filename: ${document.s3Filename}');
          print('🌐 Final URL: $urlString');

          context.push(
            '/student/document-viewer?url=${Uri.encodeComponent(urlString)}&name=${Uri.encodeComponent(document.name ?? 'Document')}',
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
        // Long press - enter selection mode
        if (document.s3Filename != null) {
          final result = ref
              .read(documentSelectionProvider.notifier)
              .toggleSelection(document.s3Filename!, document.fileSize ?? 0);

          // Show feedback if limit reached
          if (result == SelectionToggleResult.maxLimitReached) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Maximum $kMaxQuizDocuments documents allowed for quiz generation',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (result == SelectionToggleResult.sizeLimitReached) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Total file size cannot exceed $kMaxQuizTotalSizeMB MB. Current: ${selectionState.totalSizeFormatted}',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
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
            // Selection checkbox (only show in selection mode)
            if (selectionState.isSelectionMode) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                    : null,
              ),
              const SizedBox(width: 12),
            ],
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

  Widget _buildCreateQuizButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(documentSelectionProvider.notifier).enterSelectionMode();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.quiz, color: AppColors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select documents to generate quiz',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.white,
              size: 20,
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
            Image.asset('assets/icons/interview-fox.png', height: 150),
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
              onTap: () => _checkCreditsAndUpload(context, ref),
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

  Future<void> _checkCreditsAndUpload(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Check if user has document upload credits
    try {
      // Always fetch latest usage from API
      await ref.read(usageProvider.notifier).fetchUsageAllocation();

      // Get remaining document upload count
      final remainingUploads =
          ref
              .read(usageProvider)
              .usageAllocation
              ?.remainingDocumentUploadCount ??
          0;

      if (remainingUploads <= 0) {
        // Show dialog and redirect to student plans
        if (context.mounted) {
          final shouldBuyPlan = await showConfirmationDialog(
            context: context,
            title: 'No Document Upload Credits',
            subtitle:
                'You need document upload credits to upload files. Purchase a plan to continue.',
            icon: Icons.info_outline,
            iconBackgroundColor: AppColors.primary,
            confirmText: 'View Plans',
            cancelText: 'Cancel',
            confirmButtonColor: AppColors.primary,
            confirmTextColor: AppColors.white,
          );

          if (shouldBuyPlan == true && context.mounted) {
            await context.push('/student/plans');
            // Refresh usage after returning from plans
            if (context.mounted) {
              await ref.read(usageProvider.notifier).fetchUsageAllocation();
            }
          }
        }
        return; // Stop here, don't upload
      }

      // Has credits, proceed with upload
      await _pickAndUploadFile(context, ref);
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check credits: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

        // Validate file size (5MB = 5 * 1024 * 1024 bytes)
        const maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB
        if (fileSize > maxFileSizeInBytes) {
          final fileSizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File size ($fileSizeInMB MB) exceeds the 5MB limit. Please select a smaller file.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return; // Stop the upload process
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
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Uploading document...',
                        style: TextStyle(
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
        final folderId = int.tryParse(widget.lectureId) ?? 0;
        await documentsService.saveFolderItem(
          folderId: folderId,
          name: fileName,
          s3Filename: saveDocResponse.s3FileName ?? '',
          fileType: saveDocResponse.fileType ?? '',
          fileSize: fileSize,
        );

        // Step 4: Refresh documents list
        ref.invalidate(folderDocumentsProvider(folderId));

        // Step 5: Mark credits as used ONLY after successful upload
        // Run in background (non-blocking) - don't await
        final apiClient = APIClient();
        final subscriptionService = SubscriptionService(apiClient);
        subscriptionService
            .markCreditsUsed(
              resourceType: 'document_upload',
              count: 1,
              description: 'Document uploaded: $fileName',
              referenceId: saveDocResponse.s3FileName,
            )
            .catchError((e) {
              print('Failed to mark credits used: $e');
              // Silent fail - don't interrupt user experience
            });

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

  /// Generate quiz from selected documents
  Future<void> _generateQuiz(
    BuildContext context,
    WidgetRef ref,
    DocumentSelectionState selectionState,
  ) async {
    if (selectionState.selectedDocuments.isEmpty) return;

    // Check if user has quiz generation credits
    try {
      // Always fetch latest usage from API
      await ref.read(usageProvider.notifier).fetchUsageAllocation();

      // Get remaining quiz count
      final remainingQuizCount =
          ref.read(usageProvider).usageAllocation?.remainingQuizCount ?? 0;

      if (remainingQuizCount <= 0) {
        // Show dialog and redirect to student plans
        if (context.mounted) {
          final shouldBuyPlan = await showConfirmationDialog(
            context: context,
            title: 'No Quiz Generation Credits',
            subtitle:
                'You need quiz generation credits to create a quiz. Purchase a plan to continue.',
            icon: Icons.info_outline,
            iconBackgroundColor: AppColors.primary,
            confirmText: 'View Plans',
            cancelText: 'Cancel',
            confirmButtonColor: AppColors.primary,
            confirmTextColor: AppColors.white,
          );

          if (shouldBuyPlan == true && context.mounted) {
            await context.push('/student/plans');
            // Refresh usage after returning from plans
            if (context.mounted) {
              await ref.read(usageProvider.notifier).fetchUsageAllocation();
            }
          }
        }
        return; // Stop here, don't generate quiz
      }

      // Has credits, proceed with quiz generation
      // Reset progress
      ref.read(quizGenerationProgressProvider.notifier).reset();

      // Navigate to full-screen loading animation
      if (context.mounted) {
        context.push('/quiz/loading?sizeBytes=${selectionState.totalSize}');
      }

      // Call the generate quiz service with progress callback
      final service = ref.read(documentsServiceProvider);
      final quizAsync = await service.generateQuiz(
        s3Filenames: selectionState.selectedFilenames,
      );

      // Mark credits as used ONLY after successful quiz generation
      // Run in background (non-blocking) - don't await
      final apiClient = APIClient();
      final subscriptionService = SubscriptionService(apiClient);
      subscriptionService
          .markCreditsUsed(
            resourceType: 'quiz',
            count: 1,
            description:
                'Quiz generated from ${selectionState.selectionCount} documents',
            referenceId: widget.lectureName,
          )
          .catchError((e) {
            print('Failed to mark credits used: $e');
            // Silent fail - don't interrupt user experience
          });

      // Clear selection
      ref.read(documentSelectionProvider.notifier).clearSelection();

      // Navigate to quiz screen (replacing the loading screen)
      if (context.mounted) {
        context.pushReplacement(
          '/quiz/start?lectureName=${Uri.encodeComponent(widget.lectureName)}',
          extra: quizAsync,
        );
      }
    } catch (e) {
      // Go back from loading screen if it's showing
      if (context.mounted) {
        context.pop();
      }

      // Extract server error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      // Show error message from server
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
