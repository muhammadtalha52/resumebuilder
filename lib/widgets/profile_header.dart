import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/date_helpers.dart';
import '../providers/profile_image_provider.dart';
import '../services/image_picker_service.dart';
import '../utils/s3_utils.dart';

class ProfileHeader extends ConsumerStatefulWidget {
  const ProfileHeader({super.key});

  @override
  ConsumerState<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<ProfileHeader> {
  final ImagePickerService _imagePickerService = ImagePickerService();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileImageState = ref.watch(profileImageProvider);
    final user = authState.user;

    // Listen for errors from profile image provider
    ref.listen<ProfileImageState>(profileImageProvider, (previous, current) {
      if (current.error != null && previous?.error != current.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile image: ${current.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: profileImageState.isUploading ? null : _onProfileImageTap,
            child: Stack(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8E8E8),
                      width: 2,
                    ),
                  ),
                  child: profileImageState.isUploading
                      ? CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : _hasProfileImage(user?.profileImage)
                      ? CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: NetworkImage(
                            S3Utils.getProfileImageUrl(user!.profileImage),
                          ),
                          onBackgroundImageError: (_, _) {},
                          child: null,
                        )
                      : CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            _getInitials(user?.fullName),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                if (!profileImageState.isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _hasProfileImage(user?.profileImage)
                            ? Icons.edit
                            : Icons.add,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getJoinedDate(user?.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? fullName) {
    final name = (fullName?.trim().isNotEmpty == true) ? fullName!.trim() : 'User';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  bool _hasProfileImage(String? profileImage) {
    return profileImage != null && profileImage.isNotEmpty;
  }

  String _getJoinedDate(String? createdAt) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Determine label based on role: 1 = Candidate, 2 = Student
    final label = (user?.role == 2) ? 'Study Partner' : 'Member';

    if (createdAt == null || createdAt.isEmpty) {
      return '$label since recently';
    }

    try {
      final date = DateTime.parse(createdAt);
      return '$label since ${DateHelpers.formatToDisplayDate(date)}';
    } catch (e) {
      return '$label since recently';
    }
  }

  Future<void> _onProfileImageTap() async {
    try {
      // Pick and crop image
      final File? imageFile = await _imagePickerService.pickAndCropImage(
        context,
      );
      if (imageFile != null) {
        // Upload image using Riverpod provider
        await ref
            .read(profileImageProvider.notifier)
            .uploadProfileImage(imageFile);

        // Show success message if no error occurred
        final currentState = ref.read(profileImageProvider);
        if (!currentState.isUploading && currentState.error == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Image picker errors (permission denied, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to select image: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
