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
