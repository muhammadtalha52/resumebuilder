import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_image_service.dart';
import '../services/profile_service.dart';
import '../utils/s3_utils.dart';
import 'auth_provider.dart';

// State class for profile image upload
class ProfileImageState {
  final bool isUploading;
  final String? error;

  ProfileImageState({required this.isUploading, this.error});

  ProfileImageState copyWith({bool? isUploading, String? error}) {
    return ProfileImageState(
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

// Profile image notifier
class ProfileImageNotifier extends StateNotifier<ProfileImageState> {
  final ProfileImageService _profileImageService = ProfileImageService();
  final ProfileService _profileService = ProfileService();
  final Ref _ref;

  ProfileImageNotifier(this._ref)
    : super(ProfileImageState(isUploading: false));

  Future<void> uploadProfileImage(File imageFile) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      print('[ProfileImage] Starting profile image upload');
      final currentUser = _ref.read(authProvider).user;
      print(
        '[ProfileImage] Current user data before upload: ${currentUser?.toJson()}',
      );

      // Step 1: Upload image to S3
      final String s3FileName = await _profileImageService.uploadProfileImage(
        imageFile,
      );
      print('[ProfileImage] S3 upload successful: $s3FileName');

      // Step 2: Update user profile with S3 filename and get fresh user data
      final updateResponse = await _profileService.updateProfileImage(
        s3FileName,
      );
      print('[ProfileImage] API Response Status: ${updateResponse.status}');
      print(
        '[ProfileImage] API Response Data: ${updateResponse.data?.toJson()}',
      );

      // Step 3: Use fresh API data and update only profile_image to full URL
      if (updateResponse.status == 'success' && updateResponse.data != null) {
        final apiUser = updateResponse.data!;
        final String assetUrl = S3Utils.constructAssetUrl(
          apiUser.profileImage ?? '',
        );
        print('[ProfileImage] Constructed asset URL: $assetUrl');

        // Use API response data + only update profile image to full URL
        final updatedUser = apiUser.copyWith(profileImage: assetUrl);
        print(
          '[ProfileImage] Updated user with full URL: ${updatedUser.toJson()}',
        );

        // Update auth state with fresh API data
        final authNotifier = _ref.read(authProvider.notifier);
        authNotifier.updateUserData(updatedUser);

        final finalUser = _ref.read(authProvider).user;
        print('[ProfileImage] User data after update: ${finalUser?.toJson()}');

        state = state.copyWith(isUploading: false);
        print('[ProfileImage] Profile image upload completed successfully');
      } else {
        throw Exception(
          updateResponse.message ?? 'Failed to update profile image',
        );
      }
    } catch (e) {
      print('[ProfileImage] Error during upload: $e');
      state = state.copyWith(
        isUploading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, ProfileImageState>((ref) {
      return ProfileImageNotifier(ref);
    });
