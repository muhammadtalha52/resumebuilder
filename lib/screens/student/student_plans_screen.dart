import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/backend_plan_model.dart';
import '../../models/purchase_product_model.dart';

import '../../providers/iap_provider.dart';
import '../../providers/stripe_subscription_provider.dart';
import '../../providers/usage_provider.dart';
import '../../widgets/plans/active_subscription_card.dart';

import '../../widgets/plans/subscription_dialogs.dart';
import '../../widgets/plans/subscription_plan_card.dart';
import '../../widgets/plans/subscription_legal_footer.dart';

class StudentPlansScreen extends ConsumerStatefulWidget {
  const StudentPlansScreen({super.key});

  @override
  ConsumerState<StudentPlansScreen> createState() => _StudentPlansScreenState();
}

class _StudentPlansScreenState extends ConsumerState<StudentPlansScreen>
    with WidgetsBindingObserver {
  final PageController _iapPageController =
      PageController(viewportFraction: 0.92);
  int _currentIapPage = 0;

  // Documented fallback plans for Student (role 2)
  static const List<BackendPlanModel> _fallbackStudentPlans = [
    BackendPlanModel(
      id: 21,
      name: 'Cram Session',
      productId: PurchaseProducts.cramSessionProductId,
      price: '3.99',
      billingInterval: 'week',
      quizCount: 12,
      documentUploadCount: 25,
      trialDays: 7,
      trialQuizCount: 5,
      trialDocumentUploadCount: 10,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 22,
      name: 'Basic Student',
      productId: PurchaseProducts.basicStudentProductId,
      price: '5.00',
      billingInterval: 'month',
      quizCount: 10,
      documentUploadCount: 20,
      trialDays: 7,
      trialQuizCount: 5,
      trialDocumentUploadCount: 10,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 23,
      name: 'Mid Student',
      productId: PurchaseProducts.midStudentProductId,
      price: '10.00',
      billingInterval: 'month',
      quizCount: 25,
      documentUploadCount: 50,
      trialDays: 7,
      trialQuizCount: 5,
      trialDocumentUploadCount: 10,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 24,
      name: 'Nerd Out',
      productId: PurchaseProducts.nerdOutProductId,
      price: '15.00',
      billingInterval: 'month',
      quizCount: 50,
      documentUploadCount: 100,
      trialDays: 7,
      trialQuizCount: 5,
      trialDocumentUploadCount: 10,
      isSubscription: true,
      isRecommended: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.logPaywallShown(trigger: 'student_plans_screen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appLogic.accessToken.isNotEmpty) {
        // Load Stripe subscription plans only on Android
        if (!Platform.isIOS) {
          ref.read(stripeSubscriptionProvider.notifier).loadData(role: 2);
        }
        // Always load store IAP mapping
        ref.read(iapProvider.notifier).reloadProducts();
        ref.read(iapProvider.notifier).loadPlansMapping();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iapPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (appLogic.accessToken.isEmpty) return;
      if (!Platform.isAndroid) {
        final pendingSessionId =
            ref.read(stripeSubscriptionProvider).pendingSessionId;
        if (pendingSessionId != null && pendingSessionId.isNotEmpty) {
          ref
              .read(stripeSubscriptionProvider.notifier)
              .verifySession(pendingSessionId);
        } else {
          ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
        }
      } else {
        ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
      }
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    }
  }

  Future<bool> _ensureAuthenticated() async {
    if (appLogic.accessToken.isNotEmpty) return true;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Please log in or create an account to subscribe to this plan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
    if (shouldLogin == true && mounted) {
      context.push('/login');
    }
    return false;
  }

  Future<void> _onIapPlanSelected(BackendPlanModel plan) async {
    if (!await _ensureAuthenticated()) return;
    if (!mounted) return;
    final iapState = ref.read(iapProvider);
    if (!iapState.isInitialized) {
      await ref.read(iapProvider.notifier).reloadProducts();
    }

    String productId = plan.productId ?? '';
    if (productId.isEmpty) {
      final name = plan.name.toLowerCase();
      if (name.contains('cram')) {
        productId = PurchaseProducts.cramSessionProductId;
      } else if (name.contains('basic')) {
        productId = PurchaseProducts.basicStudentProductId;
      } else if (name.contains('mid')) {
        productId = PurchaseProducts.midStudentProductId;
      } else if (name.contains('nerd')) {
        productId = PurchaseProducts.nerdOutProductId;
      } else {
        productId = PurchaseProducts.cramSessionProductId;
      }
    }

    print('[StudentPlansScreen] Initiating Store IAP purchase for product: $productId');
    await ref.read(iapProvider.notifier).purchaseProduct(productId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StripeSubscriptionState>(stripeSubscriptionProvider,
        (previous, next) {
      if (next.successMessage != null && mounted) {
        ref.read(stripeSubscriptionProvider.notifier).clearSuccessMessage();
        context.go('/thank-you', extra: {'isTrial': false});
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(stripeSubscriptionProvider.notifier).clearError();
      }
    });

    ref.listen<IAPState>(iapProvider, (previous, next) {
      if (next.successMessage != null && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ref.read(iapProvider.notifier).clearSuccessMessage();
        context.go('/thank-you', extra: {'isTrial': false});
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(iapProvider.notifier).clearError();
      }
    });

    final stripeState = ref.watch(stripeSubscriptionProvider);
    final iapState = ref.watch(iapProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradientVertical,
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildHeaderWithTitleAndClose(context),
                        _buildSubtitle(),
                      ],
                    ),
                  ),

                  // Active Subscription Banner if user has one
                  if (stripeState.hasActiveSubscription)
                    SliverToBoxAdapter(
                      child: ActiveSubscriptionCard(
                        subscription: stripeState.subscription!,
                        payments: stripeState.payments,
                        isCanceling: stripeState.isCanceling,
                        onCancelOrUndo: () async {
                          final confirmed =
                              await SubscriptionDialogs.showCancelConfirmationDialog(
                            context: context,
                            subscription: stripeState.subscription!,
                          );
                          if (confirmed == true && mounted) {
                            await ref
                                .read(stripeSubscriptionProvider.notifier)
                                .cancelOrResumeSubscription(
                                  undo: stripeState
                                      .subscription!.cancelAtPeriodEnd,
                                );
                            ref
                                .read(usageProvider.notifier)
                                .fetchUsageAllocation();
                          }
                        },
                        onOpenInvoice: (url) {
                          ref
                              .read(stripeSubscriptionProvider.notifier)
                              .openInvoice(url);
                        },
                      ),
                    ),

                  // Plans Carousel
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 650,
                      child: _buildIapPlansCarousel(iapState, stripeState),
                    ),
                  ),

                  // Page Indicator and Rules
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildPageIndicator(stripeState),
                        const SizedBox(height: 12),
                        const SubscriptionLegalFooter(lightText: true),
                        const SizedBox(height: AppSizes.paddingL),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay during checkout verification (after returning from browser sheet)
          if (stripeState.isVerifying)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 18),
                      Text(
                        'Verifying your student subscription...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
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

  Widget _buildIapPlansCarousel(
      IAPState iapState, StripeSubscriptionState stripeState) {
    final plans =
        stripeState.plans.isNotEmpty ? stripeState.plans : _fallbackStudentPlans;

    return PageView.builder(
      controller: _iapPageController,
      onPageChanged: (index) {
        setState(() {
          _currentIapPage = index;
        });
      },
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return SubscriptionPlanCard(
          plan: plan,
          currentSubscription: stripeState.subscription,
          isOneTime: false,
          onSelect: () => _onIapPlanSelected(plan),
          isLoading:
              iapState.isLoadingPlansMapping || iapState.isPurchasing,
          onRestorePurchases: () => ref.read(iapProvider.notifier).restorePurchases(),
        );
      },
    );
  }

  Widget _buildHeaderWithTitleAndClose(BuildContext context) {
    final stripeState = ref.watch(stripeSubscriptionProvider);
    final trialPlan = stripeState.plans.cast<BackendPlanModel?>().firstWhere(
      (p) => p != null && p.hasTrial,
      orElse: () => null,
    );
    final trialDaysCount = trialPlan?.trialDays ?? 7;
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            height: 210,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Image.asset(
                  'assets/icons/fox-mascot.png',
                  height: 125,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '$trialDaysCount-Day Free Trial',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
              ),
              child: Text(
                'Student Learning Plans',
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
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(appLogic.accessToken.isNotEmpty ? '/home' : '/welcome');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 4),
      child: Text(
        'Supercharge your academic study sessions and quizzes with AI assistance',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPageIndicator(StripeSubscriptionState state) {
    final count = state.plans.isNotEmpty
        ? state.plans.length
        : _fallbackStudentPlans.length;
    final activeIndex = _currentIapPage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activeIndex == index ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activeIndex == index
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
