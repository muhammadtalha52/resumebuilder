import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

class InviteState {
  final bool isLoading;
  final bool isFetching;
  final String? error;
  final List<String> sentEmails;
  final int invitesSent;

  const InviteState({
    this.isLoading = false,
    this.isFetching = false,
    this.error,
    this.sentEmails = const [],
    this.invitesSent = 0,
  });

  InviteState copyWith({
    bool? isLoading,
    bool? isFetching,
    String? error,
    List<String>? sentEmails,
    int? invitesSent,
  }) {
    return InviteState(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      error: error,
      sentEmails: sentEmails ?? this.sentEmails,
      invitesSent: invitesSent ?? this.invitesSent,
    );
  }
}

class InviteNotifier extends StateNotifier<InviteState> {
  final AuthService _authService;

  InviteNotifier(this._authService) : super(const InviteState());

  Future<void> fetchInvites() async {
    state = state.copyWith(isFetching: true, error: null);

    try {
      final response = await _authService.getInvites();

      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        final invites = data['invites'] as List<dynamic>? ?? [];
        final totalInvites = data['total_invites'] as int? ?? invites.length;

        final emails = invites
            .map((invite) => invite['invitee_email'] as String? ?? '')
            .where((email) => email.isNotEmpty)
            .toList();

        state = state.copyWith(
          isFetching: false,
          sentEmails: emails,
          invitesSent: totalInvites,
          error: null,
        );
      } else {
        state = state.copyWith(isFetching: false);
      }
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> sendInvite(String email) async {
    // Check if email was already invited
    if (state.sentEmails.contains(email)) {
      state = state.copyWith(
        error: 'You have already invited this email address',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.sendInviteEmail(email: email);

      final data = response['data'] as Map<String, dynamic>?;
      final totalInvites =
          data?['total_invites_sent'] as int? ??
          data?['invite_count'] as int? ??
          state.invitesSent + 1;
      final updatedEmails = [...state.sentEmails, email];
      state = state.copyWith(
        isLoading: false,
        sentEmails: updatedEmails,
        invitesSent: totalInvites,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final inviteProvider = StateNotifierProvider<InviteNotifier, InviteState>((
  ref,
) {
  return InviteNotifier(AuthService());
});
