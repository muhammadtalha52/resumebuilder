import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/tag_list.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/profile_header.dart';
import 'edit_student_personal_details_screen.dart';
import 'edit_student_career_goals_screen.dart';
import 'edit_student_education_screen.dart';

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
                const ProfileHeader(),
                const SizedBox(height: 24),
                _buildPersonalDetailsCard(context, ref),
                const SizedBox(height: 16),
                _buildCareerGoalsCard(context, ref),
                const SizedBox(height: 16),
                _buildEducationCard(context, ref),
                const SizedBox(height: 20),
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EditStudentPersonalDetailsScreen(),
          ),
        );
      },
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRowWithDivider(
            'assets/icons/user.png',
            'Full Name',
            user?.fullName ?? 'Not provided',
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
            user?.phoneNumber ?? 'Not provided',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/work.png',
            'Home Town',
            user?.homeTown ?? 'Not provided',
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
        ['Not provided'];

    return ProfileCard(
      title: '🎯 Career Goals',
      onEdit: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EditStudentCareerGoalsScreen(),
          ),
        );
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

    return ProfileCard(
      title: '🎓 Education',
      onEdit: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EditStudentEducationScreen(),
          ),
        );
      },
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEducationDetailRow(
            user?.schoolMajor ?? 'Not provided',
            user?.schoolName ?? 'Not provided',
            user?.schoolGraduationDate ?? 'Not provided',
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
                    const SizedBox(height: 2),
                    Text(
                      major,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      school,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.smallCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
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
            ref.read(authProvider.notifier).signOut();
            context.go('/login');
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
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            }
          }
        },
        itemBuilder: (context) => [
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
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 8,
        offset: const Offset(0, 8),
      ),
    );
  }
}
