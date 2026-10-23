import '../../services/onboarding_funnel_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../common/main_screen.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_helpers.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/tag_list.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import '../../widgets/invite_friends_card.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/common/web_app_banner.dart';
import '../../widgets/profile_header.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "Profile"),
        actions: [_buildLogoutMenu(context, ref)],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const InviteFriendsCard(isStudent: true),
                const SizedBox(height: 16),
                const ProfileHeader(),
                const SizedBox(height: 16),
                const WebAppProfileTile(),
                const SizedBox(height: 16),
                _buildPersonalDetailsCard(context, ref),
                const SizedBox(height: 16),
                _buildCareerGoalsCard(context, ref),
                const SizedBox(height: 16),
                _buildEducationCard(context, ref),
                const SizedBox(height: 16),
                _buildTourGuideCard(context, ref),
                const SizedBox(height: 16),
                _buildLogoutButton(context, ref),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return ProfileCard(
      title: '👤 Personal Details',
      onEdit: () {
        context.push('/student/profile/edit-personal-details');
      },
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRowWithDivider(
            'assets/icons/user.png',
            'Full Name',
            user?.fullName ?? '',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/mail.png',
            'Email Address',
            user?.email ?? '',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/whatsapp.png',
            'Phone Number',
            user?.phoneNumber ?? '',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/work.png',
            'Home Town',
            user?.homeTown ?? '',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCareerGoalsCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Extract titles from IdealJobTitle objects
    final idealJobTitles =
        user?.idealJobTitles?.map((job) => job.title ?? 'Unknown').toList() ??
        [];

    return ProfileCard(
      title: '🎯 Career Goals',
      onEdit: () {
        context.push('/student/profile/edit-career-goals');
      },
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCareerDetailRow(
            'assets/icons/goals.png',
            'Ideal Job Titles',
            idealJobTitles,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Format graduation date to MM/DD/YYYY
    String formattedGraduationDate = '';
    if (user?.schoolGraduationDate != null &&
        user!.schoolGraduationDate!.isNotEmpty) {
      final parsedDate = DateHelpers.parseApiDate(user.schoolGraduationDate);
      if (parsedDate != null) {
        formattedGraduationDate = DateHelpers.formatToDisplayDate(parsedDate);
      }
    }

    return ProfileCard(
      title: '🎓 Education',
      onEdit: () {
        context.push('/student/profile/edit-education');
      },
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEducationDetailRow(
            user?.schoolMajor ?? '',
            user?.schoolName ?? '',
            formattedGraduationDate,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithDivider(
    String icon,
    String label,
    String value, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(icon, width: 20, height: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.inputBorder,
            ),
          ),
      ],
    );
  }

  Widget _buildCareerDetailRow(
    String icon,
    String label,
    List<String> tags, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(icon, width: 20, height: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TagList(tags: tags),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.inputBorder,
            ),
          ),
      ],
    );
  }

  Widget _buildEducationDetailRow(
    String major,
    String school,
    String date, {
    required bool showDivider,
  }) {
    // Check if degree is not completed (no graduation date)
    final isDegreeCompleted = date.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.school_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (major.isNotEmpty) ...[
                      RichText(
                        text: TextSpan(
                          text: 'Major: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: major,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (school.isNotEmpty) ...[
                      RichText(
                        text: TextSpan(
                          text: 'Institute: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: school,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Show graduation date only if completed
                    if (isDegreeCompleted) ...[
                      RichText(
                        text: TextSpan(
                          text: 'Graduation: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: date,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.inputBorder,
            ),
          ),
      ],
    );
  }

  Widget _buildTourGuideCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await OnboardingFunnelService.instance.resetTour();
            ref.read(navigationIndexProvider.notifier).state = 0;
            ref.read(forceTourTriggerProvider.notifier).state++;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take Guided Tour',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Learn how to get the most out of the app',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: ElevatedButton(
        onPressed: () async {
          final confirmed = await showConfirmationDialog(
            context: context,
            title: 'Want to Logout?',
            icon: Icons.error_outline,
            iconBackgroundColor: const Color(0xFF2C3E50),
            confirmText: 'Yes',
            cancelText: 'No',
          );

          if (confirmed == true) {
            try {
              await ref.read(authProvider.notifier).signOut();
            } catch (e) {
              print('[StudentProfileScreen] Error during signOut: $e');
            } finally {
              if (context.mounted) {
                context.go('/login');
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutMenu(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: PopupMenuButton<String>(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.more_vert,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
        ),
        onSelected: (value) async {
          if (value == 'take_tour') {
            await OnboardingFunnelService.instance.resetTour();
            ref.read(navigationIndexProvider.notifier).state = 0;
            ref.read(forceTourTriggerProvider.notifier).state++;
            return;
          }
          if (value == 'logout') {
            // Show logout confirmation dialog
            final confirmed = await showConfirmationDialog(
              context: context,
              title: 'Want to Logout?',
              icon: Icons.error_outline,
              iconBackgroundColor: const Color(0xFF2C3E50),
              confirmText: 'Yes',
              cancelText: 'No',
            );

            if (confirmed == true) {
              try {
                await ref.read(authProvider.notifier).signOut();
              } catch (e) {
                print('[StudentProfileScreen] Error during signOut: $e');
              } finally {
                if (context.mounted) {
                  context.go('/login');
                }
              }
            }
          } else if (value == 'delete_account') {
            // Show delete account confirmation dialog
            final confirmed = await showConfirmationDialog(
              context: context,
              title: 'Delete Account?',
              subtitle:
                  'This action cannot be undone. All your data will be permanently deleted.',
              icon: Icons.warning_outlined,
              iconBackgroundColor: AppColors.error,
              confirmText: 'Delete',
              cancelText: 'Cancel',
              confirmButtonColor: AppColors.error,
              confirmTextColor: Colors.white,
            );

            if (confirmed == true && context.mounted) {
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => PopScope(
                  canPop: false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.error),
                          SizedBox(height: 16),
                          Text(
                            'Deleting account...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // Call delete account API via AuthNotifier
                await ref.read(authProvider.notifier).deleteAccount();

                // Close loading
                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                // Redirect to login and show success
                if (context.mounted) {
                  context.go('/login');
                  showSuccessSnackBar(
                    context: context,
                    message: 'Account deleted successfully',
                  );
                }
              } catch (e) {
                // Close loading
                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                if (context.mounted) {
                  showErrorSnackBar(
                    context: context,
                    message: e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'take_tour',
            child: Row(
              children: [
                Icon(Icons.explore_outlined, size: 18, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Take Guided Tour',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete_account',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 8,
        offset: const Offset(0, 8),
      ),
    );
  }
}
