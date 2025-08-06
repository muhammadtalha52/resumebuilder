import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8E8E8), width: 2),
                ),
                child: _hasProfileImage(user?.profileImage)
                    ? CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: NetworkImage(user!.profileImage!),
                        onBackgroundImageError: (_, __) {},
                        child: null,
                      )
                    : CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
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
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Alex John',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.jobTitles ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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
    final name = fullName ?? 'Alex John';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'AJ';
  }

  String _getRoleDisplayName(int? roleId) {
    switch (roleId) {
      case 1:
        return 'Student';
      case 2:
        return 'Professional';
      case 3:
        return 'Freelancer';
      default:
        return 'Software Engineer';
    }
  }

  bool _hasProfileImage(dynamic profileImage) {
    if (profileImage == null) return false;
    if (profileImage is String) {
      return profileImage.isNotEmpty;
    }
    return false;
  }
}
