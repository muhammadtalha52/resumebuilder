import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/student_plan_model.dart';
import '../../models/purchase_product_model.dart';
import '../../providers/iap_provider.dart';
import '../../widgets/plans/student_plan_card.dart';

class StudentPlansScreen extends ConsumerStatefulWidget {
  const StudentPlansScreen({super.key});

  @override
  ConsumerState<StudentPlansScreen> createState() => _StudentPlansScreenState();
}

class _StudentPlansScreenState extends ConsumerState<StudentPlansScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Load plans mapping from backend when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iapProvider.notifier).loadPlansMapping();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onPlanSelected(StudentPlanModel plan) async {
    // Check if IAP is initialized
    final iapState = ref.read(iapProvider);

    if (!iapState.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              iapState.error ?? 'In-app purchases are not available',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Map plan ID to student product ID
    String productId;
    switch (plan.id) {
      case 'basic':
        productId = PurchaseProducts.studentBasicProductId;
        break;
      case 'pro':
        productId = PurchaseProducts.studentProProductId;
        break;
      case 'enterprise':
        productId = PurchaseProducts.studentEnterpriseProductId;
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid plan selected')),
          );
        }
        return;
    }

    print('[StudentPlansScreen] Initiating purchase for product: $productId');

    // Initiate purchase
    await ref.read(iapProvider.notifier).purchaseProduct(productId);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to IAP state changes for success/error messages
    ref.listen<IAPState>(iapProvider, (previous, next) {
      if (next.successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(iapProvider.notifier).clearSuccessMessage();

        // Close plans screen after successful purchase
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.pop();
          }
        });
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(iapProvider.notifier).clearError();
      }
    });

    final iapState = ref.watch(iapProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          // Loading overlay during purchase verification
          if (iapState.isPurchasing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text(
                        'Verifying your purchase...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
                _getIconPathForPlan(
                  StudentPlanModel.allStudentPlans[_currentPage].id,
                ),
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
        'Master your subjects with AI-powered study sessions and personalized quizzes',
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
    final iapState = ref.watch(iapProvider);

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: StudentPlanModel.allStudentPlans.length,
      itemBuilder: (context, index) {
        final plan = StudentPlanModel.allStudentPlans[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: StudentPlanCard(
            plan: plan,
            onTap: () => _onPlanSelected(plan),
            isLoading:
                iapState.isLoadingPlansMapping || iapState.isInitiatingCheckout,
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        StudentPlanModel.allStudentPlans.length,
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
