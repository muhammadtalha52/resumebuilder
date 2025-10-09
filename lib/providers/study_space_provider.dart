import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_folders_response.dart';
import '../services/folder_service.dart';

// Service provider
final folderServiceProvider = Provider<FolderService>((ref) {
  return FolderService();
});

// AsyncNotifier for managing study space folders
class StudySpaceNotifier extends AsyncNotifier<List<ParentFolder>> {
  @override
  Future<List<ParentFolder>> build() async {
    // Load folders from server on initialization
    return await _fetchFolders();
  }

  Future<List<ParentFolder>> _fetchFolders() async {
    final folderService = ref.read(folderServiceProvider);
    final response = await folderService.getAllFolders();
    return response.parentFolders ?? [];
  }

  // Refresh folders from server (keeps current data visible during refresh)
  Future<void> refreshFolders() async {
    // Don't show loading state, just fetch in background
    // This preserves the current UI while refreshing
    state = await AsyncValue.guard(() => _fetchFolders());
  }

  // Add new folder
  Future<void> addFolder(String name, String emoji) async {
    try {
      final folderService = ref.read(folderServiceProvider);
      // Create folder on server (parent is null for top-level folders)
      await folderService.createFolder(
        name: name,
        description: null,
        parentId: null,
      );
      // Refresh the list to show the new folder
      await refreshFolders();
    } catch (e) {
      // Rethrow to handle in UI
      rethrow;
    }
  }

  // Remove folder
  Future<void> removeFolder(int folderId) async {
    try {
      final folderService = ref.read(folderServiceProvider);
      // Delete folder on server
      await folderService.deleteFolder(folderId: folderId);
      // Refresh the list to remove the deleted folder
      await refreshFolders();
    } catch (e) {
      // Rethrow to handle in UI
      rethrow;
    }
  }

  // Update folder
  Future<void> updateFolder(int folderId, String name) async {
    try {
      final folderService = ref.read(folderServiceProvider);
      // Update folder on server
      await folderService.updateFolder(
        folderId: folderId,
        name: name,
        description: null,
      );
      // Refresh the list to show the updated folder
      await refreshFolders();
    } catch (e) {
      // Rethrow to handle in UI
      rethrow;
    }
  }
}

final studySpaceProvider =
    AsyncNotifierProvider<StudySpaceNotifier, List<ParentFolder>>(
      () => StudySpaceNotifier(),
    );
