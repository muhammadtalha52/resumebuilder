import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Padding(
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
                            padding: const EdgeInsets.all(AppSizes.paddingXL),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.privacy_tip_outlined,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: AppSizes.spaceL),
                                Text(
                                  'Privacy Policy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSizes.spaceM),
                                Text(
                                  'View our privacy policy to learn how we collect, use, and protect your personal information.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSizes.spaceXL),
                                SizedBox(
                                  width: isTablet ? 300 : double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.parse(
                                        'https://skillresy.com/privacy-policy/',
                                      );
                                      try {
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint(
                                          'Error opening URL in browser: $e',
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_browser),
                                    label: const Text(
                                      'View Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
}
