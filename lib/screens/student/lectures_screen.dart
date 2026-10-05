import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/all_folders_response.dart';
import '../../providers/subfolder_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/dialogs/create_lecture_dialog.dart';
import '../../widgets/dialogs/delete_confirmation_dialog.dart';

class LecturesScreen extends ConsumerWidget {
  final String subjectId;
  final String subjectName;

  const LecturesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentFolderId = int.parse(subjectId);
    final subfoldersAsync = ref.watch(subfolderProvider(parentFolderId));

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: subjectName,
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
        child: subfoldersAsync.when(
          data: (subfolders) {
            final hasSubfolders = subfolders.isNotEmpty;
            return hasSubfolders
                ? _buildLecturesList(context, ref, subfolders, parentFolderId)
                : _buildEmptyState(context, ref, parentFolderId);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load lectures',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(subfolderProvider(parentFolderId).notifier)
                        .refreshSubfolders();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: subfoldersAsync.maybeWhen(
        data: (subfolders) => subfolders.isNotEmpty
            ? FloatingActionButton(
                onPressed: () =>
                    _showCreateLectureDialog(context, ref, parentFolderId),
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: AppColors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildLecturesList(
    BuildContext context,
    WidgetRef ref,
    List<ParentFolder> subfolders,
    int parentFolderId,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(subfolderProvider(parentFolderId).notifier)
            .refreshSubfolders();
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: subfolders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final subfolder = subfolders[index];
          final documentCount = subfolder.itemsCount ?? 0;
          return Slidable(
            key: ValueKey(subfolder.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    final result = await showCreateLectureDialog(
                      context: context,
                      initialName: subfolder.name ?? '',
                      onCreateFolder: (name, emoji) async {
                        // Call the API to update subfolder
                        await ref
                            .read(subfolderProvider(parentFolderId).notifier)
                            .updateSubfolder(subfolder.id!, name);
                      },
                    );
                    // Show success snackbar if dialog returned result
                    if (result != null && context.mounted) {
                      showSuccessSnackBar(
                        context: context,
                        message: 'Lecture updated successfully',
                      );
                    }
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
                SlidableAction(
                  onPressed: (context) async {
                    final confirmed = await showDeleteConfirmationDialog(
                      context: context,
                      itemName: subfolder.name ?? 'Lecture',
                      itemType: 'Lecture',
                      onDelete: () async {
                        // Call the API to delete subfolder
                        await ref
                            .read(subfolderProvider(parentFolderId).notifier)
                            .removeSubfolder(subfolder.id!);
                      },
                    );
                    // Show success snackbar if dialog returned true
                    if (confirmed && context.mounted) {
                      showSuccessSnackBar(
                        context: context,
                        message: 'Lecture deleted successfully',
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
            child: _buildLectureCard(
              emoji: '📁',
              name: subfolder.name ?? 'Unnamed Lecture',
              documents: documentCount,
              onTap: () async {
                await context.push(
                  '/student/documents?lectureId=${subfolder.id}&lectureName=${Uri.encodeComponent(subfolder.name ?? 'Lecture')}',
                );
                // Refresh lectures when coming back from documents screen
                ref
                    .read(subfolderProvider(parentFolderId).notifier)
                    .refreshSubfolders();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLectureCard({
    required String emoji,
    required String name,
    required int documents,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            // Emoji/Icon
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Lecture info
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$documents Document${documents != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    int parentFolderId,
  ) {
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
        child: SingleChildScrollView(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scout fox image
            Image.asset('assets/icons/interview-fox.png', height: 150),
            const SizedBox(height: 32),
            const Text(
              'No Lectures Yet',
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
              'Start organizing your study materials\nby adding your first lecture.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () =>
                  _showCreateLectureDialog(context, ref, parentFolderId),
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
                    Icon(Icons.add, color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    const Text(
                      'Add Your First Lecture',
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
      ),
    );
  }

  void _showCreateLectureDialog(
    BuildContext context,
    WidgetRef ref,
    int parentFolderId,
  ) async {
    final result = await showCreateLectureDialog(
      context: context,
      onCreateFolder: (name, emoji) async {
        // Call the API to create subfolder
        await ref
            .read(subfolderProvider(parentFolderId).notifier)
            .addSubfolder(name);
      },
    );

    // Show success snackbar only if dialog returned result (meaning it was successful)
    if (result != null && context.mounted) {
      showSuccessSnackBar(
        context: context,
        message: 'Lecture created successfully',
      );
    }
  }
}
