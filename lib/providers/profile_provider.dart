import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_update_state.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

class ProfileNotifier extends StateNotifier<ProfileUpdateState> {
  final Ref ref;
  final ProfileService _profileService;

  ProfileNotifier(this.ref, this._profileService)
    : super(const ProfileUpdateState());

  void initializeWithUserData(User? user) {
    if (user == null) return;

    final originalValues = {
      'full_name': user.fullName ?? '',
      'phone_number': user.phoneNumber ?? '',
      'linkedin_url': user.linkedinUrl ?? '',
      'portfolio_url': user.portfolioUrl ?? '',
    };

    state = state.copyWith(
      originalValues: originalValues,
      currentValues: Map.from(originalValues),
      completePhoneNumber: user.phoneNumber ?? '',
      hasChanges: false,
    );
  }

  void updateField(String field, String value) {
    final updatedValues = Map<String, String>.from(state.currentValues);
    updatedValues[field] = value;

    state = state.copyWith(
      currentValues: updatedValues,
      hasChanges: _checkForChanges(updatedValues),
      error: null,
    );
  }

  void updatePhoneNumber(String completeNumber, String displayNumber) {
    final updatedValues = Map<String, String>.from(state.currentValues);
    updatedValues['phone_number'] = displayNumber;

    state = state.copyWith(
      currentValues: updatedValues,
      completePhoneNumber: completeNumber,
      hasChanges: _checkForChanges(updatedValues, completeNumber),
      error: null,
    );
  }

  bool _checkForChanges(
    Map<String, String> currentValues, [
    String? phoneNumber,
  ]) {
    final checkPhone = phoneNumber ?? state.completePhoneNumber;

    // Check if any field has changed from its original value
    for (final entry in currentValues.entries) {
      if (entry.key == 'phone_number') {
        if (checkPhone != state.originalValues['phone_number']) {
          return true;
        }
      } else if (entry.value != state.originalValues[entry.key]) {
        return true;
      }
    }
    return false;
  }

  Future<bool> updateProfile() async {
    // Check if there are any changes
    final changes = state.getChangedFields();
    if (changes.isEmpty) {
      state = state.copyWith(error: 'No changes to save');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call the profile service to update
      final updateResponse = await _profileService.updateProfile(changes);

      // Check if the update was successful
      if (updateResponse.status == 'success' && updateResponse.data != null) {
        final updatedUser = updateResponse.data!;

        // Update the auth provider with new user data
        ref.read(authProvider.notifier).updateUserData(updatedUser);

        // Reset the state with new original values
        final newOriginalValues = {
          'full_name': updatedUser.fullName ?? '',
          'phone_number': updatedUser.phoneNumber ?? '',
          'linkedin_url': updatedUser.linkedinUrl ?? '',
          'portfolio_url': updatedUser.portfolioUrl ?? '',
        };

        state = state.copyWith(
          isLoading: false,
          originalValues: newOriginalValues,
          currentValues: Map.from(newOriginalValues),
          completePhoneNumber: updatedUser.phoneNumber ?? '',
          hasChanges: false,
          error: null,
        );

        return true;
      } else {
        throw Exception(updateResponse.message ?? 'Profile update failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Generic update method for any profile fields
  Future<bool> updateProfileFields(Map<String, dynamic> updateData) async {
    if (updateData.isEmpty) {
      state = state.copyWith(error: 'No changes to save');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call the profile service to update
      final updateResponse = await _profileService.updateProfile(updateData);

      // Check if the update was successful
      if (updateResponse.status == 'success' && updateResponse.data != null) {
        final updatedUser = updateResponse.data!;

        // Update the auth provider with new user data
        ref.read(authProvider.notifier).updateUserData(updatedUser);

        state = state.copyWith(isLoading: false, error: null);

        return true;
      } else {
        throw Exception(updateResponse.message ?? 'Profile update failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const ProfileUpdateState();
  }
}

// Provider for the profile notifier
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileUpdateState>((ref) {
      final profileService = ProfileService();
      return ProfileNotifier(ref, profileService);
    });
