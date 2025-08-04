import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: const CustomAppBar(
        type: AppBarType.dashboard,
        showPremiumBadge: false,
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
                ProfileHeader(onboardingState: onboardingState),
                const SizedBox(height: 24),
                _buildPersonalDetailsCard(context, onboardingState),
                const SizedBox(height: 16),
                _buildCareerGoalsCard(context, onboardingState),
                const SizedBox(height: 16),
                _buildEducationCard(context, onboardingState),
                const SizedBox(height: 16),
                _buildWorkExperienceCard(context, onboardingState),
                const SizedBox(height: 16),
                _buildSkillsCard(context, onboardingState),
                const SizedBox(height: 16),
                _buildOthersCard(context, onboardingState),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(
    BuildContext context,
    OnboardingState state,
  ) {
    return ProfileCard(
      title: '👤 Personal Details',
      onEdit: () => context.go('/onboarding/step/1'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRowWithDivider(
            Icons.email_outlined,
            'Email Address',
            'abcd@gmail.com',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            Icons.phone_outlined,
            'Phone Number',
            '000-000-000',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            Icons.phone_android_outlined,
            'Whatsapp Number',
            '000-000-000',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            Icons.link_outlined,
            'LinkedIn Profile',
            'www.linkedin.com/in/yourname',
            showDivider: true,
          ),
          _buildDetailRowWithDivider(
            Icons.language_outlined,
            'Personal Website/Portfolio',
            'www.website.com',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCareerGoalsCard(BuildContext context, OnboardingState state) {
    return ProfileCard(
      title: '🎯 Career Goals & Preferences',
      onEdit: () => context.go('/onboarding/step/2'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCareerDetailRow(
            Icons.work_outline_rounded,
            'Desired Job Titles',
            [
              'UX Design',
              'UI Design',
              'Website Design',
              'Product Design',
              'Interaction Design',
            ],
            [
              const Color(0xFF2196F3),
              const Color(0xFF4CAF50),
              const Color(0xFFFF9800),
              const Color(0xFF9C27B0),
              const Color(0xFFF44336),
            ],
            showDivider: true,
          ),
          _buildCareerDetailRow(
            Icons.business_outlined,
            'Industry Preferences',
            ['IT Companies', 'Software House'],
            [const Color(0xFF2196F3), const Color(0xFF4CAF50)],
            showDivider: true,
          ),
          _buildCareerDetailRow(
            Icons.trending_up_outlined,
            'Long-term Career Goals',
            ['Company Manager', 'Leadership Role', 'Product owner'],
            [const Color(0xFF2196F3), const Color(0xFF4CAF50), const Color(0xFFFF9800)],
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(BuildContext context, OnboardingState state) {
    return ProfileCard(
      title: '🎓 Education',
      onEdit: () => context.go('/onboarding/step/3'),
      showDividers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEducationDetailRow(
            'Bachelor\'s in Computer Science',
            'Oxford University',
            '25 October 2018',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkExperienceCard(BuildContext context, OnboardingState state) {
    return ProfileCard(
      title: 'Work Experience',
      onEdit: () => context.go('/onboarding/step/4'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkEntry(
            'Senior Software Engineer',
            'Apple Inc.',
            'Present',
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text.',
          ),
          const SizedBox(height: 16),
          _buildWorkEntry(
            'Senior Software Engineer',
            'Apple Inc.',
            'July 2021 - May 2024',
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text.',
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context, OnboardingState state) {
    return ProfileCard(
      title: 'Skills & Tools',
      onEdit: () => context.go('/onboarding/step/5'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionWithTags(
            'Hard Skills, Soft Skills',
            ['Presentation', 'Speaking', 'Writing', 'Documentation'],
            [Colors.blue, Colors.green, Colors.orange, Colors.purple],
          ),
          const SizedBox(height: 16),
          _buildSectionWithTags(
            'Tools/Technologies',
            ['Figma', 'Miro', 'Coding', 'Frontend'],
            [Colors.blue, Colors.green, Colors.orange, Colors.red],
          ),
        ],
      ),
    );
  }

  Widget _buildOthersCard(BuildContext context, OnboardingState state) {
    return ProfileCard(
      title: 'Others',
      onEdit: () => context.go('/onboarding/step/6'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionWithTags(
            'Languages',
            ['English', 'Spanish', 'Dutch', 'Latin'],
            [Colors.blue, Colors.green, Colors.orange, Colors.purple],
          ),
          const SizedBox(height: 16),
          _buildSectionWithIcon('Volunteer Work', 'Field Work'),
          const SizedBox(height: 16),
          _buildSectionWithTags(
            'Hobbies & Interests',
            ['Painting', 'Singing', 'Dancing'],
            [Colors.blue, Colors.green, Colors.orange],
          ),
          const SizedBox(height: 16),
          _buildSectionWithIcon(
            'References',
            'Alex John, Senior Software Engineer at Google',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithDivider(
    IconData icon,
    String label,
    String value, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
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
    IconData icon,
    String label,
    List<String> tags,
    List<Color> colors, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(tags.length, (index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEEFF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            tags[index],
                            style: const TextStyle(
                              color: Color(0xFF7777F8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
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

  Widget _buildSectionWithTags(
    String title,
    List<String> tags,
    List<Color> colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tags.length, (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors[index % colors.length].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors[index % colors.length].withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                tags[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors[index % colors.length],
                ),
              ),
            );
          }),
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
            children: [
              Icon(Icons.school_outlined, size: 20, color: AppColors.textSecondary),
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
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Institution',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      institution,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Graduation Date',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
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

  Widget _buildWorkEntry(
    String title,
    String company,
    String duration,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              duration,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionWithIcon(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
