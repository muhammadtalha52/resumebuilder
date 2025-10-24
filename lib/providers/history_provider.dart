import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/history_service.dart';

class ResumeHistory {
  final int id;
  final String userEmail;
  final String title;
  final String template;
  final String companyName;
  final String jobTitle;
  final String linkedinJobUrl;
  final bool isActive;
  final bool isPublic;
  final int viewCount;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> contentPreview;
  final String resumeUrl;

  ResumeHistory({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.template,
    required this.companyName,
    required this.jobTitle,
    required this.linkedinJobUrl,
    required this.isActive,
    required this.isPublic,
    required this.viewCount,
    required this.downloadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.contentPreview,
    required this.resumeUrl,
  });

  factory ResumeHistory.fromJson(Map<String, dynamic> json) {
    return ResumeHistory(
      id: json['id'],
      userEmail: json['user_email'] ?? '',
      title: json['title'] ?? '',
      template: json['template'] ?? 'classic',
      companyName: json['company_name'] ?? '',
      jobTitle: json['job_title'] ?? '',
      linkedinJobUrl: json['linkedin_job_url'] ?? '',
      isActive: json['is_active'] ?? true,
      isPublic: json['is_public'] ?? false,
      viewCount: json['view_count'] ?? 0,
      downloadCount: json['download_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      contentPreview: json['content_preview'] ?? {},
      resumeUrl: json['resume_url'] ?? '',
    );
  }
}

class HistoryState {
  final List<ResumeHistory> resumes;
  final bool isLoading;
  final String? error;

  HistoryState({this.resumes = const [], this.isLoading = false, this.error});

  HistoryState copyWith({
    List<ResumeHistory>? resumes,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      resumes: resumes ?? this.resumes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryService _historyService;

  HistoryNotifier(this._historyService) : super(HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _historyService.getResumeHistory();

      if (!mounted) return;
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> resumesJson = response['data'];
        final resumes = resumesJson
            .map((json) => ResumeHistory.fromJson(json))
            .toList();

        state = state.copyWith(resumes: resumes, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load resume history',
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading resume history: ${e.toString()}',
      );
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }

  Future<void> deleteResume(int id) async {
    try {
      await _historyService.deleteResume(id);

      // Remove from local state after successful deletion
      final updatedResumes = state.resumes.where((r) => r.id != id).toList();
      state = state.copyWith(resumes: updatedResumes);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete resume: ${e.toString()}');
    }
  }
}

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  final historyService = ref.watch(historyServiceProvider);
  return HistoryNotifier(historyService);
});
