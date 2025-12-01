import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/education_data_provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/date_helpers.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/tag_list.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';
import '../../../widgets/invite_friends_card.dart';
import '../../../widgets/profile_card.dart';
import '../../../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
                const InviteFriendsCard(),
                const SizedBox(height: 16),
                const ProfileHeader(),
                const SizedBox(height: 16),
                _buildPersonalDetailsCard(context, ref),
                const SizedBox(height: 16),
                _buildCareerGoalsCard(context, ref),
                const SizedBox(height: 16),
                _buildEducationCard(context, ref),
                const SizedBox(height: 16),
                _buildWorkExperienceCard(context, ref),
                const SizedBox(height: 16),
                _buildSkillsCard(context, ref),
                const SizedBox(height: 16),
                _buildOthersCard(context, ref),
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
      onEdit: () => context.push('/profile/edit-personal-details'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRowWithDivider(
            'assets/icons/mail.png',
            'Email Address',
            user?.email ?? '',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/whatsapp.png',
            'WhatsApp Number',
            user?.phoneNumber ?? '',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/linkedin.png',
            'LinkedIn Profile',
            (user?.linkedinUrl != null && user!.linkedinUrl!.isNotEmpty)
                ? user.linkedinUrl!
                : '',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/website.png',
            'Personal Website/Portfolio',
            (user?.portfolioUrl != null && user!.portfolioUrl!.isNotEmpty)
                ? user.portfolioUrl!
                : '',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCareerGoalsCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return ProfileCard(
      title: '🎯 Career Goals & Preferences',
      onEdit: () => context.push('/profile/edit-career-goals'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCareerDetailRow(
            'assets/icons/goals.png',
            'Desired Job Titles',
            _extractJobTitles(user?.desiredJobTitles),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/industry.png',
            'Industry Preferences',
            _extractIndustryPreferences(user?.industryPreferences),
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/work.png',
            'Hometown & State',
            user?.homeTown ?? '',
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/work.png',
            'Preferred Work Arrangement',
            _extractLocationPreferences(user?.locationPreferences),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/long-term.png',
            'Long-term Career Goals',
            _extractCareerGoals(user?.careerGoals),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Get degree type name from ID
    final degreeTypeName = ref.watch(
      getDegreeTypeNameProvider(user?.degreeType),
    );

    // Get major name from ID
    final majorName = ref.watch(getMajorNameProvider(user?.major));

    // Get institution name (now stored as string directly)
    final institutionName = user?.institution ?? '';

    // Replace "Other" with "Not Specified" for display
    final displayDegreeType = _replaceOtherWithNotSpecified(degreeTypeName);
    final displayMajor = _replaceOtherWithNotSpecified(majorName);
    final displayInstitution = _replaceOtherWithNotSpecified(institutionName);

    // Get certification names
    final certifications = _extractCertifications(user?.certificationsTraining);
    final hasCertifications = certifications.isNotEmpty;

    // Format graduation date to MM/DD/YYYY
    String formattedGraduationDate = '';
    if (user?.graduationDate != null && user!.graduationDate!.isNotEmpty) {
      final parsedDate = DateHelpers.parseApiDate(user.graduationDate);
      if (parsedDate != null) {
        formattedGraduationDate = DateHelpers.formatToDisplayDate(parsedDate);
      }
    }

    return ProfileCard(
      title: '🎓 Education',
      onEdit: () => context.push('/profile/edit-education'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEducationDetailRow(
            displayDegreeType,
            displayMajor,
            displayInstitution,
            formattedGraduationDate,
            showDivider: hasCertifications,
          ),
          if (hasCertifications)
            _buildCareerDetailRow(
              'assets/icons/goals.png',
              'Certifications & Training',
              certifications,
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _buildWorkExperienceCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Create work experience entries from the new structure
    final workExperiences = _createWorkExperienceEntriesFromArray(
      user?.workExperience,
    );

    return ProfileCard(
      title: '🧑‍💼 Work Experience',
      onEdit: () => context.push('/profile/edit-work-experience'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: workExperiences.asMap().entries.map((entry) {
          final index = entry.key;
          final workExp = entry.value;
          final isLast = index == workExperiences.length - 1;

          return _buildWorkExperienceDetailRow(
            workExp['title'] ?? '',
            workExp['company'] ?? '',
            workExp['duration'] ?? '',
            workExp['responsibilities'] ?? '',
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return ProfileCard(
      title: '🛠️ Skills & Tools',
      onEdit: () => context.push('/profile/edit-skills-tools'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCareerDetailRow(
            'assets/icons/hard-soft-skills.png',
            'Hard Skills, Soft Skills',
            _extractAndCombineSkills(user?.hardSkills, user?.softSkills),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/tools-tech.png',
            'Tools/Technologies',
            _extractToolsTechnologies(user?.toolsTechnologies),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOthersCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return ProfileCard(
      title: '🌍 Others',
      onEdit: () => context.push('/profile/edit-others'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCareerDetailRow(
            'assets/icons/language-line.png',
            'Languages',
            _extractLanguages(user?.languages),
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/goals.png',
            'Volunteer Work',
            _extractVolunteerWork(user?.volunteerWork),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/industry.png',
            'Hobbies & Interests',
            _extractHobbiesInterests(user?.hobbiesInterests),
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/user.png',
            'References',
            (user?.references != null && user!.references!.isNotEmpty)
                ? user.references!
                : '',
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
    String degreeType,
    String major,
    String institution,
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
                    if (degreeType.isNotEmpty) ...[
                      RichText(
                        text: TextSpan(
                          text: 'Degree Type: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: degreeType,
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
                    if (institution.isNotEmpty) ...[
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
                              text: institution,
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

  Widget _buildWorkExperienceDetailRow(
    String title,
    String company,
    String duration,
    String responsibilities, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/icons/work.png', width: 20, height: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      company,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      responsibilities,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.4,
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
                color: Colors.black.withOpacity(0.05),
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
              final authState = ref.read(authProvider);
              final userId = authState.user?.id;

              if (userId != null) {
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
                  // Call delete account API
                  final authService = AuthService();
                  await authService.deleteAccount(userId: userId);

                  // Close loading
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  // Sign out and redirect to login
                  if (context.mounted) {
                    ref.read(authProvider.notifier).signOut();
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
              } else {
                if (context.mounted) {
                  showErrorSnackBar(
                    context: context,
                    message: 'User ID not found',
                  );
                }
              }
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

  List<Map<String, String?>> _createWorkExperienceEntriesFromArray(
    List<dynamic>? workExperienceArray,
  ) {
    // If no data exists, show a single "Not provided" entry
    if (workExperienceArray == null || workExperienceArray.isEmpty) {
      return [
        {'title': '', 'company': '', 'duration': '', 'responsibilities': ''},
      ];
    }

    final List<Map<String, String?>> workExperiences = [];

    // Create entries from the work experience array
    for (final exp in workExperienceArray) {
      // Format duration string
      String duration = '';
      if (exp.workStartDate != null) {
        try {
          final startDate = DateTime.parse(exp.workStartDate!);
          final startStr =
              '${_getMonthName(startDate.month)} ${startDate.year}';

          String endStr = 'Present';
          if (exp.isCurrentJob != true && exp.workEndDate != null) {
            final endDate = DateTime.parse(exp.workEndDate!);
            endStr = '${_getMonthName(endDate.month)} ${endDate.year}';
          }

          duration = '$startStr - $endStr';
        } catch (e) {
          // If date parsing fails, use fallback
          duration = 'Date not available';
        }
      }

      // Format responsibilities
      String responsibilities = '';
      if (exp.keyResponsibilities != null &&
          exp.keyResponsibilities!.isNotEmpty) {
        responsibilities = exp.keyResponsibilities!.join(', ');
      }

      workExperiences.add({
        'title': exp.jobTitle ?? '',
        'company': exp.companyName ?? '',
        'duration': duration,
        'responsibilities': responsibilities,
      });
    }

    return workExperiences;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  // Helper functions for extracting data from new object structures
  List<String> _extractJobTitles(List<dynamic>? desiredJobTitles) {
    if (desiredJobTitles == null || desiredJobTitles.isEmpty) {
      return [];
    }
    return desiredJobTitles
        .map((job) => job.title ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  List<String> _extractIndustryPreferences(List<dynamic>? industryPreferences) {
    if (industryPreferences == null || industryPreferences.isEmpty) {
      return [];
    }
    return industryPreferences
        .map((industry) => industry.industry ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  List<String> _extractCareerGoals(List<dynamic>? careerGoals) {
    if (careerGoals == null || careerGoals.isEmpty) {
      return [];
    }
    return careerGoals
        .map((goal) => goal.goal ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  List<String> _extractAndCombineSkills(
    List<dynamic>? hardSkills,
    List<dynamic>? softSkills,
  ) {
    final List<String> combined = [];

    if (hardSkills != null) {
      combined.addAll(
        hardSkills.map((skill) => skill.skill ?? 'Unknown').cast<String>(),
      );
    }

    if (softSkills != null) {
      combined.addAll(
        softSkills.map((skill) => skill.skill ?? 'Unknown').cast<String>(),
      );
    }

    return combined.isEmpty ? [] : combined;
  }

  List<String> _extractToolsTechnologies(List<dynamic>? toolsTechnologies) {
    if (toolsTechnologies == null || toolsTechnologies.isEmpty) {
      return [];
    }
    return toolsTechnologies
        .map((tool) => tool.tool ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  List<String> _extractLanguages(List<dynamic>? languages) {
    if (languages == null || languages.isEmpty) {
      return [];
    }
    return languages
        .map((language) => language.language ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  String _extractVolunteerWork(List<dynamic>? volunteerWork) {
    if (volunteerWork == null || volunteerWork.isEmpty) {
      return '';
    }

    final workDescriptions = volunteerWork
        .map((work) => work.description ?? '')
        .where((desc) => desc.isNotEmpty)
        .toList();

    return workDescriptions.isEmpty ? '' : workDescriptions.join(', ');
  }

  List<String> _extractHobbiesInterests(List<dynamic>? hobbiesInterests) {
    if (hobbiesInterests == null || hobbiesInterests.isEmpty) {
      return [];
    }
    return hobbiesInterests
        .map((hobby) => hobby.hobbyInterest ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  List<String> _extractLocationPreferences(List<dynamic>? locationPreferences) {
    if (locationPreferences == null || locationPreferences.isEmpty) {
      return [];
    }
    return locationPreferences
        .map((location) => location.location ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  List<String> _extractCertifications(List<dynamic>? certifications) {
    if (certifications == null || certifications.isEmpty) {
      return [];
    }
    return certifications
        .map((cert) => cert.name ?? 'Unknown')
        .cast<String>()
        .toList();
  }

  // Helper function to replace "Other" with "Not Specified" for display
  String _replaceOtherWithNotSpecified(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    // Case-insensitive check for "other"
    if (value.toLowerCase() == 'other') {
      return 'Not Specified';
    }
    return value;
  }
}
