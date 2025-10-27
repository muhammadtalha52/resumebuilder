import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/documents_response.dart';
import '../services/documents_service.dart';

enum DocumentFileType { pdf, doc, ppt, txt, other }

class Document {
  final String id;
  final String name;
  final String lectureId;
  final DocumentFileType fileType;
  final String? fileUrl;
  final int fileSize; // in bytes
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.name,
    required this.lectureId,
    required this.fileType,
    this.fileUrl,
    required this.fileSize,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  Document copyWith({
    String? id,
    String? name,
    String? lectureId,
    DocumentFileType? fileType,
    String? fileUrl,
    int? fileSize,
    DateTime? uploadedAt,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      lectureId: lectureId ?? this.lectureId,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  String get fileTypeIcon {
    switch (fileType) {
      case DocumentFileType.pdf:
        return '📄';
      case DocumentFileType.doc:
        return '📝';
      case DocumentFileType.ppt:
        return '📊';
      case DocumentFileType.txt:
        return '📋';
      case DocumentFileType.other:
        return '📁';
    }
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  static DocumentFileType getFileTypeFromExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return DocumentFileType.pdf;
      case 'doc':
      case 'docx':
        return DocumentFileType.doc;
      case 'ppt':
      case 'pptx':
        return DocumentFileType.ppt;
      case 'txt':
        return DocumentFileType.txt;
      default:
        return DocumentFileType.other;
    }
  }
}

class DocumentsNotifier extends StateNotifier<List<Document>> {
  DocumentsNotifier() : super([]);

  void addDocument({
    required String name,
    required String lectureId,
    required String filePath,
    required int fileSize,
  }) {
    final fileType = Document.getFileTypeFromExtension(name);
    final newDocument = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lectureId: lectureId,
      fileType: fileType,
      fileUrl: filePath,
      fileSize: fileSize,
    );
    state = [...state, newDocument];
  }

  void removeDocument(String id) {
    state = state.where((document) => document.id != id).toList();
  }

  void updateDocument(String id, String name) {
    state = [
      for (final document in state)
        if (document.id == id) document.copyWith(name: name) else document,
    ];
  }

  List<Document> getDocumentsForLecture(String lectureId) {
    return state.where((document) => document.lectureId == lectureId).toList();
  }

  int getDocumentCountForLecture(String lectureId) {
    return state.where((document) => document.lectureId == lectureId).length;
  }
}

final documentsProvider =
    StateNotifierProvider<DocumentsNotifier, List<Document>>((ref) {
      return DocumentsNotifier();
    });

// Service instance provider
final documentsServiceProvider = Provider<DocumentsService>((ref) {
  return DocumentsService();
});

// FutureProvider to fetch documents from API for a specific folder
final folderDocumentsProvider = FutureProvider.family
    .autoDispose<DocumentsResponse, int>((ref, folderId) async {
      final service = ref.watch(documentsServiceProvider);
      return await service.getFolderItems(folderId: folderId);
    });

/// Maximum number of documents allowed for quiz generation
const int kMaxQuizDocuments = 5;

/// Maximum total file size for quiz generation (10 MB)
const int kMaxQuizTotalSizeMB = 10;
const int kMaxQuizTotalSizeBytes = kMaxQuizTotalSizeMB * 1024 * 1024;

/// Document selection state for quiz generation
class DocumentSelectionState {
  final Map<String, int> selectedDocuments; // S3 filename -> file size (bytes)
  final bool isSelectionMode;

  DocumentSelectionState({
    required this.selectedDocuments,
    required this.isSelectionMode,
  });

  factory DocumentSelectionState.initial() {
    return DocumentSelectionState(
      selectedDocuments: {},
      isSelectionMode: false,
    );
  }

  DocumentSelectionState copyWith({
    Map<String, int>? selectedDocuments,
    bool? isSelectionMode,
  }) {
    return DocumentSelectionState(
      selectedDocuments: selectedDocuments ?? this.selectedDocuments,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get selectionCount => selectedDocuments.length;

  /// Total size of all selected documents in bytes
  int get totalSize =>
      selectedDocuments.values.fold(0, (sum, size) => sum + size);

  /// Total size formatted as human-readable string
  String get totalSizeFormatted {
    final sizeInMB = totalSize / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  bool get isAtMaxLimit => selectedDocuments.length >= kMaxQuizDocuments;

  bool get isAtMaxSize => totalSize >= kMaxQuizTotalSizeBytes;

  bool isSelected(String s3Filename) =>
      selectedDocuments.containsKey(s3Filename);

  /// Get list of selected S3 filenames
  List<String> get selectedFilenames => selectedDocuments.keys.toList();
}

/// Result of a selection toggle operation
enum SelectionToggleResult { added, removed, maxLimitReached, sizeLimitReached }

/// Notifier for managing document selection
class DocumentSelectionNotifier extends StateNotifier<DocumentSelectionState> {
  DocumentSelectionNotifier() : super(DocumentSelectionState.initial());

  /// Toggle selection for a document
  /// Returns the result of the operation
  SelectionToggleResult toggleSelection(String s3Filename, int fileSize) {
    final newSelected = Map<String, int>.from(state.selectedDocuments);

    if (newSelected.containsKey(s3Filename)) {
      // Deselecting - always allowed
      newSelected.remove(s3Filename);
      // Exit selection mode if no documents selected
      state = state.copyWith(
        selectedDocuments: newSelected,
        isSelectionMode: newSelected.isNotEmpty,
      );
      return SelectionToggleResult.removed;
    } else {
      // Selecting - check count limit
      if (state.isAtMaxLimit) {
        // Don't allow selection beyond max count limit
        return SelectionToggleResult.maxLimitReached;
      }

      // Check size limit - calculate what the new total would be
      final newTotalSize = state.totalSize + fileSize;
      if (newTotalSize > kMaxQuizTotalSizeBytes) {
        // Don't allow selection if it exceeds size limit
        return SelectionToggleResult.sizeLimitReached;
      }

      // Add document with its size
      newSelected[s3Filename] = fileSize;
      // Enter selection mode
      state = state.copyWith(
        selectedDocuments: newSelected,
        isSelectionMode: true,
      );
      return SelectionToggleResult.added;
    }
  }

  /// Clear all selections
  void clearSelection() {
    state = DocumentSelectionState.initial();
  }

  /// Enter selection mode without selecting any documents
  void enterSelectionMode() {
    state = state.copyWith(isSelectionMode: true);
  }
}

/// Provider for document selection state
final documentSelectionProvider =
    StateNotifierProvider.autoDispose<
      DocumentSelectionNotifier,
      DocumentSelectionState
    >((ref) {
      return DocumentSelectionNotifier();
    });
