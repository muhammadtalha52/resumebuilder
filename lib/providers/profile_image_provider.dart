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
      // Step 1: Upload image to S3
      final String s3FileName = await _profileImageService.uploadProfileImage(
        imageFile,
      );

      // Step 2: Update user profile with S3 filename
      await _profileService.updateProfileImage(s3FileName);

      // Step 3: Update user state with the constructed asset URL
      final String assetUrl = S3Utils.constructAssetUrl(s3FileName);
      final authNotifier = _ref.read(authProvider.notifier);
      await authNotifier.updateProfileImage(assetUrl);

      state = state.copyWith(isUploading: false);
    } catch (e) {
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
