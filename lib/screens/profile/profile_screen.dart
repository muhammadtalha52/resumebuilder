import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/education_data_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/tag_list.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        type: AppBarType.dashboard,
        showPremiumBadge: false,
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
            user?.email ?? 'Not provided',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/whatsapp.png',
            'Whatsapp Number',
            user?.phoneNumber ?? 'Not provided',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/linkedin.png',
            'LinkedIn Profile',
            (user?.linkedinUrl != null && user!.linkedinUrl!.isNotEmpty)
                ? user.linkedinUrl!
                : 'Not provided',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/website.png',
            'Personal Website/Portfolio',
            (user?.portfolioUrl != null && user!.portfolioUrl!.isNotEmpty)
                ? user.portfolioUrl!
                : 'Not provided',
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
            _parseCommaSeparatedString(user?.desiredJobTitles),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/industry.png',
            'Industry Preferences',
            _parseCommaSeparatedString(user?.industryPreferences),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/long-term.png',
            'Long-term Career Goals',
            _parseCommaSeparatedString(user?.longTermCareerGoals),
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

    // Get institution name from ID
    final institutionName = ref.watch(
      getInstitutionNameProvider(user?.institution),
    );

    // Format degree with major
    final degreeText = _formatDegreeText(degreeTypeName, majorName);

    return ProfileCard(
      title: '🎓 Education',
      onEdit: () => context.push('/profile/edit-education'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEducationDetailRow(
            degreeText,
            institutionName ?? 'Not provided',
            user?.graduationDate ?? 'Not provided',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkExperienceCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Parse work experience data
    final jobTitles = _parseCommaSeparatedStringToList(user?.jobTitles);
    final companyNames = _parseCommaSeparatedStringToList(user?.companyNames);
    final workDuration = _parseCommaSeparatedStringToList(user?.workDuration);
    final keyResponsibilities = _parseCommaSeparatedStringToList(
      user?.keyResponsibilities,
    );

    // Create work experience entries (assume they correspond by index)
    final workExperiences = _createWorkExperienceEntries(
      jobTitles,
      companyNames,
      workDuration,
      keyResponsibilities,
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
            workExp['title'] ?? 'Not provided',
            workExp['company'] ?? 'Not provided',
            workExp['duration'] ?? 'Not provided',
            workExp['responsibilities'] ?? 'Not provided',
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
            _combineSkills(user?.hardSkills, user?.softSkills),
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/tools-tech.png',
            'Tools/Technologies',
            _parseCommaSeparatedString(user?.toolsTechnologies),
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
            _parseCommaSeparatedString(user?.languages),
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/goals.png',
            'Volunteer Work',
            (user?.volunteerWork != null && user!.volunteerWork!.isNotEmpty)
                ? user.volunteerWork!
                : 'Not provided',
            showDivider: true,
          ),
          _buildCareerDetailRow(
            'assets/icons/industry.png',
            'Hobbies & Interests',
            _parseCommaSeparatedString(user?.hobbiesInterests),
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            'assets/icons/user.png',
            'References',
            (user?.references != null && user!.references!.isNotEmpty)
                ? user.references!
                : 'Not provided',
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
    String degree,
    String institution,
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
                      degree,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      institution,
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

  List<String> _parseCommaSeparatedString(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ['Not provided'];
    }

    final parsed = input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return parsed.isEmpty ? ['Not provided'] : parsed;
  }

  String _formatDegreeText(String? degreeType, String? major) {
    if (degreeType == null || degreeType.isEmpty) {
      return 'Not provided';
    }

    if (major == null || major.isEmpty) {
      return degreeType;
    }

    return '$degreeType in $major';
  }

  List<String> _parseCommaSeparatedStringToList(String? input) {
    if (input == null || input.trim().isEmpty) {
      return [];
    }

    return input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, String?>> _createWorkExperienceEntries(
    List<String> jobTitles,
    List<String> companyNames,
    List<String> workDuration,
    List<String> keyResponsibilities,
  ) {
    // If no data exists, show a single "Not provided" entry
    if (jobTitles.isEmpty &&
        companyNames.isEmpty &&
        workDuration.isEmpty &&
        keyResponsibilities.isEmpty) {
      return [
        {
          'title': 'Not provided',
          'company': 'Not provided',
          'duration': 'Not provided',
          'responsibilities': 'Not provided',
        },
      ];
    }

    // Find the maximum length among all lists
    final maxLength = [
      jobTitles.length,
      companyNames.length,
      workDuration.length,
      keyResponsibilities.length,
    ].reduce((a, b) => a > b ? a : b);

    // Create work experience entries
    final List<Map<String, String?>> workExperiences = [];

    for (int i = 0; i < maxLength; i++) {
      workExperiences.add({
        'title': i < jobTitles.length ? jobTitles[i] : 'Not provided',
        'company': i < companyNames.length ? companyNames[i] : 'Not provided',
        'duration': i < workDuration.length ? workDuration[i] : 'Not provided',
        'responsibilities': i < keyResponsibilities.length
            ? keyResponsibilities[i]
            : 'Not provided',
      });
    }

    return workExperiences;
  }

  List<String> _combineSkills(String? hardSkills, String? softSkills) {
    final hardSkillsList = _parseCommaSeparatedStringToList(hardSkills);
    final softSkillsList = _parseCommaSeparatedStringToList(softSkills);

    final combinedSkills = [...hardSkillsList, ...softSkillsList];

    if (combinedSkills.isEmpty) {
      return ['Not provided'];
    }

    return combinedSkills;
  }
}
