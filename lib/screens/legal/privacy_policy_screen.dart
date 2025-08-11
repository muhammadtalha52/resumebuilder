import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppSizes.tabletBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background pattern
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          context.pop();
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isTablet ? AppSizes.paddingXL : AppSizes.paddingL,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusL,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Last Updated
                                Text(
                                  'Last updated: January 1, 2025',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                                const SizedBox(height: AppSizes.spaceL),

                                // Introduction
                                _buildSection(
                                  context,
                                  title: 'Introduction',
                                  content:
                                      'SkillResy ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
                                ),

                                _buildSection(
                                  context,
                                  title: 'Information We Collect',
                                  content:
                                      'We collect information you provide directly to us, such as when you create an account, fill out your profile, or contact us for support. This may include:',
                                  bulletPoints: [
                                    'Personal information (name, email address, phone number)',
                                    'Professional information (work history, education, skills)',
                                    'Profile information (LinkedIn URL, personal website)',
                                    'Resume data and documents you upload',
                                    'Usage data and analytics',
                                  ],
                                ),

                                _buildSection(
                                  context,
                                  title: 'How We Use Your Information',
                                  content:
                                      'We use the information we collect to:',
                                  bulletPoints: [
                                    'Provide, maintain, and improve our services',
                                    'Generate AI-powered resume suggestions and recommendations',
                                    'Send you technical notices and support messages',
                                    'Respond to your comments and questions',
                                    'Personalize your experience',
                                    'Monitor and analyze usage patterns and trends',
                                  ],
                                ),

                                _buildSection(
                                  context,
                                  title: 'Information Sharing',
                                  content:
                                      'We do not sell, trade, or rent your personal information to third parties. We may share your information in the following situations:',
                                  bulletPoints: [
                                    'With your consent or at your direction',
                                    'To comply with legal obligations',
                                    'To protect and defend our rights and property',
                                    'With service providers who assist in our operations',
                                    'In connection with a merger, sale, or acquisition',
                                  ],
                                ),

                                _buildSection(
                                  context,
                                  title: 'Data Security',
                                  content:
                                      'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure.',
                                ),

                                _buildSection(
                                  context,
                                  title: 'Your Rights',
                                  content: 'You have the right to:',
                                  bulletPoints: [
                                    'Access and receive a copy of your personal data',
                                    'Rectify or update inaccurate information',
                                    'Request deletion of your personal data',
                                    'Object to or restrict processing of your data',
                                    'Withdraw consent at any time',
                                    'Data portability',
                                  ],
                                ),

                                _buildSection(
                                  context,
                                  title: 'Data Retention',
                                  content:
                                      'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required by law.',
                                ),

                                _buildSection(
                                  context,
                                  title: 'Children\'s Privacy',
                                  content:
                                      'Our services are not intended for individuals under the age of 16. We do not knowingly collect personal information from children under 16. If you become aware that a child has provided us with personal information, please contact us.',
                                ),

                                _buildSection(
                                  context,
                                  title: 'Changes to This Policy',
                                  content:
                                      'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                                ),

                                _buildSection(
                                  context,
                                  title: 'Contact Us',
                                  content:
                                      'If you have any questions about this Privacy Policy or our privacy practices, please contact us at:',
                                  bulletPoints: [
                                    'Email: privacy@skillresy.com',
                                    'Address: SkillResy Inc., 123 Main Street, San Francisco, CA 94105',
                                    'Phone: +1 (555) 123-4567',
                                  ],
                                ),

                                const SizedBox(height: AppSizes.spaceXL),

                                // Agreement Button
                                Center(
                                  child: SizedBox(
                                    width: isTablet ? 300 : double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusM,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'I Understand',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    List<String>? bulletPoints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (bulletPoints != null) ...[
            const SizedBox(height: AppSizes.spaceS),
            ...bulletPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(
                  left: AppSizes.paddingM,
                  bottom: AppSizes.spaceXS,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
