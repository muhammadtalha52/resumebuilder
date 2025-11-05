import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/plan_model.dart';
import '../../../widgets/plans/plan_card.dart';

class CandidatePlansScreen extends StatefulWidget {
  const CandidatePlansScreen({super.key});

  @override
  State<CandidatePlansScreen> createState() => _CandidatePlansScreenState();
}

class _CandidatePlansScreenState extends State<CandidatePlansScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPlanSelected(PlanModel plan) {
    // TODO: Implement plan selection logic
    // This will handle the subscription flow
    debugPrint('Selected plan: ${plan.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradientVertical,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeaderWithTitleAndClose(context),
              _buildSubtitle(),
              Expanded(child: _buildPlansCarousel()),
              _buildPageIndicator(),
              const SizedBox(height: AppSizes.paddingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithTitleAndClose(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Header Illustration - Centered and synced with current page
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                _getIconPathForPlan(PlanModel.allPlans[_currentPage].id),
                key: ValueKey(_currentPage),
                height: 280,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Title - Bottom (overlapping with illustration)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
              ),
              child: Text(
                'Pick The Right Plan For You',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Close Button - Top Right
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.primary),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIconPathForPlan(String planId) {
    switch (planId) {
      case 'basic':
        return 'assets/icons/basic.png';
      case 'pro':
        return 'assets/icons/pro.png';
      case 'enterprise':
        return 'assets/icons/enterprise.png';
      default:
        return 'assets/icons/fox-mascot.png';
    }
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Text(
        'Tap into AI tools that fine-tune your resume and interview skills for your dream job',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPlansCarousel() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: PlanModel.allPlans.length,
      itemBuilder: (context, index) {
        final plan = PlanModel.allPlans[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: PlanCard(plan: plan, onTap: () => _onPlanSelected(plan)),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        PlanModel.allPlans.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
