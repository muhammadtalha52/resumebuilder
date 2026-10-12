import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/welcome_page_data.dart';
import '../../services/app_preferences.dart';
import '../../widgets/page_indicator.dart';
import '../../widgets/common/server_url_tap_detector.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<WelcomePageData> _pages = WelcomePageData.welcomePages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark welcome screens as complete
      await AppPreferences.markWelcomeComplete();
      // Navigate to login screen for new users
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background pattern
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background2.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Logo at top
                Padding(
                  padding: EdgeInsets.only(
                    top: isTablet ? 40 : 20,
                    left: 20,
                    right: 20,
                  ),
                  child: ServerUrlTapDetector(
                    child: Image.asset(
                      'assets/icons/logo-fox-on-left.png',
                      height: isTablet ? 70 : 60,
                    ),
                  ),
                ),
                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildWelcomePage(_pages[index], isTablet);
                    },
                  ),
                ),
                // Bottom navigation
                Padding(
                  padding: EdgeInsets.all(isTablet ? 40 : 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicators
                      PageIndicator(
                        currentPage: _currentPage,
                        totalPages: _pages.length,
                      ),
                      // Next button
                      _buildNextButton(_pages[_currentPage].isLastPage),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(WelcomePageData pageData, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Main illustration area - centered
          Center(
            child: Image.asset(
              pageData.mainImage,
              height: isTablet ? 350 : 300,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(flex: 1),
          // Text content - left aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pageData.title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 16),
              // Description
              Text(
                pageData.description,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildNextButton(bool isLastPage) {
    if (isLastPage) {
      return SizedBox(
        width: 120,
        height: 56,
        child: ElevatedButton(
          onPressed: _onNextPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: IconButton(
          onPressed: _onNextPressed,
          icon: const Icon(
            Icons.arrow_forward,
            color: AppColors.white,
            size: 24,
          ),
          padding: EdgeInsets.zero,
        ),
      );
    }
  }
}
