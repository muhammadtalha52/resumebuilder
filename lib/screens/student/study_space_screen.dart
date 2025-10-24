import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/all_folders_response.dart';
import '../../providers/study_space_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/dialogs/create_subject_dialog.dart';
import '../../widgets/dialogs/delete_confirmation_dialog.dart';
import 'lectures_screen.dart';

class StudySpaceScreen extends ConsumerStatefulWidget {
  const StudySpaceScreen({super.key});

  @override
  ConsumerState<StudySpaceScreen> createState() => _StudySpaceScreenState();
}

class _StudySpaceScreenState extends ConsumerState<StudySpaceScreen> {
  @override
  void initState() {
    super.initState();
    // Load folders when screen is mounted
    // Using addPostFrameCallback to ensure it runs after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studySpaceProvider.notifier).loadFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(studySpaceProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: 'Study Space'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            onPressed: () {
              context.push('/quiz/history');
            },
            tooltip: 'Quiz History',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          foldersAsync.when(
            data: (folders) {
              // Filter to show only parent folders (level 0)
              final parentFolders = folders
                  .where((folder) => folder.parent == null || folder.level == 0)
                  .toList();
              final hasFolders = parentFolders.isNotEmpty;
              return hasFolders
                  ? _buildFoldersList(context, ref, parentFolders)
                  : _buildEmptyState(context, ref);
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
                  Text(
                    'Failed to load folders',
                    style: const TextStyle(
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
                      ref.read(studySpaceProvider.notifier).refreshFolders();
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
        ],
      ),
      floatingActionButton: foldersAsync.maybeWhen(
        data: (folders) => folders.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _showCreateSubjectDialog(context, ref),
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: AppColors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildFoldersList(
    BuildContext context,
    WidgetRef ref,
    List<ParentFolder> folders,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(studySpaceProvider.notifier).refreshFolders();
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: folders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final folder = folders[index];
          return Slidable(
            key: ValueKey(folder.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    final result = await showCreateSubjectDialog(
                      context: context,
                      initialName: folder.name ?? '',
                      initialEmoji: '📁',
                      onCreateFolder: (name, emoji) async {
                        // Call the API to update folder
                        await ref
                            .read(studySpaceProvider.notifier)
                            .updateFolder(folder.id!, name);
                      },
                    );
                    // Show success snackbar if dialog returned result
                    if (result != null && context.mounted) {
                      showSuccessSnackBar(
                        context: context,
                        message: 'Folder updated successfully',
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
                      itemName: folder.name ?? 'Folder',
                      itemType: 'Folder',
                      onDelete: () async {
                        // Call the API to delete folder
                        await ref
                            .read(studySpaceProvider.notifier)
                            .removeFolder(folder.id!);
                      },
                    );
                    // Show success snackbar if dialog returned true
                    if (confirmed && context.mounted) {
                      showSuccessSnackBar(
                        context: context,
                        message: 'Folder deleted successfully',
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
            child: _buildFolderCard(
              emoji: '📁',
              name: folder.name ?? 'Unnamed Folder',
              lectures: folder.subfolders?.length ?? 0,
              files: folder.itemsCount ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LecturesScreen(
                      subjectId: folder.id.toString(),
                      subjectName: folder.name ?? 'Folder',
                    ),
                  ),
                ).then((_) {
                  // Refresh folders when coming back from lectures screen
                  ref.read(studySpaceProvider.notifier).refreshFolders();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderCard({
    required String emoji,
    required String name,
    required int lectures,
    required int files,
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
            // Folder info
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
                    '$lectures Item${lectures != 1 ? 's' : ''}',
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: double.infinity,
        height: double.infinity,
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
              'Organize Your Study\nMaterials with Scout',
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
              'Create subjects, add lectures, and upload\nyour documents for easy access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => _showCreateSubjectDialog(context, ref),
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
                      'Create Your First Subject',
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

  void _showCreateSubjectDialog(BuildContext context, WidgetRef ref) async {
    final result = await showCreateSubjectDialog(
      context: context,
      onCreateFolder: (name, emoji) async {
        // Call the API to create folder
        await ref.read(studySpaceProvider.notifier).addFolder(name, emoji);
      },
    );

    // Show success snackbar only if dialog returned result (meaning it was successful)
    if (result != null && context.mounted) {
      showSuccessSnackBar(
        context: context,
        message: 'Folder created successfully',
      );
    }
  }
}
