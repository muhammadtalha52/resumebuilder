import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meeting_history_response.dart';
import '../services/meeting_history_service.dart';

class MeetingHistoryState {
  final List<MeetingHistoryItem> meetings;
  final bool isLoading;
  final String? error;

  MeetingHistoryState({
    this.meetings = const [],
    this.isLoading = false,
    this.error,
  });

  MeetingHistoryState copyWith({
    List<MeetingHistoryItem>? meetings,
    bool? isLoading,
    String? error,
  }) {
    return MeetingHistoryState(
      meetings: meetings ?? this.meetings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MeetingHistoryNotifier extends StateNotifier<MeetingHistoryState> {
  final MeetingHistoryService _service;

  MeetingHistoryNotifier(this._service) : super(MeetingHistoryState()) {
    loadMeetings();
  }

  Future<void> loadMeetings() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getMeetingHistory();

      if (!mounted) return;
      if (response.status == 'success' && response.data != null) {
        // Sort by date, most recent first
        final sortedMeetings = List<MeetingHistoryItem>.from(response.data!)
          ..sort((a, b) {
            final dateA = a.createdAt ?? DateTime.now();
            final dateB = b.createdAt ?? DateTime.now();
            return dateB.compareTo(dateA);
          });

        state = state.copyWith(meetings: sortedMeetings, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load meeting history',
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading meeting history: ${e.toString()}',
      );
    }
  }

  Future<void> refreshMeetings() async {
    await loadMeetings();
  }

  Future<void> deleteMeeting(int id) async {
    try {
      await _service.deleteMeeting(id);

      // Remove from local state after successful deletion
      final updatedMeetings = state.meetings.where((m) => m.id != id).toList();
      state = state.copyWith(meetings: updatedMeetings);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete meeting: ${e.toString()}',
      );
    }
  }
}

final meetingHistoryServiceProvider = Provider<MeetingHistoryService>((ref) {
  return MeetingHistoryService();
});

final meetingHistoryProvider =
    StateNotifierProvider<MeetingHistoryNotifier, MeetingHistoryState>((ref) {
      final service = ref.watch(meetingHistoryServiceProvider);
      return MeetingHistoryNotifier(service);
    });
