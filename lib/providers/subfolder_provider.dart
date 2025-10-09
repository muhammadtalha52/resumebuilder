import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_folders_response.dart';
import 'study_space_provider.dart';

// AsyncNotifier for managing subfolders of a specific parent folder
class SubfolderNotifier extends FamilyAsyncNotifier<List<ParentFolder>, int> {
  @override
  Future<List<ParentFolder>> build(int parentFolderId) async {
    // Load subfolders from server on initialization
    return await _fetchSubfolders(parentFolderId);
  }

  Future<List<ParentFolder>> _fetchSubfolders(int parentId) async {
    final folderService = ref.read(folderServiceProvider);
    return await folderService.getSubfolders(parentId: parentId);
  }

  // Refresh subfolders from server (keeps current data visible during refresh)
  Future<void> refreshSubfolders() async {
    // Don't show loading state, just fetch in background
    // This preserves the current UI while refreshing
    state = await AsyncValue.guard(() => _fetchSubfolders(arg));
  }

  // Add new subfolder
  Future<void> addSubfolder(String name) async {
    try {
      final folderService = ref.read(folderServiceProvider);
      // Create subfolder with parent ID
      await folderService.createFolder(
        name: name,
        description: null,
        parentId: arg,
      );
      // Refresh the list to show the new subfolder
      await refreshSubfolders();
    } catch (e) {
      // Rethrow to handle in UI
      rethrow;
    }
  }

  // Remove subfolder
  Future<void> removeSubfolder(int folderId) async {
    try {
      final folderService = ref.read(folderServiceProvider);
      // Delete subfolder on server
      await folderService.deleteFolder(folderId: folderId);
      // Refresh the list to remove the deleted subfolder
      await refreshSubfolders();
    } catch (e) {
      // Rethrow to handle in UI
      rethrow;
    }
  }

  // Update subfolder
  Future<void> updateSubfolder(int folderId, String name) async {
    try {
      final folderService = ref.read(folderServiceProvider);
      // Update subfolder on server
      await folderService.updateFolder(
        folderId: folderId,
        name: name,
        description: null,
      );
      // Refresh the list to show the updated subfolder
      await refreshSubfolders();
    } catch (e) {
      // Rethrow to handle in UI
      rethrow;
    }
  }
}

// Provider family to create separate subfolder providers for each parent folder
final subfolderProvider =
    AsyncNotifierProvider.family<SubfolderNotifier, List<ParentFolder>, int>(
      () => SubfolderNotifier(),
    );
